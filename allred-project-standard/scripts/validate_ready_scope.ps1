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

$evidence = @()
$decisions = @()
$scope = @()
$userSources = @{}
if ($null -ne $state) {
  $userSources = Get-AllredUserSourceMap $state
  $evidence = @(Get-AllredArray (Get-AllredProperty $state 'evidence'))
  $decisions = @(Get-AllredArray (Get-AllredProperty $state 'decisions'))
  $scope = @(Get-AllredArray (Get-AllredProperty $state 'scope'))
}

$evidenceById = @{}
foreach ($item in $evidence) {
  $id = [string](Get-AllredProperty $item 'id')
  $claimType = ([string](Get-AllredProperty $item 'claim_type')).ToLowerInvariant()
  $confidence = ([string](Get-AllredProperty $item 'confidence')).ToLowerInvariant()
  $method = [string](Get-AllredProperty $item 'method')
  $limitations = [string](Get-AllredProperty $item 'limitations')
  if ($id -notmatch '^E[0-9A-Za-z._-]+$') { Add-Failure "Invalid evidence ID: $id"; continue }
  if ($evidenceById.ContainsKey($id)) { Add-Failure "Duplicate evidence ID: $id"; continue }
  $evidenceById[$id] = $item
  if ($claimType -notin @('observed', 'reported', 'inferred', 'hypothesis')) { Add-Failure "Invalid evidence claim_type for ${id}: $claimType" }
  if ($confidence -notin @('verified', 'supported', 'provisional', 'unknown')) { Add-Failure "Invalid evidence confidence for ${id}: $confidence" }
  if ([string]::IsNullOrWhiteSpace($method)) { Add-Failure "Evidence has no observation method: $id" }
  if ($claimType -in @('inferred', 'hypothesis') -and [string]::IsNullOrWhiteSpace($limitations)) {
    Add-Failure "Inference or hypothesis has no limitation: $id"
  }
}

$decisionById = @{}
foreach ($decision in $decisions) {
  $id = [string](Get-AllredProperty $decision 'id')
  if ($id -match '^D[0-9A-Za-z._-]+$') { $decisionById[$id] = $decision }
}

$scopeById = @{}
$visibleScopeIds = [System.Collections.Generic.List[string]]::new()
$allowedCategories = @('behavior', 'delivery', 'data', 'effect', 'non-goal', 'acceptance', 'technical')
foreach ($item in $scope) {
  $id = [string](Get-AllredProperty $item 'id')
  $statement = [string](Get-AllredProperty $item 'statement')
  $category = ([string](Get-AllredProperty $item 'category')).ToLowerInvariant()
  $visible = Get-AllredProperty $item 'visible'
  $approvalRequired = Get-AllredProperty $item 'approval_required'
  $prominent = Get-AllredProperty $item 'recommendation_prominent'
  $provenance = @((Get-AllredArray (Get-AllredProperty $item 'provenance')) | ForEach-Object { [string]$_ })

  if ($id -notmatch '^S[0-9A-Za-z._-]+$') { Add-Failure "Invalid scope ID: $id"; continue }
  if ($scopeById.ContainsKey($id)) { Add-Failure "Duplicate scope ID: $id"; continue }
  $scopeById[$id] = $item
  if ([string]::IsNullOrWhiteSpace($statement)) { Add-Failure "Scope item has no statement: $id" }
  if ($category -notin $allowedCategories) { Add-Failure "Invalid scope category for ${id}: $category" }
  if ($null -eq $visible -or $visible -isnot [bool]) { Add-Failure "Scope visible must be boolean: $id" }
  if ($visible -eq $true) {
    $visibleScopeIds.Add($id) | Out-Null
    if ($approvalRequired -ne $true) { Add-Failure "Visible scope item is not inside the approval envelope: $id" }
  }
  if ($provenance.Count -eq 0) { Add-Failure "Scope item has no provenance: $id" }

  $hasProductAuthority = $false
  $hasRecommendation = $false
  foreach ($reference in $provenance) {
    if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UEDRB')) {
      Add-Failure "Scope item $id has invalid provenance: $reference"
      continue
    }
    switch (Get-AllredReferencePrefix $reference) {
      'U' {
        $hasProductAuthority = $true
        if (-not $userSources.ContainsKey($reference)) { Add-Failure "Scope item $id references missing user source: $reference" }
      }
      'D' {
        $hasProductAuthority = $true
        if (-not $decisionById.ContainsKey($reference) -or ([string](Get-AllredProperty $decisionById[$reference] 'status')).ToLowerInvariant() -ne 'confirmed') {
          Add-Failure "Scope item $id references unconfirmed decision: $reference"
        }
      }
      'E' { if (-not $evidenceById.ContainsKey($reference)) { Add-Failure "Scope item $id references missing evidence: $reference" } }
      'R' { $hasProductAuthority = $true; $hasRecommendation = $true }
    }
  }
  if ($visible -eq $true -and $category -ne 'technical' -and -not $hasProductAuthority) {
    Add-Failure "Evidence or benchmark alone selected user-visible scope: $id"
  }
  if ($hasRecommendation -and $prominent -ne $true) {
    Add-Failure "Unapproved recommendation is not prominent in the final scope: $id"
  }
}

if ($scope.Count -eq 0) { Add-Failure 'READY scope is empty.' }

