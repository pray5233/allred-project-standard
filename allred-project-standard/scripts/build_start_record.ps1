param(
  [Parameter(Mandatory = $true)][string]$StatePath,
  [string]$EvidenceRoot = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')

function Need-Text($Object, [string]$Name) {
  $value = Get-AllredProperty $Object $Name
  if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { throw "Missing text: $Name" }
  return $value
}
function Items($Object, [string]$Name) { @(Get-AllredArray (Get-AllredProperty $Object $Name)) }
function Cell($Value) {
  if ($null -eq $Value) { return '' }
  return (([string]$Value).Replace('&', '&amp;').Replace('|', '&#124;').Replace('<', '&lt;').Replace('>', '&gt;') -replace "`r?`n", '<br>')
}
function Line([string]$Value) { $script:lines.Add($Value) | Out-Null }
function Row([object[]]$Cells) { Line ('| ' + ((@($Cells | ForEach-Object { Cell $_ })) -join ' | ') + ' |') }
function Table([string]$Title, [string[]]$Columns) {
  Line ''; Line "## $Title"; Line ''; Row $Columns; Row @($Columns | ForEach-Object { '---' })
}
function Write-New([string]$Path, [string]$Text) {
  $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
  try { $bytes = $OutputEncoding.GetBytes($Text); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}

$sourcePath = (Resolve-Path -LiteralPath $StatePath).Path
$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$state = Read-AllredProjectState -Path $sourcePath
$missing = [System.Collections.Generic.List[string]]::new()
foreach ($section in @('evidence', 'technical_conclusions')) {
  $required = if ($section -eq 'evidence') { @('id', 'method', 'claim_type', 'confidence', 'claim') } else { @('id', 'basis_source', 'version_or_date', 'comparable_because', 'status', 'statement', 'deliberate_differences', 'method') }
  $index = 0
  foreach ($item in @(Items $state $section)) {
    foreach ($name in $required) {
      $value = Get-AllredProperty $item $name
      if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) { $missing.Add("${section}[$index].$name") }
    }
    $index++
  }
}
if ($missing.Count) { throw "Missing record text: $($missing -join ', '). Use the observed sources; do not invent values to satisfy the format." }
$auth = Get-AllredProperty $state 'authorization'
$change = Get-AllredProperty $state 'change_control'
if ((Get-AllredProperty $auth 'state') -ne 'pending' -or
    (Get-AllredProperty $change 'mode') -ne 'new-baseline' -or
    $null -ne (Get-AllredProperty $change 'change')) {
  throw 'Builder supports pending new-baseline start records only. Preserve existing delta/approved records using their normal editing path.'
}
$plan = Get-AllredProperty $state 'execution_plan'
$environment = Need-Text $plan 'target_environment'
$boundary = Get-AllredProperty $state 'write_boundary'
$root = Need-Text $boundary 'project_root'
$rollback = Need-Text $boundary 'rollback_checkpoint'
$review = Get-AllredProperty $plan 'effects_review'
if ((Get-AllredProperty $review 'complete') -ne $true) { throw 'Execution effects review is not complete.' }
foreach ($name in @('hidden_recommendations', 'hidden_behaviors', 'hidden_effects')) {
  if ($null -eq $review.PSObject.Properties[$name] -or $review.PSObject.Properties[$name].Value -isnot [array] -or @(Items $review $name).Count -ne 0) {
    throw "Unresolved or missing effects review: $name"
  }
}
$surfaced = Need-Text $review 'surfaced'
$scope = @(Items $state 'scope')
if ($scope.Count -eq 0) { throw 'Cannot build an empty scope.' }
$scopeMap = @{}
foreach ($item in $scope) {
  $id = Need-Text $item 'id'
  if ($id -notmatch '^S[0-9A-Za-z._-]+$' -or $scopeMap.ContainsKey($id)) { throw "Invalid or duplicate scope ID: $id" }
  $null = Need-Text $item 'statement'
  $scopeMap[$id] = $item
}
$steps = @{}
foreach ($step in @(Items $plan 'scope_steps')) {
  $id = Need-Text $step 'scope_id'
  if (-not $scopeMap.ContainsKey($id) -or $steps.ContainsKey($id)) { throw "Unknown or duplicate scope step: $id" }
  $null = Need-Text $step 'target'; $null = Need-Text $step 'proof'
  $steps[$id] = $step
}
foreach ($id in $scopeMap.Keys) { if (-not $steps.ContainsKey($id)) { throw "Missing implementation/verification step for scope: $id" } }

$sources = Get-AllredUserSourceMap $state
$decisions = @{}
foreach ($decision in @(Items $state 'decisions')) { $decisions[[string](Get-AllredProperty $decision 'id')] = $decision }
$trace = [ordered]@{}
foreach ($item in $scope) {
  foreach ($ref in @(Items $item 'provenance')) {
    if ([string]$ref -notmatch '^[UD]') { continue }
    if ($sources.ContainsKey($ref)) {
      $statement = Need-Text $sources[$ref] 'meaning'; $approval = [string]$ref
    } elseif ($decisions.ContainsKey($ref) -and (Get-AllredProperty $decisions[$ref] 'status') -eq 'confirmed') {
      $statement = (Need-Text $decisions[$ref] 'axis') + ': ' + (Need-Text $decisions[$ref] 'choice')
      $approval = Need-Text $decisions[$ref] 'approval_source'
    } else { throw "Missing user source or unconfirmed decision: $ref" }
    if (-not $trace.Contains($ref)) {
      $trace[$ref] = [pscustomobject]@{ statement = $statement; approval = $approval; scope_ids = [System.Collections.Generic.List[string]]::new() }
    }
    if (-not $trace[$ref].scope_ids.Contains($item.id)) { $trace[$ref].scope_ids.Add($item.id) }
  }
}
if ($trace.Count -eq 0) { throw 'No user/confirmed-decision provenance is available for an execution record.' }

$files = @(Items $plan 'files')
$commands = @(Items $plan 'commands')
if ($files.Count -eq 0 -or $commands.Count -eq 0) { throw 'Exact files and commands are required; use an explicit None command if none are planned.' }
$planned = @(Items $boundary 'planned_paths')
$protected = @(Items $boundary 'read_only_inputs')
$allowed = @(Items $boundary 'allowed_write_roots')
foreach ($field in @('project_root', 'allowed_write_roots', 'read_only_inputs', 'planned_paths')) {
  foreach ($value in @(Items $boundary $field)) {
    if (-not (Test-AllredAbsolutePath $value)) { throw "write_boundary.$field requires absolute paths: $value. Use the actual project root and a path API; no relative path inference is performed." }
  }
}
foreach ($file in $files) {
  $path = Need-Text $file 'path'
  if (-not (Test-AllredAbsolutePath $path) -or $path -match '[*?\[]' -or -not (Test-AllredNoLinkTraversal $path)) { throw "Unsafe planned file: $path" }
  if (-not (Test-AllredPathWithin $root $path) -or
      @($allowed | Where-Object { Test-AllredPathWithin $_ $path }).Count -eq 0 -or
      @($planned | Where-Object { Test-AllredPathWithin $_ $path }).Count -eq 0) { throw "File is outside the declared write plan: $path" }
  foreach ($input in $protected) {
    if ((Test-AllredPathWithin $input $path) -or (Test-AllredPathWithin $path $input)) { throw "File overlaps protected input: $path" }
  }
  if ((Get-AllredProperty $file 'action') -notin @('create', 'modify', 'delete', 'none')) { throw 'Invalid file action.' }
  $null = Need-Text $file 'purpose'
  if (@(Items $file 'scope_ids').Count -eq 0) { throw 'File has no scope basis.' }
  foreach ($id in @(Items $file 'scope_ids')) { if (-not $scopeMap.ContainsKey($id)) { throw "File references unknown scope: $id" } }
}
foreach ($command in $commands) { foreach ($name in @('command', 'effect', 'proof')) { $null = Need-Text $command $name } }
$mutations = @(Items $plan 'mutations')
foreach ($layer in @('Development-time', 'Runtime', 'External/system')) {
  if (@($mutations | Where-Object { (Get-AllredProperty $_ 'layer') -eq $layer }).Count -ne 1) { throw "Supply one mutation row for $layer." }
}
if ($mutations.Count -ne 3) { throw 'Unexpected mutation layer.' }
foreach ($mutation in $mutations) {
  foreach ($name in @('target', 'effect', 'rollback')) { $null = Need-Text $mutation $name }
  if (@(Items $mutation 'basis').Count -eq 0) { throw 'Mutation row has no explicit basis.' }
  foreach ($ref in @(Items $mutation 'basis')) {
    if ([string]$ref -notin @($sources.Keys) + @($decisions.Keys) + @(Items $auth 'envelope_id')) { throw "Unknown mutation basis: $ref" }
  }
}

$lines = [System.Collections.Generic.List[string]]::new()
$recordId = 'ER-' + [guid]::NewGuid().ToString('N')
Line '# Codex Execution Record'
Line "`n- Record ID: $recordId"
Line '- Schema version: 1'; Line '- Record status: ready'
Line ('- Approved scope reference: Pending start envelope ' + (Cell (Get-AllredProperty $auth 'envelope_id')) + '; not execution authorization')
Line ('- Active scope decision IDs: ' + ($trace.Keys -join ', '))
Line '- Previous record: None'; Line '- Owner: Codex'
Line "- Source state SHA256: $sourceHash"
Line "`n## Objective And Boundary`n"
Line ('- Current objective: ' + (Cell (($scope | Where-Object relation -ne 'excluded' | ForEach-Object statement) -join '; ')))
Line ('- Non-goals: ' + (Cell (($scope | Where-Object relation -eq 'excluded' | ForEach-Object statement) -join '; ')))
Line ('- No-touch boundary: ' + (Cell ($protected -join '; ')))
Line ('- Target environment: ' + (Cell $environment))
Table 'Evidence Ledger' @('Evidence ID', 'Source/path/version/date', 'Observation', 'Supports', 'Limitation')
foreach ($e in @(Items $state 'evidence')) { Row @($e.id, $e.method, ($e.claim_type + '/' + $e.confidence + ': ' + $e.claim), ((Items $e 'supports') -join ', '), (Get-AllredProperty $e 'limitations')) }
Table 'Approved Scope Ledger' @('Scope ID', 'Approved statement', 'Approval source/envelope', 'Lifecycle')
foreach ($id in $trace.Keys) { Row @($id, $trace[$id].statement, $trace[$id].approval, 'active') }
Table 'Proposed Envelope Scope' @('Item', 'Statement', 'Relation', 'Provenance', 'Visibility and recommendation', 'Target', 'Proof')
foreach ($s in $scope) { Row @($s.id, $s.statement, $s.relation, ($s.provenance -join ', '), ("visible=$($s.visible); prominent=$($s.recommendation_prominent); pending start"), $steps[$s.id].target, $steps[$s.id].proof) }
Line "`n## Change Control Ledger`n"
Line '- Change mode: new-baseline'
Line ('- Baseline ID: ' + (Cell $change.baseline.id)); Line ('- Baseline status: ' + (Cell $change.baseline.status))
Line '- Change ID: None'; Line '- Change status: Not applicable'
Row @('Change item ID', 'Operation', 'Scope IDs', 'Provenance', 'Status'); Row @('---', '---', '---', '---', '---')
foreach ($id in @(Items $change.baseline 'scope_ids')) {
  if (-not $scopeMap.ContainsKey($id)) { throw "Baseline references unknown scope: $id" }
  Row @("CI-$id", 'establish', $id, ($scopeMap[$id].provenance -join ', '), 'pending')
}
Line ('- Later items: ' + (Cell ((@(Items $change 'later_items') | ConvertTo-Json -Depth 20 -Compress) -join '')))
Table 'Implementation Basis' @('Benchmark/reference/version/date', 'Why comparable', 'Reuse path', 'Deliberate difference', 'Acceptance metric')
foreach ($t in @(Items $state 'technical_conclusions')) { Row @(($t.basis_source + '; ' + $t.version_or_date), $t.comparable_because, ($t.status + ': ' + $t.statement + '; ' + (Get-AllredProperty $t 'limitations')), $t.deliberate_differences, $t.method) }
Table 'Exact Files' @('Path', 'Action', 'Purpose', 'Scope basis U/D/E')
foreach ($f in $files) { Row @($f.path, $f.action, $f.purpose, ((@($f.scope_ids | ForEach-Object { $scopeMap[$_].provenance }) | Sort-Object -Unique) -join ', ')) }
Table 'Exact Commands' @('Order', 'Exact command or None', 'Network/dependency/cache/process effect', 'Expected proof')
$i = 0; foreach ($c in $commands) { $i++; Row @($i, $c.command, $c.effect, $c.proof) }
Table 'Mutation Ledger' @('Layer', 'Exact target', 'Planned effect', 'Authorization basis', 'Rollback')
foreach ($m in $mutations) { Row @($m.layer, $m.target, $m.effect, ($m.basis -join ', '), $m.rollback) }
Line "`n## Significant Effects Reconciliation`n"
Line '- Hidden recommendation R: None'; Line '- Hidden user-visible behavior: None'; Line '- Hidden consequential effect: None'
Line ('- Effects surfaced in plain language: ' + (Cell $surfaced))
Table 'Decision Coverage Ledger' @('Scope ID', 'Approved statement', 'Implementation target', 'Promise IDs', 'Status')
foreach ($id in $trace.Keys) {
  $targets = @($trace[$id].scope_ids | ForEach-Object { $_ + ': ' + $steps[$_].target }) -join '; '
  Row @($id, $trace[$id].statement, $targets, "P-$id", 'planned')
}
Table 'Acceptance Ledger' @('Promise ID', 'Approved promise', 'Planned proof', 'Validation environment', 'Status')
foreach ($id in $trace.Keys) {
  $proofs = @($trace[$id].scope_ids | ForEach-Object { $_ + ': ' + $steps[$_].proof }) -join '; '
  Row @("P-$id", $trace[$id].statement, $proofs, $environment, 'planned')
}
foreach ($s in $scope) { Row @("P-$($s.id)", ($s.relation + ': ' + $s.statement), $steps[$s.id].proof, $environment, 'planned') }
Line "`n## Rollback And Checkpoint`n"
Line ('- Pre-change checkpoint: ' + (Cell $rollback)); Line ('- Rollback steps: ' + (Cell $rollback))
Line ('- Existing user data restoration: Protected inputs remain unchanged: ' + (Cell ($protected -join '; ')))
Line '- Rollback validation: planned'
Table 'Execution Results' @('Promise ID', 'Fresh evidence', 'Environment', 'Result', 'Remaining gap')
foreach ($id in @($trace.Keys) + @($scopeMap.Keys | Sort-Object)) { Row @("P-$id", 'not run', $environment, 'unverified', 'Implementation and fresh validation have not started.') }
Line "`n- Final status: ready"; Line '- Superseded by: None'

# Only new internal snapshots are writable; reject link redirection and overlap before creating them.
$base = if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
  Join-Path ([System.IO.Path]::GetTempPath()) 'allred-project-standard/records'
} else {
  if ($EvidenceRoot -match '[*?\[]' -or $EvidenceRoot -match '^[A-Za-z]:[^\\/]') { throw 'EvidenceRoot cannot use wildcards or a drive-relative path.' }
  $candidate = if (Test-AllredAbsolutePath $EvidenceRoot) { $EvidenceRoot } else { Join-Path (Get-Location).ProviderPath $EvidenceRoot }
  [System.IO.Path]::GetFullPath($candidate)
}
$outputRoot = Join-Path $base ([guid]::NewGuid().ToString('N'))
if (-not (Test-AllredNoLinkTraversal $outputRoot)) { throw 'Temporary record path traverses a link.' }
foreach ($protectedRoot in @($root) + $protected + @((Split-Path -Parent $PSScriptRoot))) {
  if ((Test-AllredPathWithin $protectedRoot $outputRoot) -or (Test-AllredPathWithin $outputRoot $protectedRoot)) { throw "Temporary output overlaps a protected/project/Skill path: $protectedRoot" }
}
if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $sourceHash) { throw 'Input state changed during construction.' }
$null = [System.IO.Directory]::CreateDirectory($outputRoot)
$recordPath = Join-Path $outputRoot 'execution-record.md'
$outputState = Join-Path $outputRoot 'project-state.json'
Write-New $recordPath ($lines -join "`n")
$shell = (Get-Process -Id $PID).Path
foreach ($validator in @('validate_execution_record.ps1', 'validate_decision_coverage.ps1')) {
  & $shell -NoProfile -NonInteractive -File (Join-Path $PSScriptRoot $validator) -Path $recordPath
  if ($LASTEXITCODE -ne 0) { throw "Generated record failed $validator. Diagnostic artifact: $recordPath" }
}
$preflight = Get-AllredProperty $state 'preflight'
if ($null -eq $preflight) { throw 'Missing preflight; the builder cannot declare technical checks complete.' }
$preflight | Add-Member -NotePropertyName execution_record -NotePropertyValue ([pscustomobject]@{status='valid'; reference=$recordId; path=$recordPath}) -Force
Write-New $outputState ($state | ConvertTo-Json -Depth 60)
'Start record constructed; READY/EXECUTION have NOT been validated or authorized.'
"StatePath: $outputState"
"ExecutionRecordPath: $recordPath"
