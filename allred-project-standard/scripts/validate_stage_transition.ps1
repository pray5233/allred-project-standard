param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [Parameter(Mandatory = $true)]
  [ValidateSet('DECISION', 'READY', 'EXECUTION')]
  [string]$ToStage
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')

$failures = [System.Collections.Generic.List[string]]::new()
function Add-Failure([string]$Message) { $script:failures.Add($Message) | Out-Null }

try {
  $state = Read-AllredProjectState -Path $Path
} catch {
  Add-Failure $_.Exception.Message
  $state = $null
}

function Require-ReadinessItem {
  param(
    [object]$Intake,
    [string]$Name,
    [string[]]$AllowedStatuses
  )

  $item = Get-AllredProperty $Intake $Name
  if ($null -eq $item) { Add-Failure "Missing intake readiness item: $Name"; return }
  $status = ([string](Get-AllredProperty $item 'status')).ToLowerInvariant()
  $source = [string](Get-AllredProperty $item 'source')
  if ($status -notin $AllowedStatuses) { Add-Failure "Intake readiness item $Name is not complete: $status" }
  if (-not (Test-AllredReferenceId -Value $source -Prefixes 'UE')) { Add-Failure "Intake readiness item $Name has no U/E source: $source" }
}

if ($null -ne $state) {
  $userSources = Get-AllredUserSourceMap $state
  $intake = Get-AllredProperty $state 'intake'
  if ($null -eq $intake) {
    Add-Failure 'Intake readiness ledger is missing.'
  } else {
    Require-ReadinessItem -Intake $intake -Name 'outcome' -AllowedStatuses @('confirmed')
    Require-ReadinessItem -Intake $intake -Name 'materials' -AllowedStatuses @('inspected', 'unavailable', 'deferred')
    Require-ReadinessItem -Intake $intake -Name 'initial_idea' -AllowedStatuses @('confirmed', 'delegated')
    Require-ReadinessItem -Intake $intake -Name 'useful_result' -AllowedStatuses @('confirmed')

    $materials = Get-AllredProperty $intake 'materials'
    if ($null -ne $materials -and ([string](Get-AllredProperty $materials 'status')).ToLowerInvariant() -eq 'inspected') {
      if (@(Get-AllredArray (Get-AllredProperty $state 'evidence')).Count -eq 0) {
        Add-Failure 'Materials are marked inspected but the evidence ledger is empty.'
      }
    }
  }

  $complexity = Get-AllredProperty $state 'complexity'
  if ($null -eq $complexity) {
    Add-Failure 'Complexity assessment is missing.'
  } else {
    $assessment = ([string](Get-AllredProperty $complexity 'assessment')).ToLowerInvariant()
    if ($assessment -notin @('simple', 'non-simple', 'unknown')) { Add-Failure "Invalid complexity assessment: $assessment" }
    if ($assessment -in @('non-simple', 'unknown')) {
      if (@(Get-AllredArray (Get-AllredProperty $complexity 'drivers')).Count -eq 0) { Add-Failure 'Non-simple or unknown complexity has no evidence-backed drivers.' }
      if ((Get-AllredProperty $complexity 'communicated') -ne $true) { Add-Failure 'Non-simple or unknown complexity was not communicated.' }
      if ([string]::IsNullOrWhiteSpace([string](Get-AllredProperty $complexity 'user_impact'))) { Add-Failure 'Complexity communication has no user-facing impact.' }
    }
  }

  foreach ($name in @('outcome', 'materials', 'initial_idea', 'useful_result')) {
    $item = if ($null -ne $intake) { Get-AllredProperty $intake $name } else { $null }
    $source = if ($null -ne $item) { [string](Get-AllredProperty $item 'source') } else { '' }
    if ($source -match '^U' -and -not $userSources.ContainsKey($source)) { Add-Failure "Intake readiness item $name references missing user source: $source" }
  }

  if ($ToStage -in @('READY', 'EXECUTION')) {
    $preflight = Get-AllredProperty $state 'preflight'
    if ($null -eq $preflight -or ([string](Get-AllredProperty $preflight 'status')).ToLowerInvariant() -ne 'complete') {
      Add-Failure 'Read-only technical preflight is not complete.'
    }
    $record = if ($null -ne $preflight) { Get-AllredProperty $preflight 'execution_record' } else { $null }
    if ($null -eq $record -or ([string](Get-AllredProperty $record 'status')).ToLowerInvariant() -ne 'valid') {
      Add-Failure 'Internal execution record is not valid.'
    }
  }

  if ($ToStage -eq 'EXECUTION') {
    $authorization = Get-AllredProperty $state 'authorization'
    if ($null -eq $authorization -or ([string](Get-AllredProperty $authorization 'state')).ToLowerInvariant() -ne 'approved') {
      Add-Failure 'Exact READY authorization has not been approved.'
    }
  }
}

if ($failures.Count -gt 0) {
  'Stage transition validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Stage transition validation: PASS'
"Target stage: $ToStage"
