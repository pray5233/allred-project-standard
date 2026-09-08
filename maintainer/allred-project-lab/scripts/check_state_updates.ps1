param(
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [string]$OutputRoot = (Join-Path ([IO.Path]::GetTempPath()) ('allred-state-update-tests-' + [guid]::NewGuid().ToString('N')))
)
$ErrorActionPreference = 'Stop'
$shell = (Get-Process -Id $PID).Path
$StandardRoot = (Resolve-Path -LiteralPath $StandardRoot).Path
$null = New-Item -ItemType Directory -Path $OutputRoot -Force
$OutputRoot = (Resolve-Path -LiteralPath $OutputRoot).Path
$results = [Collections.Generic.List[object]]::new()
$null = New-Item -ItemType Directory -Path (Join-Path $OutputRoot 'materials') -Force
$original = Join-Path $OutputRoot 'materials/source.txt'
[IO.File]::WriteAllText($original, 'Synthetic source, not a user project.')
$originalHash = (Get-FileHash -LiteralPath $original).Hash
function Save($Path,$Value) { [IO.File]::WriteAllText($Path,($Value | ConvertTo-Json -Depth 60),[Text.UTF8Encoding]::new($false)) }
function Check([string]$Name,[bool]$Pass) {
  $results.Add([pscustomobject]@{name=$Name; passed=$Pass})
  if (-not $Pass) { throw "Failed: $Name" }
}
function Run([string]$Script,[string[]]$Arguments,[string]$Name) {
  $old=$ErrorActionPreference
  try { $ErrorActionPreference='Continue'; $text=@(& $shell -NoProfile -NonInteractive -File (Join-Path $StandardRoot "scripts/$Script") @Arguments 2>&1 | ForEach-Object{[string]$_}); $code=$LASTEXITCODE } finally { $ErrorActionPreference=$old }
  $text=$text -join "`n"
  [IO.File]::WriteAllText((Join-Path $OutputRoot "$Name.log"),$text,[Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{code=$code;text=$text;path=[regex]::Match($text,'(?m)^StatePath: (.+)$').Groups[1].Value.Trim()}
}
function Patch($Value,[string]$Name,[string]$Base='', [string]$Hash='', [string]$Route='new-standard') {
  $file=Join-Path $OutputRoot "$Name.patch.json"; Save $file $Value
  $fileHash=(Get-FileHash -LiteralPath $file).Hash
  $arguments=@('-PatchPath',$file,'-WorkspaceRoot',$OutputRoot,'-EvidenceRoot',(Join-Path $OutputRoot 'control'))
  $baseHash=$null
  if ($Base) { $baseHash=(Get-FileHash -LiteralPath $Base).Hash; if (-not $Hash) {$Hash=$baseHash}; $arguments+=@('-StatePath',$Base,'-ExpectedSha256',$Hash) }
  else { $arguments+=@('-Route',$Route) }
  $r=Run 'update_project_state.ps1' $arguments $Name
  Check "$Name patch unchanged" ((Get-FileHash -LiteralPath $file).Hash -eq $fileHash)
  if($Base){Check "$Name base unchanged" ((Get-FileHash -LiteralPath $Base).Hash -eq $baseHash)}
  return $r
}
function Confirmation-Audit([string]$Text) {
  $match=[regex]::Match($Text,'(?s)---BEGIN CONFIRMATION REVIEW---\s*(.*?)\s*---END CONFIRMATION REVIEW---')
  if($match.Success){foreach($row in ($match.Groups[1].Value|ConvertFrom-Json)){$row}}
}
function Fixture {
  $s=Get-Content -LiteralPath (Join-Path $StandardRoot 'tests/project-state.valid-ready.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($item in $s.scope){
    foreach($name in @('visible','approval_required','recommendation_prominent')){$item.PSObject.Properties.Remove($name)}
    $item | Add-Member -NotePropertyName execution -NotePropertyValue ([pscustomobject]@{target='artifact.txt section '+$item.id; proof='Fixture-specific observation for '+$item.id})
  }
  $users=@($s.user_sources)+@([pscustomobject]@{id='U4';quote='Future volume is unknown.';authority='context'})
  return [pscustomobject]@{
    set=[pscustomobject]@{intake=$s.intake;complexity=$s.complexity;discovery_coverage=$s.discovery_coverage;preflight=[pscustomobject]@{status='complete'};execution_plan=[pscustomobject]@{
      target_environment='Synthetic local test'; files=@([pscustomobject]@{path='artifact.txt';action='create';purpose='Synthetic delivery';scope_ids=@($s.scope.id)})
      commands=@([pscustomobject]@{command='None';effect='None';proof='Synthetic plan only'})
      mutations=@(@('Development-time','Runtime','External/system')|ForEach-Object{[pscustomobject]@{layer=$_;target='None';effect='None';basis=@('U1');rollback='Not applicable'}})
      effects_review=[pscustomobject]@{complete=$true;hidden_recommendations=@();hidden_behaviors=@();hidden_effects=@();surfaced='Pending fixture scope and protected source'}
    }}
    upsert=[pscustomobject]@{user_sources=$users;evidence=$s.evidence;decisions=$s.decisions;scope=$s.scope;technical_conclusions=$s.technical_conclusions;questions=@([pscustomobject]@{id='Q1';status='unknown';source='U4';remaining_facets=@()})}
    prepare_ready=[pscustomobject]@{scope_ids=@($s.scope.id);root=[pscustomobject]@{path='product';authority='recommendation'};read_only_inputs=@('materials/source.txt');rollback='Only remove proven newly created product artifacts.'}
  }
}

$fixture=Fixture
$initial=Patch $fixture 'initial'
Check 'complete patch compiles' ($initial.code -eq 0)
$initialAudit=@(Confirmation-Audit $initial.text)
Check 'initial confirmations are exposed for internal review' ($initialAudit.Count -eq 3)
Check 'confirmation audit uses literal quote not interpretation' ($initialAudit[0].literal_user_quote -ceq $fixture.upsert.user_sources[1].quote -and $initialAudit[0].literal_user_quote -cne $fixture.upsert.user_sources[1].meaning)
Check 'confirmation audit disclaims semantic validation' ($initial.text -match 'NOT semantic validation or user authorization')
$state=Get-Content -LiteralPath $initial.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'root recommendation has generated authority' ($state.write_boundary.project_root_provenance[0] -eq 'R-root' -and $state.write_boundary.project_root_status -eq 'recommended-pending')
Check 'relative plan becomes absolute inside root' ($state.write_boundary.planned_paths[0] -eq (Join-Path $OutputRoot 'product/artifact.txt'))
Check 'scope selection is bound once to baseline and envelope' (($state.authorization.scope_ids -join ',') -eq ($state.change_control.baseline.scope_ids -join ',') -and $state.authorization.scope_ids.Count -eq 4)
Check 'proof links are generated' ($state.execution_plan.scope_steps.Count -eq 4 -and $state.execution_plan.scope_steps[0].scope_id -eq 'S1')
Check 'quote is used verbatim when meaning omitted' ($state.user_sources[3].meaning -ceq 'Future volume is unknown.')
Check 'approval is not generated' ($state.authorization.state -eq 'pending' -and $null -eq $state.authorization.approval_source)
Check 'unknown is retained' ($state.questions[0].status -eq 'unknown')
Check 'record is not declared valid' ($state.preflight.execution_record.status -eq 'missing')
Check 'no product directory created' (-not(Test-Path -LiteralPath (Join-Path $OutputRoot 'product')))
$record=Run 'build_start_record.ps1' @('-StatePath',$initial.path,'-EvidenceRoot',(Join-Path $OutputRoot 'records')) 'record'
Check 'generated state feeds the existing builder' ($record.code -eq 0)
$ready=Run 'invoke_validation_gate.ps1' @('-Path',$record.path,'-ToStage','READY') 'ready'
Check 'actual existing READY gate passes' ($ready.code -eq 0)
$blocked=Run 'invoke_validation_gate.ps1' @('-Path',$record.path,'-ToStage','EXECUTION') 'execution'
Check 'actual EXECUTION gate still refuses pending approval' ($blocked.code -ne 0 -and $blocked.text -match 'not been approved')
$base=Get-Content -LiteralPath $record.path -Raw -Encoding UTF8|ConvertFrom-Json

$noop=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D1';status='confirmed'})}}) 'noop' $record.path
Check 'partial no-op accepted' ($noop.code -eq 0)
Check 'unchanged confirmations do not generate another audit' (@(Confirmation-Audit $noop.text).Count -eq 0)
$n=Get-Content -LiteralPath $noop.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'no-op preserves review and record' ($n.discovery_coverage.status -eq 'complete' -and $n.preflight.execution_record.status -eq 'valid')
Check 'parent hash is recorded' ($n.authoring.parent_sha256 -eq (Get-FileHash -LiteralPath $record.path).Hash)
Check 'snapshot path is unique' ($noop.path -ne $record.path)
$noopGate=Run 'invoke_validation_gate.ps1' @('-Path',$noop.path,'-ToStage','READY') 'noop-ready'
Check 'no-op remains accepted by actual READY gate' ($noopGate.code -eq 0)

$repeat=Patch $fixture 'repeat-complete-patch' $record.path
Check 'repeated complete patch accepted' ($repeat.code -eq 0)
$r=Get-Content -LiteralPath $repeat.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'repeated complete patch preserves generated record' ($r.preflight.execution_record.status -eq 'valid')

$update=Patch ([pscustomobject]@{upsert=[pscustomobject]@{evidence=@([pscustomobject]@{id='E1';claim='Additional structural observation; integrated behavior remains untested.'})}}) 'evidence-change' $record.path
Check 'incremental evidence accepted' ($update.code -eq 0)
$u=Get-Content -LiteralPath $update.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'unrelated decisions preserved' (($u.decisions|ConvertTo-Json -Depth 20 -Compress) -ceq ($base.decisions|ConvertTo-Json -Depth 20 -Compress))
Check 'evidence fields not supplied remain intact' ($u.evidence[0].method -eq $base.evidence[0].method -and $u.evidence.Count -eq 1)
Check 'unknown is not converted to a value' ($u.questions[0].status -eq 'unknown')
Check 'new evidence invalidates reviews and old record' ($u.discovery_coverage.status -eq 'open' -and $u.preflight.status -eq 'open' -and $u.preflight.execution_record.status -eq 'missing')
$reviewPatch=[pscustomobject]@{
  upsert=[pscustomobject]@{evidence=@([pscustomobject]@{id='E1';claim='Changed observation with an unfinished review.'})}
  set=[pscustomobject]@{discovery_coverage=[pscustomobject]@{review_methods=@('contract-slots')}}
}
$partialReview=Patch $reviewPatch 'partial-review-change' $record.path
Check 'partial review patch accepted' ($partialReview.code -eq 0)
$r=Get-Content -LiteralPath $partialReview.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'partial review cannot inherit complete coverage after change' ($r.discovery_coverage.status -eq 'open')

$protect=Patch ([pscustomobject]@{prepare_ready=[pscustomobject]@{scope_ids=@('S1','S2','S3','S4');read_only_inputs=@()}}) 'retain-originals' $record.path
Check 'ready update accepted without repeated root' ($protect.code -eq 0)
$p=Get-Content -LiteralPath $protect.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'empty input list cannot drop originals' ($p.write_boundary.read_only_inputs.Count -eq 1 -and $p.write_boundary.read_only_inputs[0] -eq $original)

$partial=Patch ([pscustomobject]@{upsert=[pscustomobject]@{user_sources=@([pscustomobject]@{id='U1';quote='I have a rough idea.';authority='context'})}}) 'partial'
Check 'incomplete draft can be saved' ($partial.code -eq 0)
$blocked=Run 'invoke_validation_gate.ps1' @('-Path',$partial.path,'-ToStage','DECISION') 'partial-gate'
Check 'incomplete draft cannot enter DECISION' ($blocked.code -ne 0 -and $blocked.text -match 'not complete')

foreach($case in @('authorization','duplicate','missing-reference','mixed-reference-errors','path-escape','ambiguous-plan','invalid-path-base','workspace-plan-escape','protected-plan','wrong-root-source','unconfirmed-root','stale-hash','approved-state','record-validity')){
  $v=[pscustomobject]@{}; $basePath=$record.path; $hash=''; $pattern=''
  switch($case){
    'authorization' {$v=[pscustomobject]@{set=[pscustomobject]@{authorization=[pscustomobject]@{state='approved'}}};$pattern='not editable'}
    'duplicate' {$v=[pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D1'},[pscustomobject]@{id='D1'})}};$pattern='Duplicate ID'}
    'missing-reference' {$v=[pscustomobject]@{upsert=[pscustomobject]@{scope=@([pscustomobject]@{id='S1';provenance=@('U-absent')})}};$pattern='missing item'}
    'mixed-reference-errors' {$v=[pscustomobject]@{upsert=[pscustomobject]@{scope=@([pscustomobject]@{id='S1';provenance=@('S2','U-absent')})}};$pattern='invalid reference type'}
    'path-escape' {$v=Fixture;$v.set.execution_plan.files[0].path='../outside.txt';$pattern='out-of-root'}
    'ambiguous-plan' {$v=Fixture;$v.set.execution_plan.files[0].path='product/artifact.txt';$pattern='Ambiguous relative plan'}
    'invalid-path-base' {$v=Fixture;$v.set.execution_plan | Add-Member -NotePropertyName file_path_base -NotePropertyValue 'guessed';$pattern='file_path_base must be'}
    'workspace-plan-escape' {$v=Fixture;$v.set.execution_plan | Add-Member -NotePropertyName file_path_base -NotePropertyValue 'workspace';$pattern='out-of-root'}
    'protected-plan' {$v=Fixture;$v.prepare_ready.read_only_inputs=@('product/artifact.txt');$pattern='overlaps protected input'}
    'wrong-root-source' {$v=Fixture;$v.prepare_ready.root=[pscustomobject]@{path='product';authority='user';source='S1'};$pattern='invalid reference type'}
    'unconfirmed-root' {$v=Fixture;$v.upsert.decisions[0].status='open';$v.prepare_ready.root=[pscustomobject]@{path='product';authority='decision';source='D1'};$pattern='not confirmed'}
    'stale-hash' {$hash='0000';$pattern='must match'}
    'approved-state' {$s=$base|ConvertTo-Json -Depth 60|ConvertFrom-Json;$s.authorization.state='approved';$basePath=Join-Path $OutputRoot 'approved-input.json';Save $basePath $s;$pattern='cannot alter approved'}
    'record-validity' {$v=[pscustomobject]@{set=[pscustomobject]@{preflight=[pscustomobject]@{execution_record=[pscustomobject]@{status='valid'}}}};$pattern='Only preflight.status'}
  }
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $bad=Patch $v $case $basePath $hash
  Check "$case is rejected for the intended reason" ($bad.code -ne 0 -and $bad.text -match $pattern)
  Check "$case creates no state snapshot" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
  if($case -eq 'mixed-reference-errors'){Check 'related diagnostics are returned together' ($bad.text -match 'missing item' -and $bad.text -match 'invalid reference type')}
}
foreach($pathBase in @('workspace','project-root','absolute')) {
  $v=Fixture
  $v.set.execution_plan.files[0].path='product/artifact.txt'
  $expected=Join-Path $OutputRoot 'product/artifact.txt'
  if($pathBase -eq 'absolute') { $v.set.execution_plan.files[0].path=$expected }
  else { $v.set.execution_plan | Add-Member -NotePropertyName file_path_base -NotePropertyValue $pathBase }
  if($pathBase -eq 'project-root') { $expected=Join-Path $OutputRoot 'product/product/artifact.txt' }
  $r=Patch $v "explicit-$pathBase"
  Check "explicit $pathBase accepted" ($r.code -eq 0)
  $s=Get-Content -LiteralPath $r.path -Raw -Encoding UTF8 | ConvertFrom-Json
  Check "explicit $pathBase resolves exactly" ($s.execution_plan.files[0].path -eq $expected -and $s.write_boundary.planned_paths[0] -eq $expected)
}
$doc=Patch (Fixture) 'document-route' '' '' 'non-software'
Check 'document route uses the same state API' ($doc.code -eq 0 -and (Get-Content -LiteralPath $doc.path -Raw -Encoding UTF8|ConvertFrom-Json).route -eq 'non-software')

. (Join-Path $StandardRoot 'scripts/state_validation_common.ps1')
function Clone($Value) { $Value | ConvertTo-Json -Depth 60 | ConvertFrom-Json }
function Decision([string]$Id,[string]$Axis) {
  [pscustomobject]@{id=$Id;axis=$Axis;status='open';choice=$null;exposed=$false;trigger='user:U1';depends_on=@();approval_source=$null;recommendation=$null}
}
$continuity=Clone $base
$continuity.decisions=@((Decision 'D10' 'handling-mode'),(Decision 'D20' 'feedback-channel')) + @($base.decisions)
$continuity.blocking_items=@([pscustomobject]@{id='B10';kind='decision';status='open';source_ids=@('D10');statement='Handling is undecided.'})
$continuity.user_sources+= [pscustomobject]@{id='U5';quote='Replace the handling question with outcome-handling and defer feedback.';meaning='Explicit correction and deferral.';authority='requirement'}
$continuityPath=Join-Path $OutputRoot 'continuity-parent.json'
Save $continuityPath $continuity
$continuityHash=(Get-FileHash -LiteralPath $continuityPath).Hash
foreach($case in @('partial-literal','bulk-clear','missing-literal','changed-confirmation')) {
  $quote=if($case -eq 'bulk-clear'){'Both just-presented recommendations are approved.'}else{'Use the basic path for now.'}
  $user=[pscustomobject]@{id='U6';quote=$quote;meaning='This authored summary overstates the user answer.';authority='requirement'}
  if($case -eq 'missing-literal'){$user.quote=$null}
  $rows=@([pscustomobject]@{id='D10';status='confirmed';choice='automatic-handling';approval_source='U6';exposed=$true})
  if($case -eq 'bulk-clear'){$rows+= [pscustomobject]@{id='D20';status='confirmed';choice='local-feedback';approval_source='U6';exposed=$true}}
  $result=Patch ([pscustomobject]@{upsert=[pscustomobject]@{user_sources=@($user);decisions=$rows}}) "answer-audit-$case" $continuityPath
  $audit=@(Confirmation-Audit $result.text)
  Check "$case remains a non-authorizing draft" ($result.code -eq 0 -and $audit.Count -eq $rows.Count -and (Get-Content -LiteralPath $result.path -Raw -Encoding UTF8|ConvertFrom-Json).authorization.state -eq 'pending')
  Check "$case audit preserves literal source" ($audit[0].literal_user_quote -ceq $user.quote -and $audit[0].source_id -eq 'U6' -and $audit[0].authored_choice -eq 'automatic-handling')
  if($case -ne 'bulk-clear'){
    $s=Get-Content -LiteralPath $result.path -Raw -Encoding UTF8|ConvertFrom-Json
    Check "$case leaves unanswered sibling open" (($s.decisions|Where-Object id -eq 'D20').status -eq 'open')
  }
  if($case -eq 'changed-confirmation'){
    $r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';choice='manual-handling'})}}) 'changed-choice-audit' $result.path
    $a=@(Confirmation-Audit $r.text)
    Check 'changed confirmation is audited with its previous choice' ($r.code -eq 0 -and $a.Count -eq 1 -and $a[0].previous_choice -eq 'automatic-handling' -and $a[0].authored_choice -eq 'manual-handling')
  }
}
foreach($case in @('unchanged','label-refinement','new-independent','partial-answer','axis-reused','decision-removed','retire-without-source','retire-without-reason','missing-source','evidence-is-not-rejection','user-deferral','user-replacement','replacement-missing','replacement-self','replacement-retired','evidence-non-applicability','parent-non-applicability','unconfirmed-parent','blocker-reassigned','blocker-removed','blocker-closed','resolved-blocker')) {
  $s=Clone $continuity
  $pattern=''
  switch($case) {
    'label-refinement' {$s.decisions[0] | Add-Member -NotePropertyName label -NotePropertyValue 'How should handling work?'}
    'new-independent' {$s.decisions+=Decision 'D30' 'time-allocation'}
    'partial-answer' {$s.decisions[0].status='confirmed';$s.decisions[0].choice='manual';$s.decisions[0].approval_source='U1'}
    'axis-reused' {$s.decisions[0].axis='time-allocation';$pattern='axis is immutable'}
    'decision-removed' {$s.decisions=@($s.decisions[1]);$pattern='Decision disappeared'}
    'retire-without-source' {$s.decisions[0].status='rejected';$pattern='retirement needs'}
    'retire-without-reason' {$s.decisions[0].status='deferred';$s.decisions[0]|Add-Member -NotePropertyName resolution_source -NotePropertyValue 'U5';$pattern='retirement needs'}
    'missing-source' {$s.decisions[0].status='deferred';$s.decisions[0]|Add-Member -NotePropertyMembers @{resolution_source='U-absent';reason='Not needed now.'};$pattern='retirement needs'}
    'evidence-is-not-rejection' {$s.decisions[0].status='rejected';$s.decisions[0]|Add-Member -NotePropertyMembers @{resolution_source='E1';reason='Evidence cannot choose rejection.'};$pattern='retirement needs'}
    'user-deferral' {$s.decisions[1].status='deferred';$s.decisions[1]|Add-Member -NotePropertyMembers @{resolution_source='U5';reason='User deferred this choice.'}}
    {$_ -in @('user-replacement','replacement-missing','replacement-self','replacement-retired')} {
      $s.decisions+=Decision 'D30' 'outcome-handling'
      $s.decisions[0].status='superseded';$s.decisions[0]|Add-Member -NotePropertyMembers @{resolution_source='U5';reason='User corrected the original question.';superseded_by=@('D30')}
      if($case -eq 'replacement-missing'){$s.decisions[0].superseded_by=@('D-absent');$pattern='no active replacement'}
      if($case -eq 'replacement-self'){$s.decisions[0].superseded_by=@('D10');$pattern='no active replacement'}
      if($case -eq 'replacement-retired'){$s.decisions[-1].status='rejected';$pattern='no active replacement'}
    }
    {$_ -in @('evidence-non-applicability','parent-non-applicability','unconfirmed-parent')} {
      $s.decisions[0].status='not-applicable';$s.decisions[0]|Add-Member -NotePropertyMembers @{resolution_source='E1';reason='The retained evidence makes this branch inapplicable.'}
      if($case -ne 'evidence-non-applicability'){$s.decisions[0].resolution_source='D20'}
      if($case -eq 'parent-non-applicability'){$s.decisions[1].status='confirmed';$s.decisions[1].choice='local';$s.decisions[1].approval_source='U1'}
      if($case -eq 'unconfirmed-parent'){$pattern='retirement needs'}
    }
    'blocker-reassigned' {$s.blocking_items[0].source_ids=@('D20');$pattern='blocker lost its original link'}
    'blocker-removed' {$s.blocking_items=@();$pattern='blocker lost its original link'}
    'blocker-closed' {$s.blocking_items[0].status='resolved';$pattern='blocker lost its original link'}
    'resolved-blocker' {$s.decisions[0].status='confirmed';$s.decisions[0].choice='manual';$s.decisions[0].approval_source='U1';$s.blocking_items[0].status='resolved'}
  }
  $issues=@(Get-AllredDecisionEvolutionFailures -PreviousState $continuity -State $s)
  Check "evolution $case" $(if($pattern){($issues -join "`n") -match $pattern}else{$issues.Count -eq 0})
}

foreach($shape in @('basis-only','source-without-kind','single-source','mixed-links')) {
  $parent=Clone $continuity
  $parent.blocking_items=@([pscustomobject]@{id='B10';status='open';basis=@('D10')})
  if($shape -eq 'source-without-kind') {
    $parent.blocking_items=@([pscustomobject]@{id='B10';status='open';source_ids=@('D10')})
  } elseif($shape -eq 'single-source') {
    $parent.blocking_items=@([pscustomobject]@{id='B10';status='open';source='D10'})
  } elseif($shape -eq 'mixed-links') {
    $parent.blocking_items[0] | Add-Member -NotePropertyName source_ids -NotePropertyValue @('D20')
    $parent.blocking_items[0] | Add-Member -NotePropertyName source -NotePropertyValue 'D10'
  }
  foreach($change in @('unchanged','removed','closed','reassigned','kind-reassigned','normalized','resolved')) {
    $s=Clone $parent
    switch($change) {
      'removed' {$s.blocking_items=@()}
      'closed' {$s.blocking_items[0].status='resolved'}
      'reassigned' {$s.blocking_items=@([pscustomobject]@{id='B10';status='open';source_ids=@('D3')})}
      'kind-reassigned' {$s.blocking_items[0]|Add-Member -NotePropertyName kind -NotePropertyValue 'evidence'}
      'normalized' {
        $links=if($shape -eq 'mixed-links'){@('D10','D20')}else{@('D10')}
        $s.blocking_items=@([pscustomobject]@{id='B10';kind='decision';status='open';source_ids=$links})
      }
      'resolved' {
        foreach($d in $s.decisions | Where-Object id -in @('D10','D20')) {$d.status='confirmed';$d.choice='manual';$d.approval_source='U1'}
        $s.blocking_items[0].status='resolved'
      }
    }
    $issues=@(Get-AllredDecisionEvolutionFailures -PreviousState $parent -State $s)
    $reject=$change -in @('removed','closed','reassigned','kind-reassigned')
    Check "blocker shape $shape $change" $(if($reject){($issues -join "`n") -match 'blocker lost its original link'}else{$issues.Count -eq 0})
  }
  $file=Join-Path $OutputRoot "$shape-parent.json"; Save $file $parent
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $rejected=Patch ([pscustomobject]@{upsert=[pscustomobject]@{blocking_items=@([pscustomobject]@{id='B10';status='resolved'})}}) "$shape-close" $file
  Check "$shape blocked by updater" ($rejected.code -ne 0 -and $rejected.text -match 'blocker lost its original link')
  Check "$shape rejection creates no snapshot" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
}

$renamePatch=[pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';axis='time-allocation'})}}
$before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
$rejected=Patch $renamePatch 'decision-overwrite' $continuityPath
Check 'updater rejects decision overwrite' ($rejected.code -ne 0 -and $rejected.text -match 'axis is immutable')
Check 'overwrite creates no snapshot' (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
$labelPatch=[pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';label='Clearer wording for handling.'},(Decision 'D30' 'time-allocation'))}}
$refined=Patch $labelPatch 'label-and-new-question' $continuityPath
Check 'updater accepts wording and new independent question' ($refined.code -eq 0)
$rs=Get-Content -LiteralPath $refined.path -Raw -Encoding UTF8 | ConvertFrom-Json
Check 'refinement retains old question and sibling' ($rs.decisions[0].axis -eq 'handling-mode' -and $rs.decisions[1].axis -eq 'feedback-channel' -and $rs.decisions[1].status -eq 'open' -and $rs.decisions.Count -eq $continuity.decisions.Count+1)
$fg=Run 'validate_decision_frontier.ps1' @('-Path',$refined.path) 'refined-frontier'
Check 'frontier accepts legitimate linked evolution' ($fg.code -eq 0)
$replacementPatch=[pscustomobject]@{upsert=[pscustomobject]@{
  decisions=@([pscustomobject]@{id='D10';status='superseded';resolution_source='U5';reason='The user corrected the original question.';superseded_by=@('D30')},(Decision 'D30' 'outcome-handling'))
  blocking_items=@([pscustomobject]@{id='B10';status='resolved'})
}}
$replacement=Patch $replacementPatch 'explicit-user-correction' $continuityPath
Check 'updater accepts source-backed replacement' ($replacement.code -eq 0)
$rg=Run 'validate_decision_frontier.ps1' @('-Path',$replacement.path) 'replacement-frontier'
Check 'frontier accepts retained replacement history' ($rg.code -eq 0)
foreach($case in @('unsupported-retirement','detached-blocker')) {
  $patch=if($case -eq 'unsupported-retirement') { [pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D20';status='deferred'})}} } else { [pscustomobject]@{upsert=[pscustomobject]@{blocking_items=@([pscustomobject]@{id='B10';source_ids=@('D20')})}} }
  $pattern=if($case -eq 'unsupported-retirement'){'retirement needs'}else{'blocker lost its original link'}
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $rejected=Patch $patch $case $continuityPath
  Check "$case rejected by updater" ($rejected.code -ne 0 -and $rejected.text -match $pattern)
  Check "$case creates no snapshot" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
}

foreach($case in @('direct-axis-change','direct-removal','wrong-parent-hash','missing-parent','wrong-project','self-parent')) {
  $s=Clone $rs
  $pattern=''
  switch($case) {
    'direct-axis-change' {$s.decisions[0].axis='unrelated-mode';$pattern='axis is immutable'}
    'direct-removal' {$s.decisions=@($s.decisions|Where-Object id -ne 'D20');$pattern='Decision disappeared'}
    'wrong-parent-hash' {$s.authoring.parent_sha256='0000';$pattern='Parent state hash does not match'}
    'missing-parent' {$s.authoring.parent_path=Join-Path $OutputRoot 'not-present.json';$pattern='continuity could not be verified'}
    'wrong-project' {$s.state_id='APS-other-project';$pattern='different project'}
    'self-parent' {$s.authoring.parent_path=Join-Path $OutputRoot "$case.json";$pattern='own parent'}
  }
  $file=Join-Path $OutputRoot "$case.json";Save $file $s
  $r=Run 'validate_decision_frontier.ps1' @('-Path',$file) $case
  Check "$case blocked by actual gate" ($r.code -ne 0 -and $r.text -match $pattern)
  if ($case -eq 'direct-axis-change') {
    $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
    $laundered=Patch ([pscustomobject]@{}) 'cannot-advance-broken-parent' $file
    Check 'empty update cannot hide a broken input transition' ($laundered.code -ne 0 -and $laundered.text -match 'axis is immutable')
    Check 'broken input creates no snapshot' (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
  }
}
$factParent=Clone $continuity
$factParent.questions=@(
  [pscustomobject]@{id='Q10';axis='available-source';label='Available source and its owner';status='open';source='U1';remaining_facets=@('source','owner')},
  [pscustomobject]@{id='Q20';axis='historical-volume';status='unknown';source='U4';remaining_facets=@()}
)
$factParent.user_sources+= [pscustomobject]@{id='U90';quote='The source is guide.md. The owner is the records team.';meaning='Source and owner supplied.';authority='context'}
$sourceReceipt=[pscustomobject]@{facet='source';status='answered';source='U90';quote='The source is guide.md.'}
$ownerReceipt=[pscustomobject]@{facet='owner';status='answered';source='U90';quote='The owner is the records team.'}
$factPath=Join-Path $OutputRoot 'factual-parent.json'; Save $factPath $factParent
$factHash=(Get-FileHash -LiteralPath $factPath).Hash
foreach($case in @('unchanged','removed-open','removed-unknown','axis-reused','axis-erased','label-refined','partial-answer','confirmed-with-remainder','unknown-with-remainder','not-applicable-with-remainder','resolved','unknown-preserved','new-question','legacy-axis')) {
  $s=Clone $factParent; $pattern=''
  switch($case) {
    'removed-open' {$s.questions=@($s.questions[1]);$pattern='Factual question disappeared'}
    'removed-unknown' {$s.questions=@($s.questions[0]);$pattern='Factual question disappeared'}
    'axis-reused' {$s.questions[0].axis='unrelated-fact';$pattern='Factual question axis is immutable'}
    'axis-erased' {$s.questions[0].PSObject.Properties.Remove('axis');$pattern='Factual question axis is immutable'}
    'label-refined' {$s.questions[0].label='Clearer question wording'}
    'partial-answer' {$s.questions[0].remaining_facets=@('owner');$s.questions[0]|Add-Member facet_resolutions @((Clone $sourceReceipt))}
    'confirmed-with-remainder' {$s.questions[0].status='confirmed';$pattern='Terminal factual question retains unanswered facets'}
    'unknown-with-remainder' {$s.questions[0].status='unknown';$pattern='Terminal factual question retains unanswered facets'}
    'not-applicable-with-remainder' {$s.questions[0].status='not-applicable';$pattern='Terminal factual question retains unanswered facets'}
    'resolved' {$s.questions[0].status='confirmed';$s.questions[0].remaining_facets=@();$s.questions[0]|Add-Member facet_resolutions @((Clone $sourceReceipt),(Clone $ownerReceipt))}
    'unknown-preserved' {$s.questions[0].remaining_facets=@('owner');$s.questions[0]|Add-Member facet_resolutions @((Clone $sourceReceipt));$s.questions[1].status='unknown'}
    'new-question' {$s.questions+=[pscustomobject]@{id='Q30';axis='new-fact';status='open';remaining_facets=@()}}
    'legacy-axis' {$s=Clone $continuity}
  }
  $parent=if($case -eq 'legacy-axis'){$continuity}else{$factParent}
  $issues=@(Get-AllredStateEvolutionFailures -PreviousState $parent -State $s)
  Check "factual continuity $case" $(if($pattern){($issues -join "`n") -match $pattern}else{$issues.Count -eq 0})
}
foreach($case in @('axis-reused','closed-with-remainder')) {
  $row=if($case -eq 'axis-reused'){[pscustomobject]@{id='Q10';axis='unrelated-fact'}}else{[pscustomobject]@{id='Q10';status='confirmed'}}
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{questions=@($row)}}) "factual-$case" $factPath
  Check "updater rejects factual $case" ($r.code -ne 0 -and $r.text -match 'Factual question axis is immutable|Terminal factual question retains unanswered facets')
  Check "factual $case writes no snapshot" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)
}
$partial=Patch ([pscustomobject]@{upsert=[pscustomobject]@{questions=@([pscustomobject]@{id='Q10';remaining_facets=@('owner');facet_resolutions=@($sourceReceipt)})}}) 'factual-partial' $factPath
Check 'partial factual answer accepted without closing sibling' ($partial.code -eq 0)
$s=Get-Content -LiteralPath $partial.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'partial factual answer preserves unknown and open meanings' ($s.questions[0].status -eq 'open' -and $s.questions[0].remaining_facets[0] -eq 'owner' -and $s.questions[1].status -eq 'unknown')
Check 'new updater stamps facet accounting' ($s.authoring.facet_accounting_version -eq 1)
$s.questions=@($s.questions[1])
$broken=Join-Path $OutputRoot 'factual-direct-removal.json';Save $broken $s
$r=Run 'validate_decision_frontier.ps1' @('-Path',$broken) 'factual-direct-removal'
Check 'actual gate rejects direct factual removal' ($r.code -ne 0 -and $r.text -match 'Factual question disappeared')
$fresh=Patch ([pscustomobject]@{upsert=[pscustomobject]@{questions=@([pscustomobject]@{id='Q90';status='confirmed';remaining_facets=@('unanswered')})}}) 'initial-contradictory-question'
Check 'initial draft cannot close an explicitly incomplete question' ($fresh.code -ne 0 -and $fresh.text -match 'Terminal factual question retains unanswered facets')
Check 'factual parent remains unchanged' ((Get-FileHash -LiteralPath $factPath).Hash -eq $factHash)
Check 'continuity parent remains unchanged' ((Get-FileHash -LiteralPath $continuityPath).Hash -eq $continuityHash)
Check 'original source remains unchanged' ((Get-FileHash -LiteralPath $original).Hash -eq $originalHash)

# Account for every removed part without imposing another question on the user.
foreach($case in @('clear-all','partial-missing','unrelated-receipt','duplicate-receipt','wrong-quote','missing-source','evidence-answer','evidence-missing-reason','unknown-answer','parent-not-applicable','parent-unconfirmed','parent-cannot-answer','transfer-q','transfer-d','transfer-inactive','transfer-no-facet','transfer-self')) {
  $s=Clone $factParent
  $s.questions[0].remaining_facets=@()
  $s.questions[0].status='confirmed'
  $s.questions[0]|Add-Member facet_resolutions @((Clone $sourceReceipt),(Clone $ownerReceipt))
  $pattern=''
  switch($case){
    'clear-all' {$s.questions[0].facet_resolutions=@();$pattern='Removed pending facet needs one'}
    'partial-missing' {$s.questions[0].status='open';$s.questions[0].remaining_facets=@('owner');$s.questions[0].facet_resolutions=@();$pattern='Removed pending facet needs one'}
    'unrelated-receipt' {$s.questions[0].facet_resolutions[1].facet='another-fact';$pattern='Removed pending facet needs one'}
    'duplicate-receipt' {$s.questions[0].facet_resolutions+=Clone $ownerReceipt;$pattern='Removed pending facet needs one'}
    'wrong-quote' {$s.questions[0].facet_resolutions[1].quote='The owner is operations.';$pattern='exact quote'}
    'missing-source' {$s.questions[0].facet_resolutions[1].source='U404';$pattern='missing or ineligible'}
    'evidence-answer' {$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='answered';source='E1';reason='Named in the inspected source.'}}
    'evidence-missing-reason' {$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='answered';source='E1'};$pattern='needs a reason'}
    'unknown-answer' {$s.user_sources+=[pscustomobject]@{id='U91';quote='The owner is unknown.';meaning='Unknown owner.';authority='context'};$s.questions[0].status='unknown';$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='unknown';source='U91';quote='The owner is unknown.'}}
    'parent-not-applicable' {$s.decisions[0].status='confirmed';$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='not-applicable';source=$s.decisions[0].id;reason='The confirmed parent removes this branch.'}}
    'parent-unconfirmed' {$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='not-applicable';source=$s.decisions[0].id;reason='Unconfirmed parent.'};$pattern='missing or ineligible'}
    'parent-cannot-answer' {$s.decisions[0].status='confirmed';$s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='answered';source=$s.decisions[0].id;reason='A preference is not an observed fact.'};$pattern='missing or ineligible'}
  }
  if($case -like 'transfer-*'){
    $target=[pscustomobject]@{id='Q30';axis='unanswered-owner';status='open';remaining_facets=@('owner')}
    if($case -eq 'transfer-d'){$target.id='D30';$s.decisions+= $target}else{$s.questions+=$target}
    $s.questions[0].facet_resolutions[1]=[pscustomobject]@{facet='owner';status='transferred';target=$target.id}
    switch($case){
      'transfer-inactive' {$target.status='confirmed';$pattern='Transferred facet needs another pending'}
      'transfer-no-facet' {$target.remaining_facets=@();$pattern='Transferred facet needs another pending'}
      'transfer-self' {$s.questions[0].facet_resolutions[1].target='Q10';$pattern='Transferred facet needs another pending'}
    }
  }
  $issues=@(Get-AllredStateEvolutionFailures -PreviousState $factParent -State $s)
  Check "removed facet $case" $(if($pattern){($issues -join "`n") -match $pattern}else{$issues.Count -eq 0})
  if($case -in @('clear-all','wrong-quote','unknown-answer','transfer-q','transfer-no-facet')){
    $patch=[pscustomobject]@{upsert=[pscustomobject]@{questions=$s.questions;decisions=$s.decisions;user_sources=$s.user_sources}}
    $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
    $r=Patch $patch "facet-updater-$case" $factPath
    Check "real updater removed facet $case" $(if($pattern){$r.code -ne 0 -and $r.text -match $pattern}else{$r.code -eq 0})
    if($pattern){Check "rejected facet $case writes nothing" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)}
  }
}
$legacy=Clone $factParent
$legacy.questions[0].status='confirmed';$legacy.questions[0].remaining_facets=@()
$legacy|Add-Member authoring ([pscustomobject]@{parent_path=$factPath;parent_sha256=$factHash}) -Force
$legacyPath=Join-Path $OutputRoot 'legacy-facet-history.json';Save $legacyPath $legacy
Check 'unversioned history keeps former checks' (@(Get-AllredStateParentFailures -State $legacy -StatePath $legacyPath).Count -eq 0)
$legacy.authoring|Add-Member facet_accounting_version 1
$taggedPath=Join-Path $OutputRoot 'tagged-facet-loss.json';Save $taggedPath $legacy
Check 'versioned parent rejects direct facet loss' ((@(Get-AllredStateParentFailures -State $legacy -StatePath $taggedPath) -join "`n") -match 'Removed pending facet needs one')
$r=Run 'validate_decision_frontier.ps1' @('-Path',$taggedPath) 'tagged-facet-loss'
Check 'actual frontier rejects direct facet loss' ($r.code -ne 0 -and $r.text -match 'Removed pending facet needs one')
$r=Patch ([pscustomobject]@{}) 'cannot-launder-facet-loss' $taggedPath
Check 'empty update cannot launder versioned facet loss' ($r.code -ne 0 -and $r.text -match 'Removed pending facet needs one')
Check 'facet test source remains unchanged' ((Get-FileHash -LiteralPath $factPath).Hash -eq $factHash)

