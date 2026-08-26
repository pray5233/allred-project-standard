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

$decisionCoverageValidator = Join-Path $PSScriptRoot 'validate_decision_coverage.ps1'
if (Test-Path -LiteralPath $decisionCoverageValidator) {
  $coverageOutput = & $decisionCoverageValidator -Path $Path
  if (-not $?) {
    $failures.Add('Decision coverage validation failed.') | Out-Null
    foreach ($line in @($coverageOutput)) { $failures.Add("Decision coverage: $line") | Out-Null }
  }
} else {
  $failures.Add('Decision coverage validator is missing.') | Out-Null
}

if ($failures.Count -gt 0) {
  'Codex execution record validation: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Codex execution record validation: PASS'
"Path: $((Resolve-Path -LiteralPath $Path).Path)"
