param(
  [Parameter(Mandatory = $true)]
  [string]$Path
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

if ($null -ne $state) {
  $scope = @(Get-AllredArray (Get-AllredProperty $state 'scope'))
  $scopeById = @{}
  foreach ($item in $scope) {
    $id = [string](Get-AllredProperty $item 'id')
    if (-not [string]::IsNullOrWhiteSpace($id)) { $scopeById[$id] = $item }
  }

  $authorization = Get-AllredProperty $state 'authorization'
  $authorizedScopeIds = @((Get-AllredArray (Get-AllredProperty $authorization 'scope_ids')) | ForEach-Object { [string]$_ })
  $changeControl = Get-AllredProperty $state 'change_control'
  if ($null -eq $changeControl) {
    Add-Failure 'READY change_control is missing.'
  } else {
    $mode = ([string](Get-AllredProperty $changeControl 'mode')).ToLowerInvariant()
    $baseline = Get-AllredProperty $changeControl 'baseline'
    $baselineId = [string](Get-AllredProperty $baseline 'id')
    $baselineStatus = ([string](Get-AllredProperty $baseline 'status')).ToLowerInvariant()
    $baselineScopeIds = @((Get-AllredArray (Get-AllredProperty $baseline 'scope_ids')) | ForEach-Object { [string]$_ })
    $preservedScopeIds = @((Get-AllredArray (Get-AllredProperty $changeControl 'preserved_scope_ids')) | ForEach-Object { [string]$_ })
    $coveredScopeIds = [System.Collections.Generic.List[string]]::new()

    if ($mode -notin @('new-baseline', 'delta')) { Add-Failure "Invalid change_control mode: $mode" }
    if ($baselineId -notmatch '^BASE-[0-9A-Za-z._-]+$') { Add-Failure "Invalid baseline ID: $baselineId" }
    if ($baselineStatus -notin @('candidate', 'confirmed')) { Add-Failure "Invalid baseline status: $baselineStatus" }
    if ($baselineScopeIds.Count -eq 0) { Add-Failure 'Baseline scope_ids is empty.' }
    foreach ($scopeId in $baselineScopeIds) {
      if (-not $scopeById.ContainsKey($scopeId)) { Add-Failure "Baseline references missing scope item: $scopeId" }
    }

    if ($mode -eq 'new-baseline') {
      foreach ($scopeId in $baselineScopeIds) { $coveredScopeIds.Add($scopeId) | Out-Null }
      if ($null -ne (Get-AllredProperty $changeControl 'change')) {
        Add-Failure 'new-baseline mode must not contain a change package.'
      }
    }

    if ($mode -eq 'delta') {
      if ($baselineStatus -ne 'confirmed') { Add-Failure 'delta mode requires a confirmed baseline.' }
      $change = Get-AllredProperty $changeControl 'change'
      if ($null -eq $change) {
        Add-Failure 'delta mode requires a change package.'
      } else {
        $changeId = [string](Get-AllredProperty $change 'id')
        $changeStatus = ([string](Get-AllredProperty $change 'status')).ToLowerInvariant()
        $operations = @(Get-AllredArray (Get-AllredProperty $change 'operations'))
        if ($changeId -notmatch '^CHG-[0-9A-Za-z._-]+$') { Add-Failure "Invalid change ID: $changeId" }
        if ($changeStatus -notin @('proposed', 'approved', 'implemented', 'verified', 'merged', 'superseded')) {
          Add-Failure "Invalid change status: $changeStatus"
        }
        if ($operations.Count -eq 0) { Add-Failure 'delta change package has no operations.' }

        $operationIds = @{}
        foreach ($operation in $operations) {
          $operationId = [string](Get-AllredProperty $operation 'id')
          $operationType = ([string](Get-AllredProperty $operation 'operation')).ToLowerInvariant()
          $statement = [string](Get-AllredProperty $operation 'statement')
          $operationScopeIds = @((Get-AllredArray (Get-AllredProperty $operation 'scope_ids')) | ForEach-Object { [string]$_ })
          $provenance = @((Get-AllredArray (Get-AllredProperty $operation 'provenance')) | ForEach-Object { [string]$_ })

          if ($operationId -notmatch '^CI-[0-9A-Za-z._-]+$') { Add-Failure "Invalid change item ID: $operationId" }
          if ($operationIds.ContainsKey($operationId)) { Add-Failure "Duplicate change item ID: $operationId" } else { $operationIds[$operationId] = $true }
          if ($operationType -notin @('add', 'modify', 'remove')) { Add-Failure "Invalid operation for ${operationId}: $operationType" }
          if ([string]::IsNullOrWhiteSpace($statement)) { Add-Failure "Change item has no statement: $operationId" }
          if ($operationScopeIds.Count -eq 0) { Add-Failure "Change item has no scope_ids: $operationId" }
          if ($provenance.Count -eq 0) { Add-Failure "Change item has no provenance: $operationId" }
          foreach ($reference in $provenance) {
            if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UEDR')) { Add-Failure "Change item $operationId has invalid provenance: $reference" }
          }
          foreach ($scopeId in $operationScopeIds) {
            if (-not $scopeById.ContainsKey($scopeId)) {
              Add-Failure "Change item $operationId references missing scope item: $scopeId"
              continue
            }
            if ($coveredScopeIds.Contains($scopeId)) { Add-Failure "Scope item is covered more than once in change_control: $scopeId" }
            $coveredScopeIds.Add($scopeId) | Out-Null
            $relation = ([string](Get-AllredProperty $scopeById[$scopeId] 'relation')).ToLowerInvariant()
            if ($operationType -eq 'remove' -and $relation -ne 'excluded') {
              Add-Failure "Removed change item must map to excluded scope: $operationId -> $scopeId"
            }
            if ($operationType -in @('add', 'modify') -and $relation -eq 'excluded') {
              Add-Failure "$operationType change item cannot map to excluded scope: $operationId -> $scopeId"
            }
          }
        }
      }

      foreach ($scopeId in $preservedScopeIds) {
        if (-not $scopeById.ContainsKey($scopeId)) { Add-Failure "preserved_scope_ids references missing scope item: $scopeId"; continue }
        if ($coveredScopeIds.Contains($scopeId)) { Add-Failure "Scope item is both changed and preserved: $scopeId" }
        $coveredScopeIds.Add($scopeId) | Out-Null
      }
    }

    foreach ($scopeId in $authorizedScopeIds) {
      if (-not $coveredScopeIds.Contains($scopeId)) { Add-Failure "Authorized scope is missing from baseline/change coverage: $scopeId" }
    }
    foreach ($scopeId in $coveredScopeIds) {
      if ($scopeId -notin $authorizedScopeIds) { Add-Failure "Baseline/change coverage is outside the authorization envelope: $scopeId" }
    }

    $laterIds = @{}
    foreach ($later in @(Get-AllredArray (Get-AllredProperty $changeControl 'later_items'))) {
      $id = [string](Get-AllredProperty $later 'id')
      $statement = [string](Get-AllredProperty $later 'statement')
      $status = ([string](Get-AllredProperty $later 'status')).ToLowerInvariant()
      $revisitWhen = [string](Get-AllredProperty $later 'revisit_when')
      $provenance = @((Get-AllredArray (Get-AllredProperty $later 'provenance')) | ForEach-Object { [string]$_ })
      if ($id -notmatch '^LATER-[0-9A-Za-z._-]+$') { Add-Failure "Invalid later item ID: $id" }
      if ($laterIds.ContainsKey($id)) { Add-Failure "Duplicate later item ID: $id" } else { $laterIds[$id] = $true }
      if ([string]::IsNullOrWhiteSpace($statement)) { Add-Failure "Later item has no statement: $id" }
      if ($status -notin @('suggested', 'confirmed-deferred')) { Add-Failure "Invalid later item status for ${id}: $status" }
      if ((Get-AllredProperty $later 'blocking') -ne $false) { Add-Failure "Later item must be non-blocking: $id" }
      if ([string]::IsNullOrWhiteSpace($revisitWhen)) { Add-Failure "Later item has no revisit condition: $id" }
      if ($provenance.Count -eq 0) { Add-Failure "Later item has no provenance: $id" }
      foreach ($reference in $provenance) {
        if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UEDR')) { Add-Failure "Later item $id has invalid provenance: $reference" }
      }
      if ($status -eq 'confirmed-deferred' -and -not @($provenance | Where-Object { $_ -match '^[UD]' }).Count) {
        Add-Failure "Confirmed deferred item lacks user or confirmed-decision provenance: $id"
      }
    }
  }
}

if ($failures.Count -gt 0) {
  'Change traceability validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Change traceability validation: PASS'