$handoff=Clone $factParent
$handoff.questions[0].status='confirmed';$handoff.questions[0].remaining_facets=@()
$handoff.questions[0]|Add-Member facet_resolutions @((Clone $sourceReceipt),[pscustomobject]@{facet='owner';status='transferred';target='D30'})
$handoff.decisions+=[pscustomobject]@{id='D30';axis='owner-follow-up';status='open';remaining_facets=@('owner')}
Check 'Q to D handoff is accounted' (@(Get-AllredStateEvolutionFailures -PreviousState $factParent -State $handoff).Count -eq 0)
$handoffPath=Join-Path $OutputRoot 'facet-handoff-parent.json';Save $handoffPath $handoff
foreach($case in @('drop-after-handoff','answer-after-handoff','self-parent','transfer-onward')){
  $s=Clone $handoff
  $d=@($s.decisions|Where-Object id -eq 'D30')[0]
  $d.remaining_facets=@()
  $pattern=''
  switch($case){
    'drop-after-handoff' {$pattern='Removed pending facet needs one'}
    'answer-after-handoff' {$d|Add-Member facet_resolutions @((Clone $ownerReceipt));$d.status='confirmed';$d|Add-Member choice 'The records team';$d|Add-Member approval_source 'U90'}
    'self-parent' {$d.status='confirmed';$d|Add-Member facet_resolutions @([pscustomobject]@{facet='owner';status='not-applicable';source='D30';reason='Circular self-justification.'});$pattern='missing or ineligible'}
    'transfer-onward' {$s.questions+=[pscustomobject]@{id='Q30';axis='owner-follow-up';status='open';remaining_facets=@('owner')};$d|Add-Member facet_resolutions @([pscustomobject]@{facet='owner';status='transferred';target='Q30'})}
  }
  $issues=@(Get-AllredStateEvolutionFailures -PreviousState $handoff -State $s)
  Check "decision facet $case" $(if($pattern){($issues -join "`n") -match $pattern}else{$issues.Count -eq 0})
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{questions=$s.questions;decisions=$s.decisions}}) $case $handoffPath
  Check "real handoff update $case" $(if($pattern){$r.code -ne 0 -and $r.text -match $pattern}else{$r.code -eq 0})
  if($pattern){Check "rejected handoff $case writes nothing" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before)}
}

