param(
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string[]]$CaseIds = @(),
  [string]$CaseIdsPath = '',
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ("allred-replay-eval-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
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

$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
$casesPath = Join-Path $LabRoot 'tests\replay-cases.json'
$oraclePath = Join-Path $LabRoot 'tests\replay-oracle.json'
$schemaPath = Join-Path $LabRoot 'tests\review-result.schema.json'
$cases = Get-Content -LiteralPath $casesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$oracle = Get-Content -LiteralPath $oraclePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($CaseIdsPath) { $CaseIds = @(Get-Content -LiteralPath $CaseIdsPath -Raw -Encoding UTF8 | ConvertFrom-Json) }
if (@($CaseIds).Count -eq 0) { $CaseIds = @($cases.cases.id) }

$selected = @($cases.cases | Where-Object { $_.id -in $CaseIds })
foreach ($id in $CaseIds) {
  if ($id -notin @($selected.id)) { throw "Unknown replay case: $id" }
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$summary = [System.Collections.Generic.List[object]]::new()
foreach ($case in $selected) {
  $caseDirectory = Join-Path $OutputRoot $case.id
  New-Item -ItemType Directory -Force -Path $caseDirectory | Out-Null
  $expected = $oracle.cases | Where-Object id -eq $case.id | Select-Object -First 1
  $transcriptPath = Join-Path $caseDirectory 'transcript.json'
  Write-AllredEvalUtf8 -Path $transcriptPath -Text ($case.transcript | ConvertTo-Json -Depth 8)

  $prompt = @"
You are an independent check group reviewing an immutable conversation record from a project workflow Skill.

Judge only the observed transcript against the supplied assertions. Do not improve, continue, or rewrite the conversation. Missing evidence is not success. A hard failure makes the result Fail. Partial means at least one material assertion is unmet without a hard failure. Pass requires every material assertion to be satisfied. Return only JSON matching the supplied schema.

CASE ID: $($case.id)
ASSERTIONS:
$((@($expected.assertions) | ConvertTo-Json -Depth 5))
HARD FAILURES:
$((@($expected.hard_failures) | ConvertTo-Json -Depth 5))
OBSERVED TRANSCRIPT:
$(Get-Content -LiteralPath $transcriptPath -Raw -Encoding UTF8)
"@
  $run = Invoke-AllredCodexEval -Prompt $prompt -RunDirectory $caseDirectory -Prefix 'review' -SchemaPath $schemaPath -CodexCommand $CodexCommand -Model $Model -ModelProvider $ModelProvider -ProviderEnvKey $ProviderEnvKey -ReasoningEffort $ReasoningEffort -UseUserConfig ([bool]$UseUserConfig) -DisablePlugins ([bool]$DisablePlugins) -TimeoutSeconds $TimeoutSeconds
  if (Test-AllredEvalInfrastructureFailure $run) {
    $summary.Add([pscustomobject]@{
      case_id = $case.id
      expected = $expected.expected_result
      actual = $null
      status = 'InfrastructureFailure'
      duration_ms = $run.DurationMs
      reason = Get-AllredEvalInfrastructureReason -Run $run -TimeoutSeconds $TimeoutSeconds
    }) | Out-Null
    continue
  }

  $reviewPath = Join-Path $caseDirectory 'review.json'
  Write-AllredEvalUtf8 -Path $reviewPath -Text $run.Final
  try {
    $review = $run.Final | ConvertFrom-Json
    $status = if ($review.result -eq $expected.expected_result) { 'Matched' } else { 'Mismatched' }
    $summary.Add([pscustomobject]@{
      case_id = $case.id
      expected = $expected.expected_result
      actual = $review.result
      status = $status
      duration_ms = $run.DurationMs
      first_divergent_turn = $review.first_divergent_turn
      report = $reviewPath
      reason = $review.notes
    }) | Out-Null
  } catch {
    $summary.Add([pscustomobject]@{
      case_id = $case.id
      expected = $expected.expected_result
      actual = $null
      status = 'ReviewerOutputInvalid'
      duration_ms = $run.DurationMs
      reason = $_.Exception.Message
    }) | Out-Null
  }
}

$summaryPath = Join-Path $OutputRoot 'summary.json'
Write-AllredEvalUtf8 -Path $summaryPath -Text (ConvertTo-Json -InputObject @($summary) -Depth 8)
'Replay evaluation complete.'
"Output: $OutputRoot"
$summary | Format-Table case_id, expected, actual, status, duration_ms -AutoSize
if (@($summary | Where-Object status -ne 'Matched').Count -gt 0) { exit 2 }
exit 0
