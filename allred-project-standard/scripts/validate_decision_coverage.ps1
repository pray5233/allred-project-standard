param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
  Write-Error "Execution record not found: $Path"
  exit 1
}

$text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) {
  $script:failures.Add($Message) | Out-Null
}

function Get-Section([string]$Heading) {
  $pattern = '(?ms)^' + [regex]::Escape($Heading) + '\s*\r?\n(.*?)(?=^## |\z)'
  $match = [regex]::Match($script:text, $pattern)
  if (-not $match.Success) {
    Add-Failure "Missing section: $Heading"
    return ''
  }
  return $match.Groups[1].Value
}

function Get-TableRows([string]$Section, [int]$ExpectedColumns) {
  $rows = [System.Collections.Generic.List[object]]::new()
  foreach ($line in ($Section -split "`r?`n")) {
    if ($line -notmatch '^\s*\|') { continue }
    $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    if ($cells.Count -ne $ExpectedColumns) { continue }
    if ($cells[0] -match '^(Scope ID|Promise ID)$') { continue }
    if (($cells -join '') -match '^-+$') { continue }
    if ($cells[0] -match '^-+$') { continue }
    $rows.Add($cells) | Out-Null
  }
  return $rows
}

$activeMatch = [regex]::Match($text, '(?m)^- Active scope decision IDs:\s*(.+?)\s*$')
if (-not $activeMatch.Success) {
  Add-Failure 'Missing Active scope decision IDs.'
  $activeIds = @()
} else {
  $activeIds = @($activeMatch.Groups[1].Value -split '[,;，；\s]+' | Where-Object { $_ })
}

foreach ($id in $activeIds) {
  if ($id -notmatch '^[UD][0-9A-Za-z._-]+$') { Add-Failure "Invalid active scope ID: $id" }
}
foreach ($group in ($activeIds | Group-Object | Where-Object Count -gt 1)) {
  Add-Failure "Duplicate active scope ID: $($group.Name)"
}

$approvedRows = @(Get-TableRows (Get-Section '## Approved Scope Ledger') 4)
$coverageRows = @(Get-TableRows (Get-Section '## Decision Coverage Ledger') 5)
$acceptanceRows = @(Get-TableRows (Get-Section '## Acceptance Ledger') 5)
$resultRows = @(Get-TableRows (Get-Section '## Execution Results') 5)

$approvedIds = @($approvedRows | ForEach-Object { $_[0] })
$coverageIds = @($coverageRows | ForEach-Object { $_[0] })
$promiseIds = @($acceptanceRows | ForEach-Object { $_[0] })
$acceptanceStatusByPromise = @{}
$approvedById = @{}
$approvedLifecycleById = @{}
foreach ($row in $approvedRows) {
  if ($approvedById.ContainsKey($row[0])) { Add-Failure "Duplicate Approved Scope Ledger row: $($row[0])" }
  $approvedById[$row[0]] = $row[1]
  $approvedLifecycleById[$row[0]] = $row[3].ToLowerInvariant()
  if ($row[0] -notmatch '^[UD][0-9A-Za-z._-]+$') { Add-Failure "Invalid Approved Scope ID: $($row[0])" }
  if ([string]::IsNullOrWhiteSpace($row[1]) -or $row[1] -match '^(replace|TBD|TODO)$') { Add-Failure "Approved statement is unresolved: $($row[0])" }
  if ([string]::IsNullOrWhiteSpace($row[2]) -or $row[2] -match '^(replace|TBD|TODO|None)$') { Add-Failure "Approved scope has no source/envelope: $($row[0])" }
  if ($approvedLifecycleById[$row[0]] -notin @('active', 'deferred', 'superseded')) { Add-Failure "Invalid approved lifecycle for $($row[0]): $($row[3])" }
}
$resultByPromise = @{}
foreach ($row in $resultRows) {
  if ($resultByPromise.ContainsKey($row[0])) { Add-Failure "Duplicate Execution Results row: $($row[0])" }
  $resultByPromise[$row[0]] = $row[3].ToLowerInvariant()
}
foreach ($row in $acceptanceRows) {
  $acceptanceStatusByPromise[$row[0]] = $row[4].ToLowerInvariant()
  if ($acceptanceStatusByPromise[$row[0]] -notin @('planned', 'verified', 'unverified', 'failed')) { Add-Failure "Invalid Acceptance Ledger status for $($row[0]): $($row[4])" }
}

foreach ($group in ($coverageIds | Group-Object | Where-Object Count -gt 1)) {
  Add-Failure "Duplicate decision coverage row: $($group.Name)"
}
foreach ($id in $coverageIds) {
  if ($id -notmatch '^[UD][0-9A-Za-z._-]+$') { Add-Failure "Invalid decision coverage ID: $id" }
}
foreach ($group in ($promiseIds | Group-Object | Where-Object Count -gt 1)) {
  Add-Failure "Duplicate Acceptance Ledger Promise ID: $($group.Name)"
}
foreach ($id in $promiseIds) {
  if ($id -notmatch '^P[0-9A-Za-z._-]+$') { Add-Failure "Invalid Acceptance Ledger Promise ID: $id" }
}
foreach ($id in $activeIds) {
  if ($id -notin $coverageIds) { Add-Failure "Active scope decision has no coverage row: $id" }
}
foreach ($id in $approvedIds) {
  if ($id -notin $coverageIds) { Add-Failure "Approved scope decision has no coverage row: $id" }
}
foreach ($id in $coverageIds) {
  if ($id -notin $approvedIds) { Add-Failure "Coverage row is not listed in Approved Scope Ledger: $id" }
}

