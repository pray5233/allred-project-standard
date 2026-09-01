param(
  [ValidateSet('Changed', 'Release', 'FullLow', 'FullDual')]
  [string]$Suite = 'Changed',
  [string]$RepoRoot = '',
  [string]$StandardRoot = '',
  [string]$LabRoot = '',
  [string]$BaselineRef = 'v0.8.0-rc11',
  [string]$Model = 'gpt-5.6-sol',
  [ValidateRange(1, 8)]
  [int]$MaxParallelCases = 3,
  [ValidateRange(30, 3600)]
  [int]$TimeoutSeconds = 420,
  [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

if ([string]::IsNullOrWhiteSpace($LabRoot)) { $LabRoot = Split-Path -Parent $PSScriptRoot }
$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = (Resolve-Path (Join-Path $LabRoot '..\..')).Path }
else { $RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path }
if ([string]::IsNullOrWhiteSpace($StandardRoot)) { $StandardRoot = Join-Path $RepoRoot 'allred-project-standard' }
$StandardRoot = (Resolve-Path -LiteralPath $StandardRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path $RepoRoot ("_eval\{0}-{1}" -f $Suite.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$codex = Get-Command 'codex' -ErrorAction SilentlyContinue
if ($null -eq $codex) { throw 'Codex CLI is not available on this runner.' }
& $codex.Source login status
if ($LASTEXITCODE -ne 0) { throw 'Codex CLI is not authenticated on this runner.' }

$runner = Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'
$batch = Join-Path $LabRoot 'scripts\invoke_behavior_eval_batch.ps1'
$candidate = Join-Path $LabRoot 'scripts\invoke_candidate_validation.ps1'

function Invoke-AllredCiCommand {
  param([string]$FilePath, [hashtable]$Parameters)
  & $FilePath @Parameters
  $code = $LASTEXITCODE
  if ($null -eq $code) { $code = 0 }
  if ($code -ne 0) { exit [int]$code }
}

if ($Suite -in @('Changed', 'Release')) {
  $mode = if ($Suite -eq 'Changed') { 'Changed' } else { 'Candidate' }
  $parameters = @{
    Mode = $mode
    RepoRoot = $RepoRoot
    StandardRoot = $StandardRoot
    LabRoot = $LabRoot
    ReleaseRoot = $RepoRoot
    BaselineRef = $BaselineRef
    Model = $Model
    LowReasoningEffort = 'low'
    HighReasoningEffort = 'xhigh'
    MaxParallelCases = $MaxParallelCases
    TimeoutSeconds = $TimeoutSeconds
    OutputRoot = $OutputRoot
  }
  Invoke-AllredCiCommand -FilePath $candidate -Parameters $parameters
  exit 0
}

$suiteJson = Get-Content -LiteralPath (Join-Path $StandardRoot 'tests\behavior-cases.test.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$caseIds = @($suiteJson.cases.id | ForEach-Object { [string]$_ })
if ($caseIds.Count -eq 0) { throw 'Behavior suite contains no cases.' }
$caseIdsPath = Join-Path $OutputRoot 'all-case-ids.json'
[System.IO.File]::WriteAllText($caseIdsPath, ($caseIds | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))

$efforts = if ($Suite -eq 'FullDual') { @('low', 'xhigh') } else { @('low') }
foreach ($effort in $efforts) {
  $runRoot = Join-Path $OutputRoot $effort
  $parameters = @{
    RunnerPath = $runner
    SkillRoot = $StandardRoot
    SuiteRoot = $StandardRoot
    OutputRoot = $runRoot
    CaseIdsPath = $caseIdsPath
    Model = $Model
    ReasoningEffort = $effort
    UseUserConfig = $true
    DisablePlugins = $true
    StatelessTurns = $true
    MaxParallelCases = $MaxParallelCases
    TimeoutSeconds = $TimeoutSeconds
  }
  Invoke-AllredCiCommand -FilePath $batch -Parameters $parameters
}

"Allred CI behavior evaluation: PASS"
"Suite: $Suite"
"Cases: $($caseIds.Count)"
"Output: $OutputRoot"
