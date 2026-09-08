param([string]$OutputRoot = (Join-Path ([IO.Path]::GetTempPath()) ('allred-migration-contracts-' + [Guid]::NewGuid().ToString('N'))))
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $OutputRoot) { throw 'Use a new unit-test output directory.' }
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
$ps = (Get-Process -Id $PID).Path
$lab = Join-Path $OutputRoot 'unit-lab'
$standard = Join-Path $OutputRoot 'unit-standard'
Write-AllredEvalUtf8 (Join-Path $lab 'tests/runtime-evidence-migrations.json') '{"migrations":[{"legacy_case_id":"legacy","runtime_case_id":"actual","required_stage":"READY"}]}'
Write-AllredEvalUtf8 (Join-Path $lab 'tests/runtime-dialogues.json') '{"cases":[{"id":"actual","turns":["unit input"],"assertions":["Observe the synthetic gate fixture."]}]}'
$harness = @(foreach ($relative in @('tests/runtime-review.schema.json','tests/ordered-review.schema.json','scripts/eval_runtime.ps1','scripts/ordered_review.ps1','scripts/run_runtime_dialogues.ps1')) {
  $target = Join-Path $lab $relative
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
  Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) $relative) -Destination $target
  [pscustomobject]@{path=(Split-Path -Leaf $relative);sha256=(Get-FileHash -LiteralPath $target).Hash;source=$target}
})
foreach ($name in @('agents','references','scripts','templates')) { New-Item -ItemType Directory -Path (Join-Path $standard $name) -Force | Out-Null }
Write-AllredEvalUtf8 (Join-Path $standard 'SKILL.md') 'Unit-test fixture, not a usable Skill or behavioral acceptance.'
Write-AllredEvalUtf8 (Join-Path $standard 'VERSION') 'unit'
$files = @(Get-ChildItem -LiteralPath $standard -Recurse -File | ForEach-Object { [pscustomobject]@{path=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash} })
$cases = @('valid','missing-result','partial','wrong-effort','stale-suite','stale-runtime','changed-snapshot','unfinished-turn','simulated-gate','failed-command','simulated-kind','wrong-review-case','contradictory-review','ungrounded-review','invented-quote','stale-harness','stale-ordered-helper','missing-ordered-schema','unknown-format','format-mismatch','ordered-valid','ordered-without-events','ordered-mismatched-events','ordered-invalid-reference')
foreach ($caseName in $cases) {
  $root = Join-Path $OutputRoot $caseName
  New-Item -ItemType Directory -Path $root | Out-Null
  Copy-Item -LiteralPath $standard -Destination (Join-Path $root 'runtime-snapshot') -Recurse
  New-Item -ItemType Directory -Path (Join-Path $root 'harness-snapshot') | Out-Null
  foreach ($file in $harness) { Copy-Item -LiteralPath $file.source -Destination (Join-Path $root 'harness-snapshot') }
  $manifest = [ordered]@{evidence_kind='actual-local-files-and-tools;unit-fixture-only';effort='low';model='unit';suite_sha256=(Get-FileHash -LiteralPath (Join-Path $lab 'tests/runtime-dialogues.json')).Hash;files=$files;harness_files=@($harness | Select-Object path,sha256)}
  $row = [ordered]@{case_id='actual';status='Evaluated';result='Pass';review=@{case_id='actual';result='Pass';failed_assertions=@();hard_failures=@();first_divergent_turn=$null;assertion_checks=@(@{assertion_index=1;result='Met';reason='Observed fixture command';evidence=@(@{turn=1;kind='command';index=0;quote='Actual aggregate validation passed'})})};violations=@();completed_turns=1}
  $manifest.reviewer_format='Legacy'
  $row.reviewer_format='Legacy'
  $turn = [ordered]@{turn=1;exit_code=0;response='unit fixture';state_snapshots=@(@{path='unit.json'});commands=@(@{exit_code=0;command='pwsh -File get_route_context.ps1 -Stage ready -StatePath unit.json';aggregated_output='Actual aggregate validation passed'})}
  foreach ($index in @(2,3)) {
    $row.review.assertion_checks += @{assertion_index=$index;result='Met';reason='Synthetic review contract only';evidence=@(@{turn=1;kind='response';index=$null;quote='unit fixture'})}
  }
  switch ($caseName) {
    'missing-result' { $row.case_id='other' }
    'partial' { $row.result='Partial' }
    'wrong-effort' { $manifest.effort='xhigh' }
    'stale-suite' { $manifest.suite_sha256='old' }
    'stale-runtime' { $manifest.files=@(@{path='SKILL.md';sha256='old'}) }
    'changed-snapshot' { Write-AllredEvalUtf8 (Join-Path $root 'runtime-snapshot/VERSION') 'changed' }
    'unfinished-turn' { $turn.response='' }
    'simulated-gate' { $turn.commands[0].command='echo E_READY_PASSED' }
    'failed-command' { $turn.commands[0].exit_code=1 }
    'simulated-kind' { $manifest.evidence_kind='legacy-conversation-simulation' }
    'wrong-review-case' { $row.review.case_id='other' }
    'contradictory-review' { $row.review.failed_assertions=@('an assertion failed') }
    'ungrounded-review' { $row.review.assertion_checks=@() }
    'invented-quote' { $row.review.assertion_checks[0].evidence[0].quote='not in evidence' }
    'stale-harness' { $manifest.harness_files[0].sha256='old' }
    'stale-ordered-helper' { ($manifest.harness_files | Where-Object path -eq 'ordered_review.ps1').sha256='old' }
    'missing-ordered-schema' { $manifest.harness_files=@($manifest.harness_files | Where-Object path -ne 'ordered-review.schema.json') }
    'unknown-format' { $manifest.reviewer_format='unknown' }
    'format-mismatch' { $row.reviewer_format='Ordered' }
  }
  if ($caseName -like 'ordered-*') {
    $manifest.reviewer_format='Ordered'; $row.reviewer_format='Ordered'
    $turn.user='unit input'; $turn.messages=@('unit fixture')
    $row.review.assertion_checks[0].evidence[0].kind='event'
    $row.review.assertion_checks[0].evidence[0].index=0
    $events=@(
      @{type='item.completed';item=@{id='c1';type='command_execution';command=$turn.commands[0].command;aggregated_output=$turn.commands[0].aggregated_output;exit_code=0}}
      @{type='item.completed';item=@{id='m1';type='agent_message';text='unit fixture'}}
    )
    if ($caseName -eq 'ordered-mismatched-events') { $events[0].item.aggregated_output='other output' }
    if ($caseName -eq 'ordered-invalid-reference') { $row.review.assertion_checks[0].evidence[0].index=99 }
    if ($caseName -ne 'ordered-without-events') {
      Write-AllredEvalUtf8 (Join-Path $root 'actual/workspace/turn-01.events.jsonl') (($events | ForEach-Object { ConvertTo-Json $_ -Depth 8 -Compress }) -join "`n")
    }
  }
  Write-AllredEvalUtf8 (Join-Path $root 'manifest.json') ($manifest | ConvertTo-Json -Depth 8)
  Write-AllredEvalUtf8 (Join-Path $root 'summary.json') (ConvertTo-Json -InputObject @($row) -Depth 8)
  Write-AllredEvalUtf8 (Join-Path $root 'actual/transcript.json') (ConvertTo-Json -InputObject @($turn) -Depth 8)
  $output = & $ps -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check_runtime_evidence_migration.ps1') -EvidenceRoot $root -LegacyCaseId legacy -ReasoningEffort low -Model unit -LabRoot $lab -StandardRoot $standard
  $expected = if ($caseName -in @('valid','ordered-valid')) { 0 } else { 3 }
  if ($LASTEXITCODE -ne $expected) { throw "Migration unit test $caseName failed: $output" }
  Write-AllredEvalUtf8 (Join-Path $root 'unit-result.txt') ($output -join "`n")
}
"Runtime migration contracts: PASS ($($cases.Count) synthetic unit fixtures; not behavioral evidence)"
