param(
  [ValidateSet('Quick', 'Changed', 'Candidate')]
  [string]$Mode = 'Quick',
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$ReleaseRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path 'allred-project-standard-release'),
  [string]$BaselineRef = 'HEAD',
  [string[]]$CaseIds = @(),
  [switch]$ExactCaseSelection,
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [ValidateSet('low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$LowReasoningEffort = 'low',
  [ValidateSet('high', 'xhigh', 'ultra', 'max')]
  [string]$HighReasoningEffort = 'xhigh',
  [switch]$IgnoreUserConfig,
  [switch]$EnablePlugins,
  [bool]$StatelessBehaviorTurns = $true,
  [ValidateRange(1, 8)]
  [int]$MaxParallelCases = 3,
  [ValidateRange(1, 5)]
  [int]$InitialTrials = 1,
  [ValidateRange(0, 5)]
  [int]$RetryTrials = 2,
  [ValidateRange(1, 5)]
  [int]$MinimumAgreement = 1,
  [ValidateRange(30, 3600)]
  [int]$TimeoutSeconds = 300,
  [string]$ReuseCandidateLowRoot = '',
  [string]$ReuseCandidateHighRoot = '',
  [string]$ReuseBaselineRoot = '',
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ("allred-candidate-validation-" + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

function Write-Utf8File {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Add-StepResult {
  param([string]$Name, [string]$Status, [int]$ExitCode, [int64]$DurationMs, [string]$Log, [string]$Reason = '')
  $script:steps.Add([pscustomobject]@{
    name = $Name
    status = $Status
    exit_code = $ExitCode
    duration_ms = $DurationMs
    log = $Log
    reason = $Reason
  }) | Out-Null
  if ($Status -eq 'Fail') { $script:failures.Add("$Name failed. See $Log") | Out-Null }
  if ($Status -eq 'Inconclusive') { $script:inconclusive = $true }
}

function Invoke-ValidationStep {
  param([string]$Name, [string]$FilePath, [string[]]$Arguments, [int[]]$AllowedExitCodes = @(0))
  $safeName = ($Name -replace '[^0-9A-Za-z._-]', '-')
  $logPath = Join-Path $script:logsRoot "$safeName.log"
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) { $exitCode = 0 }
    $text = (@($output | ForEach-Object { $_.ToString() }) -join "`n")
    Write-Utf8File -Path $logPath -Text $text
    $stopwatch.Stop()
    $infrastructurePattern = 'InfrastructureFailure|InfrastructureInconclusive|INVALID_API_KEY|authentication(?:\s+is)?\s+required|not\s+logged\s+in|timed\s+out|network\s+(?:is\s+)?unavailable|connection\s+(?:failed|refused|timed\s+out)'
    $semanticFailurePattern = 'StableFail|Variable|NotRun'
    $status = if ($exitCode -in $AllowedExitCodes) { 'Pass' } elseif ($exitCode -eq 3 -or ($text -match $infrastructurePattern -and $text -notmatch $semanticFailurePattern)) { 'Inconclusive' } else { 'Fail' }
    Add-StepResult -Name $Name -Status $status -ExitCode $exitCode -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath
    return ($status -eq 'Pass')
  } catch {
    $stopwatch.Stop()
    Write-Utf8File -Path $logPath -Text ($_ | Out-String)
    Add-StepResult -Name $Name -Status 'Fail' -ExitCode 1 -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath -Reason $_.Exception.Message
    return $false
  }
}

function Import-ReusableBehaviorRun {
  param([string]$Name, [string]$SourceRoot, [string]$DestinationRoot, [string[]]$ExpectedCaseIds, [string]$ExpectedSkillRoot, [string]$ExpectedSuiteRoot, [string]$ExpectedReasoningEffort)
  $logPath = Join-Path $script:logsRoot "$Name.log"
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $source = (Resolve-Path -LiteralPath $SourceRoot).Path
    $summaryPath = Join-Path $source 'summary.json'
    $configPath = Join-Path $source 'run-config.json'
    if (-not (Test-Path -LiteralPath $summaryPath) -or -not (Test-Path -LiteralPath $configPath)) { throw 'Reusable behavior run is missing summary or configuration evidence.' }
    $items = @(Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $actualIds = @($items.case_id | Sort-Object -Unique)
    $expectedIds = @($ExpectedCaseIds | Sort-Object -Unique)
    if ((Compare-Object $expectedIds $actualIds).Count -gt 0) { throw 'Reusable behavior run does not cover the exact selected case set.' }
    if (@($items | Where-Object { $_.status -ne 'Evaluated' -or $_.result -ne 'Pass' -or $_.aggregate_result -ne 'StablePass' }).Count -gt 0) { throw 'Reusable behavior run contains a non-stable case.' }
    $skillHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedSkillRoot 'SKILL.md') -Algorithm SHA256).Hash.ToLowerInvariant()
    $runtimeHash = Get-RuntimeSurfaceHash -Root $ExpectedSkillRoot
    $testHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedSuiteRoot 'tests\behavior-cases.test.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    $oracleHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedSuiteRoot 'tests\behavior-cases.oracle.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($config.skill_md_sha256 -ne $skillHash -or $config.runtime_surface_sha256 -ne $runtimeHash -or $config.test_suite_sha256 -ne $testHash -or $config.oracle_suite_sha256 -ne $oracleHash) { throw 'Reusable behavior run hashes do not match the current runtime surface and suite.' }
    if ($Model -and $config.model_override -ne $Model) { throw 'Reusable candidate model does not match.' }
    if ($config.model_provider_override -ne $ModelProvider -or $config.provider_env_key_name -ne $ProviderEnvKey) { throw 'Reusable candidate provider selection does not match.' }
    if ($config.reasoning_effort_override -ne $ExpectedReasoningEffort -or [bool]$config.use_user_config -ne [bool]$UseUserConfig -or [bool]$config.disable_plugins -ne [bool]$DisablePlugins -or [bool]$config.stateless_turns -ne [bool]$StatelessBehaviorTurns) { throw 'Reusable candidate runtime configuration does not match.' }
    if ([int]$config.initial_trials -ne $InitialTrials -or [int]$config.retry_trials -ne $RetryTrials -or [int]$config.minimum_agreement -ne $MinimumAgreement) { throw 'Reusable candidate trial policy does not match.' }
    if ($UseUserConfig) {
      $codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { Join-Path $HOME '.codex' } else { $env:CODEX_HOME }
      $userConfigPath = Join-Path $codexHome 'config.toml'
      $userConfigHash = if (Test-Path -LiteralPath $userConfigPath) { (Get-FileHash -LiteralPath $userConfigPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
      if ($config.user_config_sha256 -ne $userConfigHash) { throw 'Reusable candidate user-config hash does not match.' }
    }
    Copy-Item -LiteralPath $source -Destination $DestinationRoot -Recurse -Force
    $stopwatch.Stop()
    Write-Utf8File -Path $logPath -Text "Reused validated behavior run: $source"
    Add-StepResult -Name $Name -Status 'Pass' -ExitCode 0 -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath
    return $true
  } catch {
    $stopwatch.Stop()
    Write-Utf8File -Path $logPath -Text ($_ | Out-String)
    Add-StepResult -Name $Name -Status 'Fail' -ExitCode 1 -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath -Reason $_.Exception.Message
    return $false
  }
}

function Import-ReusableBaselineTranscripts {
  param([string]$SourceRoot, [string]$DestinationRoot, [string[]]$ExpectedCaseIds, [string]$ExpectedBaselineSkillRoot, [string]$ExpectedSuiteRoot)
  $name = 'baseline-behavior-low-transcripts-reused'
  $logPath = Join-Path $script:logsRoot "$name.log"
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $source = (Resolve-Path -LiteralPath $SourceRoot).Path
    $summaryPath = Join-Path $source 'summary.json'
    $configPath = Join-Path $source 'run-config.json'
    if (-not (Test-Path -LiteralPath $summaryPath) -or -not (Test-Path -LiteralPath $configPath)) { throw 'Reusable baseline run is missing summary or configuration evidence.' }
    $items = @(Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $actualIds = @($items.case_id | Sort-Object -Unique)
    $expectedIds = @($ExpectedCaseIds | Sort-Object -Unique)
    if ((Compare-Object $expectedIds $actualIds).Count -gt 0) { throw 'Reusable baseline run does not cover the exact selected case set.' }
    if (@($items | Where-Object status -eq 'InfrastructureFailure').Count -gt 0) { throw 'Reusable baseline run contains an infrastructure failure.' }
    $missingTranscripts = @($expectedIds | Where-Object { -not (Test-Path -LiteralPath (Join-Path (Join-Path $source $_) 'transcript.json')) })
    if ($missingTranscripts.Count -gt 0) { throw "Reusable baseline run is missing transcripts: $($missingTranscripts -join ', ')" }
    $baselineSkillHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedBaselineSkillRoot 'SKILL.md') -Algorithm SHA256).Hash.ToLowerInvariant()
    $baselineRuntimeHash = Get-RuntimeSurfaceHash -Root $ExpectedBaselineSkillRoot
    $testHash = (Get-FileHash -LiteralPath (Join-Path $ExpectedSuiteRoot 'tests\behavior-cases.test.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($config.skill_md_sha256 -ne $baselineSkillHash -or $config.runtime_surface_sha256 -ne $baselineRuntimeHash -or $config.test_suite_sha256 -ne $testHash) { throw 'Reusable baseline transcript hashes do not match the frozen runtime surface and current test inputs.' }
    if ($Model -and $config.model_override -ne $Model) { throw 'Reusable baseline model does not match.' }
    if ($config.model_provider_override -ne $ModelProvider -or $config.provider_env_key_name -ne $ProviderEnvKey) { throw 'Reusable baseline provider selection does not match.' }
    if ($config.reasoning_effort_override -ne $LowReasoningEffort -or [bool]$config.use_user_config -ne [bool]$UseUserConfig -or [bool]$config.disable_plugins -ne [bool]$DisablePlugins -or [bool]$config.stateless_turns -ne [bool]$StatelessBehaviorTurns) { throw 'Reusable baseline runtime configuration does not match.' }
    if ([int]$config.initial_trials -ne 1 -or [int]$config.retry_trials -ne 0 -or [int]$config.minimum_agreement -ne 1) { throw 'Reusable baseline trial policy does not match.' }
    if ($UseUserConfig) {
      $codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { Join-Path $HOME '.codex' } else { $env:CODEX_HOME }
      $userConfigPath = Join-Path $codexHome 'config.toml'
      $userConfigHash = if (Test-Path -LiteralPath $userConfigPath) { (Get-FileHash -LiteralPath $userConfigPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
      if ($config.user_config_sha256 -ne $userConfigHash) { throw 'Reusable baseline user-config hash does not match.' }
    }
    Copy-Item -LiteralPath $source -Destination $DestinationRoot -Recurse -Force
    $stopwatch.Stop()
    Write-Utf8File -Path $logPath -Text "Reused immutable baseline transcripts: $source`nOracle review is intentionally refreshed only by the current blind comparison."
    Add-StepResult -Name $name -Status 'Pass' -ExitCode 0 -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath
    return $true
  } catch {
    $stopwatch.Stop()
    Write-Utf8File -Path $logPath -Text ($_ | Out-String)
    Add-StepResult -Name $name -Status 'Fail' -ExitCode 1 -DurationMs $stopwatch.ElapsedMilliseconds -Log $logPath -Reason $_.Exception.Message
    return $false
  }
}

function Get-RelativePathValue {
  param([string]$Root, [string]$Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

function Get-RuntimeSurfaceHash {
  param([string]$Root)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $entries = foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File) {
    $relative = $file.FullName.Substring($rootFull.Length).Replace('\', '/')
    if ($relative -notmatch '^(?:SKILL\.md|VERSION|agents/|references/|templates/|scripts/)') { continue }
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$relative|$hash"
  }
  $payload = [System.Text.Encoding]::UTF8.GetBytes((@($entries | Sort-Object) -join "`n"))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { return ([System.BitConverter]::ToString($sha.ComputeHash($payload)) -replace '-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}

function Add-DynamicOptions {
  param([System.Collections.Generic.List[string]]$Arguments, [string]$Effort)
  if ($Model) { $Arguments.Add('-Model'); $Arguments.Add($Model) }
  if ($ModelProvider) { $Arguments.Add('-ModelProvider'); $Arguments.Add($ModelProvider) }
  if ($ProviderEnvKey) { $Arguments.Add('-ProviderEnvKey'); $Arguments.Add($ProviderEnvKey) }
  $Arguments.Add('-ReasoningEffort'); $Arguments.Add($Effort)
  $Arguments.Add('-TimeoutSeconds'); $Arguments.Add([string]$TimeoutSeconds)
  if ($UseUserConfig) { $Arguments.Add('-UseUserConfig') }
  if ($DisablePlugins) { $Arguments.Add('-DisablePlugins') }
}

function Add-BehaviorOptions {
  param([System.Collections.Generic.List[string]]$Arguments, [string]$Effort, [switch]$Baseline)
  Add-DynamicOptions -Arguments $Arguments -Effort $Effort
  $Arguments.Add('-MaxParallelCases'); $Arguments.Add([string]$MaxParallelCases)
  $Arguments.Add('-InitialTrials'); $Arguments.Add([string]$(if ($Baseline) { 1 } else { $InitialTrials }))
  $Arguments.Add('-RetryTrials'); $Arguments.Add([string]$(if ($Baseline) { 0 } else { $RetryTrials }))
  $Arguments.Add('-MinimumAgreement'); $Arguments.Add([string]$(if ($Baseline) { 1 } else { $MinimumAgreement }))
  if ($StatelessBehaviorTurns) { $Arguments.Add('-StatelessTurns') }
}

function Get-BehaviorAggregateEvidence {
  param([string]$Root)
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath (Join-Path $Root 'summary.json'))) { return $null }
  $items = @(Get-Content -LiteralPath (Join-Path $Root 'summary.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
  $counts = [ordered]@{}
  foreach ($name in @('StablePass', 'StableFail', 'Variable', 'InfrastructureInconclusive', 'NotRun')) {
    $counts[$name] = @($items | Where-Object aggregate_result -eq $name).Count
  }
  return [pscustomobject]@{
    root = $Root
    total_cases = $items.Count
    counts = $counts
    cases = @($items | ForEach-Object { [pscustomobject]@{ case_id = $_.case_id; priority = $_.priority; aggregate_result = $_.aggregate_result; trial_count = $_.trial_count; counts = $_.counts; has_variance = $_.has_variance; first_divergent_turn = $_.first_divergent_turn; report = $_.report } })
  }
}

function Add-ComparisonOptions {
  param([System.Collections.Generic.List[string]]$Arguments, [string]$Effort)
  Add-DynamicOptions -Arguments $Arguments -Effort $Effort
  $Arguments.Add('-MaxParallelCases'); $Arguments.Add([string]$MaxParallelCases)
}

$startedAt = [DateTime]::UtcNow
$candidateModeDefaults = $Mode -eq 'Candidate'
if ($candidateModeDefaults -and -not $PSBoundParameters.ContainsKey('InitialTrials')) { $InitialTrials = 2 }
if ($candidateModeDefaults -and -not $PSBoundParameters.ContainsKey('RetryTrials')) { $RetryTrials = 1 }
if ($candidateModeDefaults -and -not $PSBoundParameters.ContainsKey('MinimumAgreement')) { $MinimumAgreement = 2 }
$UseUserConfig = -not [bool]$IgnoreUserConfig
$DisablePlugins = -not [bool]$EnablePlugins
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$StandardRoot = (Resolve-Path -LiteralPath $StandardRoot).Path
$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$logsRoot = Join-Path $OutputRoot 'logs'
New-Item -ItemType Directory -Force -Path $logsRoot | Out-Null
$steps = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()
$inconclusive = $false
$hostPowerShell = (Get-Process -Id $PID).Path
$labRunRoot = ''
$candidateLowRoot = ''
$candidateHighRoot = ''
$baselineLowRoot = ''

$impactPath = Join-Path $OutputRoot 'impact.json'
$resolveArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\resolve_impacted_cases.ps1'), '-RepoRoot', $RepoRoot, '-StandardRoot', $StandardRoot, '-LabRoot', $LabRoot, '-BaselineRef', $BaselineRef, '-IncludeAdjacent', '-OutputPath', $impactPath)
[void](Invoke-ValidationStep -Name 'resolve-impact' -FilePath $hostPowerShell -Arguments $resolveArgs)
if (Test-Path -LiteralPath $impactPath) {
  $impact = Get-Content -LiteralPath $impactPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
  $impact = [pscustomobject]@{ changed_paths = @(); standard_case_ids = @(); lab_case_ids = @(); replay_case_ids = @(); warnings = @('Impact resolution failed.') }
}

$quickSteps = @(
  @{ name = 'standard-fast-structure'; script = Join-Path $LabRoot 'scripts\check_standard_fast.ps1'; args = @('-StandardRoot', $StandardRoot) },
  @{ name = 'standard-behavior-manifest'; script = Join-Path $StandardRoot 'scripts\check_behavior_manifest.ps1'; args = @('-SkillRoot', $StandardRoot) },
  @{ name = 'standard-invariants'; script = Join-Path $StandardRoot 'scripts\check_invariants.ps1'; args = @('-SkillRoot', $StandardRoot) },
  @{ name = 'standard-runtime-generality'; script = Join-Path $StandardRoot 'scripts\check_runtime_generality.ps1'; args = @('-SkillRoot', $StandardRoot) },
  @{ name = 'standard-route-budget'; script = Join-Path $StandardRoot 'scripts\check_route_context_budget.ps1'; args = @('-SkillRoot', $StandardRoot) },
  @{ name = 'lab-structure'; script = Join-Path $LabRoot 'scripts\check_lab_structure.ps1'; args = @('-LabRoot', $LabRoot, '-StandardRoot', $StandardRoot) },
  @{ name = 'candidate-harness'; script = Join-Path $LabRoot 'scripts\check_candidate_harness.ps1'; args = @('-LabRoot', $LabRoot, '-StandardRoot', $StandardRoot) }
)
foreach ($item in $quickSteps) {
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $item.script) + @($item.args)
  [void](Invoke-ValidationStep -Name $item.name -FilePath $hostPowerShell -Arguments $arguments)
}

if ($Mode -eq 'Candidate') {
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $StandardRoot 'scripts\check_skill_structure.ps1'), '-SkillRoot', $StandardRoot)
  [void](Invoke-ValidationStep -Name 'standard-full-structure' -FilePath $hostPowerShell -Arguments $arguments)
}

$selectedStandard = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$selectedLab = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$selectedReplay = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($id in @($impact.standard_case_ids)) { $selectedStandard.Add([string]$id) | Out-Null }
foreach ($id in @($impact.lab_case_ids)) { $selectedLab.Add([string]$id) | Out-Null }
foreach ($id in @($impact.replay_case_ids)) { $selectedReplay.Add([string]$id) | Out-Null }
if (@($CaseIds).Count -gt 0) {
  $selectedStandard.Clear()
  foreach ($id in $CaseIds) { $selectedStandard.Add($id) | Out-Null }
}
if ($Mode -eq 'Candidate') {
  $impactMap = Get-Content -LiteralPath (Join-Path $LabRoot 'tests\impact-map.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $ExactCaseSelection) {
    foreach ($id in @($impactMap.default_release_case_ids)) { $selectedStandard.Add([string]$id) | Out-Null }
  }
  foreach ($id in @($impactMap.default_lab_case_ids)) { $selectedLab.Add([string]$id) | Out-Null }
  foreach ($id in @($impactMap.default_replay_case_ids)) { $selectedReplay.Add([string]$id) | Out-Null }
}
$standardCaseIdsPath = Join-Path $OutputRoot 'selected-standard-cases.json'
$labCaseIdsPath = Join-Path $OutputRoot 'selected-lab-cases.json'
$replayCaseIdsPath = Join-Path $OutputRoot 'selected-replay-cases.json'
Write-Utf8File -Path $standardCaseIdsPath -Text (ConvertTo-Json -InputObject @($selectedStandard | Sort-Object))
Write-Utf8File -Path $labCaseIdsPath -Text (ConvertTo-Json -InputObject @($selectedLab | Sort-Object))
Write-Utf8File -Path $replayCaseIdsPath -Text (ConvertTo-Json -InputObject @($selectedReplay | Sort-Object))

$staticFailed = @($steps | Where-Object { $_.status -eq 'Fail' }).Count -gt 0
$dynamicBlocked = $staticFailed
if ($Mode -ne 'Quick' -and -not $staticFailed) {
  if ($selectedReplay.Count -gt 0) {
    $replayRoot = Join-Path $OutputRoot 'replay'
    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\run_replay_eval.ps1'), '-LabRoot', $LabRoot, '-OutputRoot', $replayRoot, '-CaseIdsPath', $replayCaseIdsPath)) { $arguments.Add($value) }
    Add-DynamicOptions -Arguments $arguments -Effort $LowReasoningEffort
    $replayPassed = Invoke-ValidationStep -Name 'fixed-record-replay' -FilePath $hostPowerShell -Arguments @($arguments)
    if (-not $replayPassed -and $Mode -eq 'Candidate') { $dynamicBlocked = $true }
  }

  if (-not $dynamicBlocked -and $selectedLab.Count -gt 0) {
    $labRunRoot = Join-Path $OutputRoot 'lab-behavior-low'
    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1'), '-RunnerPath', (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'), '-SkillRoot', $LabRoot, '-SuiteRoot', $LabRoot, '-OutputRoot', $labRunRoot, '-CaseIdsPath', $labCaseIdsPath)) { $arguments.Add($value) }
    if ($Mode -eq 'Candidate') { $arguments.Add('-FailFastP0') }
    Add-BehaviorOptions -Arguments $arguments -Effort $LowReasoningEffort
    $labPassed = Invoke-ValidationStep -Name 'lab-behavior-low' -FilePath $hostPowerShell -Arguments @($arguments)
    if (-not $labPassed -and $Mode -eq 'Candidate') { $dynamicBlocked = $true }
  }

  if (-not $dynamicBlocked -and $selectedStandard.Count -gt 0) {
    $candidateLowRoot = Join-Path $OutputRoot 'candidate-behavior-low'
    if ($ReuseCandidateLowRoot) {
      if (-not (Import-ReusableBehaviorRun -Name 'candidate-behavior-low-reused' -SourceRoot $ReuseCandidateLowRoot -DestinationRoot $candidateLowRoot -ExpectedCaseIds @($selectedStandard) -ExpectedSkillRoot $StandardRoot -ExpectedSuiteRoot $StandardRoot -ExpectedReasoningEffort $LowReasoningEffort)) { $dynamicBlocked = $true }
    } else {
      $arguments = [System.Collections.Generic.List[string]]::new()
      foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1'), '-RunnerPath', (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'), '-SkillRoot', $StandardRoot, '-SuiteRoot', $StandardRoot, '-OutputRoot', $candidateLowRoot, '-CaseIdsPath', $standardCaseIdsPath)) { $arguments.Add($value) }
      if ($Mode -eq 'Candidate') { $arguments.Add('-FailFastP0') }
      Add-BehaviorOptions -Arguments $arguments -Effort $LowReasoningEffort
      if (-not (Invoke-ValidationStep -Name 'candidate-behavior-low' -FilePath $hostPowerShell -Arguments @($arguments))) { $dynamicBlocked = $true }
    }
  }
}