$expectedActiveIds = @($approvedRows | Where-Object { $_[3].ToLowerInvariant() -eq 'active' } | ForEach-Object { $_[0] })
foreach ($id in $expectedActiveIds) {
  if ($id -notin $activeIds) { Add-Failure "Active Approved Scope row is missing from Active scope decision IDs: $id" }
}
foreach ($id in $activeIds) {
  if ($id -notin $expectedActiveIds) { Add-Failure "Active scope decision ID is not active in Approved Scope Ledger: $id" }
}

$allowedStatuses = @('planned', 'implemented', 'verified', 'deferred', 'superseded')
foreach ($row in $coverageRows) {
  $id = $row[0]
  $statement = $row[1]
  $target = $row[2]
  $promises = @($row[3] -split '[,;，；\s]+' | Where-Object { $_ -and $_ -ne 'None' })
  $status = $row[4].ToLowerInvariant()

  if ([string]::IsNullOrWhiteSpace($statement) -or $statement -match '^(replace|TBD|TODO)$') { Add-Failure "Decision statement is unresolved: $id" }
  if ($approvedById.ContainsKey($id) -and $statement -ne $approvedById[$id]) { Add-Failure "Decision coverage statement differs from Approved Scope Ledger: $id" }
  if ($status -notin $allowedStatuses) { Add-Failure "Invalid decision coverage status for ${id}: $status"; continue }

  if ($approvedLifecycleById.ContainsKey($id)) {
    $lifecycle = $approvedLifecycleById[$id]
    if ($lifecycle -eq 'active' -and $status -in @('deferred', 'superseded')) { Add-Failure "Active approved decision has inactive coverage status: $id ($status)" }
    if ($lifecycle -eq 'deferred' -and $status -ne 'deferred') { Add-Failure "Deferred approved decision has mismatched coverage status: $id ($status)" }
    if ($lifecycle -eq 'superseded' -and $status -ne 'superseded') { Add-Failure "Superseded approved decision has mismatched coverage status: $id ($status)" }
  }

  if ($status -in @('planned', 'implemented', 'verified')) {
    if ([string]::IsNullOrWhiteSpace($target) -or $target -eq 'None' -or $target -match '^(replace|TBD|TODO)$') { Add-Failure "Active decision has no implementation target: $id" }
    if ($promises.Count -eq 0) { Add-Failure "Active decision has no Promise ID: $id" }
  }

  foreach ($promise in $promises) {
    if ($promise -notmatch '^P[0-9A-Za-z._-]+$') { Add-Failure "Invalid Promise ID '$promise' in decision $id"; continue }
    if ($promise -notin $promiseIds) { Add-Failure "Decision $id references missing Acceptance Ledger row: $promise" }
    if ($status -eq 'verified') {
      if (-not $acceptanceStatusByPromise.ContainsKey($promise) -or $acceptanceStatusByPromise[$promise] -ne 'verified') { Add-Failure "Verified decision $id has non-verified Acceptance Ledger state for $promise" }
      if (-not $resultByPromise.ContainsKey($promise)) { Add-Failure "Verified decision $id has no Execution Results row for $promise" }
      elseif ($resultByPromise[$promise] -notin @('passed', 'verified')) { Add-Failure "Verified decision $id has non-passing result for ${promise}: $($resultByPromise[$promise])" }
      else {
        $resultRow = $resultRows | Where-Object { $_[0] -eq $promise } | Select-Object -First 1
        if ($resultRow[1] -match '^(not run|None|replace|TBD|TODO)$') { Add-Failure "Verified Promise has no fresh evidence description: $promise" }
        if ($resultRow[2] -match '^(None|replace|TBD|TODO)$') { Add-Failure "Verified Promise has no validation environment: $promise" }
      }
    }
  }
}

$promiseUse = @{}
foreach ($row in $coverageRows) {
  if ($row[4].ToLowerInvariant() -notin @('planned', 'implemented', 'verified')) { continue }
  foreach ($promise in @($row[3] -split '[,;，；\s]+' | Where-Object { $_ -and $_ -ne 'None' })) {
    if (-not $promiseUse.ContainsKey($promise)) { $promiseUse[$promise] = 0 }
    $promiseUse[$promise]++
  }
}
foreach ($row in $coverageRows) {
  if ($row[4].ToLowerInvariant() -notin @('planned', 'implemented', 'verified')) { continue }
  $rowPromises = @($row[3] -split '[,;，；\s]+' | Where-Object { $_ -and $_ -ne 'None' })
  if (@($rowPromises | Where-Object { $promiseUse[$_] -eq 1 }).Count -eq 0) {
    Add-Failure "Active decision has no decision-specific Promise ID: $($row[0])"
  }
}

$statusMatch = [regex]::Match($text, '(?m)^- Record status:\s*(ready|active|closed|superseded)\s*$')
if ($statusMatch.Success -and $statusMatch.Groups[1].Value -eq 'closed') {
  foreach ($row in $coverageRows) {
    if ($row[4].ToLowerInvariant() -notin @('verified', 'deferred', 'superseded')) {
      Add-Failure "Closed record has unresolved active decision: $($row[0]) ($($row[4]))"
    }
  }
}

if ($failures.Count -gt 0) {
  'Decision coverage validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Decision coverage validation: PASS'
"Approved scope decisions: $($approvedIds.Count)"
"Active scope decisions: $($activeIds.Count)"
"Coverage rows: $($coverageRows.Count)"
