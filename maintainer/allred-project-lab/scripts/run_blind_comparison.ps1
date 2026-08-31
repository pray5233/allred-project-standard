param(
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$SuiteRoot = (Join-Path (Split-Path -Parent $LabRoot) 'allred-project-standard'),
  [Parameter(Mandatory = $true)][string]$CandidateRunRoot,
  [Parameter(Mandatory = $true)][string]$BaselineRunRoot,
  [string[]]$CaseIds = @(),
  [string]$CaseIdsPath = '',
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ("allred-blind-comparison-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [ValidateSet('default', 'low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$ReasoningEffort = 'low',
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [ValidateRange(30, 900)]
  [int]$TimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')

$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path
$CandidateRunRoot = (Resolve-Path -LiteralPath $CandidateRunRoot).Path
$BaselineRunRoot = (Resolve-Path -LiteralPath $BaselineRunRoot).Path
$testSuite = Get-Content -LiteralPath (Join-Path $SuiteRoot 'tests\behavior-cases.test.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oracleSuite = Get-Content -LiteralPath (Join-Path $SuiteRoot 'tests\behavior-cases.oracle.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$schemaPath = Join-Path $LabRoot 'tests\comparison-result.schema.json'
if ($CaseIdsPath) { $CaseIds = @(Get-Content -LiteralPath $CaseIdsPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
if (@($CaseIds).Count -eq 0) {
  $CaseIds = @((Get-ChildItem -LiteralPath $CandidateRunRoot -Directory).Name | Where-Object { Test-Path -LiteralPath (Join-Path $BaselineRunRoot $_) })
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$summary = [System.Collections.Generic.List[object]]::new()
foreach ($id in $CaseIds) {
  $candidatePath = Join-Path (Join-Path $CandidateRunRoot $id) 'transcript.json'
  $baselinePath = Join-Path (Join-Path $BaselineRunRoot $id) 'transcript.json'
  if (-not (Test-Path -LiteralPath $candidatePath) -or -not (Test-Path -LiteralPath $baselinePath)) {
    $summary.Add([pscustomobject]@{ case_id = $id; status = 'MissingTranscript'; candidate_outcome = $null; material_regression = $true; reason = 'Candidate or baseline transcript is missing.' }) | Out-Null
    continue
  }

  $case = $testSuite.cases | Where-Object id -eq $id | Select-Object -First 1
  $oracle = $oracleSuite.cases | Where-Object id -eq $id | Select-Object -First 1
  $checksum = 0
  foreach ($character in $id.ToCharArray()) { $checksum += [int][char]$character }
  $candidateLabel = if (($checksum % 2) -eq 0) { 'A' } else { 'B' }
  $baselineLabel = if ($candidateLabel -eq 'A') { 'B' } else { 'A' }
  $outputs = @{}
  $outputs[$candidateLabel] = Get-Content -LiteralPath $candidatePath -Raw -Encoding UTF8
  $outputs[$baselineLabel] = Get-Content -LiteralPath $baselinePath -Raw -Encoding UTF8
  $caseDirectory = Join-Path $OutputRoot $id

  $prompt = @"
You are a blind comparator for two versions of a project workflow Skill. You do not know which output is newer.

Compare the immutable transcripts against the user-visible scenario, assertions, and hard failures. Prefer the output that better preserves user intent, evidence honesty, decision efficiency, authorization boundaries, and usable communication. Do not reward verbosity. Set material_regression=true only when the losing output is meaningfully worse for project correctness, user control, or interaction quality; a stylistic preference alone is not material. Return only JSON matching the supplied schema.

CASE ID: $id
VISIBLE SCENARIO:
$((@($case.visible_turns) | ConvertTo-Json -Depth 6))
ASSERTIONS:
$((@($oracle.assertions) | ConvertTo-Json -Depth 6))
HARD FAILURES:
$((@($oracle.hard_failures) | ConvertTo-Json -Depth 6))
OUTPUT A:
$($outputs['A'])
OUTPUT B:
$($outputs['B'])
"@
  $run = Invoke-AllredCodexEval -Prompt $prompt -RunDirectory $caseDirectory -Prefix 'compare' -SchemaPath $schemaPath -CodexCommand $CodexCommand -Model $Model -ModelProvider $ModelProvider -ProviderEnvKey $ProviderEnvKey -ReasoningEffort $ReasoningEffort -UseUserConfig ([bool]$UseUserConfig) -DisablePlugins ([bool]$DisablePlugins) -TimeoutSeconds $TimeoutSeconds
  if (Test-AllredEvalInfrastructureFailure $run) {
    $summary.Add([pscustomobject]@{ case_id = $id; status = 'InfrastructureFailure'; candidate_outcome = $null; material_regression = $null; reason = Get-AllredEvalInfrastructureReason -Run $run -TimeoutSeconds $TimeoutSeconds }) | Out-Null
    continue
  }

  try {
    $comparison = $run.Final | ConvertFrom-Json
    Write-AllredEvalUtf8 -Path (Join-Path $caseDirectory 'comparison.json') -Text $run.Final
    $candidateOutcome = if ($comparison.winner -eq 'Tie') { 'Equivalent' } elseif ($comparison.winner -eq $candidateLabel) { 'CandidateBetter' } else { 'BaselineBetter' }
    $summary.Add([pscustomobject]@{
      case_id = $id
      status = 'Compared'
      candidate_outcome = $candidateOutcome
      material_regression = [bool]$comparison.material_regression
      duration_ms = $run.DurationMs
      reason = $comparison.reasoning
      candidate_label = $candidateLabel
    }) | Out-Null
  } catch {
    $summary.Add([pscustomobject]@{ case_id = $id; status = 'ReviewerOutputInvalid'; candidate_outcome = $null; material_regression = $null; reason = $_.Exception.Message }) | Out-Null
  }
}

$summaryPath = Join-Path $OutputRoot 'summary.json'
Write-AllredEvalUtf8 -Path $summaryPath -Text (ConvertTo-Json -InputObject @($summary) -Depth 8)
'Blind comparison complete.'
"Output: $OutputRoot"
$summary | Format-Table case_id, status, candidate_outcome, material_regression, duration_ms -AutoSize
$failures = @($summary | Where-Object { $_.status -ne 'Compared' -or ($_.candidate_outcome -eq 'BaselineBetter' -and $_.material_regression) })
if ($failures.Count -gt 0) { exit 2 }
exit 0