if ($Mode -eq 'Candidate' -and -not $dynamicBlocked) {
  if ($selectedStandard.Count -gt 0) {
    $candidateHighRoot = Join-Path $OutputRoot 'candidate-behavior-high'
    if ($ReuseCandidateHighRoot) {
      if (-not (Import-ReusableBehaviorRun -Name 'candidate-behavior-high-reused' -SourceRoot $ReuseCandidateHighRoot -DestinationRoot $candidateHighRoot -ExpectedCaseIds @($selectedStandard) -ExpectedSkillRoot $StandardRoot -ExpectedSuiteRoot $StandardRoot -ExpectedReasoningEffort $HighReasoningEffort)) { $dynamicBlocked = $true }
    } else {
      $arguments = [System.Collections.Generic.List[string]]::new()
      foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1'), '-RunnerPath', (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'), '-SkillRoot', $StandardRoot, '-SuiteRoot', $StandardRoot, '-OutputRoot', $candidateHighRoot, '-CaseIdsPath', $standardCaseIdsPath, '-FailFastP0')) { $arguments.Add($value) }
      Add-BehaviorOptions -Arguments $arguments -Effort $HighReasoningEffort
      if (-not (Invoke-ValidationStep -Name 'candidate-behavior-high' -FilePath $hostPowerShell -Arguments @($arguments))) { $dynamicBlocked = $true }
    }
  }

  if (-not $dynamicBlocked) {
  $snapshotRoot = Join-Path $OutputRoot 'baseline-snapshot'
  $standardRepoPath = Get-RelativePathValue -Root $RepoRoot -Path $StandardRoot
  $snapshotLog = Join-Path $logsRoot 'baseline-snapshot.log'
  $snapshotStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $archivePath = Join-Path $OutputRoot 'baseline.zip'
    & git -C $RepoRoot archive --format=zip --output=$archivePath $BaselineRef -- $standardRepoPath 2>&1 | Set-Content -LiteralPath $snapshotLog -Encoding UTF8
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for $BaselineRef" }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $snapshotRoot -Force
    $baselineSkillRoot = Join-Path $snapshotRoot $standardRepoPath.Replace('/', '\')
    if (-not (Test-Path -LiteralPath (Join-Path $baselineSkillRoot 'SKILL.md'))) { throw 'Baseline Skill snapshot is incomplete.' }
    $snapshotStopwatch.Stop()
    Add-StepResult -Name 'baseline-snapshot' -Status 'Pass' -ExitCode 0 -DurationMs $snapshotStopwatch.ElapsedMilliseconds -Log $snapshotLog
  } catch {
    $snapshotStopwatch.Stop()
    Write-Utf8File -Path $snapshotLog -Text ($_ | Out-String)
    Add-StepResult -Name 'baseline-snapshot' -Status 'Fail' -ExitCode 1 -DurationMs $snapshotStopwatch.ElapsedMilliseconds -Log $snapshotLog
  }

  if ($selectedStandard.Count -gt 0 -and (Test-Path -LiteralPath (Join-Path $snapshotRoot $standardRepoPath.Replace('/', '\')))) {
    $baselineSkillRoot = Join-Path $snapshotRoot $standardRepoPath.Replace('/', '\')
    $baselineLowRoot = Join-Path $OutputRoot 'baseline-behavior-low'
    if ($ReuseBaselineRoot) {
      $baselineRan = Import-ReusableBaselineTranscripts -SourceRoot $ReuseBaselineRoot -DestinationRoot $baselineLowRoot -ExpectedCaseIds @($selectedStandard) -ExpectedBaselineSkillRoot $baselineSkillRoot -ExpectedSuiteRoot $StandardRoot
    } else {
      $arguments = [System.Collections.Generic.List[string]]::new()
      foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1'), '-RunnerPath', (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'), '-SkillRoot', $baselineSkillRoot, '-SuiteRoot', $StandardRoot, '-OutputRoot', $baselineLowRoot, '-CaseIdsPath', $standardCaseIdsPath)) { $arguments.Add($value) }
      Add-BehaviorOptions -Arguments $arguments -Effort $LowReasoningEffort -Baseline
      $baselineRan = Invoke-ValidationStep -Name 'baseline-behavior-low' -FilePath $hostPowerShell -Arguments @($arguments) -AllowedExitCodes @(0, 2)
    }
    $baselineCompletenessLog = Join-Path $logsRoot 'baseline-transcript-completeness.log'
    $baselineComplete = $false
    if ($baselineRan -and (Test-Path -LiteralPath (Join-Path $baselineLowRoot 'summary.json'))) {
      $baselineItems = @(Get-Content -LiteralPath (Join-Path $baselineLowRoot 'summary.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
      $baselineIds = @($baselineItems.case_id | Sort-Object -Unique)
      $expectedIds = @($selectedStandard | Sort-Object -Unique)
      $missingTranscripts = @($expectedIds | Where-Object { -not (Test-Path -LiteralPath (Join-Path (Join-Path $baselineLowRoot $_) 'transcript.json')) })
      $baselineComplete = (Compare-Object $expectedIds $baselineIds).Count -eq 0 -and @($baselineItems | Where-Object status -eq 'InfrastructureFailure').Count -eq 0 -and $missingTranscripts.Count -eq 0
      Write-Utf8File -Path $baselineCompletenessLog -Text "cases=$($baselineItems.Count); missing_transcripts=$($missingTranscripts -join ','); infrastructure_failures=$(@($baselineItems | Where-Object status -eq 'InfrastructureFailure').Count)"
    } else {
      Write-Utf8File -Path $baselineCompletenessLog -Text 'Baseline summary is unavailable.'
    }
    Add-StepResult -Name 'baseline-transcript-completeness' -Status $(if ($baselineComplete) { 'Pass' } else { 'Fail' }) -ExitCode $(if ($baselineComplete) { 0 } else { 1 }) -DurationMs 0 -Log $baselineCompletenessLog

    if ($baselineComplete -and (Test-Path -LiteralPath $candidateLowRoot) -and (Test-Path -LiteralPath $baselineLowRoot)) {
      $comparisonRoot = Join-Path $OutputRoot 'blind-comparison'
      $arguments = [System.Collections.Generic.List[string]]::new()
      foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\invoke_blind_comparison_batch.ps1'), '-RunnerPath', (Join-Path $LabRoot 'scripts\run_blind_comparison.ps1'), '-LabRoot', $LabRoot, '-SuiteRoot', $StandardRoot, '-CandidateRunRoot', $candidateLowRoot, '-BaselineRunRoot', $baselineLowRoot, '-OutputRoot', $comparisonRoot, '-CaseIdsPath', $standardCaseIdsPath)) { $arguments.Add($value) }
      Add-ComparisonOptions -Arguments $arguments -Effort $LowReasoningEffort
      [void](Invoke-ValidationStep -Name 'blind-baseline-comparison' -FilePath $hostPowerShell -Arguments @($arguments))
    }
  }

  $entryRoot = Join-Path $OutputRoot 'entry-guard'
  $entryArguments = [System.Collections.Generic.List[string]]::new()
  foreach ($value in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $StandardRoot 'scripts\run_entry_guard_eval.ps1'), '-SkillRoot', $StandardRoot, '-OutputRoot', $entryRoot, '-ReasoningEffort', $LowReasoningEffort, '-TimeoutSeconds', [string]$TimeoutSeconds)) { $entryArguments.Add($value) }
  if ($Model) { $entryArguments.Add('-Model'); $entryArguments.Add($Model) }
  if ($ModelProvider) { $entryArguments.Add('-ModelProvider'); $entryArguments.Add($ModelProvider) }
  if ($ProviderEnvKey) { $entryArguments.Add('-ProviderEnvKey'); $entryArguments.Add($ProviderEnvKey) }
  if ($UseUserConfig) { $entryArguments.Add('-UseUserConfig') }
  if ($DisablePlugins) { $entryArguments.Add('-DisablePlugins') }
  [void](Invoke-ValidationStep -Name 'entry-write-guard' -FilePath $hostPowerShell -Arguments @($entryArguments))

  $parityArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $LabRoot 'scripts\check_release_parity.ps1'), '-StandardRoot', $StandardRoot, '-LabRoot', $LabRoot, '-ReleaseRoot', $ReleaseRoot)
  [void](Invoke-ValidationStep -Name 'source-release-parity' -FilePath $hostPowerShell -Arguments $parityArguments)

  $windowsPowerShell = Get-Command 'powershell.exe' -ErrorAction SilentlyContinue
  if ($null -ne $windowsPowerShell) {
    [void](Invoke-ValidationStep -Name 'powershell-5.1-structure' -FilePath $windowsPowerShell.Source -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $StandardRoot 'scripts\check_skill_structure.ps1'), '-SkillRoot', $StandardRoot))
  }

  $validator = Join-Path $HOME '.codex\skills\.system\skill-creator\scripts\quick_validate.py'
  $pythonCandidates = @(
    (Join-Path $RepoRoot 'allred-project-standard-validation\quick-validate-env\Scripts\python.exe'),
    'python.exe',
    'python'
  )
  $pythonCommand = $null
  foreach ($candidate in $pythonCandidates) {
    if (Test-Path -LiteralPath $candidate) { $pythonCommand = $candidate; break }
    $found = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($null -ne $found) { $pythonCommand = $found.Source; break }
  }
  if ($pythonCommand -and (Test-Path -LiteralPath $validator)) {
    $previousPythonUtf8 = $env:PYTHONUTF8
    $env:PYTHONUTF8 = '1'
    try {
      [void](Invoke-ValidationStep -Name 'official-validate-standard' -FilePath $pythonCommand -Arguments @($validator, $StandardRoot))
      [void](Invoke-ValidationStep -Name 'official-validate-lab' -FilePath $pythonCommand -Arguments @($validator, $LabRoot))
    } finally {
      $env:PYTHONUTF8 = $previousPythonUtf8
    }
  } else {
    Add-StepResult -Name 'official-quick-validate' -Status 'Inconclusive' -ExitCode 3 -DurationMs 0 -Log '' -Reason 'Python validator runtime is unavailable.'
  }

  if (Test-Path -LiteralPath (Join-Path $ReleaseRoot 'install.ps1')) {
    $installRoot = Join-Path $OutputRoot 'isolated-install'
    [void](Invoke-ValidationStep -Name 'isolated-install' -FilePath $hostPowerShell -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $ReleaseRoot 'install.ps1'), '-DestinationRoot', $installRoot))
  }
  }
}

