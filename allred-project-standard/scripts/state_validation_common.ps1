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

  $completionFailures = @(Get-AllredConfirmedDecisionFacetFailures -State $state)
  if ($completionFailures.Count) { throw ($completionFailures -join "`n") }
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
  return $Path -match '^[A-Za-z]:[\\/]' -or $Path.StartsWith('/') -or $Path.StartsWith('\\')
}

function ConvertTo-AllredComparablePath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  if (-not (Test-AllredAbsolutePath -Path $Path)) { throw "Path must be absolute: $Path" }
  $value = [System.IO.Path]::GetFullPath($Path).Replace('\', '/')
  if ($value.Length -gt 1) { $value = $value.TrimEnd('/') }
  if ($value -match '^[A-Za-z]:') { $value = $value.Substring(0, 1).ToLowerInvariant() + $value.Substring(1) }
  return $value
}

function Test-AllredPathWithin {
  param(
    [string]$Root,
    [string]$Candidate
  )

  if (-not (Test-AllredAbsolutePath -Path $Root) -or -not (Test-AllredAbsolutePath -Path $Candidate)) { return $false }
  try {
    $rootValue = ConvertTo-AllredComparablePath -Path $Root
    $candidateValue = ConvertTo-AllredComparablePath -Path $Candidate
  } catch { return $false }
  if ($candidateValue.Equals($rootValue, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
  return $candidateValue.StartsWith($rootValue.TrimEnd('/') + '/', [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-AllredDecisionStatuses {
  @('open', 'waiting', 'investigating', 'proposed', 'confirmed', 'deferred', 'rejected', 'conflict', 'superseded', 'not-applicable')
}

function Get-AllredBlockerSources {
  param([object]$Blocker)
  # Preserve explicit links in older authored states when normalizing field names.
  foreach ($field in @('source_ids', 'basis', 'source')) {
    Get-AllredArray (Get-AllredProperty $Blocker $field)
  }
}

function Get-AllredDecisionEvolutionFailures {
  param([object]$PreviousState, [object]$State)

  $problems = [System.Collections.Generic.List[string]]::new()
  $current = @{}
  foreach ($d in @(Get-AllredArray (Get-AllredProperty $State 'decisions'))) {
    $id = [string](Get-AllredProperty $d 'id')
    if ($current.ContainsKey($id)) { $problems.Add("Duplicate current decision ID: $id") }
    $current[$id] = $d
  }
  $users = Get-AllredUserSourceMap $State
  $evidenceIds = @((Get-AllredArray (Get-AllredProperty $State 'evidence')) | ForEach-Object { [string](Get-AllredProperty $_ 'id') })
  $retired = @('deferred', 'rejected', 'superseded', 'not-applicable')
  $unresolved = @('open', 'waiting', 'investigating', 'proposed', 'conflict')
  foreach ($old in @(Get-AllredArray (Get-AllredProperty $PreviousState 'decisions'))) {
    $id = [string](Get-AllredProperty $old 'id')
    if (-not $current.ContainsKey($id)) { $problems.Add("Decision disappeared from current state: $id. Retain its lifecycle record."); continue }
    $new = $current[$id]
    $axis = [string](Get-AllredProperty $old 'axis')
    if ($axis -and $axis -cne [string](Get-AllredProperty $new 'axis')) {
      $problems.Add("Decision axis is immutable for ${id}. Use label for wording or a new decision ID for a different question; preserve the old decision.")
    }
    $status = [string](Get-AllredProperty $new 'status')
    $oldStatus = [string](Get-AllredProperty $old 'status')
    if ($status -in $retired -and ($status -ne $oldStatus -or
        (Get-AllredProperty $new 'resolution_source') -ne (Get-AllredProperty $old 'resolution_source') -or
        (Get-AllredProperty $new 'reason') -ne (Get-AllredProperty $old 'reason') -or
        ((Get-AllredProperty $new 'superseded_by') | ConvertTo-Json -Compress) -cne ((Get-AllredProperty $old 'superseded_by') | ConvertTo-Json -Compress))) {
      $source = [string](Get-AllredProperty $new 'resolution_source')
      $reason = [string](Get-AllredProperty $new 'reason')
      $sourceValid = $source -cmatch '^U[0-9A-Za-z._-]+$' -and $users.ContainsKey($source)
      if ($status -eq 'not-applicable') {
        $sourceValid = $sourceValid -or ($source -cmatch '^E[0-9A-Za-z._-]+$' -and $source -cin $evidenceIds) -or
          ($source -cmatch '^D[0-9A-Za-z._-]+$' -and $source -ne $id -and $current.ContainsKey($source) -and (Get-AllredProperty $current[$source] 'status') -eq 'confirmed')
      }
      if (-not $sourceValid -or [string]::IsNullOrWhiteSpace($reason)) {
        $problems.Add("Decision retirement needs a valid resolution_source and reason: $id ($status). Deferral, rejection and replacement require a user source; non-applicability may use evidence or a confirmed parent.")
      }
      if ($status -eq 'superseded') {
        $replacements = @(Get-AllredArray (Get-AllredProperty $new 'superseded_by'))
        if (-not $replacements.Count -or @($replacements | Select-Object -Unique).Count -ne $replacements.Count) { $problems.Add("Superseded decision needs unique replacement IDs: $id") }
        foreach ($replacement in $replacements) {
          if ($replacement -eq $id -or -not $current.ContainsKey([string]$replacement) -or
              (Get-AllredProperty $current[[string]$replacement] 'status') -notin ($unresolved + @('confirmed'))) {
            $problems.Add("Superseded decision has no active replacement: $id -> $replacement")
          }
        }
      }
    }
  }

  # A blocker cannot be reassigned to another topic while its original decision is still open.
  $blockers = @{}
  foreach ($b in @(Get-AllredArray (Get-AllredProperty $State 'blocking_items'))) { $blockers[[string](Get-AllredProperty $b 'id')] = $b }
  foreach ($old in @(Get-AllredArray (Get-AllredProperty $PreviousState 'blocking_items'))) {
    $oldKind = [string](Get-AllredProperty $old 'kind')
    if (($oldKind -and $oldKind -ne 'decision') -or (Get-AllredProperty $old 'status') -notin $unresolved) { continue }
    $id = [string](Get-AllredProperty $old 'id')
    foreach ($source in @(Get-AllredBlockerSources $old | Select-Object -Unique)) {
      if ([string]$source -notmatch '^D' -or -not $current.ContainsKey([string]$source) -or (Get-AllredProperty $current[[string]$source] 'status') -notin $unresolved) { continue }
      $new = $blockers[$id]
      $newKind = [string](Get-AllredProperty $new 'kind')
      if ($null -eq $new -or $newKind -notin @('', 'decision') -or ($oldKind -eq 'decision' -and $newKind -ne 'decision') -or
          (Get-AllredProperty $new 'status') -notin $unresolved -or
          $source -notin @(Get-AllredBlockerSources $new)) {
        $problems.Add("Unresolved decision blocker lost its original link: $id -> $source. Keep it pending until that decision is resolved.")
      }
    }
  }
  return @($problems)
}

function Get-AllredConfirmedDecisionFacetFailures {
  param([object]$State)

  foreach ($decision in @(Get-AllredArray (Get-AllredProperty $State 'decisions'))) {
    if ((Get-AllredProperty $decision 'status') -eq 'confirmed' -and
        @(Get-AllredArray (Get-AllredProperty $decision 'remaining_facets')).Count) {
      $id = [string](Get-AllredProperty $decision 'id')
      "Confirmed decision retains unanswered facets: $id. Keep partial answers open; for a complete existing answer, resolve the recorded facets with their sources in the same patch. Do not ask the user again just to repair bookkeeping."
    }
  }
}

function Get-AllredRemovedFacetFailures {
  param([object]$PreviousItem, [object]$Item, [object]$State)

  $id = [string](Get-AllredProperty $Item 'id')
  $remaining = @(Get-AllredArray (Get-AllredProperty $Item 'remaining_facets'))
  $resolutions = @(Get-AllredArray (Get-AllredProperty $Item 'facet_resolutions'))
  $users = Get-AllredUserSourceMap $State
  $evidenceIds = @((Get-AllredArray (Get-AllredProperty $State 'evidence')) | ForEach-Object { Get-AllredProperty $_ 'id' })
  $targets = @{}
  foreach ($ledger in @('questions','decisions')) {
    foreach ($row in @(Get-AllredArray (Get-AllredProperty $State $ledger))) { $targets[[string](Get-AllredProperty $row 'id')] = $row }
  }
  foreach ($facet in @(Get-AllredArray (Get-AllredProperty $PreviousItem 'remaining_facets'))) {
    if ($remaining -ccontains $facet) { continue }
    $matches = @($resolutions | Where-Object { (Get-AllredProperty $_ 'facet') -ceq $facet })
    if ($matches.Count -ne 1) {
      "Removed pending facet needs one facet_resolutions entry: $id / $facet. Keep it pending, cite its answer, or transfer it explicitly."
      continue
    }
    $resolution = $matches[0]
    $status = [string](Get-AllredProperty $resolution 'status')
    if ($status -eq 'transferred') {
      $targetId = [string](Get-AllredProperty $resolution 'target')
      $target = $targets[$targetId]
      if ($targetId -eq $id -or $null -eq $target -or
          (Get-AllredProperty $target 'status') -notin @('open','waiting','investigating','proposed','conflict') -or
          @(Get-AllredArray (Get-AllredProperty $target 'remaining_facets')) -cnotcontains $facet) {
        "Transferred facet needs another pending Q/D retaining that facet: $id / $facet -> $targetId"
      }
      continue
    }
    $source = [string](Get-AllredProperty $resolution 'source')
    $reason = [string](Get-AllredProperty $resolution 'reason')
    if ($status -notin @('answered','unknown','not-applicable')) {
      "Invalid removed-facet disposition: $id / $facet ($status)"
      continue
    }
    if ($users.ContainsKey($source)) {
      $quote = [string](Get-AllredProperty $resolution 'quote')
      $literal = [string](Get-AllredProperty $users[$source] 'quote')
      if ([string]::IsNullOrWhiteSpace($quote) -or $literal.IndexOf($quote,[StringComparison]::Ordinal) -lt 0) {
        "Removed-facet user source needs its exact quote: $id / $facet ($source)"
      }
    } elseif (($source -cin $evidenceIds) -or
        ($status -eq 'not-applicable' -and $source -cne $id -and $source -cmatch '^D' -and $targets.ContainsKey($source) -and (Get-AllredProperty $targets[$source] 'status') -eq 'confirmed')) {
      if ([string]::IsNullOrWhiteSpace($reason)) { "Removed-facet evidence/parent source needs a reason: $id / $facet ($source)" }
    } else { "Removed-facet source is missing or ineligible: $id / $facet ($source)" }
  }
}

function Get-AllredStateEvolutionFailures {
  param([object]$PreviousState, [object]$State, [bool]$CheckFacetAccounting = $true)

  Get-AllredDecisionEvolutionFailures -PreviousState $PreviousState -State $State
  $questions = @{}
  foreach ($q in @(Get-AllredArray (Get-AllredProperty $State 'questions'))) {
    $id = [string](Get-AllredProperty $q 'id')
    if ($questions.ContainsKey($id)) { "Duplicate current question ID: $id" }
    $questions[$id] = $q
    if ((Get-AllredProperty $q 'status') -in @('confirmed', 'unknown', 'not-applicable') -and
        @(Get-AllredArray (Get-AllredProperty $q 'remaining_facets')).Count) {
      "Terminal factual question retains unanswered facets: $id. Keep it open or retain those facets as separate pending questions."
    }
  }
  foreach ($old in @(Get-AllredArray (Get-AllredProperty $PreviousState 'questions'))) {
    $id = [string](Get-AllredProperty $old 'id')
    if (-not $questions.ContainsKey($id)) { "Factual question disappeared from current state: $id. Retain its lifecycle record."; continue }
    $axis = [string](Get-AllredProperty $old 'axis')
    if ($axis -and $axis -cne [string](Get-AllredProperty $questions[$id] 'axis')) {
      "Factual question axis is immutable for ${id}. Use label for wording or a new ID for a different fact."
    }
    if ($CheckFacetAccounting) { Get-AllredRemovedFacetFailures -PreviousItem $old -Item $questions[$id] -State $State }
  }
  if ($CheckFacetAccounting) {
    $decisions = @{}
    foreach ($d in @(Get-AllredArray (Get-AllredProperty $State 'decisions'))) { $decisions[[string](Get-AllredProperty $d 'id')] = $d }
    foreach ($old in @(Get-AllredArray (Get-AllredProperty $PreviousState 'decisions'))) {
      $id = [string](Get-AllredProperty $old 'id')
      if ($decisions.ContainsKey($id)) { Get-AllredRemovedFacetFailures -PreviousItem $old -Item $decisions[$id] -State $State }
    }
  }
}

function Get-AllredStateParentFailures {
  param([object]$State, [string]$StatePath)

  $authoring = Get-AllredProperty $State 'authoring'
  $path = [string](Get-AllredProperty $authoring 'parent_path')
  $hash = [string](Get-AllredProperty $authoring 'parent_sha256')
  if (-not $path -and -not $hash) { return }
  try {
    if (-not (Test-AllredAbsolutePath $path) -or -not $hash) { throw 'Parent path and SHA256 must both be present.' }
    if ((ConvertTo-AllredComparablePath $path) -eq (ConvertTo-AllredComparablePath ([IO.Path]::GetFullPath($StatePath)))) { throw 'State cannot be its own parent.' }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hash) { throw 'Parent state hash does not match.' }
    # A parent may be an incomplete intake draft; compare identity without demanding READY fields.
    $parent = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ((Get-AllredProperty $parent 'schema_version') -ne 1 -or
        (Get-AllredProperty $parent 'state_id') -cne (Get-AllredProperty $State 'state_id') -or
        (Get-AllredProperty $parent 'route') -cne (Get-AllredProperty $State 'route')) { throw 'Parent belongs to a different project or schema.' }
    $facetVersion = Get-AllredProperty $authoring 'facet_accounting_version'
    if ($null -ne $facetVersion -and $facetVersion -ne 1) { throw 'Unsupported facet accounting version.' }
    # Old snapshots predate the receipt field; every new updater transition checks removals.
    Get-AllredStateEvolutionFailures -PreviousState $parent -State $State -CheckFacetAccounting ($facetVersion -eq 1)
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hash) { throw 'Parent state changed during validation.' }
  } catch { "State continuity could not be verified: $($_.Exception.Message)" }
}

function Test-AllredNoLinkTraversal {
  param([string]$Path)

  # A lexical path is not a write boundary when an existing ancestor redirects it.
  try {
    $current = [System.IO.Path]::GetFullPath($Path)
    while (-not [string]::IsNullOrEmpty($current)) {
      if (Test-Path -LiteralPath $current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
      }
      $parent = [System.IO.Path]::GetDirectoryName($current)
      if ($parent -eq $current) { break }
      $current = $parent
    }
    return $true
  } catch { return $false }
}
