param([Parameter(Mandatory=$true)][string]$OutputRoot)
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $OutputRoot){throw 'Use a new evidence directory.'}
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
. (Join-Path $PSScriptRoot 'ordered_review.ps1')
[void][IO.Directory]::CreateDirectory($OutputRoot)
$script:count=0
function Check($Passed,$Name){if(-not $Passed){throw $Name};$script:count++}
function Reject([scriptblock]$Action,$Name){$rejected=$false;try{& $Action|Out-Null}catch{$rejected=$true};Check $rejected $Name}
$path=Join-Path $OutputRoot 'events.jsonl'
$eventLines=@(
  '{"type":"item.started","item":{"id":"c1","type":"command_execution","command":"check"}}',
  '{"type":"item.completed","item":{"id":"m1","type":"agent_message","text":"Still waiting."}}',
  '{"type":"item.completed","item":{"id":"c1","type":"command_execution","command":"check","aggregated_output":"PASS","exit_code":0}}',
  '{"type":"item.completed","item":{"id":"m2","type":"agent_message","text":"Check passed."}}'
)
Write-AllredEvalUtf8 $path ($eventLines -join "`n")
$turn=[pscustomobject]@{turn=1;user='Run existing check.';response='Check passed.';messages=@('Still waiting.','Check passed.');commands=@([pscustomobject]@{command='check';aggregated_output='PASS';exit_code=0});state_snapshots=@([pscustomobject]@{path='state.json';content='{"status":"open"}'});timing=@{duration_ms=99}}
$original=ConvertTo-Json $turn -Depth 20 -Compress
$bundle=New-AllredOrderedReviewEvidence @($turn) @{1=$path}
Check ((ConvertTo-Json $turn -Depth 20 -Compress) -ceq $original) 'Input was mutated.'
Check ($bundle.order.Count -eq 4) 'Lost start/message/completion events.'
Check ($bundle.order[0].event -eq 'item.started' -and $bundle.order[1].item_id -eq 'm1' -and $bundle.order[2].item_id -eq 'c1') 'Interleaving changed.'
Check (@($bundle.entries|Where-Object id -eq 'T01-E000001')[0].text -eq 'check') 'Future output leaked into start evidence.'
Check (@($bundle.entries|Where-Object id -eq 'T01-E000003')[0].text.Contains('PASS')) 'Completed output was lost.'
Check (@($bundle.entries|Where-Object id -eq 'T01-E000003')[0].location.Contains('exit_code=0')) 'Exit code was lost.'
Check (-not $bundle.transcript[0].PSObject.Properties['timing']) 'Timing leaked.'
$formatted=Format-AllredOrderedReviewEvidence $bundle
Check ($formatted.Contains('T01-E000002 [user-facing assistant message]')) 'Progress lost its visible role.'
Check ($formatted.Contains('T01-E000003 [internal tool observation]')) 'Tool output misclassified as visible narration.'
Check ($formatted.IndexOf('--- EVIDENCE T01-E000002') -lt $formatted.IndexOf('--- EVIDENCE T01-R')) 'Final reply moved before progress in catalog.'
Check ($formatted.Contains('{"status":"open"}') -and -not $formatted.Contains('{\"status\":')) 'State text was escaped again.'
$fallback=New-AllredOrderedReviewEvidence @($turn)
Check ($fallback.order[0].event -match 'unavailable') 'Invented legacy order.'
Check ($fallback.entries.Count -eq 6) 'Legacy source lost.'
$second=$turn|ConvertTo-Json -Depth 20|ConvertFrom-Json
$second.turn=2;$second.user='Continue the same check.'
$multi=New-AllredOrderedReviewEvidence @($turn,$second) @{1=$path;2=$path}
Check ($multi.transcript.Count -eq 2 -and $multi.transcript[0].turn -eq 1 -and $multi.transcript[1].turn -eq 2) 'Multi-turn JSON became one nested row.'
Check ($multi.order.Count -eq 8 -and @($multi.entries|Where-Object id -eq 'T02-U')[0].text -eq $second.user) 'Second-turn order or identity was lost.'
Check (-not $multi.transcript[1].PSObject.Properties['timing']) 'Second-turn diagnostic timing leaked.'
$review=@'
{"case_id":"R","result":"Pass","first_divergent_turn":null,"failed_assertions":[],"hard_failures":[],"notes":"Observed order.","assertion_checks":[{"assertion_index":1,"result":"Met","reason":"Pending then completed.","evidence":[{"evidence_id":"T01-E000002","quote":"Still waiting."},{"evidence_id":"T01-E000003","quote":"PASS"}]}]}
'@|ConvertFrom-Json
$reviewBefore=ConvertTo-Json $review -Depth 20 -Compress
$resolved=ConvertFrom-AllredOrderedReview $review $bundle
Check ($formatted.Contains('process output, not necessarily delivery to the model')) 'Process completion was treated as model receipt.'
$selected=Resolve-AllredReviewEvidence $review $bundle.transcript $bundle Ordered
Check ((ConvertTo-Json $selected.review -Depth 20 -Compress) -ceq (ConvertTo-Json $resolved -Depth 20 -Compress)) 'Ordered interface changed judgments or citations.'
Check (@($selected.corrections).Count -eq 0) 'Ordered IDs were silently rebound.'
Reject {Resolve-AllredReviewEvidence $review $bundle.transcript $null Ordered} 'Ordered interface accepted a missing bundle.'
$legacy=Resolve-AllredReviewEvidence $resolved $bundle.transcript $null Legacy
Check ((ConvertTo-Json $legacy.review -Depth 20 -Compress) -ceq (ConvertTo-Json $resolved -Depth 20 -Compress)) 'Legacy interface changed.'
Check ((ConvertTo-Json $review -Depth 20 -Compress) -ceq $reviewBefore) 'Raw review mutated.'
$case=[pscustomobject]@{id='R';assertions=@('Respect actual order.')}
Check ((Test-AllredRuntimeReview $resolved $case $bundle.transcript).semantic_verdict -eq 'Pass') 'Valid review rejected.'
foreach($mode in @('id','quote','empty','later-source')){
  $bad=$reviewBefore|ConvertFrom-Json
  switch($mode){
    'id'{$bad.assertion_checks[0].evidence[0].evidence_id='T99-E000002'}
    'quote'{$bad.assertion_checks[0].evidence[0].quote='Invented observation'}
    'empty'{$bad.assertion_checks[0].evidence[0].quote=''}
    'later-source'{$bad.assertion_checks[0].evidence[0].evidence_id='T01-E000001';$bad.assertion_checks[0].evidence[0].quote='PASS'}
  }
  Reject {ConvertFrom-AllredOrderedReview $bad $bundle} "Accepted bad $mode reference."
}
$bad=$reviewBefore|ConvertFrom-Json;$bad.result='Fail'
Reject {Test-AllredRuntimeReview (ConvertFrom-AllredOrderedReview $bad $bundle) $case $bundle.transcript} 'Changed aggregate slipped through.'
$bad=$reviewBefore|ConvertFrom-Json;$bad.assertion_checks=@()
Reject {Test-AllredRuntimeReview (ConvertFrom-AllredOrderedReview $bad $bundle) $case $bundle.transcript} 'Dropped assertion accepted.'
$other=$turn|ConvertTo-Json -Depth 20|ConvertFrom-Json;$other.messages[0]='Different dialogue'
Reject {New-AllredOrderedReviewEvidence @($other) @{1=$path}} 'Mismatched messages accepted.'
$other=$turn|ConvertTo-Json -Depth 20|ConvertFrom-Json;$other.commands[0].aggregated_output='FAIL'
Reject {New-AllredOrderedReviewEvidence @($other) @{1=$path}} 'Mismatched output accepted.'
$other=$turn|ConvertTo-Json -Depth 20|ConvertFrom-Json;$other.commands[0].exit_code=1
Reject {New-AllredOrderedReviewEvidence @($other) @{1=$path}} 'Mismatched exit accepted.'
Reject {New-AllredOrderedReviewEvidence @($turn,$turn)} 'Duplicate turns accepted.'
$badPath=Join-Path $OutputRoot 'bad.jsonl';Write-AllredEvalUtf8 $badPath '{broken'
Reject {New-AllredOrderedReviewEvidence @($turn) @{1=$badPath}} 'Broken event silently skipped.'
$other=$turn|ConvertTo-Json -Depth 20|ConvertFrom-Json;$other.state_snapshots[0].content='{"status":"confirmed"}'
$changed=New-AllredOrderedReviewEvidence @($other)
Check (@($bundle.entries|Where-Object kind -eq 'state')[0].id -ne @($changed.entries|Where-Object kind -eq 'state')[0].id) 'Changed state kept identity.'
$other.state_snapshots=@($turn.state_snapshots[0],$turn.state_snapshots[0])
Reject {New-AllredOrderedReviewEvidence @($other)} 'Duplicate state identity accepted.'
$turn.timing.duration_ms=99999
Check ((Format-AllredOrderedReviewEvidence (New-AllredOrderedReviewEvidence @($turn) @{1=$path})) -ceq $formatted) 'Elapsed time changed quality input.'
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'summary.json') (ConvertTo-Json @{checks=$script:count;status='Pass'})
"Ordered evidence contracts: PASS ($script:count checks)."
