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
$allowedRelations = @('required', 'excluded', 'recommended', 'acceptance', 'technical')
foreach ($item in $scope) {
  $id = [string](Get-AllredProperty $item 'id')
  $statement = [string](Get-AllredProperty $item 'statement')
  $category = ([string](Get-AllredProperty $item 'category')).ToLowerInvariant()
  $relation = ([string](Get-AllredProperty $item 'relation')).ToLowerInvariant()
  $visible = Get-AllredProperty $item 'visible'
  $approvalRequired = Get-AllredProperty $item 'approval_required'
  $prominent = Get-AllredProperty $item 'recommendation_prominent'
  $provenance = @((Get-AllredArray (Get-AllredProperty $item 'provenance')) | ForEach-Object { [string]$_ })

  if ($id -notmatch '^S[0-9A-Za-z._-]+$') { Add-Failure "Invalid scope ID: $id"; continue }
  if ($scopeById.ContainsKey($id)) { Add-Failure "Duplicate scope ID: $id"; continue }
  $scopeById[$id] = $item
  if ([string]::IsNullOrWhiteSpace($statement)) { Add-Failure "Scope item has no statement: $id" }
  if ($category -notin $allowedCategories) { Add-Failure "Invalid scope category for ${id}: $category" }
  if ($relation -notin $allowedRelations) { Add-Failure "Invalid scope relation for ${id}: $relation" }
  if ($category -eq 'non-goal' -and $relation -ne 'excluded') { Add-Failure "Non-goal scope item is not explicitly excluded: $id" }
  if ($relation -eq 'excluded' -and $category -ne 'non-goal') { Add-Failure "Excluded scope item must use category non-goal: $id" }
  if ($category -eq 'acceptance' -and $relation -ne 'acceptance') { Add-Failure "Acceptance scope item has the wrong relation: $id" }
  if ($relation -eq 'acceptance' -and $category -ne 'acceptance') { Add-Failure "Acceptance relation must use category acceptance: $id" }
  if ($category -eq 'technical' -and $relation -ne 'technical') { Add-Failure "Technical scope item has the wrong relation: $id" }
  if ($relation -eq 'technical' -and $category -ne 'technical') { Add-Failure "Technical relation must use category technical: $id" }
  if ($null -eq $visible -or $visible -isnot [bool]) { Add-Failure "Scope visible must be boolean: $id" }
  if ($visible -eq $true) {
    $visibleScopeIds.Add($id) | Out-Null
    if ($approvalRequired -ne $true) { Add-Failure "Visible scope item is not inside the approval envelope: $id" }
  }
  if ($provenance.Count -eq 0) { Add-Failure "Scope item has no provenance: $id" }

  $hasProductAuthority = $false
  $hasExplicitExclusion = $false
  $hasRecommendation = $false
  foreach ($reference in $provenance) {
    if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UEDRB')) {
      Add-Failure "Scope item $id has invalid provenance: $reference"
      continue
    }
    switch (Get-AllredReferencePrefix $reference) {
      'U' {
        if (-not $userSources.ContainsKey($reference)) {
          Add-Failure "Scope item $id references missing user source: $reference"
        } else {
          $sourceAuthority = ([string](Get-AllredProperty $userSources[$reference] 'authority')).ToLowerInvariant()
          if ($sourceAuthority -in @('requirement', 'constraint', 'acceptance', 'delegation')) { $hasProductAuthority = $true }
          if ($sourceAuthority -eq 'explicit-exclusion') { $hasExplicitExclusion = $true }
        }
      }
      'D' {
        if (-not $decisionById.ContainsKey($reference) -or ([string](Get-AllredProperty $decisionById[$reference] 'status')).ToLowerInvariant() -ne 'confirmed') {
          Add-Failure "Scope item $id references unconfirmed decision: $reference"
        } else {
          $decisionAuthority = ([string](Get-AllredProperty $decisionById[$reference] 'authority')).ToLowerInvariant()
          if ($decisionAuthority -notin @('required', 'explicit-exclusion', 'constraint', 'acceptance', 'recommendation-approval')) {
            Add-Failure "Scope item $id references decision with invalid authority: $reference ($decisionAuthority)"
          }
          if ($decisionAuthority -in @('required', 'constraint', 'acceptance', 'recommendation-approval')) { $hasProductAuthority = $true }
          if ($decisionAuthority -eq 'explicit-exclusion') { $hasExplicitExclusion = $true }
        }
      }
      'E' { if (-not $evidenceById.ContainsKey($reference)) { Add-Failure "Scope item $id references missing evidence: $reference" } }
      'R' { $hasProductAuthority = $true; $hasRecommendation = $true }
    }
  }
  switch ($relation) {
    'required' {
      if (-not $hasProductAuthority) { Add-Failure "Required scope lacks user or confirmed-decision authority: $id" }
    }
    'excluded' {
      if (-not ($hasExplicitExclusion -or ($hasRecommendation -and $prominent -eq $true))) {
        Add-Failure "Excluded scope lacks explicit user exclusion, confirmed decision, or prominent recommendation: $id"
      }
    }
    'recommended' {
      if (-not $hasRecommendation) { Add-Failure "Recommended scope has no R provenance: $id" }
      if ($prominent -ne $true) { Add-Failure "Unapproved recommendation is not prominent in the final scope: $id" }
    }
    'acceptance' {
      if (-not $hasProductAuthority) { Add-Failure "Acceptance scope lacks user or confirmed-decision authority: $id" }
    }
  }
  if ($hasRecommendation -and $relation -ne 'recommended' -and $prominent -ne $true) {
    Add-Failure "Recommendation provenance is hidden by another relation: $id"
  }
}