$finishedAt = [DateTime]::UtcNow
$failed = @($steps | Where-Object status -eq 'Fail').Count -gt 0
$result = if ($failed) { 'FAIL' } elseif ($inconclusive) { 'INCONCLUSIVE' } else { 'PASS' }
$behaviorEvidence = [ordered]@{
  lab_low = Get-BehaviorAggregateEvidence -Root $labRunRoot
  candidate_low = Get-BehaviorAggregateEvidence -Root $candidateLowRoot
  candidate_high = Get-BehaviorAggregateEvidence -Root $candidateHighRoot
  baseline_low = Get-BehaviorAggregateEvidence -Root $baselineLowRoot
}
$summary = [ordered]@{
  schema_version = 1
  mode = $Mode
  result = $result
  baseline_ref = $BaselineRef
  started_at_utc = $startedAt.ToString('o')
  finished_at_utc = $finishedAt.ToString('o')
  duration_ms = [int64]($finishedAt - $startedAt).TotalMilliseconds
  runtime = [ordered]@{
    model = $Model
    model_provider = $ModelProvider
    provider_env_key_name = $ProviderEnvKey
    low_reasoning_effort = $LowReasoningEffort
    high_reasoning_effort = $HighReasoningEffort
    use_user_config = [bool]$UseUserConfig
    plugins_enabled = -not [bool]$DisablePlugins
    max_parallel_cases = $MaxParallelCases
    initial_trials = $InitialTrials
    retry_trials = $RetryTrials
    minimum_agreement = $MinimumAgreement
    stateless_behavior_turns = [bool]$StatelessBehaviorTurns
    exact_case_selection = [bool]$ExactCaseSelection
  }
  impact = $impact
  selection = [ordered]@{
    standard_case_ids = @($selectedStandard | Sort-Object)
    lab_case_ids = @($selectedLab | Sort-Object)
    replay_case_ids = @($selectedReplay | Sort-Object)
  }
  steps = @($steps)
  behavior_evidence = $behaviorEvidence
  failures = @($failures)
}
$summaryPath = Join-Path $OutputRoot 'validation-summary.json'
Write-Utf8File -Path $summaryPath -Text ($summary | ConvertTo-Json -Depth 12)
& $hostPowerShell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $LabRoot 'scripts\write_validation_report.ps1') -SummaryPath $summaryPath | Out-Null

"Allred validation: $result"
"Mode: $Mode"
"Output: $OutputRoot"
"Report: $(Join-Path $OutputRoot 'report.html')"
$steps | Format-Table name, status, exit_code, duration_ms -AutoSize
if ($result -eq 'FAIL') { exit 2 }
if ($result -eq 'INCONCLUSIVE') { exit 3 }
exit 0
