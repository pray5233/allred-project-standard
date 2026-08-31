param(
  [Parameter(Mandatory = $true)][string]$RunnerPath,
  [Parameter(Mandatory = $true)][string]$LabRoot,
  [Parameter(Mandatory = $true)][string]$SuiteRoot,
  [Parameter(Mandatory = $true)][string]$CandidateRunRoot,
  [Parameter(Mandatory = $true)][string]$BaselineRunRoot,
  [Parameter(Mandatory = $true)][string]$OutputRoot,
  [Parameter(Mandatory = $true)][string]$CaseIdsPath,
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [ValidateSet('default', 'low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$ReasoningEffort = 'low',
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [ValidateRange(1, 8)]
  [int]$MaxParallelCases = 1,
  [ValidateRange(30, 900)]
  [int]$TimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'
$decodedCaseIds = Get-Content -LiteralPath $CaseIdsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$caseIds = @()
foreach ($caseId in $decodedCaseIds) { $caseIds += [string]$caseId }
if ($caseIds.Count -eq 0) { throw 'CaseIdsPath contains no comparison cases.' }
$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path
$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path
$CandidateRunRoot = (Resolve-Path -LiteralPath $CandidateRunRoot).Path
$BaselineRunRoot = (Resolve-Path -LiteralPath $BaselineRunRoot).Path
$parameters = @{
  LabRoot = $LabRoot
  SuiteRoot = $SuiteRoot
  CandidateRunRoot = $CandidateRunRoot
  BaselineRunRoot = $BaselineRunRoot
  CodexCommand = $CodexCommand
  Model = $Model
  ModelProvider = $ModelProvider
  ProviderEnvKey = $ProviderEnvKey
  ReasoningEffort = $ReasoningEffort
  UseUserConfig = [bool]$UseUserConfig
  DisablePlugins = [bool]$DisablePlugins
  TimeoutSeconds = $TimeoutSeconds
}

if ($MaxParallelCases -eq 1 -or $caseIds.Count -eq 1) {
  $parameters.CaseIds = @($caseIds)
  $parameters.OutputRoot = $OutputRoot
  & $RunnerPath @parameters
  $runnerExitCode = $LASTEXITCODE
  if ($null -eq $runnerExitCode) { $runnerExitCode = 0 }
  exit [int]$runnerExitCode
}

$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$partsRoot = Join-Path $OutputRoot '.parallel-parts'
$logsRoot = Join-Path $OutputRoot '.parallel-logs'
New-Item -ItemType Directory -Force -Path $partsRoot, $logsRoot | Out-Null
$allResults = [System.Collections.Generic.List[object]]::new()

for ($offset = 0; $offset -lt $caseIds.Count; $offset += $MaxParallelCases) {
  $last = [Math]::Min($offset + $MaxParallelCases - 1, $caseIds.Count - 1)
  $batch = @($caseIds[$offset..$last])
  $jobs = foreach ($caseId in $batch) {
    $partRoot = Join-Path $partsRoot $caseId
    $caseParameters = $parameters.Clone()
    $caseParameters.CaseIds = @($caseId)
    $caseParameters.OutputRoot = $partRoot
    Start-Job -Name $caseId -ScriptBlock {
      param($Runner, $Parameters)
      $output = & $Runner @Parameters 2>&1
      $code = $LASTEXITCODE
      if ($null -eq $code) { $code = 0 }
      [pscustomobject]@{ case_id = $Parameters.CaseIds[0]; exit_code = [int]$code; output = (@($output | ForEach-Object { $_.ToString() }) -join "`n") }
    } -ArgumentList $RunnerPath, $caseParameters
  }

  $jobs | Wait-Job | Out-Null
  foreach ($job in $jobs) {
    $jobResult = Receive-Job -Job $job
    $caseId = $job.Name
    $partRoot = Join-Path $partsRoot $caseId
    [System.IO.File]::WriteAllText((Join-Path $logsRoot "$caseId.log"), [string]$jobResult.output, [System.Text.UTF8Encoding]::new($false))
    $caseDirectory = Join-Path $partRoot $caseId
    if (Test-Path -LiteralPath $caseDirectory) { Copy-Item -LiteralPath $caseDirectory -Destination $OutputRoot -Recurse -Force }
    $partSummaryPath = Join-Path $partRoot 'summary.json'
    if (Test-Path -LiteralPath $partSummaryPath) {
      foreach ($item in @(Get-Content -LiteralPath $partSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json)) { $allResults.Add($item) | Out-Null }
    } else {
      $allResults.Add([pscustomobject]@{ case_id = $caseId; status = 'InfrastructureFailure'; candidate_outcome = $null; material_regression = $null; reason = "Parallel comparison worker exited with code $($jobResult.exit_code) without summary." }) | Out-Null
    }
    Remove-Job -Job $job -Force
  }
}

$orderedResults = [System.Collections.Generic.List[object]]::new()
foreach ($caseId in $caseIds) {
  $matches = @($allResults | Where-Object case_id -eq $caseId)
  if ($matches.Count -eq 1) {
    $orderedResults.Add($matches[0]) | Out-Null
  } else {
    $orderedResults.Add([pscustomobject]@{ case_id = $caseId; status = 'InfrastructureFailure'; candidate_outcome = $null; material_regression = $null; reason = "Parallel comparison aggregation found $($matches.Count) results; expected exactly one." }) | Out-Null
  }
}
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'summary.json'), (ConvertTo-Json -InputObject ([object[]]$orderedResults) -Depth 8), [System.Text.UTF8Encoding]::new($false))
'Parallel blind comparison complete.'
"Output: $OutputRoot"
$orderedResults | Format-Table case_id, status, candidate_outcome, material_regression, duration_ms -AutoSize
$failures = @($orderedResults | Where-Object { $_.status -ne 'Compared' -or ($_.candidate_outcome -eq 'BaselineBetter' -and $_.material_regression) })
if ($failures.Count -gt 0) { exit 2 }
exit 0
