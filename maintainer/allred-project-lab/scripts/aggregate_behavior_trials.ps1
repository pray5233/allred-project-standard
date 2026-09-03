param(
  [Parameter(Mandatory = $true)][string]$CaseRoot,
  [Parameter(Mandatory = $true)][string]$CaseId,
  [ValidateRange(1, 5)][int]$MinimumAgreement = 1,
  [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$CaseRoot = (Resolve-Path -LiteralPath $CaseRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $CaseRoot 'aggregate.json' }
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

function Get-ConfigFingerprint {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $config = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  $stable = [ordered]@{
    skill_md_sha256 = $config.skill_md_sha256
    runtime_surface_sha256 = $config.runtime_surface_sha256
    test_suite_sha256 = $config.test_suite_sha256
    oracle_suite_sha256 = $config.oracle_suite_sha256
    model_override = $config.model_override
    model_provider_override = $config.model_provider_override
    provider_env_key_name = $config.provider_env_key_name
    reasoning_effort_override = $config.reasoning_effort_override
    timeout_seconds = $config.timeout_seconds
    use_user_config = $config.use_user_config
    disable_plugins = $config.disable_plugins
    stateless_turns = $config.stateless_turns
    user_config_sha256 = $config.user_config_sha256
  }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($stable | ConvertTo-Json -Compress -Depth 5))
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() }
  finally { $sha.Dispose() }
}

$trialDirectories = @(Get-ChildItem -LiteralPath $CaseRoot -Directory | Where-Object { $_.Name -match '^trial-[0-9]+$' } | Sort-Object Name)
if ($trialDirectories.Count -eq 0) { throw "No trial directories were found for $CaseId under $CaseRoot." }

$records = [System.Collections.Generic.List[object]]::new()
$priority = $null
$hardFailureCounts = @{}
foreach ($trialDirectory in $trialDirectories) {
  $summaryPath = Join-Path $trialDirectory.FullName 'summary.json'
  $configPath = Join-Path $trialDirectory.FullName 'run-config.json'
  $configExists = Test-Path -LiteralPath $configPath
  $runtimeHash = $null
  if ($configExists) {
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $runtimeHash = [string]$config.runtime_surface_sha256
  }

  $item = $null
  $reason = ''
  if (Test-Path -LiteralPath $summaryPath) {
    $matches = @(Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json | Where-Object { [string]$_.case_id -eq $CaseId })
    if ($matches.Count -eq 1) { $item = $matches[0] }
    else { $reason = "Trial summary contained $($matches.Count) matching results; expected exactly one." }
  } else {
    $reason = 'Trial summary is missing.'
  }

  $status = if ($null -ne $item) { [string]$item.status } else { 'InfrastructureFailure' }
  $result = if ($null -ne $item) { [string]$item.result } else { $null }
  if ($null -ne $item -and $null -eq $priority) { $priority = $item.priority }
  if ($null -ne $item -and $item.infrastructure_reason) { $reason = [string]$item.infrastructure_reason }
  $outcome = if ($status -eq 'Evaluated' -and $result -in @('Pass', 'Partial', 'Fail')) { $result } else { 'InfrastructureFailure' }

  $transcriptPath = Join-Path (Join-Path $trialDirectory.FullName $CaseId) 'transcript.json'
  $reviewPath = Join-Path (Join-Path $trialDirectory.FullName $CaseId) 'review.json'
  if (-not (Test-Path -LiteralPath $reviewPath) -and $null -ne $item -and $item.report) { $reviewPath = [string]$item.report }
  $hardFailures = @()
  $reviewValid = $false
  if (Test-Path -LiteralPath $reviewPath) {
    try {
      $reviewData = Get-Content -LiteralPath $reviewPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ([string]$reviewData.case_id -ne $CaseId -or [string]$reviewData.result -ne $result) { throw 'Reviewer evidence does not match the trial summary.' }
      $hardFailures = @($reviewData.hard_failures | ForEach-Object { [string]$_ })
      $reviewValid = $true
    }
    catch { $reason = (@($reason, 'Reviewer evidence is invalid JSON.') | Where-Object { $_ }) -join ' ' }
  }
  if ($status -eq 'Evaluated') {
    $evidenceGaps = @()
    if (-not $configExists) { $evidenceGaps += 'run config is missing' }
    elseif ([string]::IsNullOrWhiteSpace($runtimeHash)) { $evidenceGaps += 'runtime-surface hash is missing' }
    if (-not (Test-Path -LiteralPath $transcriptPath)) { $evidenceGaps += 'transcript is missing' }
    if (-not $reviewValid) { $evidenceGaps += 'review evidence is missing or invalid' }
    if ($evidenceGaps.Count -gt 0) {
      $outcome = 'InfrastructureFailure'
      $reason = (@($reason, ($evidenceGaps -join ', ')) | Where-Object { $_ }) -join ' '
      $hardFailures = @()
    }
  }
  foreach ($failure in $hardFailures) {
    $signature = $failure.Trim().ToLowerInvariant()
    if (-not $signature) { continue }
    if (-not $hardFailureCounts.ContainsKey($signature)) { $hardFailureCounts[$signature] = 0 }
    $hardFailureCounts[$signature]++
  }

  $records.Add([pscustomobject]@{
    trial = $trialDirectory.Name
    status = $status
    result = $result
    outcome = $outcome
    first_divergent_turn = if ($null -ne $item) { $item.first_divergent_turn } else { $null }
    review_path = if (Test-Path -LiteralPath $reviewPath) { $reviewPath } else { $null }
    transcript_path = $transcriptPath
    runtime_surface_sha256 = $runtimeHash
    configuration_fingerprint = Get-ConfigFingerprint -Path $configPath
    infrastructure_reason = if ($outcome -eq 'InfrastructureFailure') { $reason } else { $null }
    hard_failures = @($hardFailures)
  }) | Out-Null
}

