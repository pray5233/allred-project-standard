param(
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$StandardRoot = (Join-Path (Split-Path -Parent $LabRoot) 'allred-project-standard')
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Read-JsonFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    $script:failures.Add("Missing: $Path") | Out-Null
    return $null
  }
  try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch {
    $script:failures.Add("Invalid JSON: $Path") | Out-Null
    return $null
  }
}

$required = @(
  'tests\impact-map.json',
  'tests\replay-cases.json',
  'tests\replay-oracle.json',
  'tests\comparison-result.schema.json',
  'tests\behavior-trial-aggregation-fixtures.json',
  'scripts\eval_runtime.ps1',
  'scripts\check_standard_fast.ps1',
  'scripts\aggregate_behavior_trials.ps1',
  'scripts\invoke_behavior_eval_batch.ps1',
  'scripts\invoke_blind_comparison_batch.ps1',
  'scripts\resolve_impacted_cases.ps1',
  'scripts\run_replay_eval.ps1',
  'scripts\run_blind_comparison.ps1',
  'scripts\write_validation_report.ps1',
  'scripts\invoke_candidate_validation.ps1',
  'scripts\run_ci_behavior.ps1'
)
foreach ($relative in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $LabRoot $relative))) {
    $failures.Add("Missing candidate-validation file: $relative") | Out-Null
  }
}

$impact = Read-JsonFile (Join-Path $LabRoot 'tests\impact-map.json')
$replays = Read-JsonFile (Join-Path $LabRoot 'tests\replay-cases.json')
$oracle = Read-JsonFile (Join-Path $LabRoot 'tests\replay-oracle.json')
$behavior = Read-JsonFile (Join-Path $StandardRoot 'tests\behavior-cases.test.json')
$labBehavior = Read-JsonFile (Join-Path $LabRoot 'tests\behavior-cases.test.json')

if ($impact -and $behavior -and $labBehavior -and $replays) {
  $behaviorIds = @($behavior.cases.id)
  $labIds = @($labBehavior.cases.id)
  $replayIds = @($replays.cases.id)
  $referencedCases = @($impact.default_release_case_ids) + @($impact.rules | ForEach-Object { @($_.case_ids) + @($_.adjacent_case_ids) })
  foreach ($id in @($referencedCases | Sort-Object -Unique)) {
    if ($id -notin $behaviorIds) { $failures.Add("Impact map references unknown behavior case: $id") | Out-Null }
  }
  foreach ($id in @($impact.default_lab_case_ids)) {
    if ($id -notin $labIds) { $failures.Add("Impact map references unknown Lab case: $id") | Out-Null }
  }
  foreach ($id in @($impact.default_replay_case_ids)) {
    if ($id -notin $replayIds) { $failures.Add("Impact map references unknown replay case: $id") | Out-Null }
  }

  try {
    $repoRoot = (Resolve-Path (Join-Path $LabRoot '..\..\..')).Path
    $resolvedText = (& (Join-Path $LabRoot 'scripts\resolve_impacted_cases.ps1') -RepoRoot $repoRoot -StandardRoot $StandardRoot -LabRoot $LabRoot -BaselineRef HEAD -IncludeAdjacent) -join "`n"
    $resolvedImpact = $resolvedText | ConvertFrom-Json
    foreach ($id in @($resolvedImpact.standard_case_ids)) {
      if ($id -notin $behaviorIds) { $failures.Add("Impact resolver selected non-runnable behavior case: $id") | Out-Null }
    }
  } catch {
    $failures.Add("Impact resolver integration check failed: $($_.Exception.Message)") | Out-Null
  }
}

if ($replays -and $oracle) {
  $testIds = @($replays.cases.id)
  $oracleIds = @($oracle.cases.id)
  if (@($testIds | Sort-Object -Unique).Count -ne $testIds.Count) { $failures.Add('Duplicate replay case ID.') | Out-Null }
  foreach ($id in $testIds) {
    if ($id -notin $oracleIds) { $failures.Add("Missing replay Oracle: $id") | Out-Null }
    $case = $replays.cases | Where-Object id -eq $id | Select-Object -First 1
    if (@($case.transcript).Count -lt 2) { $failures.Add("Replay transcript is too short: $id") | Out-Null }
  }
  foreach ($item in @($oracle.cases)) {
    if ($item.id -notin $testIds) { $failures.Add("Oracle-only replay case: $($item.id)") | Out-Null }
    if ($item.expected_result -notin @('Pass', 'Fail')) { $failures.Add("Unsupported replay expectation: $($item.id)") | Out-Null }
    if (@($item.assertions).Count -eq 0 -or @($item.hard_failures).Count -eq 0) { $failures.Add("Incomplete replay Oracle: $($item.id)") | Out-Null }
  }
}

