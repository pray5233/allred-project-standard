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
$text = $text -replace "`r`n?", "`n"
$failures = [System.Collections.Generic.List[string]]::new()

function Require([string]$Pattern, [string]$Message) {
  if ($text -notmatch $Pattern) { $script:failures.Add($Message) | Out-Null }
}

foreach ($heading in @(
  '## Objective And Boundary',
  '## Evidence Ledger',
  '## Approved Scope Ledger',
  '## Change Control Ledger',
  '## Implementation Basis',
  '## Exact Files',
  '## Exact Commands',
  '## Mutation Ledger',
  '## Significant Effects Reconciliation',
  '## Decision Coverage Ledger',
  '## Acceptance Ledger',
  '## Rollback And Checkpoint',
  '## Execution Results'
)) {
  Require ([regex]::Escape($heading)) "Missing section: $heading"
}

Require '(?m)^- Record ID: ER-[A-Za-z0-9._-]+$' 'Record ID must use ER- followed by a stable identifier.'
Require '(?m)^- Schema version: 1$' 'Schema version must be 1.'
Require '(?m)^- Record status: (ready|active|closed|superseded)$' 'Record status must be ready, active, closed, or superseded.'
Require '(?m)^- Approved scope reference: .{3,}$' 'Approved scope reference is missing.'
Require '(?m)^- Active scope decision IDs: [UD][0-9A-Za-z._-]+' 'Active scope decision IDs are missing.'
Require '(?m)^- Change mode: (new-baseline|delta)$' 'Change mode must be new-baseline or delta.'
Require '(?m)^- Baseline ID: BASE-[0-9A-Za-z._-]+$' 'Baseline ID is missing or invalid.'
Require '(?m)^- Baseline status: (candidate|confirmed)$' 'Baseline status must be candidate or confirmed.'
Require '(?m)^- Change ID: (CHG-[0-9A-Za-z._-]+|None)$' 'Change ID is missing or invalid.'
Require '(?m)^- Change status: (proposed|approved|implemented|verified|merged|superseded|Not applicable)$' 'Change status is missing or invalid.'
Require '(?m)^\| CI[0-9A-Za-z._-]+ \| (establish|add|modify|remove|preserve) \|.+\| (pending|approved|implemented|verified|merged) \|$' 'Change control ledger needs at least one traceable item.'
Require '(?m)^- Hidden recommendation R: None$' 'Unapproved recommendations must not be hidden in the execution record.'
Require '(?m)^- Hidden user-visible behavior: None$' 'User-visible behavior must be surfaced in the approved scope.'
Require '(?m)^- Hidden consequential effect: None$' 'Consequential effects must be surfaced through user authorization.'
Require '(?m)^\| Development-time \|.+\|$' 'Development-time mutation ledger row is missing.'
Require '(?m)^\| Runtime \|.+\|$' 'Runtime mutation ledger row is missing.'
Require '(?m)^\| External/system \|.+\|$' 'External/system mutation ledger row is missing.'
Require '(?m)^\| P[0-9A-Za-z._-]+ \|.+\| (planned|verified|unverified|failed) \|$' 'Acceptance ledger needs at least one promised item and state.'

foreach ($placeholder in @('ER-YYYYMMDD-NNN', 'replace with', '| replace |', 'replace or', 'TBD', 'TODO', '待填写')) {
  if ($text.Contains($placeholder)) { $failures.Add("Unresolved placeholder: $placeholder") | Out-Null }
}

if ($failures.Count -gt 0) {
  'Codex execution record validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Codex execution record validation: PASS'
"Path: $((Resolve-Path -LiteralPath $Path).Path)"