$passCount = @($records | Where-Object outcome -eq 'Pass').Count
$partialCount = @($records | Where-Object outcome -eq 'Partial').Count
$failCount = @($records | Where-Object outcome -eq 'Fail').Count
$infrastructureCount = @($records | Where-Object outcome -eq 'InfrastructureFailure').Count
$semanticCount = $passCount + $partialCount + $failCount
$nonPassCount = $partialCount + $failCount
$repeatedHardFailure = @($hardFailureCounts.GetEnumerator() | Where-Object Value -ge 2).Count -gt 0
$hardFailureTotal = @($hardFailureCounts.GetEnumerator() | ForEach-Object { [int]$_.Value } | Measure-Object -Sum).Sum
if ($null -eq $hardFailureTotal) { $hardFailureTotal = 0 }
$runtimeHashes = @($records.runtime_surface_sha256 | Where-Object { $_ } | Sort-Object -Unique)
$configFingerprints = @($records.configuration_fingerprint | Where-Object { $_ } | Sort-Object -Unique)
$configurationDrift = $runtimeHashes.Count -gt 1 -or $configFingerprints.Count -gt 1

$aggregateResult = if ($semanticCount -eq 0) {
  'InfrastructureInconclusive'
} elseif ($configurationDrift) {
  'Variable'
} elseif ($repeatedHardFailure) {
  'StableFail'
} elseif ($passCount -ge $MinimumAgreement -and $passCount -gt $nonPassCount -and $failCount -eq 0 -and $hardFailureTotal -eq 0) {
  'StablePass'
} elseif ($nonPassCount -ge $MinimumAgreement -and $nonPassCount -gt $passCount) {
  'StableFail'
} else {
  'Variable'
}

$compatibilityStatus = if ($aggregateResult -eq 'InfrastructureInconclusive') { 'InfrastructureFailure' } else { 'Evaluated' }
$compatibilityResult = switch ($aggregateResult) {
  'StablePass' { 'Pass' }
  'StableFail' { 'Fail' }
  'Variable' { 'Partial' }
  default { $null }
}
$divergentTurns = @($records | Where-Object { $null -ne $_.first_divergent_turn } | ForEach-Object { [int]$_.first_divergent_turn } | Sort-Object)
$representative = $records | Where-Object { $_.outcome -in @('Pass', 'Partial', 'Fail') } | Select-Object -First 1
if ($null -eq $representative) { $representative = $records | Select-Object -First 1 }
$outcomes = @($records.outcome | Sort-Object -Unique)
$hardFailureSummary = @($hardFailureCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { [pscustomobject]@{ signature = $_.Name; count = [int]$_.Value } })

$aggregate = [pscustomobject]@{
  aggregate_schema_version = 1
  case_id = $CaseId
  priority = $priority
  status = $compatibilityStatus
  result = $compatibilityResult
  aggregate_result = $aggregateResult
  consistency_met = $aggregateResult -in @('StablePass', 'StableFail')
  consistency_threshold = $MinimumAgreement
  trial_count = $records.Count
  counts = [ordered]@{
    Pass = $passCount
    Partial = $partialCount
    Fail = $failCount
    InfrastructureFailure = $infrastructureCount
  }
  has_variance = ($outcomes.Count -gt 1 -or $configurationDrift)
  first_divergent_turn = if ($divergentTurns.Count -gt 0) { $divergentTurns[0] } else { $null }
  report = $OutputPath
  representative_trial = $representative.trial
  runtime_surface_hashes = @($runtimeHashes)
  configuration_fingerprints = @($configFingerprints)
  hard_failure_signatures = @($hardFailureSummary)
  infrastructure_reasons = @($records.infrastructure_reason | Where-Object { $_ } | Sort-Object -Unique)
  trials = @($records)
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
[System.IO.File]::WriteAllText($OutputPath, ($aggregate | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
$aggregate