foreach ($conclusion in @(Get-AllredArray (Get-AllredProperty $state 'technical_conclusions'))) {
  $id = [string](Get-AllredProperty $conclusion 'id')
  $status = ([string](Get-AllredProperty $conclusion 'status')).ToLowerInvariant()
  $statement = [string](Get-AllredProperty $conclusion 'statement')
  $method = [string](Get-AllredProperty $conclusion 'method')
  $limitations = [string](Get-AllredProperty $conclusion 'limitations')
  $basisSource = [string](Get-AllredProperty $conclusion 'basis_source')
  $versionOrDate = [string](Get-AllredProperty $conclusion 'version_or_date')
  $comparableBecause = [string](Get-AllredProperty $conclusion 'comparable_because')
  $deliberateDifferences = [string](Get-AllredProperty $conclusion 'deliberate_differences')
  $basis = @((Get-AllredArray (Get-AllredProperty $conclusion 'evidence')) | ForEach-Object { [string]$_ })
  if ($id -notmatch '^T[0-9A-Za-z._-]+$') { Add-Failure "Invalid technical conclusion ID: $id" }
  if ([string]::IsNullOrWhiteSpace($statement)) { Add-Failure "Technical conclusion has no statement: $id" }
  if ($status -notin @('candidate', 'verified', 'unknown')) { Add-Failure "Technical conclusion uses unsupported certainty for ${id}: $status" }
  if ([string]::IsNullOrWhiteSpace($method)) { Add-Failure "Technical conclusion has no validation method: $id" }
  if ([string]::IsNullOrWhiteSpace($basisSource)) { Add-Failure "Technical conclusion has no named basis source: $id" }
  if ([string]::IsNullOrWhiteSpace($versionOrDate)) { Add-Failure "Technical conclusion has no version or date: $id" }
  if ([string]::IsNullOrWhiteSpace($comparableBecause)) { Add-Failure "Technical conclusion has no comparability rationale: $id" }
  if ([string]::IsNullOrWhiteSpace($deliberateDifferences)) { Add-Failure "Technical conclusion has no deliberate-differences record: $id" }
  foreach ($reference in $basis) {
    if ($reference -notmatch '^[EB][0-9A-Za-z._-]+$') { Add-Failure "Technical conclusion $id has invalid evidence/benchmark reference: $reference" }
    if ($reference -match '^E' -and -not $evidenceById.ContainsKey($reference)) { Add-Failure "Technical conclusion $id references missing evidence: $reference" }
  }
  if ($status -eq 'verified' -and $basis.Count -eq 0) { Add-Failure "Verified technical conclusion has no evidence: $id" }
  if ($status -in @('candidate', 'unknown') -and [string]::IsNullOrWhiteSpace($limitations)) {
    Add-Failure "Candidate or unknown technical conclusion has no limitation: $id"
  }
}

foreach ($blocker in @(Get-AllredArray (Get-AllredProperty $state 'blocking_items'))) {
  $status = ([string](Get-AllredProperty $blocker 'status')).ToLowerInvariant()
  $blocks = @((Get-AllredArray (Get-AllredProperty $blocker 'blocks')) | ForEach-Object { ([string]$_).ToUpperInvariant() })
  if ($status -eq 'open' -and ('READY' -in $blocks -or 'EXECUTION' -in $blocks)) {
    Add-Failure "Open blocker remains before READY: $([string](Get-AllredProperty $blocker 'id'))"
  }
}

$authorization = Get-AllredProperty $state 'authorization'
if ($null -eq $authorization) {
  Add-Failure 'Authorization envelope is missing.'
} else {
  $envelopeId = [string](Get-AllredProperty $authorization 'envelope_id')
  $authState = ([string](Get-AllredProperty $authorization 'state')).ToLowerInvariant()
  $authScopeIds = @((Get-AllredArray (Get-AllredProperty $authorization 'scope_ids')) | ForEach-Object { [string]$_ })
  if ($envelopeId -notmatch '^C[0-9A-Za-z._-]+$') { Add-Failure "Invalid authorization envelope ID: $envelopeId" }
  if ($authState -notin @('pending', 'approved')) { Add-Failure "Invalid authorization state: $authState" }
  if ((Get-AllredProperty $authorization 'starts_execution') -ne $true) { Add-Failure 'READY envelope does not explicitly start execution.' }
  foreach ($scopeId in $visibleScopeIds) {
    if ($scopeId -notin $authScopeIds) { Add-Failure "Visible scope item is outside the exact authorization envelope: $scopeId" }
  }
  foreach ($scopeId in $authScopeIds) {
    if (-not $scopeById.ContainsKey($scopeId)) { Add-Failure "Authorization envelope references missing scope item: $scopeId" }
  }
  if ($authState -eq 'approved' -and ([string](Get-AllredProperty $authorization 'approval_source')) -notmatch '^(U|C)[0-9A-Za-z._-]+$') {
    Add-Failure 'Approved authorization has no exact user/envelope source.'
  }
  $authSource = [string](Get-AllredProperty $authorization 'approval_source')
  if ($authState -eq 'approved' -and $authSource -match '^U' -and -not $userSources.ContainsKey($authSource)) {
    Add-Failure "Approved authorization references missing user source: $authSource"
  }
}

$interaction = Get-AllredProperty $state 'interaction'
if ($null -eq $interaction) {
  Add-Failure 'Interaction contract is missing.'
} else {
  if ((Get-AllredProperty $interaction 'natural_language_reply_allowed') -ne $true) { Add-Failure 'Natural-language replies are not allowed.' }
  if ((Get-AllredProperty $interaction 'id_reply_optional') -ne $true) { Add-Failure 'Q/D IDs are not optional for the user.' }
}

if ($failures.Count -gt 0) {
  'READY scope validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'READY scope validation: PASS'
"Scope items checked: $($scope.Count)"
"Visible scope items: $($visibleScopeIds.Count)"
