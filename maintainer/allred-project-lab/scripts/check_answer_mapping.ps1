param(
  [string]$StandardRoot='',
  [Parameter(Mandatory=$true)][string]$OutputRoot
)
$ErrorActionPreference='Stop'
$shell=(Get-Process -Id $PID).Path
if(-not $StandardRoot){$StandardRoot=Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'}
$StandardRoot=(Resolve-Path -LiteralPath $StandardRoot).Path
if(Test-Path -LiteralPath $OutputRoot){throw 'Use a new evidence directory'}
[void][IO.Directory]::CreateDirectory($OutputRoot)
$OutputRoot=(Resolve-Path -LiteralPath $OutputRoot).Path
$control=Join-Path $OutputRoot 'control';[void][IO.Directory]::CreateDirectory($control)
$checks=[Collections.Generic.List[object]]::new()
function Save($Path,$Value){[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 60),[Text.UTF8Encoding]::new($false))}
function Check($Name,$Pass){$checks.Add([pscustomobject]@{name=$Name;passed=[bool]$Pass});Save (Join-Path $OutputRoot 'checks.json') @($checks);if(-not $Pass){throw "Failed: $Name"}}
function Clone($Value){$Value|ConvertTo-Json -Depth 60|ConvertFrom-Json}
function Run($Name,$Script,$Arguments){
  $old=$ErrorActionPreference
  try{$ErrorActionPreference='Continue';$text=@(& $shell -NoProfile -NonInteractive -File (Join-Path $StandardRoot "scripts/$Script") @Arguments 2>&1|ForEach-Object{"$_"}) -join "`n";$code=$LASTEXITCODE}
  finally{$ErrorActionPreference=$old}
  [IO.File]::WriteAllText((Join-Path $OutputRoot "$Name.log"),$text,[Text.UTF8Encoding]::new($false))
  [pscustomobject]@{code=$code;text=$text;path=[regex]::Match($text,'(?m)^StatePath: (.+)$').Groups[1].Value.Trim()}
}
$parent=Get-Content -LiteralPath (Join-Path $StandardRoot 'tests/project-state.valid-ready.json') -Raw -Encoding UTF8|ConvertFrom-Json
$draft=Get-Content -LiteralPath (Join-Path $StandardRoot 'templates/project-state.draft.json') -Raw -Encoding UTF8|ConvertFrom-Json
$parent|Add-Member -NotePropertyName execution_plan -NotePropertyValue $draft.execution_plan
foreach($id in @('D10','D20')){$parent.decisions+=[pscustomobject]@{id=$id;axis="axis-$id";label="Choice $id";status='open';choice=$null;exposed=$true;depends_on=@();approval_source=$null;trigger='user:U1';recommendation=$null}}
$parent.blocking_items=@(
  [pscustomobject]@{id='B10';kind='decision';status='open';source_ids=@('D10')},
  [pscustomobject]@{id='B20';kind='decision';status='open';source_ids=@('D20')}
)
$statePath=Join-Path $OutputRoot 'parent.json';Save $statePath $parent
$questionPath=Join-Path $OutputRoot 'previous-question.txt'
$replyPath=Join-Path $OutputRoot 'literal-reply.txt'
$question='D10: Which handling rule? D20: Which retention rule?'
$reply="Use the chosen handling rule. The retention rule is undecided.`nDo not start work."
[IO.File]::WriteAllText($questionPath,$question,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($replyPath,$reply,[Text.UTF8Encoding]::new($false))
$originalHashes=@($statePath,$questionPath,$replyPath)|ForEach-Object{[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}}
$before=@(Get-ChildItem -LiteralPath $OutputRoot -File -Recurse).Count
$prepared=Run 'prepare' 'prepare_answer_update.ps1' @('-StatePath',$statePath,'-QuestionPath',$questionPath,'-ReplyPath',$replyPath)
Check 'preparer succeeds' ($prepared.code -eq 0)
$ctx=$prepared.text|ConvertFrom-Json
Check 'preparer is read-only apart from harness log' (@(Get-ChildItem -LiteralPath $OutputRoot -File -Recurse).Count -eq $before+2)
Check 'preparer preserves complete literal inputs' ($ctx.literal_reply -ceq $reply -and $ctx.previous_question -ceq $question)
Check 'preparer includes pending siblings and original quotes' ($ctx.unresolved_decision_ids.Count -eq 2 -and 'D10' -in $ctx.unresolved_decision_ids -and 'D20' -in $ctx.unresolved_decision_ids -and $ctx.prior_user_quotes.Count -eq $parent.user_sources.Count)
$map=[pscustomobject]@{binding=$ctx.binding;confirmed=@([pscustomobject]@{id='D10';choice='selected-rule'});pending=@('D20')}
function Apply($Name,$Patch,[string]$Base=$statePath){
  $p=Join-Path $OutputRoot "$Name.patch.json";Save $p $Patch
  $hash=(Get-FileHash -LiteralPath $p).Hash;$baseHash=(Get-FileHash -LiteralPath $Base).Hash
  $r=Run $Name 'update_project_state.ps1' @('-PatchPath',$p,'-StatePath',$Base,'-ExpectedSha256',$baseHash,'-WorkspaceRoot',$OutputRoot,'-EvidenceRoot',$control)
  Check "$Name preserves input state and patch" ((Get-FileHash -LiteralPath $p).Hash -eq $hash -and (Get-FileHash -LiteralPath $Base).Hash -eq $baseHash)
  return $r
}
$first=Apply 'valid' ([pscustomobject]@{answer_map=$map})
Check 'valid map applied' ($first.code -eq 0)
$s=Get-Content -LiteralPath $first.path -Raw -Encoding UTF8|ConvertFrom-Json
Check 'answer mapping reconciles only confirmed decision blocker' ($s.blocking_items[0].status -eq 'resolved' -and $s.blocking_items[0].resolution_mode -eq 'confirmed-decisions' -and $s.blocking_items[1].status -eq 'open')
$d=@($s.decisions|Where-Object id -eq 'D10')[0]
Check 'mapped meaning copied exactly once' ($d.choice -ceq $map.confirmed[0].choice -and $d.status -eq 'confirmed' -and $d.approval_source -eq $ctx.source_id)
Check 'full user quote stored without generated paraphrase' ((@($s.user_sources|Where-Object id -eq $ctx.source_id)[0].quote -ceq $reply) -and (@($s.user_sources|Where-Object id -eq $ctx.source_id)[0].meaning -ceq $reply))
Check 'unanswered sibling unchanged' ((@($s.decisions|Where-Object id -eq 'D20')[0]|ConvertTo-Json -Depth 6 -Compress) -ceq (@($parent.decisions|Where-Object id -eq 'D20')[0]|ConvertTo-Json -Depth 6 -Compress))
Check 'map does not approve execution' ($s.authorization.state -eq 'pending')
foreach($case in @('missing-pending','scalar-confirmed','scalar-pending','absent-pending','overlap','duplicate','unknown-id','non-string-choice','override','manual-source','stale-state','stale-question','stale-reply','extra-field')){
  $patch=[pscustomobject]@{answer_map=(Clone $map)}
  $pattern='';$base=$statePath
  switch($case){
    'missing-pending'{$patch.answer_map.pending=@();$pattern='Unaccounted unresolved answer'}
    'scalar-confirmed'{$patch.answer_map.confirmed=$patch.answer_map.confirmed[0];$pattern='confirmed must be an explicit array'}
    'scalar-pending'{$patch.answer_map.pending='D20';$pattern='pending must be an explicit array'}
    'absent-pending'{$patch.answer_map.PSObject.Properties.Remove('pending');$pattern='pending must be an explicit array'}
    'overlap'{$patch.answer_map.pending=@('D10','D20');$pattern='conflicting answer mapping'}
    'duplicate'{$patch.answer_map.confirmed+=Clone $patch.answer_map.confirmed[0];$pattern='Duplicate answer mapping'}
    'unknown-id'{$patch.answer_map.confirmed[0].id='Dmissing';$pattern='Invalid confirmed answer'}
    'non-string-choice'{$patch.answer_map.confirmed[0].choice=42;$pattern='Invalid confirmed answer'}
    'override'{$patch|Add-Member -NotePropertyName upsert -NotePropertyValue ([pscustomobject]@{decisions=@([pscustomobject]@{id='D10';choice='rewritten'})});$pattern='cannot be overridden'}
    'manual-source'{$patch|Add-Member -NotePropertyName upsert -NotePropertyValue ([pscustomobject]@{user_sources=@([pscustomobject]@{id=$ctx.source_id;quote='shortened'})});$pattern='source is generated'}
    'stale-state'{$base=$first.path;$pattern='mismatched answer binding'}
    'stale-question'{$patch.answer_map.binding.question_sha256='0000';$pattern='mismatched answer binding'}
    'stale-reply'{$patch.answer_map.binding.reply_sha256='0000';$pattern='mismatched answer binding'}
    'extra-field'{$patch.answer_map.confirmed[0]|Add-Member -NotePropertyName approval -NotePropertyValue $true;$pattern='Unsupported confirmed answer field'}
  }
  $count=@(Get-ChildItem -LiteralPath $control -Directory).Count
  $r=Apply $case $patch $base
  Check "$case rejected without snapshot" ($r.code -ne 0 -and $r.text -match $pattern -and @(Get-ChildItem -LiteralPath $control -Directory).Count -eq $count)
}
$pending=Clone $map;$pending.confirmed=@();$pending.pending=@('D10','D20')
$r=Apply 'all-pending' ([pscustomobject]@{answer_map=$pending})
Check 'ambiguous reply can leave every decision pending' ($r.code -eq 0 -and @((Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json).decisions|Where-Object {$_.id -in @('D10','D20') -and $_.status -ne 'open'}).Count -eq 0)
$combined=Clone $map;$combined.confirmed+= [pscustomobject]@{id='D20';choice='chosen-retention'};$combined.pending=@()
$r=Apply 'combined' ([pscustomobject]@{answer_map=$combined})
Check 'combined interpretation applied in one update' ($r.code -eq 0 -and @((Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json).decisions|Where-Object {$_.id -in @('D10','D20') -and $_.status -eq 'confirmed'}).Count -eq 2)
Check 'structural mapping does not certify semantic truth' ($r.code -eq 0)
$newContext=Run 'prepare-correction' 'prepare_answer_update.ps1' @('-StatePath',$first.path,'-QuestionPath',$questionPath,'-ReplyPath',$replyPath)
$c=$newContext.text|ConvertFrom-Json
$correction=Clone $map;$correction.binding=$c.binding;$correction.confirmed[0].choice='explicit-custom-correction'
$r=Apply 'correction' ([pscustomobject]@{answer_map=$correction}) $first.path
Check 'prior choices can be explicitly corrected without replaying siblings' ($r.code -eq 0 -and (@((Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json).decisions|Where-Object id -eq 'D10')[0].choice -ceq 'explicit-custom-correction'))
foreach($case in @('deferred','rejected','superseded','not-applicable','missing-replacement','resolved-overlap','resolved-override','missing-reason')){
  $literal=Join-Path $OutputRoot "$case.reply.txt"
  [IO.File]::WriteAllText($literal,"Use selected-rule for handling. Retention is explicitly $case. Do not start work.",[Text.UTF8Encoding]::new($false))
  $prepared=Run "prepare-$case" 'prepare_answer_update.ps1' @('-StatePath',$statePath,'-QuestionPath',$questionPath,'-ReplyPath',$literal)
  Check "$case context prepared" ($prepared.code -eq 0)
  $ctxResolved=$prepared.text|ConvertFrom-Json
  $m=Clone $map;$m.binding=$ctxResolved.binding;$m.pending=@()
  $status=if($case -in @('missing-replacement')){'superseded'}elseif($case -in @('resolved-overlap','resolved-override','missing-reason')){'deferred'}else{$case}
  $m|Add-Member -NotePropertyName resolved -NotePropertyValue @([pscustomobject]@{id='D20';status=$status;reason='Explicit user resolution'})
  $p=[pscustomobject]@{answer_map=$m}
  $pattern=''
  switch($case){
    'superseded'{
      $m.resolved[0]|Add-Member -NotePropertyName superseded_by -NotePropertyValue @('D30')
      $p|Add-Member -NotePropertyName upsert -NotePropertyValue ([pscustomobject]@{decisions=@([pscustomobject]@{id='D30';axis='replacement-rule';status='open';depends_on=@()})})
    }
    'missing-replacement'{$pattern='needs unique replacement IDs'}
    'resolved-overlap'{$m.pending=@('D20');$pattern='conflicting answer mapping'}
    'resolved-override'{$p|Add-Member -NotePropertyName upsert -NotePropertyValue ([pscustomobject]@{decisions=@([pscustomobject]@{id='D20';status='confirmed'})});$pattern='cannot be overridden'}
    'missing-reason'{$m.resolved[0].reason='';$pattern='Invalid resolved answer mapping'}
  }
  $count=@(Get-ChildItem -LiteralPath $control -Directory).Count
  $r=Apply $case $p
  if($pattern){Check "$case rejected without snapshot" ($r.code -ne 0 -and $r.text -match $pattern -and @(Get-ChildItem -LiteralPath $control -Directory).Count -eq $count)}
  else{
    Check "$case lifecycle accepted" ($r.code -eq 0)
    $stateResolved=Get-Content -LiteralPath $r.path -Raw -Encoding UTF8|ConvertFrom-Json
    $dResolved=@($stateResolved.decisions|Where-Object id -eq 'D20')[0]
    Check "$case binds user resolution without approval" ($dResolved.status -eq $status -and $dResolved.resolution_source -eq $ctxResolved.source_id -and $stateResolved.authorization.state -eq 'pending')
  }
}
foreach($f in $originalHashes){Check "original input preserved: $([IO.Path]::GetFileName($f.path))" ((Get-FileHash -LiteralPath $f.path).Hash -eq $f.sha256)}
"Answer mapping contracts: PASS ($($checks.Count) assertions; no semantic certification)"
