Set-StrictMode -Version 2.0

function Get-AllredProperty {
  param(
    [object]$Object,
    [string]$Name
  )

  if ($null -eq $Object) { return $null }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { return $null }
  return $property.Value
}

function Get-AllredArray {
  param([object]$Value)

  if ($null -eq $Value) { return @() }
  return @($Value)
}

function Read-AllredProjectState {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Project state package not found: $Path"
  }

  try {
    $state = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    throw "Project state package is not valid JSON: $($_.Exception.Message)"
  }

  if ((Get-AllredProperty $state 'schema_version') -ne 1) {
    throw 'Project state package schema_version must be 1.'
  }
  if ([string]::IsNullOrWhiteSpace([string](Get-AllredProperty $state 'state_id'))) {
    throw 'Project state package state_id is missing.'
  }
  if ([string]::IsNullOrWhiteSpace([string](Get-AllredProperty $state 'route'))) {
    throw 'Project state package route is missing.'
  }

  $userSources = @(Get-AllredArray (Get-AllredProperty $state 'user_sources'))
  if ($userSources.Count -eq 0) {
    throw 'Project state package user_sources ledger is missing.'
  }
  $sourceIds = @{}
  foreach ($source in $userSources) {
    $id = [string](Get-AllredProperty $source 'id')
    $quote = [string](Get-AllredProperty $source 'quote')
    $meaning = [string](Get-AllredProperty $source 'meaning')
    $authority = ([string](Get-AllredProperty $source 'authority')).ToLowerInvariant()
    if ($id -notmatch '^U[0-9A-Za-z._-]+$') { throw "Invalid user source ID: $id" }
    if ($sourceIds.ContainsKey($id)) { throw "Duplicate user source ID: $id" }
    if ([string]::IsNullOrWhiteSpace($quote)) { throw "User source has no exact quote: $id" }
    if ([string]::IsNullOrWhiteSpace($meaning)) { throw "User source has no normalized meaning: $id" }
    if ($authority -notin @('requirement', 'explicit-exclusion', 'constraint', 'context', 'acceptance', 'delegation')) {
      throw "User source has invalid authority: $id ($authority)"
    }
    $sourceIds[$id] = $source
  }

  return $state
}

function Get-AllredUserSourceMap {
  param([object]$State)

  $result = @{}
  foreach ($source in @(Get-AllredArray (Get-AllredProperty $State 'user_sources'))) {
    $result[[string](Get-AllredProperty $source 'id')] = $source
  }
  return $result
}

function Test-AllredReferenceId {
  param(
    [string]$Value,
    [string]$Prefixes = 'UEDRB'
  )

  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  return $Value -match "^[$Prefixes][0-9A-Za-z._-]+$"
}

function Get-AllredReferencePrefix {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  return $Value.Substring(0, 1).ToUpperInvariant()
}

function Test-AllredAbsolutePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  return $Path -match '^[A-Za-z]:[\\/]' -or $Path.StartsWith('/')
}

function ConvertTo-AllredComparablePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  $value = ($Path -replace '\\', '/').TrimEnd('/')
  if ($value -match '^[A-Za-z]:') { $value = $value.Substring(0, 1).ToLowerInvariant() + $value.Substring(1) }
  return $value
}

function Test-AllredPathWithin {
  param(
    [string]$Root,
    [string]$Candidate
  )

  if (-not (Test-AllredAbsolutePath -Path $Root) -or -not (Test-AllredAbsolutePath -Path $Candidate)) { return $false }
  $rootValue = ConvertTo-AllredComparablePath -Path $Root
  $candidateValue = ConvertTo-AllredComparablePath -Path $Candidate
  if ($candidateValue.Equals($rootValue, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $candidateValue.StartsWith($rootValue + '/', [System.StringComparison]::OrdinalIgnoreCase)
}