# Decision-backed bookkeeping uses source links, never scenario text or a sibling answer.
# Completion is checked on the current candidate, so an older inconsistency can be repaired.
$completionParent=Clone $continuity
$completionParent.decisions[0]|Add-Member remaining_facets @('handling','retention')
$completionParent.user_sources+=[pscustomobject]@{id='U94';quote='Use manual handling and retain every prior version.';meaning='Complete handling and retention answer.';authority='requirement'}
$completionPath=Join-Path $OutputRoot 'completion-parent.json';Save $completionPath $completionParent
$completionHash=(Get-FileHash -LiteralPath $completionPath).Hash
$completeReceipts=@(
  [pscustomobject]@{facet='handling';status='answered';source='U94';quote='Use manual handling'},
  [pscustomobject]@{facet='retention';status='answered';source='U94';quote='retain every prior version'}
)
foreach($status in @('open','waiting','investigating','proposed','conflict','deferred','rejected','not-applicable','superseded','confirmed')) {
  $s=Clone $completionParent
  $s.decisions[0].status=$status
  $file=Join-Path $OutputRoot "completion-read-$status.json";Save $file $s
  $errorText=''
  try {$null=Read-AllredProjectState -Path $file}catch{$errorText=$_.Exception.Message}
  Check "completion reader $status" $(if($status -eq 'confirmed'){$errorText -match 'Confirmed decision retains unanswered facets'}else{-not $errorText})
}
foreach($case in @('retain-partial','resolve-complete','confirmed-with-remainder','receipt-with-remainder','clear-without-source','transfer-before-confirming')) {
  $decision=[pscustomobject]@{id='D10';status='confirmed';choice='Manual handling; every prior version retained.';approval_source='U94';exposed=$true}
  $patch=[pscustomobject]@{upsert=[pscustomobject]@{decisions=@($decision)}}
  $pattern=''
  switch($case) {
    'retain-partial' {$decision.status='open';$decision|Add-Member remaining_facets @('retention');$decision|Add-Member facet_resolutions @($completeReceipts[0])}
    'resolve-complete' {$decision|Add-Member remaining_facets @();$decision|Add-Member facet_resolutions $completeReceipts}
    'confirmed-with-remainder' {$pattern='Confirmed decision retains unanswered facets'}
    'receipt-with-remainder' {$decision|Add-Member facet_resolutions $completeReceipts;$pattern='Confirmed decision retains unanswered facets'}
    'clear-without-source' {$decision|Add-Member remaining_facets @();$pattern='Removed pending facet needs one'}
    'transfer-before-confirming' {
      $decision.choice='Manual handling; retention still undecided in D30.'
      $decision|Add-Member remaining_facets @()
      $decision|Add-Member facet_resolutions @($completeReceipts[0],[pscustomobject]@{facet='retention';status='transferred';target='D30'})
      $target=Decision 'D30' 'retention-policy';$target|Add-Member remaining_facets @('retention')
      $patch.upsert.decisions+=$target
    }
  }
  $before=@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count
  $r=Patch $patch "completion-$case" $completionPath
  Check "completion updater $case" $(if($pattern){$r.code -ne 0 -and $r.text -match $pattern}else{$r.code -eq 0})
  if($pattern){Check "completion rejection $case writes nothing" (@(Get-ChildItem -LiteralPath (Join-Path $OutputRoot 'control') -Directory).Count -eq $before);continue}
  $s=Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json
  Check "completion $case preserves sibling and authority" ($s.decisions[1].status -eq 'open' -and $s.authorization.state -eq 'pending')
  if($case -eq 'resolve-complete'){Check 'full answer settles both facets without new user input' ($s.decisions[0].status -eq 'confirmed' -and $s.decisions[0].remaining_facets.Count -eq 0 -and $s.user_sources.Count -eq $completionParent.user_sources.Count)}
  if($case -eq 'retain-partial'){Check 'partial answer retains exact remainder' ($s.decisions[0].status -eq 'open' -and $s.decisions[0].remaining_facets[0] -eq 'retention')}
  if($case -eq 'transfer-before-confirming'){Check 'closed parent cannot lose transferred choice' ($s.decisions[-1].status -eq 'open' -and $s.decisions[-1].remaining_facets[0] -eq 'retention')}
}
$inconsistent=Clone $completionParent
$inconsistent.decisions[0].status='confirmed';$inconsistent.decisions[0].choice='Manual handling; every prior version retained.';$inconsistent.decisions[0].approval_source='U94'
$inconsistent.decisions[0]|Add-Member facet_resolutions $completeReceipts
$inconsistentPath=Join-Path $OutputRoot 'completion-legacy-inconsistent.json';Save $inconsistentPath $inconsistent
foreach($script in @('validate_decision_frontier.ps1','validate_ready_scope.ps1','validate_stage_transition.ps1')) {
  $arguments=@('-Path',$inconsistentPath)
  if($script -eq 'validate_stage_transition.ps1'){$arguments+=@('-ToStage','DECISION')}
  $r=Run $script $arguments "completion-gate-$script"
  Check "current $script rejects old contradictory confirmation" ($r.code -ne 0 -and $r.text -match 'Confirmed decision retains unanswered facets')
}
$r=Patch ([pscustomobject]@{}) 'completion-noop-cannot-launder' $inconsistentPath
Check 'no-op cannot certify old contradictory confirmation' ($r.code -ne 0 -and $r.text -match 'Confirmed decision retains unanswered facets')
$r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';remaining_facets=@()})}}) 'completion-repair-old' $inconsistentPath
Check 'old contradiction repaired from existing receipts' ($r.code -eq 0)
$s=Read-AllredProjectState -Path $r.path
Check 'repair retains original answer and pending sibling' ($s.decisions[0].choice -eq $inconsistent.decisions[0].choice -and $s.decisions[1].status -eq 'open' -and $s.authoring.parent_path -eq $inconsistentPath -and $s.authorization.state -eq 'pending')
$r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';status='open';choice=$null;approval_source=$null})}}) 'completion-reopen-old' $inconsistentPath
Check 'old contradiction can instead preserve unanswered parts' ($r.code -eq 0 -and (Read-AllredProjectState -Path $r.path).decisions[0].remaining_facets.Count -eq 2)
$r=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D90';status='confirmed';remaining_facets=@('unanswered')})}}) 'completion-initial-draft'
Check 'initial draft rejects contradictory decision' ($r.code -ne 0 -and $r.text -match 'Confirmed decision retains unanswered facets')
Check 'completion parent remains unchanged' ((Get-FileHash -LiteralPath $completionPath).Hash -eq $completionHash)

