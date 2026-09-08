param(
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][string]$LegacyCaseId,
  [Parameter(Mandatory=$true)][string]$ReasoningEffort,
  [string]$Model = '',
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$StandardRoot = (Join-Path (Split-Path -Parent $LabRoot) 'allred-project-standard')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
try {
  $map = Get-Content -Raw -Encoding UTF8 (Join-Path $LabRoot 'tests/runtime-evidence-migrations.json') | ConvertFrom-Json
  $matches = @($map.migrations | Where-Object legacy_case_id -eq $LegacyCaseId)
  if ($matches.Count -ne 1) { throw 'Migration must have one explicit owner.' }
  $migration = $matches[0]
  $manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $EvidenceRoot 'manifest.json') | ConvertFrom-Json
  if ($manifest.evidence_kind -notlike 'actual-local-files-and-tools;*') { throw 'Simulated evidence cannot replace actual runtime acceptance.' }
  if ($manifest.effort -ne $ReasoningEffort -or ($Model -and $manifest.model -ne $Model)) { throw 'Model/effort does not match the required run.' }
  if ($manifest.suite_sha256 -ne (Get-FileHash -LiteralPath (Join-Path $LabRoot 'tests/runtime-dialogues.json')).Hash) { throw 'Runtime suite hash is stale.' }
  if ($manifest.reviewer_format -notin @('Ordered','Legacy')) { throw 'Runtime review format is missing or unknown.' }
  foreach ($relative in @('tests/runtime-review.schema.json','tests/ordered-review.schema.json','scripts/eval_runtime.ps1','scripts/ordered_review.ps1','scripts/run_runtime_dialogues.ps1')) {
    $name = Split-Path -Leaf $relative
    $entries = @($manifest.harness_files | Where-Object path -eq $name)
    if ($entries.Count -ne 1 -or $entries[0].sha256 -ne (Get-FileHash -LiteralPath (Join-Path $LabRoot $relative)).Hash -or $entries[0].sha256 -ne (Get-FileHash -LiteralPath (Join-Path $EvidenceRoot "harness-snapshot/$name")).Hash) { throw 'Runtime review harness is stale or incomplete.' }
  }
  $expected = @(foreach ($name in @('SKILL.md','VERSION','agents','references','scripts','templates')) { Get-ChildItem -LiteralPath (Join-Path $StandardRoot $name) -File -Recurse })
  $root = (Resolve-Path -LiteralPath $StandardRoot).Path
  $actualPaths = @($manifest.files | ForEach-Object { $_.path.Replace('\','/') } | Sort-Object -Unique)
  $expectedPaths = @($expected | ForEach-Object { $_.FullName.Substring($root.Length+1).Replace('\','/') } | Sort-Object -Unique)
  if (@(Compare-Object $actualPaths $expectedPaths).Count -gt 0 -or $manifest.files.Count -ne $expectedPaths.Count) { throw 'Runtime file set is stale or incomplete.' }
  foreach ($entry in $manifest.files) {
    if ($entry.sha256 -ne (Get-FileHash -LiteralPath (Join-Path $root $entry.path)).Hash) { throw "Runtime hash is stale: $($entry.path)" }
    if ($entry.sha256 -ne (Get-FileHash -LiteralPath (Join-Path (Join-Path $EvidenceRoot 'runtime-snapshot') $entry.path)).Hash) { throw 'Evaluated runtime snapshot was changed.' }
  }
  $case = (Get-Content -Raw -Encoding UTF8 (Join-Path $LabRoot 'tests/runtime-dialogues.json') | ConvertFrom-Json).cases | Where-Object id -eq $migration.runtime_case_id
  $parsedRows = Get-Content -Raw -Encoding UTF8 (Join-Path $EvidenceRoot 'summary.json') | ConvertFrom-Json
  $rows = @($parsedRows | Where-Object case_id -eq $migration.runtime_case_id)
  if ($rows.Count -ne 1) { throw 'Actual runtime result is missing or duplicated.' }
  $row = $rows[0]
  if ($row.reviewer_format -ne $manifest.reviewer_format) { throw 'Runtime review format does not match its manifest.' }
  if ($row.status -ne 'Evaluated' -or $row.result -ne 'Pass' -or $row.review.case_id -ne $case.id -or $row.review.result -ne 'Pass' -or @($row.review.failed_assertions).Count -gt 0 -or @($row.review.hard_failures).Count -gt 0 -or $null -ne $row.review.first_divergent_turn -or @($row.violations).Count -gt 0 -or $row.completed_turns -ne $case.turns.Count) { throw 'Actual runtime case is incomplete or did not independently pass.' }
  $transcript = Get-Content -Raw -Encoding UTF8 (Join-Path $EvidenceRoot "$($case.id)/transcript.json") | ConvertFrom-Json
  $transcript = @($transcript)
  if ($transcript.Count -ne $case.turns.Count -or @($transcript | Where-Object { $_.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace($_.response) }).Count) { throw 'Completed-turn evidence is missing.' }
  $reviewTranscript = $transcript
  if ($manifest.reviewer_format -eq 'Ordered') {
    . (Join-Path $PSScriptRoot 'ordered_review.ps1')
    $eventPaths = @{}
    foreach ($turn in $transcript) { $eventPaths[[int]$turn.turn] = Join-Path $EvidenceRoot ('{0}/workspace/turn-{1:D2}.events.jsonl' -f $case.id,$turn.turn) }
    $bundle = New-AllredOrderedReviewEvidence $transcript $eventPaths
    $reviewTranscript = @($bundle.transcript)
  }
  Test-AllredRuntimeReview -Review $row.review -Case (Get-AllredRuntimeReviewCase $case) -Transcript $reviewTranscript | Out-Null
  $stagePattern = '(?i)-(?:Stage|ToStage)\s+[''"\x5c]*' + [regex]::Escape($migration.required_stage) + '\b'
  $gates = @($transcript.commands | Where-Object { $_.exit_code -eq 0 -and $_.command -match '(get_route_context|invoke_validation_gate)\.ps1' -and $_.command -match $stagePattern -and $_.aggregated_output -match 'Actual aggregate validation passed|Allred validation gate: PASS' })
  if ($gates.Count -eq 0 -or @($transcript.state_snapshots).Count -eq 0) { throw 'No actual matching stage-gate and state evidence.' }
  "Runtime migration: PASS ($LegacyCaseId -> $($case.id), $ReasoningEffort; actual files/tools and independent review)"
} catch {
  "Runtime migration: INCOMPLETE ($LegacyCaseId): $($_.Exception.Message)"
  exit 3
}
