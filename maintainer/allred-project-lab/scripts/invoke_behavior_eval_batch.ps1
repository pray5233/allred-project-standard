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
  [ValidateRange(1, 8)][int]$MaxParallelCases = 1,
  [ValidateRange(1, 5)][int]$InitialTrials = 1,
  [ValidateRange(0, 5)][int]$RetryTrials = 2,
  [ValidateRange(1, 5)][int]$MinimumAgreement = 1,
  [ValidateRange(10, 3600)][int]$TimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
$decodedCaseIds = Get-Content -LiteralPath $CaseIdsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$caseIds = @()
foreach ($caseId in $decodedCaseIds) { $caseIds += [string]$caseId }
if ($caseIds.Count -eq 0) { throw 'CaseIdsPath contains no behavior cases.' }
$RunnerPath = (Resolve-Path -LiteralPath $RunnerPath).Path
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$SuiteRoot = (Resolve-Path -LiteralPath $SuiteRoot).Path
$suiteManifest = Get-Content -LiteralPath (Join-Path $SuiteRoot 'tests\behavior-cases.test.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$priorityByCase = @{}
foreach ($case in @($suiteManifest.cases)) { $priorityByCase[[string]$case.id] = [string]$case.priority }
foreach ($caseId in $caseIds) { if (-not $priorityByCase.ContainsKey($caseId)) { throw "Unknown behavior case: $caseId" } }
$AggregatorPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'aggregate_behavior_trials.ps1')).Path
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$partsRoot = Join-Path $OutputRoot '.parallel-parts'
$logsRoot = Join-Path $OutputRoot '.parallel-logs'
New-Item -ItemType Directory -Force -Path $partsRoot, $logsRoot | Out-Null

$baseParameters = @{
  SkillRoot = $SkillRoot
  SuiteRoot = $SuiteRoot
  CodexCommand = $CodexCommand
  Model = $Model
  ModelProvider = $ModelProvider
  ProviderEnvKey = $ProviderEnvKey
  ReasoningEffort = $ReasoningEffort
  TimeoutSeconds = $TimeoutSeconds
  UseUserConfig = [bool]$UseUserConfig
  DisablePlugins = [bool]$DisablePlugins
  StatelessTurns = [bool]$StatelessTurns
}
$allResults = [System.Collections.Generic.List[object]]::new()
$hasFailures = $false
$stopAfterBatch = $false
$firstConfig = $null
$attemptedCaseIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

