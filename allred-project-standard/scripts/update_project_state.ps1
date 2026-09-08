param(
  [Parameter(Mandatory = $true)][string]$PatchPath,
  [string]$StatePath = '',
  [string]$ExpectedSha256 = '',
  [string]$Route = '',
  [string]$WorkspaceRoot = '',
  [string]$EvidenceRoot = ''
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')
. (Join-Path $PSScriptRoot 'answer_context_common.ps1')
$errorsFound = [Collections.Generic.List[string]]::new()
function Problem([string]$Message) { $script:errorsFound.Add($Message) | Out-Null }
function Put($Object, [string]$Name, $Value) {
  $property = $Object.PSObject.Properties[$Name]
  if ($null -ne $property) { $property.Value = $Value }
  else { $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}
function Rows($Object, [string]$Name) { @(Get-AllredArray (Get-AllredProperty $Object $Name)) }
function Sync-DecisionBlockers($State) {
  $decisions = @{}
  foreach ($d in @(Rows $State 'decisions')) { $decisions[[string]$d.id] = $d }
  $users = Get-AllredUserSourceMap $State
  foreach ($b in @(Rows $State 'blocking_items')) {
    $generated = (Get-AllredProperty $b 'resolution_mode') -eq 'confirmed-decisions'
    $status = [string](Get-AllredProperty $b 'status')
    if ($status -notin @('open','waiting','investigating','proposed','resolved')) { continue }
    if ($status -eq 'resolved' -and -not $generated) { continue }
    $sources = @(Get-AllredBlockerSources $b | Select-Object -Unique)
    $complete = (Get-AllredProperty $b 'kind') -eq 'decision' -and $sources.Count -gt 0 -and
      @(Rows $b 'remaining_facets').Count -eq 0
    foreach ($source in $sources) {
      $d = $decisions[[string]$source]
      $approval = [string](Get-AllredProperty $d 'approval_source')
      if ([string]$source -cnotmatch '^D[0-9A-Za-z._-]+$' -or $null -eq $d -or
          (Get-AllredProperty $d 'status') -ne 'confirmed' -or
          [string]::IsNullOrWhiteSpace([string](Get-AllredProperty $d 'choice')) -or
          (Get-AllredProperty $d 'exposed') -ne $true -or
          @(Rows $d 'remaining_facets').Count -gt 0 -or
          $approval -cnotmatch '^U[0-9A-Za-z._-]+$' -or -not $users.ContainsKey($approval) -or
          [string]::IsNullOrWhiteSpace([string](Get-AllredProperty $users[$approval] 'quote'))) {
        $complete = $false
      }
    }
    if ($complete) {
      Put $b 'status' 'resolved'
      Put $b 'resolution_mode' 'confirmed-decisions'
    } elseif ($generated) {
      # Only reopen closures derived here; authored lifecycle resolutions stay authored.
      if ($status -eq 'resolved') { Put $b 'status' 'open' }
      $b.PSObject.Properties.Remove('resolution_mode')
    }
  }
}
function Confirmation-Review($Before, $After) {
  $previous = @{}
  foreach ($d in @(Rows $Before 'decisions')) { $previous[[string]$d.id] = $d }
  $users = Get-AllredUserSourceMap $After
  foreach ($d in @(Rows $After 'decisions')) {
    if ((Get-AllredProperty $d 'status') -ne 'confirmed') { continue }
    $old = $previous[[string]$d.id]
    $choice = Get-AllredProperty $d 'choice'
    $source = [string](Get-AllredProperty $d 'approval_source')
    if ($null -ne $old -and (Get-AllredProperty $old 'status') -eq 'confirmed' -and
        (Get-AllredProperty $old 'choice') -ceq $choice -and (Get-AllredProperty $old 'approval_source') -ceq $source) { continue }
    [pscustomobject]@{
      decision_id = $d.id
      question = $(if ($null -ne $old) { Get-AllredProperty $old 'axis' } else { Get-AllredProperty $d 'axis' })
      previous_choice = Get-AllredProperty $old 'choice'
      authored_choice = $choice
      source_id = $source
      literal_user_quote = $(if ($users.ContainsKey($source)) { Get-AllredProperty $users[$source] 'quote' } else { $null })
    }
  }
}
function Merge($Target, $Patch) {
  foreach ($p in $Patch.PSObject.Properties) {
    $old = Get-AllredProperty $Target $p.Name
    if ($p.Value -is [pscustomobject] -and $old -is [pscustomobject]) { Merge $old $p.Value }
    else { Put $Target $p.Name $p.Value }
  }
}
function Contract-Text($State) {
  $contract = [ordered]@{}
  foreach ($name in @('intake','complexity','user_sources','evidence','decisions','questions','scope','technical_conclusions','blocking_items','write_boundary','execution_plan')) {
    $contract[$name] = Get-AllredProperty $State $name
  }
  return ($contract | ConvertTo-Json -Depth 60 -Compress)
}
function Absolute([string]$Value, [string]$Base) {
  if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '[*?\[]' -or $Value -match '^[A-Za-z]:($|[^\\/])') { throw "Invalid path: $Value" }
  if (-not (Test-AllredAbsolutePath $Value)) { $Value = Join-Path $Base $Value }
  return [IO.Path]::GetFullPath($Value)
}
function Check-References($Values, [string]$Prefixes, [string]$Location) {
  foreach ($value in @($Values)) {
    if (-not (Test-AllredReferenceId -Value $value -Prefixes $Prefixes)) { Problem "$Location has an invalid reference type: $value (allowed: $Prefixes)"; continue }
    if ([string]$value -match '^[UEDSQT]' -and -not $script:ids.ContainsKey([string]$value)) { Problem "$Location references a missing item: $value" }
  }
}
function Stop-OnProblems {
  if ($script:errorsFound.Count) {
    'Project state update: REJECTED; no snapshot written.'
    $script:errorsFound | ForEach-Object { "- $_" }
    exit 1
  }
}

function Apply-AnswerMap($Patch, $Before, [string]$SourcePath) {
  $map = Get-AllredProperty $Patch 'answer_map'
  if ($null -eq $map) { return }
  if (-not $SourcePath) { Problem 'answer_map requires the existing StatePath.'; return }
  foreach ($p in $map.PSObject.Properties) { if ($p.Name -notin @('binding','confirmed','pending','resolved')) { Problem "Unsupported answer_map field: $($p.Name)" } }
  $binding = Get-AllredProperty $map 'binding'
  try {
    $context = Read-AllredAnswerContext -StatePath $SourcePath -QuestionPath ([string](Get-AllredProperty $binding 'question_path')) -ReplyPath ([string](Get-AllredProperty $binding 'reply_path'))
    foreach ($p in $context.binding.PSObject.Properties) {
      if ((Get-AllredProperty $binding $p.Name) -cne $p.Value) { Problem "Stale or mismatched answer binding: $($p.Name)" }
    }
  } catch { Problem $_.Exception.Message; return }
  foreach ($field in @('confirmed','pending')) {
    $property = $map.PSObject.Properties[$field]
    if ($null -eq $property -or $property.Value -isnot [array]) { Problem "answer_map.$field must be an explicit array." }
  }
  $resolvedProperty = $map.PSObject.Properties['resolved']
  if ($null -ne $resolvedProperty -and $resolvedProperty.Value -isnot [array]) { Problem 'answer_map.resolved must be an array when supplied.' }
  if ($script:errorsFound.Count) { return }
  $confirmed = @(Rows $map 'confirmed')
  $pending = @(Rows $map 'pending')
  $byId = @{}
  foreach ($d in @(Rows $Before 'decisions')) { $byId[[string]$d.id] = $d }
  $seen = @{}
  foreach ($row in $confirmed) {
    $id = [string](Get-AllredProperty $row 'id')
    $choice = Get-AllredProperty $row 'choice'
    if ($row -isnot [pscustomobject] -or -not $byId.ContainsKey($id) -or
        (Get-AllredProperty $byId[$id] 'status') -in @('deferred','rejected','superseded','not-applicable') -or
        $choice -isnot [string] -or [string]::IsNullOrWhiteSpace($choice)) { Problem "Invalid confirmed answer mapping: $id"; continue }
    foreach ($p in $row.PSObject.Properties) { if ($p.Name -notin @('id','choice')) { Problem "Unsupported confirmed answer field: $($p.Name)" } }
    if ($seen.ContainsKey($id)) { Problem "Duplicate answer mapping: $id" }
    $seen[$id] = 'confirmed'
  }
  $resolved = @(Rows $map 'resolved')
  foreach ($row in $resolved) {
    $id = [string](Get-AllredProperty $row 'id')
    if ($row -isnot [pscustomobject] -or -not $byId.ContainsKey($id) -or
        (Get-AllredProperty $row 'status') -notin @('deferred','rejected','superseded','not-applicable') -or
        [string]::IsNullOrWhiteSpace([string](Get-AllredProperty $row 'reason'))) { Problem "Invalid resolved answer mapping: $id"; continue }
    foreach ($p in $row.PSObject.Properties) { if ($p.Name -notin @('id','status','reason','superseded_by')) { Problem "Unsupported resolved answer field: $($p.Name)" } }
    if ($seen.ContainsKey($id)) { Problem "Duplicate or conflicting answer mapping: $id" }
    $seen[$id] = 'resolved'
  }
  foreach ($id in $pending) {
    if ($id -isnot [string] -or $id -notin $context.unresolved_decision_ids) { Problem "Invalid pending answer mapping: $id"; continue }
    if ($seen.ContainsKey($id)) { Problem "Duplicate or conflicting answer mapping: $id" }
    $seen[$id] = 'pending'
  }
  foreach ($id in $context.unresolved_decision_ids) { if (-not $seen.ContainsKey($id)) { Problem "Unaccounted unresolved answer: $id" } }
  if ($script:errorsFound.Count) { return }

  if ($null -eq (Get-AllredProperty $Patch 'upsert')) { Put $Patch 'upsert' ([pscustomobject]@{}) }
  $upsert = $Patch.upsert
  $users = @(Rows $upsert 'user_sources')
  $existingSources = @(@(Rows $Before 'user_sources') + $users | Where-Object { $_.id -eq $context.source_id })
  if ($existingSources.Count) { Problem 'The answer source is generated; do not author or reuse its ID manually.'; return }
  Put $upsert 'user_sources' @($users + @([pscustomobject]@{id=$context.source_id;quote=$context.literal_reply;authority='context'}))
  $decisionRows = @(Rows $upsert 'decisions')
  foreach ($row in $decisionRows) {
    if ($seen.ContainsKey([string]$row.id)) {
      foreach ($field in @('status','choice','approval_source','resolution_source','reason','superseded_by')) {
        if ($null -ne $row.PSObject.Properties[$field]) { Problem "Answer-mapped decision cannot be overridden in upsert: $($row.id).$field" }
      }
    }
  }
  if ($script:errorsFound.Count) { return }
  foreach ($answer in $confirmed) {
    $row = @($decisionRows | Where-Object { $_.id -eq $answer.id })
    $target = if ($row.Count) { $row[0] } else { [pscustomobject]@{id=$answer.id} }
    Put $target 'status' 'confirmed'
    Put $target 'choice' $answer.choice
    Put $target 'approval_source' $context.source_id
    Put $target 'exposed' $true
    if (-not $row.Count) { $decisionRows += $target }
  }
  foreach ($answer in $resolved) {
    $row = @($decisionRows | Where-Object { $_.id -eq $answer.id })
    $target = if ($row.Count) { $row[0] } else { [pscustomobject]@{id=$answer.id} }
    foreach ($p in $answer.PSObject.Properties) { Put $target $p.Name $p.Value }
    Put $target 'resolution_source' $context.source_id
    if (-not $row.Count) { $decisionRows += $target }
  }
  Put $upsert 'decisions' $decisionRows
  # A second read detects edits to the literal inputs before snapshot construction.
  foreach ($name in @('question','reply')) {
    if ((Get-FileHash -LiteralPath (Get-AllredProperty $context.binding ($name+'_path'))).Hash -ne (Get-AllredProperty $context.binding ($name+'_sha256'))) { Problem "Answer input changed during update: $name" }
  }
}

$patchFile = (Resolve-Path -LiteralPath $PatchPath).Path
$patchHash = (Get-FileHash -LiteralPath $patchFile).Hash
$patch = Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($patch -isnot [pscustomobject]) { throw 'Patch must be a JSON object.' }
foreach ($p in $patch.PSObject.Properties) {
  if ($p.Name -notin @('set','upsert','prepare_ready','answer_map')) { Problem "Unsupported patch operation: $($p.Name)" }
  elseif ($p.Value -isnot [pscustomobject]) { Problem "$($p.Name) must be an object." }
}
Stop-OnProblems
$sourceHash = $null
$sourceFile = $null
if ($StatePath) {
  $sourceFile = (Resolve-Path -LiteralPath $StatePath).Path
  $sourceHash = (Get-FileHash -LiteralPath $sourceFile).Hash
  if (-not $ExpectedSha256 -or $ExpectedSha256 -ne $sourceHash) { throw 'ExpectedSha256 is required and must match the current source state. Read the latest state before updating.' }
  $state = Get-Content -LiteralPath $sourceFile -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($state.schema_version -ne 1) { throw 'Only schema version 1 is supported.' }
  if ($Route -and $Route -ne $state.route) { throw 'Do not change the route through an incremental patch.' }
} else {
  if ($Route -notin @('new-standard','non-software')) { throw 'A new state requires Route new-standard or non-software.' }
  $state = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../templates/project-state.draft.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $key = [guid]::NewGuid().ToString('N')
  $state.state_id = "APS-$key"; $state.route = $Route; $state.change_control.baseline.id = "BASE-$key"
}
if ($state.authorization.state -ne 'pending' -or $state.change_control.mode -ne 'new-baseline' -or $state.change_control.baseline.status -ne 'candidate') {
  throw 'This authoring API only updates pending new-baseline drafts. It cannot alter approved or delta work.'
}
if ($sourceFile) {
  foreach ($failure in @(Get-AllredStateParentFailures -State $state -StatePath $sourceFile)) { Problem $failure }
  Stop-OnProblems
}
$previousBoundary = $state.write_boundary | ConvertTo-Json -Depth 20 | ConvertFrom-Json
$beforeContract = Contract-Text $state
$beforeState = $state | ConvertTo-Json -Depth 60 -Compress
$previousAuthoring = Get-AllredProperty $state 'authoring'
if (-not $WorkspaceRoot) { $WorkspaceRoot = [string](Get-AllredProperty $previousAuthoring 'workspace_root') }
if (-not $WorkspaceRoot) { $WorkspaceRoot = (Get-Location).ProviderPath }
$workspace = Absolute $WorkspaceRoot (Get-Location).ProviderPath
if ($null -ne $previousAuthoring -and $workspace -ne (Get-AllredProperty $previousAuthoring 'workspace_root')) { throw 'WorkspaceRoot cannot silently rebase an existing state.' }

Apply-AnswerMap -Patch $patch -Before $state -SourcePath $sourceFile
Stop-OnProblems
$set = Get-AllredProperty $patch 'set'
if ($null -ne $set) {
  foreach ($p in $set.PSObject.Properties) {
    if ($p.Name -notin @('intake','complexity','discovery_coverage','preflight','execution_plan')) { Problem "set.$($p.Name) is not editable here; use ledger upserts or prepare_ready."; continue }
    if ($p.Value -isnot [pscustomobject]) { Problem "set.$($p.Name) must be an object."; continue }
    if ($p.Name -eq 'preflight' -and @($p.Value.PSObject.Properties | Where-Object Name -ne 'status').Count) { Problem 'Only preflight.status is authored; execution-record validity is generated.'; continue }
    if ((Get-AllredProperty $state $p.Name) -isnot [pscustomobject]) { Put $state $p.Name ([pscustomobject]@{}) }
    Merge (Get-AllredProperty $state $p.Name) $p.Value
  }
}
$ledgerPrefixes = @{user_sources='U'; evidence='E'; decisions='D'; questions='Q'; scope='S'; technical_conclusions='T'; blocking_items=''}
$upsert = Get-AllredProperty $patch 'upsert'
if ($null -ne $upsert) {
  foreach ($p in $upsert.PSObject.Properties) {
    if (-not $ledgerPrefixes.ContainsKey($p.Name)) { Problem "Unknown upsert ledger: $($p.Name)"; continue }
    if ($p.Value -isnot [array]) { Problem "upsert.$($p.Name) must be an array."; continue }
    $list = [Collections.Generic.List[object]]::new()
    foreach ($row in @(Rows $state $p.Name)) { $list.Add($row) }
    $seen = @{}
    foreach ($row in $p.Value) {
      $id = [string](Get-AllredProperty $row 'id')
      if ($row -isnot [pscustomobject] -or -not $id -or ($ledgerPrefixes[$p.Name] -and $id -notmatch ('^' + $ledgerPrefixes[$p.Name] + '[0-9A-Za-z._-]+$'))) { Problem "Invalid ID in $($p.Name): $id"; continue }
      if ($seen.ContainsKey($id)) { Problem "Duplicate ID in this patch: $id"; continue }
      $seen[$id] = $true
      $existing = @($list | Where-Object { (Get-AllredProperty $_ 'id') -eq $id })
      if ($existing.Count -gt 1) { Problem "Duplicate ID in base state: $id"; continue }
      if ($existing.Count) { Merge $existing[0] $row } else { $list.Add($row) }
    }
    Put $state $p.Name @($list)
  }
}
foreach ($u in @(Rows $state 'user_sources')) {
  if ($null -eq $u.PSObject.Properties['meaning']) { Put $u 'meaning' (Get-AllredProperty $u 'quote') }
}
$ids = @{}
foreach ($ledger in $ledgerPrefixes.Keys) {
  foreach ($row in @(Rows $state $ledger)) {
    $id = [string](Get-AllredProperty $row 'id')
    if (-not $id -or $ids.ContainsKey($id)) { Problem "Missing or duplicate state ID: $id" } else { $ids[$id] = $row }
  }
}

$ready = Get-AllredProperty $patch 'prepare_ready'
if ($null -ne $ready) {
  foreach ($p in $ready.PSObject.Properties) { if ($p.Name -notin @('scope_ids','root','read_only_inputs','rollback')) { Problem "Unknown prepare_ready field: $($p.Name)" } }
  $selection = @(Rows $ready 'scope_ids')
  if ($selection.Count -eq 0) { Problem 'prepare_ready.scope_ids must explicitly select the proposed envelope.' }
  Check-References $selection 'S' 'prepare_ready.scope_ids'
  if (@($selection | Select-Object -Unique).Count -ne $selection.Count) { Problem 'Duplicate selected scope ID.' }
  $root = Get-AllredProperty $ready 'root'
  if ($null -ne $root) {
    foreach ($p in $root.PSObject.Properties) { if ($p.Name -notin @('path','authority','source')) { Problem "Unknown root field: $($p.Name)" } }
    try { $state.write_boundary.project_root = Absolute ([string](Get-AllredProperty $root 'path')) $workspace } catch { Problem $_.Exception.Message }
    $authority = Get-AllredProperty $root 'authority'
    $source = [string](Get-AllredProperty $root 'source')
    switch ($authority) {
      'recommendation' {
        if ($source) { Problem 'A recommended root is not user-approved; omit source. Its R marker is generated.' }
        $state.write_boundary.project_root_status = 'recommended-pending'
        $state.write_boundary.project_root_provenance = @('R-root')
        $state.write_boundary.project_root_recommendation_prominent = $true
      }
      { $_ -in @('user','decision') } {
        $prefix = if ($authority -eq 'user') { 'U' } else { 'D' }
        Check-References @($source) $prefix 'prepare_ready.root.source'
        if ($authority -eq 'decision' -and $ids.ContainsKey($source) -and (Get-AllredProperty $ids[$source] 'status') -ne 'confirmed') { Problem 'Root decision is not confirmed.' }
        $state.write_boundary.project_root_status = 'confirmed'
        $state.write_boundary.project_root_provenance = @($source)
        $state.write_boundary.project_root_recommendation_prominent = $false
      }
      default { Problem 'Root authority must be recommendation, user, or decision.' }
    }
  }
  if (-not $state.write_boundary.project_root) { Problem 'The proposed envelope requires a root choice.' }
  $state.write_boundary.allowed_write_roots = @($state.write_boundary.project_root)
  $originals = [Collections.Generic.List[string]]::new()
  foreach ($path in @($previousBoundary.read_only_inputs) + @(Rows $ready 'read_only_inputs')) {
    try { $full = Absolute $path $workspace; if (-not $originals.Contains($full)) { $originals.Add($full) } } catch { Problem $_.Exception.Message }
  }
  $state.write_boundary.read_only_inputs = @($originals)
  if ($null -ne $ready.PSObject.Properties['rollback']) { $state.write_boundary.rollback_checkpoint = [string]$ready.rollback }
  $state.write_boundary.visible_in_ready = $true
  foreach ($s in @(Rows $state 'scope')) {
    if ($s.id -in $selection) { Put $s 'visible' $true; Put $s 'approval_required' $true }
    if ($null -eq $s.PSObject.Properties['recommendation_prominent']) { Put $s 'recommendation_prominent' ((Get-AllredProperty $s 'relation') -eq 'recommended') }
  }
  $state.authorization.scope_ids = $selection; $state.authorization.starts_execution = $true
  $state.change_control.baseline.scope_ids = $selection
  $files = @(Rows $state.execution_plan 'files')
  $pathBase = [string](Get-AllredProperty $state.execution_plan 'file_path_base')
  if ($pathBase -and $pathBase -notin @('project-root','workspace')) { Problem 'execution_plan.file_path_base must be project-root or workspace.' }
  foreach ($file in $files) {
    try {
      $raw = [string](Get-AllredProperty $file 'path')
      $full = Absolute $raw $state.write_boundary.project_root
      if (-not (Test-AllredAbsolutePath $raw)) {
        $workspacePath = Absolute $raw $workspace
        if ($pathBase -eq 'workspace') { $full = $workspacePath }
        elseif (-not $pathBase -and $full -ne $workspacePath -and (Test-AllredPathWithin $state.write_boundary.project_root $workspacePath)) {
          Problem "Ambiguous relative plan: $raw. Use an absolute path or set execution_plan.file_path_base to project-root or workspace; do not silently duplicate the product directory."
        }
      }
      if (-not (Test-AllredPathWithin $state.write_boundary.project_root $full) -or -not (Test-AllredNoLinkTraversal $full)) { Problem "Unsafe or out-of-root plan: $full" }
      foreach ($inputPath in $originals) { if ((Test-AllredPathWithin $inputPath $full) -or (Test-AllredPathWithin $full $inputPath)) { Problem "Plan overlaps protected input: $full" } }
      Put $file 'path' $full
    } catch { Problem $_.Exception.Message }
  }
  $state.write_boundary.planned_paths = @($files | ForEach-Object { Get-AllredProperty $_ 'path' } | Select-Object -Unique)
  $steps = [Collections.Generic.List[object]]::new()
  foreach ($step in @(Rows $state.execution_plan 'scope_steps')) { $steps.Add($step) }
  foreach ($s in @(Rows $state 'scope')) {
    $execution = Get-AllredProperty $s 'execution'
    if ($null -ne $execution) {
      for ($i=$steps.Count-1; $i -ge 0; $i--) { if ($steps[$i].scope_id -eq $s.id) { $steps.RemoveAt($i) } }
      $steps.Add([pscustomobject]@{scope_id=$s.id; target=(Get-AllredProperty $execution 'target'); proof=(Get-AllredProperty $execution 'proof')})
    }
  }
  $state.execution_plan.scope_steps = @($steps)
}

Sync-DecisionBlockers $state
$changedContract = (Contract-Text $state) -cne $beforeContract
if ($changedContract) {
  if ($null -eq (Get-AllredProperty (Get-AllredProperty $set 'discovery_coverage') 'status')) { $state.discovery_coverage.status = 'open' }
  if ($null -eq (Get-AllredProperty (Get-AllredProperty $set 'preflight') 'status')) { $state.preflight.status = 'open' }
}
# A changed snapshot cannot inherit a previously generated record receipt. No-op updates keep settled work.
if (($state | ConvertTo-Json -Depth 60 -Compress) -cne $beforeState) {
  Put $state.preflight 'execution_record' ([pscustomobject]@{status='missing'; reference=''; path=''})
}

foreach ($name in @('outcome','materials','initial_idea','useful_result')) {
  $source = Get-AllredProperty (Get-AllredProperty $state.intake $name) 'source'
  if ($source) { Check-References @($source) 'UE' "intake.$name.source" }
}
foreach ($s in @(Rows $state 'scope')) { Check-References @(Rows $s 'provenance') 'UEDRB' "scope.$($s.id).provenance" }
foreach ($d in @(Rows $state 'decisions')) {
  foreach ($dep in @(Rows $d 'depends_on')) { Check-References @((Get-AllredProperty $dep 'id')) 'D' "decision.$($d.id).depends_on" }
  $source = Get-AllredProperty $d 'approval_source'
  if ($source) { Check-References @($source) 'UC' "decision.$($d.id).approval_source" }
  Check-References @(Rows (Get-AllredProperty $d 'recommendation') 'basis') 'UED' "decision.$($d.id).recommendation"
}
foreach ($area in @(Rows $state.discovery_coverage 'areas')) {
  Check-References @(Rows $area 'basis') 'UED' "coverage.$($area.id).basis"
  Check-References @(Rows $area 'scope_ids') 'S' "coverage.$($area.id).scope_ids"
  Check-References @(Rows $area 'decision_ids') 'D' "coverage.$($area.id).decision_ids"
}
foreach ($t in @(Rows $state 'technical_conclusions')) { Check-References @(Rows $t 'evidence') 'EB' "technical.$($t.id).evidence" }
Check-References @(Rows $state.write_boundary 'project_root_provenance') 'UDR' 'write_boundary.project_root_provenance'
foreach ($file in @(Rows $state.execution_plan 'files')) { Check-References @(Rows $file 'scope_ids') 'S' 'execution_plan.files.scope_ids' }
foreach ($failure in @(Get-AllredStateEvolutionFailures -PreviousState ($beforeState | ConvertFrom-Json) -State $state)) { Problem $failure }
foreach ($failure in @(Get-AllredConfirmedDecisionFacetFailures -State $state)) { Problem $failure }
Stop-OnProblems

$confirmationReview = @(Confirmation-Review ($beforeState | ConvertFrom-Json) $state)
$base = if ($EvidenceRoot) { Absolute $EvidenceRoot (Get-Location).ProviderPath } else { Join-Path ([IO.Path]::GetTempPath()) 'allred-project-standard/state' }
$output = Join-Path $base ([guid]::NewGuid().ToString('N'))
if (-not (Test-AllredNoLinkTraversal $output)) { throw 'Internal output traverses a link.' }
foreach ($protected in @($previousBoundary.project_root,$state.write_boundary.project_root) + @($previousBoundary.read_only_inputs) + @($state.write_boundary.read_only_inputs) + @((Split-Path -Parent $PSScriptRoot))) {
  if ($protected -and ((Test-AllredPathWithin $protected $output) -or (Test-AllredPathWithin $output $protected))) { throw "Internal output overlaps a protected path: $protected" }
}
if ($sourceFile -and (Get-FileHash -LiteralPath $sourceFile).Hash -ne $sourceHash) { throw 'Source changed during update.' }
if ((Get-FileHash -LiteralPath $patchFile).Hash -ne $patchHash) { throw 'Patch changed during update.' }
Put $state 'authoring' ([pscustomobject]@{workspace_root=$workspace; parent_path=$sourceFile; parent_sha256=$sourceHash; patch_sha256=$patchHash; facet_accounting_version=1})
$null = [IO.Directory]::CreateDirectory($output)
$destination = Join-Path $output 'project-state.json'
$stream = [IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try { $bytes=$OutputEncoding.GetBytes(($state | ConvertTo-Json -Depth 60)); $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
'Project state draft saved. No stage has been validated and no execution is authorized.'
"StatePath: $destination"
"SHA256: $((Get-FileHash -LiteralPath $destination).Hash)"
"Source: $(if ($sourceFile) { $sourceFile } else { 'new neutral draft' })"
if ($confirmationReview.Count) {
  'Internal answer audit: apply Frontier Round to these newly authored confirmations before the next packet. This is NOT semantic validation or user authorization; missing literal quotes remain unverified. Do not show this diagnostic to the user.'
  '---BEGIN CONFIRMATION REVIEW---'
  ConvertTo-Json -InputObject $confirmationReview -Depth 8
  '---END CONFIRMATION REVIEW---'
}
