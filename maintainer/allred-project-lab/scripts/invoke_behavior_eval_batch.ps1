param(
  [Parameter(Mandatory = $true)][string]$RunnerPath,
  [Parameter(Mandatory = $true)][string]$SkillRoot,
  [Parameter(Mandatory = $true)][string]$SuiteRoot,
  [Parameter(Mandatory = $true)][string]$OutputRoot,
  [Parameter(Mandatory = $true)][string]$CaseIdsPath,
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [ValidateSet('default', 'low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$ReasoningEffort = 'default',
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [switch]$StatelessTurns,
  [switch]$FailFastP0,
  [ValidateRange(1, 8)]
  [int]$MaxParallelCases = 1,
  [ValidateRange(10, 3600)]
  [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
$decodedCaseIds = Get-Content -LiteralPath $CaseIdsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$caseIds = @()
foreach ($caseId in $decodedCaseIds) { $caseIds += [string]$caseId }
if ($caseIds.Count -eq 0) { throw 'CaseIdsPath contains no behavior cases.' }
$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path
$parameters = @{
  SkillRoot = $SkillRoot
  SuiteRoot = $SuiteRoot
  OutputRoot = $OutputRoot
  CaseIds = @($caseIds)
  CodexCommand = $CodexCommand
  Model = $Model
  ModelProvider = $ModelProvider
  ProviderEnvKey = $ProviderEnvKey
  ReasoningEffort = $ReasoningEffort
  TimeoutSeconds = $TimeoutSeconds
  UseUserConfig = [bool]$UseUserConfig
  DisablePlugins = [bool]$DisablePlugins
  StatelessTurns = [bool]$StatelessTurns
  FailFastP0 = [bool]$FailFastP0
}

if ($MaxParallelCases -eq 1 -or $caseIds.Count -eq 1) {
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
$hasFailures = $false
$stopAfterBatch = $false
$firstConfig = $null

for ($offset = 0; $offset -lt $caseIds.Count -and -not $stopAfterBatch; $offset += $MaxParallelCases) {
  $last = [Math]::Min($offset + $MaxParallelCases - 1, $caseIds.Count - 1)
  $batch = @($caseIds[$offset..$last])
  $jobs = foreach ($caseId in $batch) {
    $partRoot = Join-Path $partsRoot $caseId
    $caseParameters = $parameters.Clone()
    $caseParameters.OutputRoot = $partRoot
    $caseParameters.CaseIds = @($caseId)
    $caseParameters.FailFastP0 = $false
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
      $decodedSummary = Get-Content -LiteralPath $partSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($item in $decodedSummary) { $allResults.Add($item) | Out-Null }
    } else {
      $allResults.Add([pscustomobject]@{ case_id = $caseId; priority = $null; status = 'InfrastructureFailure'; result = $null; first_divergent_turn = $null; report = $null; infrastructure_reason = "Parallel worker exited with code $($jobResult.exit_code) without summary." }) | Out-Null
    }
    if ($null -eq $firstConfig -and (Test-Path -LiteralPath (Join-Path $partRoot 'run-config.json'))) {
      $firstConfig = Get-Content -LiteralPath (Join-Path $partRoot 'run-config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    Remove-Job -Job $job -Force
  }

  $failedItems = @($allResults | Where-Object { $_.status -ne 'Evaluated' -or $_.result -ne 'Pass' })
  if ($failedItems.Count -gt 0) {
    $hasFailures = $true
    if ($FailFastP0) { $stopAfterBatch = $true }
  }
}

if ($null -ne $firstConfig) {
  $firstConfig.case_ids = @($caseIds)
  $firstConfig | Add-Member -NotePropertyName max_parallel_cases -NotePropertyValue $MaxParallelCases -Force
  [System.IO.File]::WriteAllText((Join-Path $OutputRoot 'run-config.json'), ($firstConfig | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}
$orderedResults = [System.Collections.Generic.List[object]]::new()
foreach ($caseId in $caseIds) {
  $matches = @($allResults | Where-Object { [string]$_.case_id -eq $caseId })
  if ($matches.Count -eq 1) {
    $orderedResults.Add($matches[0]) | Out-Null
  } else {
    $hasFailures = $true
    $orderedResults.Add([pscustomobject]@{ case_id = $caseId; priority = $null; status = 'InfrastructureFailure'; result = $null; first_divergent_turn = $null; report = $null; infrastructure_reason = "Parallel aggregation found $($matches.Count) results; expected exactly one." }) | Out-Null
  }
}
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'summary.json'), (ConvertTo-Json -InputObject ([object[]]$orderedResults) -Depth 8), [System.Text.UTF8Encoding]::new($false))

'Parallel behavior runtime evaluation complete.'
"Output: $OutputRoot"
$orderedResults | Format-Table case_id, priority, status, result, first_divergent_turn -AutoSize
if ($hasFailures) { exit 2 }
exit 0