$blockerBase=Clone $continuity
$blockerBase.blocking_items+= [pscustomobject]@{id='B20';kind='decision';status='open';source_ids=@('D20');statement='Feedback is undecided.'}
$blockerBasePath=Join-Path $OutputRoot 'blocker-parent.json';Save $blockerBasePath $blockerBase
$exactChoice='Allow corrections; retain the complete content before every change.'
foreach($case in @('single','both','multiple-partial','multiple-complete','mixed-evidence','legacy-basis','legacy-source','missing-link','missing-kind','evidence-kind','missing-quote','missing-choice','unexposed','partial','conflict','remaining-decision','remaining-blocker','manual-resolution')) {
  $parent=Clone $blockerBase
  $patch=[pscustomobject]@{upsert=[pscustomobject]@{
    user_sources=@([pscustomobject]@{id='U6';quote=$exactChoice;authority='requirement'})
    decisions=@([pscustomobject]@{id='D10';status='confirmed';choice=$exactChoice;approval_source='U6';exposed=$true})
  }}
  $expected='open'
  switch($case) {
    'single' {$expected='resolved'}
    'both' {$expected='resolved';$patch.upsert.decisions+=[pscustomobject]@{id='D20';status='confirmed';choice='Keep feedback local.';approval_source='U6';exposed=$true};$patch.upsert.user_sources[0].quote+=' Keep feedback local.'}
    'multiple-partial' {$parent.blocking_items[0].source_ids=@('D10','D20')}
    'multiple-complete' {$expected='resolved';$parent.blocking_items[0].source_ids=@('D10','D20');$patch.upsert.decisions+=[pscustomobject]@{id='D20';status='confirmed';choice='Keep feedback local.';approval_source='U6';exposed=$true};$patch.upsert.user_sources[0].quote+=' Keep feedback local.'}
    'mixed-evidence' {$parent.blocking_items[0]|Add-Member -NotePropertyName basis -NotePropertyValue @('E1')}
    'legacy-basis' {$expected='resolved';$parent.blocking_items[0].PSObject.Properties.Remove('source_ids');$parent.blocking_items[0]|Add-Member -NotePropertyName basis -NotePropertyValue @('D10')}
    'legacy-source' {$expected='resolved';$parent.blocking_items[0].PSObject.Properties.Remove('source_ids');$parent.blocking_items[0]|Add-Member -NotePropertyName source -NotePropertyValue 'D10'}
    'missing-link' {$parent.blocking_items[0].source_ids=@('D90')}
    'missing-kind' {$parent.blocking_items[0].PSObject.Properties.Remove('kind')}
    'evidence-kind' {$parent.blocking_items[0].kind='evidence'}
    'missing-quote' {$patch.upsert.user_sources[0].quote=$null}
    'missing-choice' {$patch.upsert.decisions[0].choice=''}
    'unexposed' {$patch.upsert.decisions[0].exposed=$false}
    'partial' {$patch.upsert.decisions[0].status='open'}
    'conflict' {$parent.blocking_items[0].status='conflict';$expected='conflict'}
    'remaining-decision' {$patch.upsert.decisions[0]|Add-Member -NotePropertyName remaining_facets -NotePropertyValue @('extent')}
    'remaining-blocker' {$parent.blocking_items[0]|Add-Member -NotePropertyName remaining_facets -NotePropertyValue @('independent-check')}
    'manual-resolution' {$parent.blocking_items[0].status='resolved';$expected='resolved'}
  }
  $path=Join-Path $OutputRoot "blocker-$case-parent.json";Save $path $parent
  $r=Patch $patch "blocker-$case" $path
  if($case -eq 'remaining-decision') {
    Check 'blocker cannot accept contradictory confirmed decision' ($r.code -ne 0 -and $r.text -match 'Confirmed decision retains unanswered facets')
    Check 'rejected blocker parent remains open without execution authority' ($parent.blocking_items[0].status -eq 'open' -and $parent.blocking_items[1].status -eq 'open' -and $parent.authorization.state -eq 'pending')
    continue
  }
  Check "blocker $case update succeeds" ($r.code -eq 0)
  $s=Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json
  Check "blocker $case status" ($s.blocking_items[0].status -eq $expected)
  $siblingExpected=if($case -in @('both','multiple-complete')){'resolved'}else{'open'}
  Check "blocker $case sibling" ($s.blocking_items[1].status -eq $siblingExpected)
  Check "blocker $case has no execution authority" ($s.authorization.state -eq 'pending')
  if($case -eq 'single') {
    $resolvedPath=$r.path
    Check 'derived closure preserves exact choice and blocker link' ($s.decisions[0].choice -ceq $exactChoice -and $s.blocking_items[0].source_ids[0] -eq 'D10' -and $s.blocking_items[0].resolution_mode -eq 'confirmed-decisions')
    Check 'closure invalidates cached readiness' ($s.discovery_coverage.status -eq 'open' -and $s.preflight.status -eq 'open' -and $s.preflight.execution_record.status -eq 'missing')
  }
  if($case -eq 'manual-resolution'){Check 'manual closure is not taken over' ($null -eq $s.blocking_items[0].PSObject.Properties['resolution_mode'])}
}
$noop=Patch ([pscustomobject]@{}) 'blocker-noop' $resolvedPath
Check 'derived closure remains stable across no-op' ($noop.code -eq 0 -and (Get-Content -LiteralPath $noop.path -Raw -Encoding UTF8|ConvertFrom-Json).blocking_items[0].status -eq 'resolved')
$reopened=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';status='open';choice=$null;approval_source=$null})}}) 'blocker-reopened' $noop.path
Check 'correction reopens only derived blocker' ($reopened.code -eq 0 -and (Get-Content -LiteralPath $reopened.path -Raw -Encoding UTF8|ConvertFrom-Json).blocking_items[0].status -eq 'open')
$closedAgain=Patch ([pscustomobject]@{upsert=[pscustomobject]@{decisions=@([pscustomobject]@{id='D10';status='confirmed';choice=$exactChoice;approval_source='U6'})}}) 'blocker-reconfirmed' $reopened.path
$s=Get-Content -LiteralPath $closedAgain.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'reconfirmation continues latest immutable snapshot' ($closedAgain.code -eq 0 -and $s.blocking_items[0].status -eq 'resolved' -and $s.authoring.parent_path -eq $reopened.path -and $s.authoring.parent_sha256 -eq (Get-FileHash -LiteralPath $reopened.path).Hash)
Save (Join-Path $OutputRoot 'summary.json') @($results)
"Incremental state contracts: PASS ($($results.Count) assertions; synthetic, not model behavior evidence)"
"Evidence: $OutputRoot"