$batchWrapperText = Get-Content -LiteralPath (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1') -Raw -Encoding UTF8
foreach ($trialContract in @('[int]$InitialTrials = 1', '[int]$RetryTrials = 2', '[int]$MinimumAgreement = 1', "'trial-{0:d2}'", 'aggregate_behavior_trials.ps1', "aggregate_result -in @('StablePass', 'StableFail')")) {
  if (-not $batchWrapperText.Contains($trialContract)) { $failures.Add("Behavior batch wrapper is missing multi-trial contract: $trialContract") | Out-Null }
}
foreach ($failFastContract in @("status = 'NotRun'", 'Skipped after an earlier P0 case did not pass.', '$attemptedCaseIds.Contains($caseId)', "Where-Object priority -eq 'P0'")) {
  if (-not $batchWrapperText.Contains($failFastContract)) { $failures.Add("Behavior batch wrapper is missing fail-fast reporting contract: $failFastContract") | Out-Null }
}
if (-not $batchWrapperText.Contains('ModelProvider = $ModelProvider') -or -not $batchWrapperText.Contains('ProviderEnvKey = $ProviderEnvKey')) {
  $failures.Add('Behavior batch wrapper does not propagate provider selection without credentials.') | Out-Null
}
foreach ($parallelContract in @('[int]$MaxParallelCases = 1', 'Start-Job -Name $caseId', "'.parallel-parts'", '$hasFailures = $true', '$stopAfterBatch = $true')) {
  if (-not $batchWrapperText.Contains($parallelContract)) { $failures.Add("Behavior batch wrapper is missing parallel contract: $parallelContract") | Out-Null }
}
foreach ($aggregationContract in @('Parallel aggregation found $($matches.Count) results; expected exactly one.', 'ConvertTo-Json -InputObject ([object[]]$orderedResults)', "aggregate_result -ne 'StablePass'", "Where-Object aggregate_result -ne 'InfrastructureInconclusive'")) {
  if (-not $batchWrapperText.Contains($aggregationContract)) { $failures.Add("Behavior batch wrapper is missing exact-result aggregation: $aggregationContract") | Out-Null }
}
if (-not $batchWrapperText.Contains('foreach ($caseId in $decodedCaseIds)')) {
  $failures.Add('Behavior batch wrapper does not normalize PowerShell 5.1 JSON arrays.') | Out-Null
}
foreach ($pathContract in @('$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path', '$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path', '$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path')) {
  if (-not $batchWrapperText.Contains($pathContract)) { $failures.Add("Behavior batch wrapper is missing background-job path normalization: $pathContract") | Out-Null }
}

$aggregationFixtures = Read-JsonFile (Join-Path $LabRoot 'tests\behavior-trial-aggregation-fixtures.json')
$aggregatorPath = Join-Path $LabRoot 'scripts\aggregate_behavior_trials.ps1'
if ($aggregationFixtures -and (Test-Path -LiteralPath $aggregatorPath)) {
  $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-trial-aggregation-" + [Guid]::NewGuid().ToString('N'))
  try {
    New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
    foreach ($fixture in @($aggregationFixtures.fixtures)) {
      $caseId = [string]$fixture.id
      $caseRoot = Join-Path $fixtureRoot $caseId
      New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null
      $trialNumber = 0
      foreach ($trial in @($fixture.trials)) {
        $trialNumber++
        $trialRoot = Join-Path $caseRoot ('trial-{0:d2}' -f $trialNumber)
        $caseTrialRoot = Join-Path $trialRoot $caseId
        New-Item -ItemType Directory -Force -Path $caseTrialRoot | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $caseTrialRoot 'transcript.json'), '[]', [System.Text.UTF8Encoding]::new($false))
        $reviewPath = Join-Path $caseTrialRoot 'review.json'
        if ($trial.status -eq 'Evaluated') {
          $review = [ordered]@{ case_id = $caseId; result = $trial.result; first_divergent_turn = $trial.first_divergent_turn; failed_assertions = @(); hard_failures = @($trial.hard_failures); notes = 'fixture' }
          [System.IO.File]::WriteAllText($reviewPath, ($review | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
        }
        $summaryItem = [pscustomobject]@{ case_id = $caseId; priority = 'P0'; status = $trial.status; result = $trial.result; first_divergent_turn = $trial.first_divergent_turn; report = if ($trial.status -eq 'Evaluated') { $reviewPath } else { $null }; infrastructure_reason = if ($trial.status -eq 'InfrastructureFailure') { 'fixture infrastructure failure' } else { $null } }
        [System.IO.File]::WriteAllText((Join-Path $trialRoot 'summary.json'), (ConvertTo-Json -InputObject ([object[]]@($summaryItem)) -Depth 5), [System.Text.UTF8Encoding]::new($false))
        $runtimeHash = if ($trial.PSObject.Properties['runtime_hash']) { [string]$trial.runtime_hash } else { 'runtime' }
        $config = [ordered]@{ skill_md_sha256 = 'skill'; runtime_surface_sha256 = $runtimeHash; test_suite_sha256 = 'tests'; oracle_suite_sha256 = 'oracle'; model_override = 'fixture'; model_provider_override = ''; provider_env_key_name = ''; reasoning_effort_override = 'low'; timeout_seconds = 60; use_user_config = $false; disable_plugins = $true; stateless_turns = $true; user_config_sha256 = $null }
        [System.IO.File]::WriteAllText((Join-Path $trialRoot 'run-config.json'), ($config | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
      }
      $aggregatePath = Join-Path $caseRoot 'aggregate.json'
      & $aggregatorPath -CaseRoot $caseRoot -CaseId $caseId -MinimumAgreement ([int]$fixture.minimum_agreement) -OutputPath $aggregatePath | Out-Null
      $aggregate = Get-Content -LiteralPath $aggregatePath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($aggregate.aggregate_result -ne $fixture.expected) { $failures.Add("Trial aggregation fixture $caseId returned $($aggregate.aggregate_result); expected $($fixture.expected).") | Out-Null }
      if ($aggregate.trial_count -ne @($fixture.trials).Count) { $failures.Add("Trial aggregation fixture $caseId lost trial evidence.") | Out-Null }
    }
  } catch {
    $failures.Add("Trial aggregation fixture check failed: $($_.Exception.Message)") | Out-Null
  } finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
  }
}

$batchContractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-batch-contract-" + [Guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Force -Path $batchContractRoot | Out-Null
  $fakeRunnerPath = Join-Path $batchContractRoot 'fake_behavior_runner.ps1'
  $fakeSuiteRoot = Join-Path $batchContractRoot 'fake-suite'
  New-Item -ItemType Directory -Force -Path (Join-Path $fakeSuiteRoot 'tests') | Out-Null
  $fakeCases = @('first-pass', 'retry-pass', 'stable-fail', 'infrastructure') | ForEach-Object { [pscustomobject]@{ id = $_; priority = 'P0' } }
  [System.IO.File]::WriteAllText((Join-Path $fakeSuiteRoot 'tests\behavior-cases.test.json'), ([ordered]@{ cases = @($fakeCases) } | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
  $fakeRunner = @'
param(
  [string]$SkillRoot,
  [string]$SuiteRoot,
  [string]$OutputRoot,
  [string[]]$CaseIds,
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [string]$ReasoningEffort = 'low',
  [int]$TimeoutSeconds = 60,
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [switch]$StatelessTurns,
  [switch]$FailFastP0
)
$caseId = [string]$CaseIds[0]
$trialName = Split-Path -Leaf $OutputRoot
$trialNumber = [int]($trialName -replace '[^0-9]', '')
$status = 'Evaluated'
$result = 'Pass'
$hardFailures = @()
if ($caseId -eq 'retry-pass' -and $trialNumber -eq 1) { $result = 'Partial' }
if ($caseId -eq 'stable-fail') { $result = 'Fail'; $hardFailures = @('same hard failure') }
if ($caseId -eq 'infrastructure') { $status = 'InfrastructureFailure'; $result = $null }
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$caseRoot = Join-Path $OutputRoot $caseId
New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null
[System.IO.File]::WriteAllText((Join-Path $caseRoot 'transcript.json'), '[]', [System.Text.UTF8Encoding]::new($false))
$reviewPath = Join-Path $caseRoot 'review.json'
if ($status -eq 'Evaluated') {
  $review = [ordered]@{ case_id = $caseId; result = $result; first_divergent_turn = if ($result -eq 'Pass') { $null } else { 1 }; failed_assertions = @(); hard_failures = @($hardFailures); notes = 'fake runner' }
  [System.IO.File]::WriteAllText($reviewPath, ($review | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
}
$item = [pscustomobject]@{ case_id = $caseId; priority = 'P0'; status = $status; result = $result; first_divergent_turn = if ($result -eq 'Pass') { $null } else { 1 }; report = if ($status -eq 'Evaluated') { $reviewPath } else { $null }; infrastructure_reason = if ($status -eq 'InfrastructureFailure') { 'fake infrastructure failure' } else { $null } }
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'summary.json'), (ConvertTo-Json -InputObject ([object[]]@($item)) -Depth 5), [System.Text.UTF8Encoding]::new($false))
$config = [ordered]@{ skill_md_sha256 = 'skill'; runtime_surface_sha256 = 'runtime'; test_suite_sha256 = 'tests'; oracle_suite_sha256 = 'oracle'; case_ids = @($caseId); model_override = $Model; model_provider_override = $ModelProvider; provider_env_key_name = $ProviderEnvKey; reasoning_effort_override = $ReasoningEffort; timeout_seconds = $TimeoutSeconds; use_user_config = [bool]$UseUserConfig; disable_plugins = [bool]$DisablePlugins; stateless_turns = [bool]$StatelessTurns; user_config_sha256 = $null }
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'run-config.json'), ($config | ConvertTo-Json -Depth 5), [System.Text.UTF8Encoding]::new($false))
if ($status -eq 'InfrastructureFailure') { exit 3 }
if ($result -ne 'Pass') { exit 2 }
exit 0
'@
  [System.IO.File]::WriteAllText($fakeRunnerPath, $fakeRunner, [System.Text.UTF8Encoding]::new($false))
  $caseIdsPath = Join-Path $batchContractRoot 'case-ids.json'
  [System.IO.File]::WriteAllText($caseIdsPath, (ConvertTo-Json -InputObject ([object[]]@('first-pass', 'retry-pass', 'stable-fail', 'infrastructure'))), [System.Text.UTF8Encoding]::new($false))
  $batchOutput = Join-Path $batchContractRoot 'batch-output'
  & (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1') -RunnerPath $fakeRunnerPath -SkillRoot $LabRoot -SuiteRoot $fakeSuiteRoot -OutputRoot $batchOutput -CaseIdsPath $caseIdsPath -InitialTrials 2 -RetryTrials 1 -MinimumAgreement 2 -MaxParallelCases 2 | Out-Null
  $batchExit = $LASTEXITCODE
  $decodedBatchSummary = Get-Content -LiteralPath (Join-Path $batchOutput 'summary.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $batchSummary = @()
  foreach ($entry in $decodedBatchSummary) { $batchSummary += $entry }
  $expectedBatch = @{ 'first-pass' = @('StablePass', 2); 'retry-pass' = @('StablePass', 3); 'stable-fail' = @('StableFail', 2); 'infrastructure' = @('InfrastructureInconclusive', 3) }
  foreach ($caseId in $expectedBatch.Keys) {
    $item = $batchSummary | Where-Object case_id -eq $caseId | Select-Object -First 1
    if ($null -eq $item -or $item.aggregate_result -ne $expectedBatch[$caseId][0] -or [int]$item.trial_count -ne [int]$expectedBatch[$caseId][1]) {
      $actual = if ($null -eq $item) { 'missing' } else { "$($item.aggregate_result)/$($item.trial_count)" }
      $failures.Add("Behavior batch retry contract failed for ${caseId}: actual $actual; expected $($expectedBatch[$caseId][0])/$($expectedBatch[$caseId][1]).") | Out-Null
    }
  }
  $retryRepresentative = $batchSummary | Where-Object case_id -eq 'retry-pass' | Select-Object -First 1
  if ($null -eq $retryRepresentative -or $retryRepresentative.representative_trial -ne 'trial-01') { $failures.Add('Behavior batch selected a best-scoring retry instead of the first semantic trial.') | Out-Null }
  if ($batchExit -ne 2) { $failures.Add("Mixed behavior batch returned exit $batchExit; expected 2.") | Out-Null }

  $failFastIdsPath = Join-Path $batchContractRoot 'fail-fast-case-ids.json'
  [System.IO.File]::WriteAllText($failFastIdsPath, (ConvertTo-Json -InputObject ([object[]]@('stable-fail', 'first-pass', 'retry-pass'))), [System.Text.UTF8Encoding]::new($false))
  $failFastOutput = Join-Path $batchContractRoot 'fail-fast-output'
  & (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1') -RunnerPath $fakeRunnerPath -SkillRoot $LabRoot -SuiteRoot $fakeSuiteRoot -OutputRoot $failFastOutput -CaseIdsPath $failFastIdsPath -InitialTrials 1 -RetryTrials 1 -MinimumAgreement 1 -MaxParallelCases 2 -FailFastP0 | Out-Null
  $decodedFailFastSummary = Get-Content -LiteralPath (Join-Path $failFastOutput 'summary.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $failFastSummary = @()
  foreach ($entry in $decodedFailFastSummary) { $failFastSummary += $entry }
  $notRun = $failFastSummary | Where-Object case_id -eq 'retry-pass' | Select-Object -First 1
  if ($null -eq $notRun -or $notRun.aggregate_result -ne 'NotRun') {
    $actual = if ($null -eq $notRun) { 'missing' } else { [string]$notRun.aggregate_result }
    $failures.Add("P0 fail-fast did not preserve the unattempted case as NotRun; actual $actual.") | Out-Null
  }

  $reportSummaryPath = Join-Path $batchContractRoot 'validation-summary.json'
  $reportSummary = [ordered]@{
    schema_version = 1
    mode = 'Changed'
    result = 'FAIL'
    baseline_ref = 'fixture'
    started_at_utc = [DateTime]::UtcNow.ToString('o')
    finished_at_utc = [DateTime]::UtcNow.ToString('o')
    impact = [ordered]@{ warnings = @(); changed_paths = @() }
    selection = [ordered]@{ standard_case_ids = @('first-pass', 'retry-pass', 'stable-fail', 'infrastructure'); lab_case_ids = @(); replay_case_ids = @() }
    steps = @()
    behavior_evidence = [ordered]@{ diagnostic = [ordered]@{ total_cases = 4; counts = [ordered]@{ StablePass = 2; StableFail = 1; Variable = 0; InfrastructureInconclusive = 1; NotRun = 0 }; cases = @($batchSummary) } }
    failures = @('fixture')
  }
  [System.IO.File]::WriteAllText($reportSummaryPath, ($reportSummary | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
  & (Join-Path $LabRoot 'scripts\write_validation_report.ps1') -SummaryPath $reportSummaryPath | Out-Null
  $reportText = Get-Content -LiteralPath (Join-Path $batchContractRoot 'report.md') -Raw -Encoding UTF8
  if (-not $reportText.Contains('## Behavior Consistency') -or -not $reportText.Contains('| diagnostic | 4 | 2 | 1 | 0 | 1 | 0 |')) { $failures.Add('Validation report does not render aggregate behavior evidence.') | Out-Null }
} catch {
  $failures.Add("Behavior batch contract check failed: $($_.Exception.Message)") | Out-Null
} finally {
  if ($env:ALLRED_KEEP_HARNESS_ARTIFACTS -eq '1') { "Behavior batch debug artifacts: $batchContractRoot" }
  elseif (Test-Path -LiteralPath $batchContractRoot) { Remove-Item -LiteralPath $batchContractRoot -Recurse -Force }
}
$blindBatchText = Get-Content -LiteralPath (Join-Path $LabRoot 'scripts\invoke_blind_comparison_batch.ps1') -Raw -Encoding UTF8
foreach ($parallelContract in @('[int]$MaxParallelCases = 1', 'Start-Job -Name $caseId', "'.parallel-parts'", "candidate_outcome -eq 'BaselineBetter'")) {
  if (-not $blindBatchText.Contains($parallelContract)) { $failures.Add("Blind comparison wrapper is missing parallel contract: $parallelContract") | Out-Null }
}
foreach ($blindPathContract in @('$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path', '$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path', '$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path', '$CandidateRunRoot = (Resolve-Path -LiteralPath $CandidateRunRoot).Path', '$BaselineRunRoot = (Resolve-Path -LiteralPath $BaselineRunRoot).Path')) {
  if (-not $blindBatchText.Contains($blindPathContract)) { $failures.Add("Blind comparison wrapper is missing path normalization: $blindPathContract") | Out-Null }
}
foreach ($blindAggregationContract in @('foreach ($caseId in $decodedCaseIds)', 'Parallel comparison aggregation found $($matches.Count) results; expected exactly one.', 'ConvertTo-Json -InputObject ([object[]]$orderedResults)')) {
  if (-not $blindBatchText.Contains($blindAggregationContract)) { $failures.Add("Blind comparison wrapper is missing exact-result aggregation: $blindAggregationContract") | Out-Null }
}

$behaviorRunnerText = Get-Content -LiteralPath (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1') -Raw -Encoding UTF8
foreach ($resultContract in @('CommandResults = @($commandResults)', 'observed_command_results = @($run.CommandResults)', '[command output truncated]', 'runtime_surface_sha256 = Get-RuntimeSurfaceHash -Root $SkillRoot')) {
  if (-not $behaviorRunnerText.Contains($resultContract)) { $failures.Add("Behavior transcript is missing command-result evidence: $resultContract") | Out-Null }
}
foreach ($statelessContract in @('[switch]$StatelessTurns', 'New-StatelessContinuationPrompt', 'PRIOR TRANSCRIPT JSON:', 'stateless_turns = [bool]$StatelessTurns', '$Run.TurnCompleted', '$Run.TurnFailed')) {
  if (-not $behaviorRunnerText.Contains($statelessContract)) { $failures.Add("Behavior runner is missing stateless replay contract: $statelessContract") | Out-Null }
}
if (-not $batchWrapperText.Contains('StatelessTurns = [bool]$StatelessTurns')) {
  $failures.Add('Behavior batch wrapper does not propagate stateless replay mode.') | Out-Null
}

$candidateText = Get-Content -LiteralPath (Join-Path $LabRoot 'scripts\invoke_candidate_validation.ps1') -Raw -Encoding UTF8
$failFastContracts = @(
  '$dynamicBlocked = $staticFailed',
  'if (-not $dynamicBlocked -and $selectedLab.Count -gt 0)',
  'if (-not $dynamicBlocked -and $selectedStandard.Count -gt 0)',
  "if (`$Mode -eq 'Candidate' -and -not `$dynamicBlocked)",
  "if (-not (Invoke-ValidationStep -Name 'candidate-behavior-high'",
  "if (`$Mode -eq 'Candidate') { `$arguments.Add('-FailFastP0') }",
  "if (-not `$replayPassed -and `$Mode -eq 'Candidate')",
  "if (-not `$labPassed -and `$Mode -eq 'Candidate')"
)
foreach ($contract in $failFastContracts) {
  if (-not $candidateText.Contains($contract)) {
    $failures.Add("Candidate pipeline is missing fail-fast contract: $contract") | Out-Null
  }
}
if (-not $candidateText.Contains("'-ModelProvider'") -or -not $candidateText.Contains("'-ProviderEnvKey'")) {
  $failures.Add('Candidate pipeline does not propagate explicit provider selection.') | Out-Null
}
if (-not $candidateText.Contains('[int]$MaxParallelCases = 3') -or -not $candidateText.Contains("'-MaxParallelCases'")) {
  $failures.Add('Candidate pipeline does not use bounded case-level parallelism.') | Out-Null
}
foreach ($trialContract in @('[int]$InitialTrials = 1', '[int]$RetryTrials = 2', '[int]$MinimumAgreement = 1', "'-InitialTrials'", "'-RetryTrials'", "'-MinimumAgreement'", 'Reusable candidate trial policy does not match.', 'Reusable baseline trial policy does not match.')) {
  if (-not $candidateText.Contains($trialContract)) { $failures.Add("Candidate pipeline is missing trial-policy contract: $trialContract") | Out-Null }
}
if (-not $candidateText.Contains('[bool]$StatelessBehaviorTurns = $true') -or -not $candidateText.Contains("'-StatelessTurns'")) {
  $failures.Add('Candidate pipeline does not default to isolated stateless behavior turns.') | Out-Null
}
if (-not $candidateText.Contains('function Add-ComparisonOptions')) {
  $failures.Add('Candidate pipeline does not keep stateless behavior-only flags out of blind comparison.') | Out-Null
}
$comparisonOptions = [regex]::Match($candidateText, 'function Add-ComparisonOptions\s*\{(?<body>.*?)\r?\n\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $comparisonOptions.Success -or $comparisonOptions.Groups['body'].Value.Contains('StatelessTurns')) {
  $failures.Add('Blind comparison options incorrectly include stateless behavior-turn flags.') | Out-Null
}
$candidateLowBlock = [regex]::Match($candidateText, '\$candidateLowRoot\s*=.*?\r?\nif \(\$Mode -eq ''Candidate'' -and -not \$dynamicBlocked\)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $candidateLowBlock.Success -or -not $candidateLowBlock.Value.Contains('Add-BehaviorOptions -Arguments $arguments -Effort $LowReasoningEffort') -or $candidateLowBlock.Value.Contains('Add-ComparisonOptions -Arguments $arguments')) {
  $failures.Add('Candidate low behavior block does not use stateless behavior options.') | Out-Null
}
$blindBlock = [regex]::Match($candidateText, 'invoke_blind_comparison_batch\.ps1.*?Invoke-ValidationStep -Name ''blind-baseline-comparison''', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $blindBlock.Success -or -not $blindBlock.Value.Contains('Add-ComparisonOptions -Arguments $arguments -Effort $LowReasoningEffort') -or $blindBlock.Value.Contains('Add-BehaviorOptions -Arguments $arguments')) {
  $failures.Add('Blind comparison block does not use comparison-only options.') | Out-Null
}

$ciBehaviorText = Get-Content -LiteralPath (Join-Path $LabRoot 'scripts\run_ci_behavior.ps1') -Raw -Encoding UTF8
foreach ($contract in @(
  "[ValidateSet('Changed', 'Release', 'FullLow', 'FullDual')]",
  "login status",
  "@('low', 'xhigh')",
  "DisablePlugins = `$true",
  "StatelessTurns = `$true",
  "[string]`$TrialProfile = 'Auto'",
  "InitialTrials = `$trialSettings.InitialTrials",
  "exit [int]`$code"
)) {
  if (-not $ciBehaviorText.Contains($contract)) { $failures.Add("CI behavior runner is missing contract: $contract") | Out-Null }
}
$entryGuardText = Get-Content -LiteralPath (Join-Path $StandardRoot 'scripts\run_entry_guard_eval.ps1') -Raw -Encoding UTF8
$noWriteBoundaryContract = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('KD865rKh5pyJfOacqikoPzrkv67mlLl85Yib5bu6KSg/OuaIluWIm+W7unzlkozliJvlu7opPyg/OuS7u+S9lSk/KD866aG555uuKT/mlofku7Y='))
if (-not $entryGuardText.Contains($noWriteBoundaryContract)) {
  $failures.Add('Entry guard does not recognize a natural-language no-write boundary.') | Out-Null
}
if (-not $candidateText.Contains("name = 'standard-runtime-generality'")) {
  $failures.Add('Candidate pipeline does not run the runtime-generality gate in Quick mode.') | Out-Null
}
foreach ($reuseContract in @('Import-ReusableBehaviorRun', 'Reusable behavior run hashes do not match', 'Import-ReusableBaselineTranscripts', 'Oracle review is intentionally refreshed only by the current blind comparison', 'baseline-transcript-completeness', '-AllowedExitCodes @(0, 2)')) {
  if (-not $candidateText.Contains($reuseContract)) { $failures.Add("Candidate pipeline is missing reuse/baseline contract: $reuseContract") | Out-Null }
}
foreach ($reuseContract in @('Get-RuntimeSurfaceHash -Root $ExpectedSkillRoot', 'Get-RuntimeSurfaceHash -Root $ExpectedBaselineSkillRoot', 'runtime_surface_sha256', 'stateless_turns -ne [bool]$StatelessBehaviorTurns', 'ExpectedReasoningEffort', 'Reusable candidate user-config hash does not match')) {
  if (-not $candidateText.Contains($reuseContract)) { $failures.Add("Candidate pipeline is missing runtime-surface reuse validation: $reuseContract") | Out-Null }
}
if (-not $candidateText.Contains('[switch]$ExactCaseSelection') -or -not $candidateText.Contains('if (-not $ExactCaseSelection)')) {
  $failures.Add('Candidate pipeline does not support explicit exact standard-case selection.') | Out-Null
}

if ($failures.Count -gt 0) {
  'Candidate harness check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Candidate harness check: PASS'
"Replay cases: $(@($replays.cases).Count)"
"Impact rules: $(@($impact.rules).Count)"