for ($offset = 0; $offset -lt $caseIds.Count -and -not $stopAfterBatch; $offset += $MaxParallelCases) {
  $last = [Math]::Min($offset + $MaxParallelCases - 1, $caseIds.Count - 1)
  $batch = @($caseIds[$offset..$last])
  foreach ($caseId in $batch) { $attemptedCaseIds.Add($caseId) | Out-Null }
  $jobs = foreach ($caseId in $batch) {
    $partRoot = Join-Path $partsRoot $caseId
    Start-Job -Name $caseId -ScriptBlock {
      param($Runner, $Aggregator, $BaseParameters, $PartRoot, $CaseId, $InitialTrials, $RetryTrials, $MinimumAgreement)
      $ErrorActionPreference = 'Stop'
      $caseRoot = Join-Path $PartRoot $CaseId
      New-Item -ItemType Directory -Force -Path $caseRoot | Out-Null

      function Invoke-OneTrial {
        param([int]$TrialNumber)
        $trialName = 'trial-{0:d2}' -f $TrialNumber
        $trialRoot = Join-Path $caseRoot $trialName
        $parameters = @{}
        if ($BaseParameters -is [System.Collections.IDictionary]) {
          foreach ($key in $BaseParameters.Keys) { $parameters[$key] = $BaseParameters[$key] }
        } else {
          foreach ($property in $BaseParameters.PSObject.Properties) { $parameters[$property.Name] = $property.Value }
        }
        $parameters.OutputRoot = $trialRoot
        $parameters.CaseIds = @($CaseId)
        $parameters.FailFastP0 = $false
        $output = & $Runner @parameters 2>&1
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        [System.IO.File]::WriteAllText((Join-Path $caseRoot "$trialName.log"), (@($output | ForEach-Object { $_.ToString() }) -join "`n"), [System.Text.UTF8Encoding]::new($false))
        $summaryPath = Join-Path $trialRoot 'summary.json'
        if (-not (Test-Path -LiteralPath $summaryPath)) { return $false }
        $items = @(Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json)
        $matches = @($items | Where-Object { [string]$_.case_id -eq $CaseId })
        return ($matches.Count -eq 1 -and $matches[0].status -eq 'Evaluated' -and $matches[0].result -eq 'Pass')
      }

      $trialNumber = 0
      $initialAllPass = $true
      for ($i = 0; $i -lt $InitialTrials; $i++) {
        $trialNumber++
        if (-not (Invoke-OneTrial -TrialNumber $trialNumber)) { $initialAllPass = $false }
      }
      $needsRetry = -not $initialAllPass
      if ($needsRetry) {
        $aggregatePath = Join-Path $caseRoot 'aggregate.json'
        & $Aggregator -CaseRoot $caseRoot -CaseId $CaseId -MinimumAgreement $MinimumAgreement -OutputPath $aggregatePath | Out-Null
        $aggregate = Get-Content -LiteralPath $aggregatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $minimumEvidence = [Math]::Max(2, $MinimumAgreement)
        if ($aggregate.trial_count -ge $minimumEvidence -and $aggregate.aggregate_result -in @('StablePass', 'StableFail')) { $needsRetry = $false }
      }
      if ($needsRetry) {
        for ($retry = 0; $retry -lt $RetryTrials; $retry++) {
          $trialNumber++
          [void](Invoke-OneTrial -TrialNumber $trialNumber)
          $aggregatePath = Join-Path $caseRoot 'aggregate.json'
          & $Aggregator -CaseRoot $caseRoot -CaseId $CaseId -MinimumAgreement $MinimumAgreement -OutputPath $aggregatePath | Out-Null
          $aggregate = Get-Content -LiteralPath $aggregatePath -Raw -Encoding UTF8 | ConvertFrom-Json
          $minimumEvidence = [Math]::Max(2, $MinimumAgreement)
          if ($aggregate.trial_count -ge $minimumEvidence -and $aggregate.aggregate_result -in @('StablePass', 'StableFail')) { break }
        }
      }

      $aggregatePath = Join-Path $caseRoot 'aggregate.json'
      & $Aggregator -CaseRoot $caseRoot -CaseId $CaseId -MinimumAgreement $MinimumAgreement -OutputPath $aggregatePath | Out-Null
      $aggregate = Get-Content -LiteralPath $aggregatePath -Raw -Encoding UTF8 | ConvertFrom-Json
      $representativeRoot = Join-Path (Join-Path $caseRoot ([string]$aggregate.representative_trial)) $CaseId
      if (Test-Path -LiteralPath $representativeRoot) {
        Get-ChildItem -LiteralPath $representativeRoot -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $caseRoot -Force }
      }
      [pscustomobject]@{ case_id = $CaseId; aggregate_result = $aggregate.aggregate_result; trial_count = $aggregate.trial_count }
    } -ArgumentList $RunnerPath, $AggregatorPath, $baseParameters, $partRoot, $caseId, $InitialTrials, $RetryTrials, $MinimumAgreement
  }

  $jobs | Wait-Job | Out-Null
  foreach ($job in $jobs) {
    $caseId = $job.Name
    $jobOutput = @(Receive-Job -Job $job 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    [System.IO.File]::WriteAllText((Join-Path $logsRoot "$caseId.log"), $jobOutput, [System.Text.UTF8Encoding]::new($false))
    $partCaseRoot = Join-Path (Join-Path $partsRoot $caseId) $caseId
    $destinationCaseRoot = Join-Path $OutputRoot $caseId
    if (Test-Path -LiteralPath $partCaseRoot) {
      Copy-Item -LiteralPath $partCaseRoot -Destination $OutputRoot -Recurse -Force
      $aggregatePath = Join-Path $destinationCaseRoot 'aggregate.json'
      & $AggregatorPath -CaseRoot $destinationCaseRoot -CaseId $caseId -MinimumAgreement $MinimumAgreement -OutputPath $aggregatePath | Out-Null
      $aggregate = Get-Content -LiteralPath $aggregatePath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($null -eq $aggregate.priority) { $aggregate.priority = $priorityByCase[$caseId] }
      $allResults.Add($aggregate) | Out-Null
      if ($null -eq $firstConfig) {
        $firstTrialConfig = Get-ChildItem -LiteralPath $destinationCaseRoot -Directory | Where-Object Name -match '^trial-[0-9]+$' | Sort-Object Name | ForEach-Object { Join-Path $_.FullName 'run-config.json' } | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($firstTrialConfig) { $firstConfig = Get-Content -LiteralPath $firstTrialConfig -Raw -Encoding UTF8 | ConvertFrom-Json }
      }
    } else {
      $allResults.Add([pscustomobject]@{ case_id = $caseId; priority = $priorityByCase[$caseId]; status = 'InfrastructureFailure'; result = $null; aggregate_result = 'InfrastructureInconclusive'; consistency_met = $false; consistency_threshold = $MinimumAgreement; trial_count = 0; counts = [ordered]@{ Pass = 0; Partial = 0; Fail = 0; InfrastructureFailure = 1 }; first_divergent_turn = $null; report = $null; infrastructure_reasons = @('Parallel worker produced no case evidence.') }) | Out-Null
    }
    Remove-Job -Job $job -Force
  }

  $failedItems = @($allResults | Where-Object { $_.aggregate_result -ne 'StablePass' })
  if ($failedItems.Count -gt 0) { $hasFailures = $true }
  if ($FailFastP0 -and @($failedItems | Where-Object priority -eq 'P0').Count -gt 0) { $stopAfterBatch = $true }
}

