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
  'scripts\eval_runtime.ps1',
  'scripts\check_standard_fast.ps1',
  'scripts\invoke_behavior_eval_batch.ps1',
  'scripts\invoke_blind_comparison_batch.ps1',
  'scripts\resolve_impacted_cases.ps1',
  'scripts\run_replay_eval.ps1',
  'scripts\run_blind_comparison.ps1',
  'scripts\write_validation_report.ps1',
  'scripts\invoke_candidate_validation.ps1'
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
if (-not $batchWrapperText.Contains('exit [int]$runnerExitCode')) {
  $failures.Add('Behavior batch wrapper does not propagate the runner exit code.') | Out-Null
}
if (-not $batchWrapperText.Contains('ModelProvider = $ModelProvider') -or -not $batchWrapperText.Contains('ProviderEnvKey = $ProviderEnvKey')) {
  $failures.Add('Behavior batch wrapper does not propagate provider selection without credentials.') | Out-Null
}
foreach ($parallelContract in @('[int]$MaxParallelCases = 1', 'Start-Job -Name $caseId', "'.parallel-parts'", '$hasFailures = $true', 'if ($FailFastP0) { $stopAfterBatch = $true }')) {
  if (-not $batchWrapperText.Contains($parallelContract)) { $failures.Add("Behavior batch wrapper is missing parallel contract: $parallelContract") | Out-Null }
}
foreach ($aggregationContract in @('foreach ($item in $decodedSummary)', 'Parallel aggregation found $($matches.Count) results; expected exactly one.', 'ConvertTo-Json -InputObject ([object[]]$orderedResults)')) {
  if (-not $batchWrapperText.Contains($aggregationContract)) { $failures.Add("Behavior batch wrapper is missing exact-result aggregation: $aggregationContract") | Out-Null }
}
if (-not $batchWrapperText.Contains('foreach ($caseId in $decodedCaseIds)')) {
  $failures.Add('Behavior batch wrapper does not normalize PowerShell 5.1 JSON arrays.') | Out-Null
}
foreach ($pathContract in @('$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path', '$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path', '$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path')) {
  if (-not $batchWrapperText.Contains($pathContract)) { $failures.Add("Behavior batch wrapper is missing background-job path normalization: $pathContract") | Out-Null }
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
  "'-FailFastP0'"
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
$candidateLowBlock = [regex]::Match($candidateText, '\$candidateLowRoot\s*=.*?if \(\$Mode -eq', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $candidateLowBlock.Success -or -not $candidateLowBlock.Value.Contains('Add-BehaviorOptions -Arguments $arguments -Effort $LowReasoningEffort') -or $candidateLowBlock.Value.Contains('Add-ComparisonOptions -Arguments $arguments')) {
  $failures.Add('Candidate low behavior block does not use stateless behavior options.') | Out-Null
}
$blindBlock = [regex]::Match($candidateText, 'invoke_blind_comparison_batch\.ps1.*?Invoke-ValidationStep -Name ''blind-baseline-comparison''', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if (-not $blindBlock.Success -or -not $blindBlock.Value.Contains('Add-ComparisonOptions -Arguments $arguments -Effort $LowReasoningEffort') -or $blindBlock.Value.Contains('Add-BehaviorOptions -Arguments $arguments')) {
  $failures.Add('Blind comparison block does not use comparison-only options.') | Out-Null
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
