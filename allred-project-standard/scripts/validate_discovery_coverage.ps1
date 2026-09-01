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
  $coverage = Get-AllredProperty $state 'discovery_coverage'
  if ($null -eq $coverage) {
    Add-Failure 'Discovery coverage review is missing.'
  } else {
    $coverageStatus = ([string](Get-AllredProperty $coverage 'status')).ToLowerInvariant()
    if ($coverageStatus -ne 'complete') { Add-Failure "Discovery coverage review is not complete: $coverageStatus" }

    $requiredMethods = @('contract-slots', 'evidence-gaps', 'counterexample-sweep')
    $methods = @((Get-AllredArray (Get-AllredProperty $coverage 'review_methods')) | ForEach-Object { ([string]$_).ToLowerInvariant() })
    foreach ($method in $requiredMethods) {
      if ($method -notin $methods) { Add-Failure "Discovery coverage review method is missing: $method" }
    }

    $evidence = @(Get-AllredArray (Get-AllredProperty $state 'evidence'))
    $evidenceIds = @($evidence | ForEach-Object { [string](Get-AllredProperty $_ 'id') })
    $reviewedEvidenceIds = @((Get-AllredArray (Get-AllredProperty $coverage 'evidence_ids_reviewed')) | ForEach-Object { [string]$_ })
    foreach ($evidenceId in $evidenceIds) {
      if ($evidenceId -notin $reviewedEvidenceIds) { Add-Failure "Discovery coverage did not review current evidence: $evidenceId" }
    }
    foreach ($reviewedId in $reviewedEvidenceIds) {
      if ($reviewedId -notin $evidenceIds) { Add-Failure "Discovery coverage references missing evidence: $reviewedId" }
    }

    $requiredAreaIds = @('workflow', 'information', 'lifecycle', 'operating-scale', 'delivery-effects', 'acceptance')
    $allowedStatuses = @('resolved', 'not-applicable', 'deferred', 'open', 'investigating')
    $closedStatuses = @('resolved', 'not-applicable', 'deferred')
    $areas = @(Get-AllredArray (Get-AllredProperty $coverage 'areas'))
    $areasById = @{}
    $coveredDecisionIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $coveredScopeIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $userSources = Get-AllredUserSourceMap $state
    $decisionIds = @((Get-AllredArray (Get-AllredProperty $state 'decisions')) | ForEach-Object { [string](Get-AllredProperty $_ 'id') })
    $scopeIds = @((Get-AllredArray (Get-AllredProperty $state 'scope')) | ForEach-Object { [string](Get-AllredProperty $_ 'id') })

    foreach ($area in $areas) {
      $id = ([string](Get-AllredProperty $area 'id')).ToLowerInvariant()
      $status = ([string](Get-AllredProperty $area 'status')).ToLowerInvariant()
      $summary = [string](Get-AllredProperty $area 'summary')
      $basis = @((Get-AllredArray (Get-AllredProperty $area 'basis')) | ForEach-Object { [string]$_ })
      $openItems = @((Get-AllredArray (Get-AllredProperty $area 'open_item_ids')) | ForEach-Object { [string]$_ })
      $reason = [string](Get-AllredProperty $area 'reason')
      $consequence = [string](Get-AllredProperty $area 'consequence')
      $revisitCondition = [string](Get-AllredProperty $area 'revisit_condition')

      if ([string]::IsNullOrWhiteSpace($id)) { Add-Failure 'Discovery coverage area has no ID.'; continue }
      if ($areasById.ContainsKey($id)) { Add-Failure "Duplicate discovery coverage area: $id"; continue }
      $areasById[$id] = $area
      if ($status -notin $allowedStatuses) { Add-Failure "Invalid discovery coverage status for ${id}: $status" }
      if ([string]::IsNullOrWhiteSpace($summary)) { Add-Failure "Discovery coverage area has no summary: $id" }
      if ($basis.Count -eq 0) { Add-Failure "Discovery coverage area has no U/E/D basis: $id" }
      foreach ($reference in $basis) {
        if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UED')) {
          Add-Failure "Discovery coverage area $id has invalid basis: $reference"
        } elseif ($reference -match '^U' -and -not $userSources.ContainsKey($reference)) {
          Add-Failure "Discovery coverage area $id references missing user source: $reference"
        } elseif ($reference -match '^E' -and $reference -notin $evidenceIds) {
          Add-Failure "Discovery coverage area $id references missing evidence: $reference"
        } elseif ($reference -match '^D' -and $reference -notin $decisionIds) {
          Add-Failure "Discovery coverage area $id references missing decision: $reference"
        }
      }

      if ($status -notin $closedStatuses) {
        Add-Failure "Discovery coverage area remains unresolved at READY: $id ($status)"
        if ($openItems.Count -eq 0) { Add-Failure "Unresolved discovery coverage area has no tracked open item: $id" }
      } elseif ($openItems.Count -gt 0) {
        Add-Failure "Closed discovery coverage area still has open items: $id"
      }

      if ($status -eq 'not-applicable' -and [string]::IsNullOrWhiteSpace($reason)) {
        Add-Failure "Not-applicable discovery coverage area has no reason: $id"
      }
      if ($status -eq 'deferred') {
        if (@($basis | Where-Object { $_ -match '^[UD]' }).Count -eq 0) { Add-Failure "Deferred discovery coverage area has no exact U/D source: $id" }
        if ([string]::IsNullOrWhiteSpace($consequence)) { Add-Failure "Deferred discovery coverage area has no consequence: $id" }
        if ([string]::IsNullOrWhiteSpace($revisitCondition)) { Add-Failure "Deferred discovery coverage area has no revisit condition: $id" }
      }

      foreach ($decisionId in @((Get-AllredArray (Get-AllredProperty $area 'decision_ids')) | ForEach-Object { [string]$_ })) {
        if ($decisionId -notin $decisionIds) { Add-Failure "Discovery coverage area $id references missing decision ID: $decisionId" }
        else { $coveredDecisionIds.Add($decisionId) | Out-Null }
      }
      foreach ($scopeId in @((Get-AllredArray (Get-AllredProperty $area 'scope_ids')) | ForEach-Object { [string]$_ })) {
        if ($scopeId -notin $scopeIds) { Add-Failure "Discovery coverage area $id references missing scope ID: $scopeId" }
        else { $coveredScopeIds.Add($scopeId) | Out-Null }
      }
    }

    foreach ($requiredAreaId in $requiredAreaIds) {
      if (-not $areasById.ContainsKey($requiredAreaId)) { Add-Failure "Required discovery coverage lens is missing: $requiredAreaId" }
    }

    foreach ($decision in @(Get-AllredArray (Get-AllredProperty $state 'decisions'))) {
      $id = [string](Get-AllredProperty $decision 'id')
      $status = ([string](Get-AllredProperty $decision 'status')).ToLowerInvariant()
      if ($status -in @('confirmed', 'deferred') -and -not $coveredDecisionIds.Contains($id)) {
        Add-Failure "Confirmed/deferred decision is absent from discovery coverage: $id"
      }
    }
    foreach ($scopeId in $scopeIds) {
      if (-not $coveredScopeIds.Contains($scopeId)) { Add-Failure "Scope item is absent from discovery coverage: $scopeId" }
    }
  }
}

if ($failures.Count -gt 0) {
  'Discovery coverage validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Discovery coverage validation: PASS'