if ($null -ne $firstConfig) {
  $firstConfig.case_ids = @($caseIds)
  $firstConfig | Add-Member -NotePropertyName max_parallel_cases -NotePropertyValue $MaxParallelCases -Force
  $firstConfig | Add-Member -NotePropertyName initial_trials -NotePropertyValue $InitialTrials -Force
  $firstConfig | Add-Member -NotePropertyName retry_trials -NotePropertyValue $RetryTrials -Force
  $firstConfig | Add-Member -NotePropertyName minimum_agreement -NotePropertyValue $MinimumAgreement -Force
  [System.IO.File]::WriteAllText((Join-Path $OutputRoot 'run-config.json'), ($firstConfig | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

$orderedResults = [System.Collections.Generic.List[object]]::new()
foreach ($caseId in $caseIds) {
  $matches = @($allResults | Where-Object { [string]$_.case_id -eq $caseId })
  if ($matches.Count -eq 1) {
    $orderedResults.Add($matches[0]) | Out-Null
  } elseif ($matches.Count -eq 0 -and $stopAfterBatch -and -not $attemptedCaseIds.Contains($caseId)) {
    $orderedResults.Add([pscustomobject]@{ case_id = $caseId; priority = $priorityByCase[$caseId]; status = 'NotRun'; result = $null; aggregate_result = 'NotRun'; consistency_met = $false; consistency_threshold = $MinimumAgreement; trial_count = 0; counts = [ordered]@{ Pass = 0; Partial = 0; Fail = 0; InfrastructureFailure = 0 }; first_divergent_turn = $null; report = $null; not_run_reason = 'Skipped after an earlier P0 case did not pass.' }) | Out-Null
  } else {
    $hasFailures = $true
    $orderedResults.Add([pscustomobject]@{ case_id = $caseId; priority = $priorityByCase[$caseId]; status = 'InfrastructureFailure'; result = $null; aggregate_result = 'InfrastructureInconclusive'; consistency_met = $false; consistency_threshold = $MinimumAgreement; trial_count = 0; counts = [ordered]@{ Pass = 0; Partial = 0; Fail = 0; InfrastructureFailure = 1 }; first_divergent_turn = $null; report = $null; infrastructure_reasons = @("Parallel aggregation found $($matches.Count) results; expected exactly one.") }) | Out-Null
  }
}
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'summary.json'), (ConvertTo-Json -InputObject ([object[]]$orderedResults) -Depth 12), [System.Text.UTF8Encoding]::new($false))

'Multi-trial behavior runtime evaluation complete.'
"Output: $OutputRoot"
$orderedResults | Format-Table case_id, priority, aggregate_result, trial_count, first_divergent_turn -AutoSize
if (-not $hasFailures) { exit 0 }
$nonPassing = @($orderedResults | Where-Object aggregate_result -ne 'StablePass')
if ($nonPassing.Count -gt 0 -and @($nonPassing | Where-Object aggregate_result -ne 'InfrastructureInconclusive').Count -eq 0) { exit 3 }
exit 2
