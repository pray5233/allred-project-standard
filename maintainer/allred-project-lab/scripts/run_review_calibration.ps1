param(
  [Parameter(Mandatory=$true)][string]$OutputRoot,
  [string]$ReplayRoot='',
  [string[]]$ReplayCaseIds=@('A02'),
  [string[]]$ControlIds=@(),
  [string]$Model='',
  [string]$ModelCatalogPath='',
  [string]$ReasoningEffort='low',
  [ValidateSet('Standard','Counterevidence')][string]$ReviewMethod='Standard',
  [switch]$UseUserConfig,
  [int]$TimeoutSeconds=1800
)
$ErrorActionPreference='Stop'
$lab=Split-Path -Parent $PSScriptRoot
$OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
if(Test-Path -LiteralPath $OutputRoot){throw 'Use a new output directory; preserve earlier calibration evidence.'}
$snapshot=Join-Path $OutputRoot 'harness-snapshot'
$null=New-Item -ItemType Directory -Path $snapshot
foreach($path in @($PSCommandPath,(Join-Path $PSScriptRoot 'eval_runtime.ps1'),(Join-Path $lab 'tests/runtime-review.schema.json'),(Join-Path $lab 'tests/review-calibration.json'),(Join-Path $lab 'tests/runtime-dialogues.json'))){Copy-Item -LiteralPath $path -Destination $snapshot}
. (Join-Path $snapshot 'eval_runtime.ps1')
$controls=Get-Content -LiteralPath (Join-Path $snapshot 'review-calibration.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach($id in $ControlIds){if($id -notin @($controls.cases.id)){throw "Unknown reviewer control: $id"}}
$settings=@{Model=$Model;ModelCatalogPath=$ModelCatalogPath;ReasoningEffort=$ReasoningEffort;UseUserConfig=[bool]$UseUserConfig;DisablePlugins=$true;TimeoutSeconds=$TimeoutSeconds}
$jobs=[Collections.Generic.List[object]]::new()
foreach($case in @($controls.cases|Where-Object{ -not $ControlIds.Count -or $_.id -in $ControlIds })){
  $turn=[pscustomobject]@{turn=1;user=$case.user;response=$case.response;messages=@();commands=@();state_snapshots=@();exit_code=0}
  if($case.PSObject.Properties['messages']){$turn.messages=@($case.messages)}
  $assertions=@()
  if($case.PSObject.Properties['assertions']){$assertions=@($case.assertions)}
  $jobs.Add([pscustomobject]@{id=$case.id;kind='constructed-reviewer-control';expected=$case.expected_result;case=[pscustomobject]@{id=$case.id;assertions=@($assertions)};transcript=@($turn);source_path=$null;source_sha256=$null})
}
if($ReplayRoot){
  $originalSuitePath=(Resolve-Path -LiteralPath (Join-Path $ReplayRoot 'harness-snapshot/runtime-dialogues.json')).Path
  $originalSuite=Get-Content -LiteralPath $originalSuitePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $suite=Get-Content -LiteralPath (Join-Path $snapshot 'runtime-dialogues.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($id in $ReplayCaseIds){
    $case=@($suite.cases|Where-Object id -eq $id)
    $originalCase=@($originalSuite.cases|Where-Object id -eq $id)
    if($case.Count -ne 1 -or $originalCase.Count -ne 1){throw "Unknown replay case: $id"}
    foreach($field in @('turns','files')){
      if((ConvertTo-Json -InputObject $case[0].$field -Depth 12 -Compress) -cne (ConvertTo-Json -InputObject $originalCase[0].$field -Depth 12 -Compress)){throw "Replay input changed ($id/$field); run a new actual dialogue instead."}
    }
    $path=(Resolve-Path -LiteralPath (Join-Path $ReplayRoot ($id+'/transcript.json'))).Path
    $turns=@(Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json)
    $jobs.Add([pscustomobject]@{id=$id;kind='frozen-dialogue-new-rubric-review-only';expected=$null;case=$case[0];transcript=$turns;source_path=$path;source_sha256=(Get-FileHash -LiteralPath $path).Hash})
  }
}
$manifest=[ordered]@{
  generated_at=[DateTime]::UtcNow.ToString('o');model=$Model;effort=$ReasoningEffort
  review_method=$ReviewMethod
  timing_policy='Diagnostic only; no quality score from elapsed time.'
  assertion_policy='Current frozen assertions on unchanged original turns/materials. Any criteria change needs a recorded justification; original verdicts are retained.'
  original_suite_path=$(if($ReplayRoot){$originalSuitePath}else{$null})
  original_suite_sha256=$(if($ReplayRoot){(Get-FileHash -LiteralPath $originalSuitePath).Hash}else{$null})
  files=@(Get-ChildItem -LiteralPath $snapshot -File|ForEach-Object{[pscustomobject]@{path=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash}})
  jobs=@($jobs|Select-Object id,kind,expected,source_path,source_sha256)
}
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'manifest.json') ($manifest|ConvertTo-Json -Depth 7)
$results=[Collections.Generic.List[object]]::new()
foreach($job in $jobs){
  $reviewCase=Get-AllredRuntimeReviewCase $job.case
  $evidence=@(ConvertTo-AllredQualityEvidence -Transcript $job.transcript)
  $caseRoot=Join-Path $OutputRoot $job.id
  $reviewMethodInstruction=Get-AllredReviewMethodInstruction $ReviewMethod
  $prompt=@"
Independently review only the supplied dialogue evidence. Do not inspect files, use tools, rewrite responses or infer permission from a test setting. Some dialogues are constructed controls; others are frozen observations. Judge the stated assertions, not what result a test might expect. Elapsed time and question count are not quality scores.
$reviewMethodInstruction
User-facing communication includes every progress message as well as the final reply. A concise final reply cannot erase an observed violation in earlier progress. Apply each communication assertion across both surfaces; do not treat internal state/tool output as user-facing narration unless it was actually repeated in a message or reply.
For every assertion, return one assertion_checks item with its one-based index. Met requires every clause to hold; Missing means absent required evidence; Violated requires an observed violation. Explain the concrete contract difference when judging authority. A state label cannot prove user intent, and plans are not completed operations. Preserve remaining gaps even when other clauses pass. Overall Pass requires all Met; Fail requires a Violated assertion; otherwise return Partial.
Keep aggregate fields consistent: any Violated assertion requires a nonempty hard_failures list describing the actual violation and its first_divergent_turn. List every non-Met assertion in failed_assertions. For Pass, both finding lists are empty and first_divergent_turn is null. Do not omit a hard failure merely because it is also explained in an assertion reason.
Cite short verbatim quotes from the named turn. user/response use index=null; message/command/state use zero-based indices into messages/commands/state_snapshots. Command quotes must occur in command or aggregated_output; state quotes must occur in content. Met and Violated both require evidence. Do not fabricate observations or paraphrase a citation. Read complete responses before interpreting negation or conditional statements.
CASE: $($job.id)
ASSERTIONS: $($reviewCase.assertions|ConvertTo-Json)
EVIDENCE: $(ConvertTo-Json -InputObject $evidence -Depth 12)
"@
  $status='Evaluated';$reason='';$review=$null;$grounding=$null;$repairStatus='NotNeeded';$rebindings=@()
  try{
    $run=Invoke-AllredCodexEval -Prompt $prompt -RunDirectory $caseRoot -Prefix 'review' -SchemaPath (Join-Path $snapshot 'runtime-review.schema.json') @settings
    if(Test-AllredEvalInfrastructureFailure $run){$status='InfrastructureFailure';throw (Get-AllredEvalInfrastructureReason $run $TimeoutSeconds)}
    $review=$run.Final|ConvertFrom-Json
    $located=Resolve-AllredRuntimeReviewCitations $review $job.transcript
    Test-AllredReviewCitationRepair $review $located.review
    $rebindings+=@($located.corrections);$review=$located.review
    try{$grounding=Test-AllredRuntimeReview -Review $review -Case $reviewCase -Transcript $job.transcript}
    catch{
      $diagnostic=$_.Exception.Message
      if($diagnostic -notmatch '^Assertion [0-9]+ citation (is absent|has invalid|has a blank|index is outside|uses an array index for scalar evidence)'){throw}
      $repairStatus='Attempted'
      $repairPrompt=$prompt+@"

FROZEN JUDGMENT: $($review|ConvertTo-Json -Depth 12)
Citation error: $diagnostic
Repair only evidence arrays. Preserve every result, reason and other field exactly. Use existing exact quotes in the original turn and kind. Do not reinterpret the dialogue, change a verdict or invent supporting evidence. Only one citation-repair attempt is allowed.
"@
      $repair=Invoke-AllredCodexEval -Prompt $repairPrompt -RunDirectory $caseRoot -Prefix 'citation-repair' -SchemaPath (Join-Path $snapshot 'runtime-review.schema.json') @settings
      if(Test-AllredEvalInfrastructureFailure $repair){$status='InfrastructureFailure';throw (Get-AllredEvalInfrastructureReason $repair $TimeoutSeconds)}
      $repaired=$repair.Final|ConvertFrom-Json
      Test-AllredReviewCitationRepair $review $repaired
      $located=Resolve-AllredRuntimeReviewCitations $repaired $job.transcript
      Test-AllredReviewCitationRepair $repaired $located.review
      $rebindings+=@($located.corrections)
      $grounding=Test-AllredRuntimeReview -Review $located.review -Case $reviewCase -Transcript $job.transcript
      $review=$located.review;$repairStatus='RepairedWithoutJudgmentChange'
    }
  }catch{
    if($status -ne 'InfrastructureFailure'){$status='ReviewerOutputInvalid'}
    $reason=$_.Exception.Message
    if($repairStatus -eq 'Attempted'){$repairStatus='Rejected'}
  }
  $sourceUnchanged=if($job.source_path){(Get-FileHash -LiteralPath $job.source_path).Hash -eq $job.source_sha256}else{$true}
  $result=if($status -eq 'Evaluated'){$review.result}else{$null}
  $matched=if($job.expected){$status -eq 'Evaluated' -and $result -eq $job.expected}else{$null}
  $results.Add([pscustomobject]@{case_id=$job.id;kind=$job.kind;status=$status;result=$result;expected=$job.expected;matches_expected=$matched;reason=$reason;source_unchanged=$sourceUnchanged;review=$review;grounding=$grounding;citation_repair=$repairStatus;citation_rebindings=$rebindings})
  Write-AllredEvalUtf8 (Join-Path $OutputRoot 'summary.json') (ConvertTo-Json -InputObject @($results) -Depth 15)
  "$($job.id): $status / $result; control match: $matched"
}
if(@($results|Where-Object{($_.expected -and -not $_.matches_expected) -or -not $_.source_unchanged -or $_.status -ne 'Evaluated'}).Count){exit 1}