if ($scope.Count -eq 0) { Add-Failure 'READY scope is empty.' }

$writeBoundary = if ($null -ne $state) { Get-AllredProperty $state 'write_boundary' } else { $null }
if ($null -eq $writeBoundary) {
  Add-Failure 'READY write boundary is missing.'
} else {
  $projectRoot = [string](Get-AllredProperty $writeBoundary 'project_root')
  $projectRootStatus = ([string](Get-AllredProperty $writeBoundary 'project_root_status')).ToLowerInvariant()
  $projectRootProvenance = @((Get-AllredArray (Get-AllredProperty $writeBoundary 'project_root_provenance')) | ForEach-Object { [string]$_ })
  $projectRootRecommendationProminent = Get-AllredProperty $writeBoundary 'project_root_recommendation_prominent'
  $allowedWriteRoots = @((Get-AllredArray (Get-AllredProperty $writeBoundary 'allowed_write_roots')) | ForEach-Object { [string]$_ })
  $readOnlyInputs = @((Get-AllredArray (Get-AllredProperty $writeBoundary 'read_only_inputs')) | ForEach-Object { [string]$_ })
  $plannedPaths = @((Get-AllredArray (Get-AllredProperty $writeBoundary 'planned_paths')) | ForEach-Object { [string]$_ })
  $rollbackCheckpoint = [string](Get-AllredProperty $writeBoundary 'rollback_checkpoint')

  if (-not (Test-AllredAbsolutePath -Path $projectRoot)) { Add-Failure 'READY project_root must be an absolute path.' }
  if ($projectRootStatus -notin @('confirmed', 'recommended-pending')) { Add-Failure "Invalid project_root_status: $projectRootStatus" }
  if ($projectRootProvenance.Count -eq 0) { Add-Failure 'READY project_root has no provenance.' }
  if ((Get-AllredProperty $writeBoundary 'visible_in_ready') -ne $true) { Add-Failure 'READY write boundary is not marked visible in the approval envelope.' }
  if ($allowedWriteRoots.Count -eq 0) { Add-Failure 'READY allowed_write_roots is empty.' }
  if ($plannedPaths.Count -eq 0) { Add-Failure 'READY planned_paths is empty.' }
  if ([string]::IsNullOrWhiteSpace($rollbackCheckpoint)) { Add-Failure 'READY rollback checkpoint is missing.' }

  $rootHasConfirmedAuthority = $false
  $rootHasRecommendation = $false
  foreach ($reference in $projectRootProvenance) {
    if (-not (Test-AllredReferenceId -Value $reference -Prefixes 'UDR')) {
      Add-Failure "Project root has invalid provenance: $reference"
      continue
    }
    switch (Get-AllredReferencePrefix $reference) {
      'U' {
        if (-not $userSources.ContainsKey($reference)) {
          Add-Failure "Project root references missing user source: $reference"
        } elseif (([string](Get-AllredProperty $userSources[$reference] 'authority')).ToLowerInvariant() -in @('requirement', 'constraint', 'delegation')) {
          $rootHasConfirmedAuthority = $true
        }
      }
      'D' {
        if (-not $decisionById.ContainsKey($reference) -or ([string](Get-AllredProperty $decisionById[$reference] 'status')).ToLowerInvariant() -ne 'confirmed') {
          Add-Failure "Project root references unconfirmed decision: $reference"
        } else {
          $rootHasConfirmedAuthority = $true
        }
      }
      'R' { $rootHasRecommendation = $true }
    }
  }
  if ($projectRootStatus -eq 'confirmed' -and -not $rootHasConfirmedAuthority) {
    Add-Failure 'Confirmed project_root lacks user or confirmed-decision authority.'
  }
  if ($projectRootStatus -eq 'recommended-pending' -and (-not $rootHasRecommendation -or $projectRootRecommendationProminent -ne $true)) {
    Add-Failure 'Pending project_root recommendation is not prominent or lacks R provenance.'
  }

  foreach ($allowedRoot in $allowedWriteRoots) {
    if (-not (Test-AllredAbsolutePath -Path $allowedRoot)) { Add-Failure "Allowed write root is not absolute: $allowedRoot"; continue }
    if (-not (Test-AllredPathWithin -Root $projectRoot -Candidate $allowedRoot)) { Add-Failure "Allowed write root is outside project_root: $allowedRoot" }
  }
  foreach ($inputPath in $readOnlyInputs) {
    if (-not (Test-AllredAbsolutePath -Path $inputPath)) { Add-Failure "Read-only input is not absolute: $inputPath" }
  }
  foreach ($plannedPath in $plannedPaths) {
    if (-not (Test-AllredAbsolutePath -Path $plannedPath)) { Add-Failure "Planned path is not absolute: $plannedPath"; continue }
    if ($plannedPath -match '[*?\[]') { Add-Failure "Planned path contains a wildcard: $plannedPath" }
    if (-not (@($allowedWriteRoots | Where-Object { Test-AllredPathWithin -Root $_ -Candidate $plannedPath }).Count -gt 0)) {
      Add-Failure "Planned path is outside allowed_write_roots: $plannedPath"
    }
    foreach ($inputPath in $readOnlyInputs) {
      if ((Test-AllredPathWithin -Root $inputPath -Candidate $plannedPath) -or (Test-AllredPathWithin -Root $plannedPath -Candidate $inputPath)) {
        Add-Failure "Planned path overlaps protected read-only input: $plannedPath <-> $inputPath"
      }
    }
  }

  $intake = if ($null -ne $state) { Get-AllredProperty $state 'intake' } else { $null }
  $materials = if ($null -ne $intake) { Get-AllredProperty $intake 'materials' } else { $null }
  if ($null -ne $materials -and ([string](Get-AllredProperty $materials 'status')).ToLowerInvariant() -eq 'inspected' -and $readOnlyInputs.Count -eq 0) {
    Add-Failure 'Inspected materials are not listed as protected read-only inputs.'
  }
}

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
