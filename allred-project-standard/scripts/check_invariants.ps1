param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) {
  $script:failures.Add($Message) | Out-Null
}

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { Add-Failure "Missing JSON file: $Path"; return $null }
  try { return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch { Add-Failure "Invalid JSON in ${Path}: $($_.Exception.Message)"; return $null }
}

$manifestPath = Join-Path $SkillRoot 'tests\invariants.json'
$casesPath = Join-Path $SkillRoot 'tests\behavior-cases.test.json'
$manifest = Read-Json $manifestPath
$suite = Read-Json $casesPath

if ($manifest -and $suite) {
  if ($manifest.schema_version -ne 1) { Add-Failure 'Unsupported invariant schema version.' }
  if ($manifest.skill -ne 'allred-project-standard') { Add-Failure "Unexpected invariant skill: $($manifest.skill)" }

  $invariants = @($manifest.invariants)
  $caseIds = @($suite.cases.id)
  $duplicateIds = $invariants | Group-Object id | Where-Object Count -gt 1
  foreach ($group in $duplicateIds) { Add-Failure "Duplicate invariant id: $($group.Name)" }

  foreach ($invariant in $invariants) {
    if ([string]::IsNullOrWhiteSpace($invariant.id)) { Add-Failure 'Invariant without id.'; continue }
    if ($invariant.priority -notin @('P0', 'P1')) { Add-Failure "Invalid priority for $($invariant.id)" }
    if ([string]::IsNullOrWhiteSpace($invariant.owner)) { Add-Failure "Missing owner for $($invariant.id)"; continue }
    $ownerPath = Join-Path $SkillRoot ([string]$invariant.owner).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $ownerPath)) {
      Add-Failure "Owner file missing for $($invariant.id): $($invariant.owner)"
    } elseif (-not [string]::IsNullOrWhiteSpace($invariant.owner_section)) {
      $ownerText = Get-Content -LiteralPath $ownerPath -Raw -Encoding UTF8
      $heading = "## $($invariant.owner_section)"
      if (-not $ownerText.Contains($heading)) { Add-Failure "Owner section missing for $($invariant.id): $heading" }
    }

    if (@($invariant.behavior_cases).Count -eq 0) { Add-Failure "No behavior coverage for $($invariant.id)" }
    foreach ($caseId in @($invariant.behavior_cases)) {
      if ($caseId -notin $caseIds) { Add-Failure "Unknown behavior case $caseId for $($invariant.id)" }
      elseif ($invariant.priority -eq 'P0') {
        $case = $suite.cases | Where-Object id -eq $caseId | Select-Object -First 1
        if ($case.priority -ne 'P0') { Add-Failure "P0 invariant $($invariant.id) uses non-P0 case $caseId" }
      }
    }
    foreach ($relative in @($invariant.enforcement)) {
      $enforcementPath = Join-Path $SkillRoot ([string]$relative).Replace('/', '\')
      if (-not (Test-Path -LiteralPath $enforcementPath)) { Add-Failure "Enforcement file missing for $($invariant.id): $relative" }
    }
  }

  $overlayNames = @($manifest.conditional_overlays.name)
  if (@($overlayNames | Select-Object -Unique).Count -ne $overlayNames.Count) { Add-Failure 'Duplicate conditional overlay name.' }
  foreach ($overlay in @($manifest.conditional_overlays)) {
    if ($overlay.activation_invariant -notin @($invariants.id)) { Add-Failure "Overlay invariant missing: $($overlay.name)" }
    $matching = @($invariants | Where-Object id -eq $overlay.activation_invariant)
    if ($matching.Count -eq 1 -and $matching[0].owner -ne $overlay.owner) { Add-Failure "Overlay owner mismatch: $($overlay.name)" }
  }

  foreach ($scenario in @('software', 'training', 'external-data', 'shared-collaboration', 'debugging', 'long-term')) {
    $property = $manifest.release_matrix.PSObject.Properties[$scenario]
    if ($null -eq $property -or @($property.Value).Count -eq 0) { Add-Failure "Release matrix scenario missing: $scenario"; continue }
    foreach ($caseId in @($property.Value)) {
      if ($caseId -notin $caseIds) { Add-Failure "Release matrix case missing: $scenario/$caseId" }
    }
  }
}

if ($failures.Count -gt 0) {
  'Invariant check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Invariant check: PASS'
"Invariants: $(@($manifest.invariants).Count)"
"Conditional overlays: $(@($manifest.conditional_overlays).Count)"
"Release scenarios: $(@($manifest.release_matrix.PSObject.Properties).Count)"
