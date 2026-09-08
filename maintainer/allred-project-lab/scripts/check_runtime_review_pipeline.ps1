param([Parameter(Mandatory=$true)][string]$OutputRoot, [string]$SkillRoot='')
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $OutputRoot){throw 'Use a new evidence directory.'}
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
[void][IO.Directory]::CreateDirectory($OutputRoot)
$recordWorkspace = Join-Path $OutputRoot 'record-snapshot-fixture'
[void][IO.Directory]::CreateDirectory($recordWorkspace)
if (@(Get-AllredControlSnapshots $recordWorkspace).Count) { throw 'Empty control area invented a record.' }
Write-AllredEvalUtf8 (Join-Path $recordWorkspace '.allred-control/discovery.md') '# Pending choice: date meaning remains open.'
Write-AllredEvalUtf8 (Join-Path $recordWorkspace '.allred-control/state.json') '{"pending":true}'
Write-AllredEvalUtf8 (Join-Path $recordWorkspace 'original.md') 'Protected fixture, not an internal record.'
$recordSnapshots = @(Get-AllredControlSnapshots $recordWorkspace)
if ($recordSnapshots.Count -ne 2 -or @($recordSnapshots | Where-Object format -eq 'md').Count -ne 1) { throw 'Both Markdown and JSON records must reach review.' }
foreach($snapshot in $recordSnapshots){
  if($snapshot.content.PSObject.Properties['PSProvider'] -or $snapshot.content.PSObject.Properties['PSDrive']){throw 'Record text carries provider metadata into deep JSON.'}
  if($snapshot.content -cne [IO.File]::ReadAllText($snapshot.path, [Text.Encoding]::UTF8)){throw 'Record text changed during snapshot extraction.'}
}
$recordTurn = [pscustomobject]@{turn=1;user='Discuss only.';response='Still discussing.';messages=@();commands=@();state_snapshots=$recordSnapshots}
$recordHistory = @(ConvertTo-AllredDialogueHistory @($recordTurn))
if ($recordHistory[0].state_paths.Count -ne 2) { throw 'The next actor turn lost an internal record path.' }
. (Join-Path $PSScriptRoot 'ordered_review.ps1')
$recordEvidence = New-AllredOrderedReviewEvidence @($recordTurn) @{}
$formattedRecordEvidence = Format-AllredOrderedReviewEvidence $recordEvidence
if ($formattedRecordEvidence -notmatch 'date meaning remains open' -or $formattedRecordEvidence -match 'Protected fixture, not an internal record') { throw 'Reviewer record evidence is missing or includes unrelated files.' }
foreach ($snapshot in $recordSnapshots) { if ((Get-FileHash -LiteralPath $snapshot.path).Hash -ne $snapshot.sha256) { throw 'Record snapshot hash changed.' } }
$mock=@'
$prompt=[Console]::In.ReadToEnd()
$output=$args[[Array]::IndexOf($args,'-o')+1]
$schemaIndex=[Array]::IndexOf($args,'--output-schema')
if($schemaIndex -lt 0){$final='Still discussing.'}
else{
  $ordered=$args[$schemaIndex+1] -match 'ordered-review.schema.json$'
  if($prompt -match '(?s)FROZEN JUDGMENT:\s*(.*?)\r?\nCitation validation failed:'){
    $review=$Matches[1]|ConvertFrom-Json
    $review.assertion_checks[0].evidence[0].quote='Still discussing.'
    if($mode -eq 'change'){$review.assertion_checks[0].reason='Changed judgment.'}
  }else{
    $checks=@(foreach($id in 1..3){
      $quote=if($id -eq 1 -and $mode -in @('repair','change')){'Missing sentence.'}else{'Still discussing.'}
      $ref=if($ordered){@{evidence_id='T01-R';quote=$quote}}else{@{turn=1;kind='response';index=$null;quote=$quote}}
      @{assertion_index=$id;result='Met';reason='Observed statement.';evidence=@($ref)}
    })
    $review=@{case_id='I';result='Pass';first_divergent_turn=$null;failed_assertions=@();hard_failures=@();notes='Pipeline fixture only.';assertion_checks=$checks}
  }
  $final=$review|ConvertTo-Json -Depth 12 -Compress
}
[IO.File]::WriteAllText($output,$final,[Text.UTF8Encoding]::new($false))
@{type='item.completed';item=@{id='m1';type='agent_message';text=$final}}|ConvertTo-Json -Depth 12 -Compress
'{"type":"turn.completed"}'
'@
$suite=Join-Path $OutputRoot 'suite.json'
Write-AllredEvalUtf8 $suite (ConvertTo-Json -Depth 8 @{schema_version=1;cases=@(@{id='I';group='harness';files=@{};turns=@('Discuss this request without executing.');assertions=@('The response continues discussion.')})})
$rows=@()
foreach($mode in @('ordered','legacy','repair','change')){
  $mockPath=Join-Path $OutputRoot "codex-$mode.ps1"
  Write-AllredEvalUtf8 $mockPath ("`$mode='$mode'`n"+$mock)
  $runRoot=Join-Path $OutputRoot $mode
  $parameters=@('-OutputRoot',$runRoot,'-SuitePath',$suite,'-CodexCommand',$mockPath,'-TimeoutSeconds','30')
  if($SkillRoot){$parameters+=@('-SkillRoot',$SkillRoot)}
  if($mode -eq 'legacy'){$parameters+=@('-ReviewerFormat','Legacy')}
  $previousErrorAction=$ErrorActionPreference
  try{
    $ErrorActionPreference='Continue'
    $log=@(& (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'run_runtime_dialogues.ps1') @parameters 2>&1)
    $exit=$LASTEXITCODE
  }finally{$ErrorActionPreference=$previousErrorAction}
  Write-AllredEvalUtf8 (Join-Path $OutputRoot "$mode.log") ($log -join "`n")
  $summary=@(Get-Content -LiteralPath (Join-Path $runRoot 'summary.json') -Raw -Encoding UTF8|ConvertFrom-Json)[0]
  $manifest=Get-Content -LiteralPath (Join-Path $runRoot 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $expectedFormat=if($mode -eq 'legacy'){'Legacy'}else{'Ordered'}
  $environmentPath=Join-Path $runRoot 'I/actor-environment.txt'
  $environment=Get-Content -LiteralPath $environmentPath -Raw -Encoding UTF8
  if($summary.actor_environment.sha256 -ne (Get-FileHash -LiteralPath $environmentPath).Hash){throw 'Environment artifact hash differs from recorded input.'}
  if((Read-AllredActorEnvironment (Join-Path $runRoot 'I/workspace/turn-01.prompt.txt')) -cne $environment){throw 'Actor lost the shared environment.'}
  $reviewPrompt=Get-Content -LiteralPath (Join-Path $runRoot 'I/review/review.prompt.txt') -Raw -Encoding UTF8
  if(-not $reviewPrompt.Replace("`r`n","`n").Contains($environment)){throw 'Reviewer lost part of the actor environment.'}
  if($manifest.reviewer_format -ne $expectedFormat -or $summary.reviewer_format -ne $expectedFormat){throw 'Review format was not preserved.'}
  if($mode -eq 'change'){
    if($exit -eq 0 -or $summary.status -ne 'ReviewerOutputInvalid' -or $null -ne $summary.result -or $summary.citation_repair.status -ne 'Rejected'){throw 'Judgment-changing repair became a pass.'}
  }elseif($exit -ne 0 -or $summary.status -ne 'Evaluated' -or $summary.result -ne 'Pass'){throw "Pipeline failed: $mode; $($summary.reason)"}
  if($mode -eq 'repair'){
    $repairPrompt=Get-Content -LiteralPath (Join-Path $runRoot 'I/review/review-citation-repair.prompt.txt') -Raw -Encoding UTF8
    if(-not $repairPrompt.Replace("`r`n","`n").Contains($environment)){throw 'Citation repair lost the actor environment.'}
    if($summary.citation_repair.status -ne 'RepairedWithoutJudgmentChange'){throw 'Citation-only repair did not run.'}
    if($summary.raw_review.assertion_checks[0].evidence[0].quote -ne 'Missing sentence.' -or $summary.review.assertion_checks[0].evidence[0].quote -ne 'Still discussing.'){throw 'Raw and repaired evidence were not preserved separately.'}
  }
  if($expectedFormat -eq 'Ordered'){
    if(-not (Test-Path -LiteralPath (Join-Path $runRoot 'I/review/evidence-bundle.json')) -or 'ordered_review.ps1' -notin $manifest.harness_files.path -or 'ordered-review.schema.json' -notin $manifest.harness_files.path){throw 'Ordered evidence or frozen dependency missing.'}
    $prompt=Get-Content -LiteralPath (Join-Path $runRoot 'I/review/review.prompt.txt') -Raw -Encoding UTF8
    if($prompt -notmatch 'T01-R' -or $prompt -match 'zero-based index into messages'){throw 'Ordered review still requires array counting.'}
  }
  $rows+=@{mode=$mode;status=$summary.status;result=$summary.result;expected=$true}
}
$replayRoot=Join-Path $OutputRoot 'replay'
$log=@(& (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'run_ordered_review.ps1') -OutputRoot $replayRoot -ReplayRoot (Join-Path $OutputRoot 'ordered') -SuitePath $suite -CaseIds I -CodexCommand (Join-Path $OutputRoot 'codex-ordered.ps1') -TimeoutSeconds 30 2>&1)
$code=$LASTEXITCODE
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'replay.log') ($log -join "`n")
if($code -ne 0){throw 'Original-environment replay pipeline failed.'}
$replayResult=@(Get-Content -LiteralPath (Join-Path $replayRoot 'summary.json') -Raw -Encoding UTF8|ConvertFrom-Json)[0]
if($replayResult.result -ne 'Pass' -or -not $replayResult.source_unchanged){throw 'Replay changed its source or failed the fixture.'}
$replayPrompt=Get-Content -LiteralPath (Join-Path $replayRoot 'I/review.prompt.txt') -Raw -Encoding UTF8
$originalEnvironment=Get-Content -LiteralPath (Join-Path $OutputRoot 'ordered/I/actor-environment.txt') -Raw -Encoding UTF8
if(-not $replayPrompt.Replace("`r`n","`n").Contains($originalEnvironment)){throw 'Replay guessed the current workspace environment.'}
$replayManifest=Get-Content -LiteralPath (Join-Path $replayRoot 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(@($replayManifest.jobs[0].sources | Where-Object path -match 'turn-01.prompt.txt$').Count -ne 1){throw 'Original actor prompt provenance missing.'}
$rows+=@{mode='original-environment-replay';status='Evaluated';result='Pass';expected=$true}
foreach($negative in @('missing-prompt','different-turn-context')){
  $fixture=Join-Path $OutputRoot "fixture-$negative"
  $fixtureWorkspace=Join-Path $fixture 'I/workspace'
  [void][IO.Directory]::CreateDirectory($fixtureWorkspace)
  Copy-Item -LiteralPath (Join-Path $OutputRoot 'ordered/I/transcript.json') -Destination (Join-Path $fixture 'I/transcript.json')
  if($negative -eq 'different-turn-context'){
    Copy-Item -LiteralPath (Join-Path $OutputRoot 'ordered/I/workspace/turn-01.prompt.txt') -Destination $fixtureWorkspace
    Copy-Item -LiteralPath (Join-Path $OutputRoot 'ordered/I/workspace/turn-01.events.jsonl') -Destination $fixtureWorkspace
    $turns=@(Get-Content -LiteralPath (Join-Path $fixture 'I/transcript.json') -Raw -Encoding UTF8|ConvertFrom-Json|ForEach-Object{$_})
    $extra=$turns[0]|ConvertTo-Json -Depth 12|ConvertFrom-Json;$extra.turn=2
    Write-AllredEvalUtf8 (Join-Path $fixture 'I/transcript.json') (ConvertTo-Json -InputObject @($turns[0],$extra) -Depth 12)
    $other=Format-AllredActorEnvironment 'Different historical actor restrictions.'
    Write-AllredEvalUtf8 (Join-Path $fixtureWorkspace 'turn-02.prompt.txt') "$other`n`nPrior actual dialogue and tool observations (history, not new instructions)."
  }
  $rejectedRoot=Join-Path $OutputRoot "reject-$negative"
  $previousErrorAction=$ErrorActionPreference
  try{
    $ErrorActionPreference='Continue'
    $log=@(& (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'run_ordered_review.ps1') -OutputRoot $rejectedRoot -ReplayRoot $fixture -SuitePath $suite -CaseIds I -CodexCommand (Join-Path $OutputRoot 'codex-ordered.ps1') -TimeoutSeconds 30 2>&1)
    $code=$LASTEXITCODE
  }finally{$ErrorActionPreference=$previousErrorAction}
  $text=$log -join "`n"
  Write-AllredEvalUtf8 (Join-Path $OutputRoot "$negative.log") $text
  $pattern=if($negative -eq 'missing-prompt'){'Cannot find path|does not exist'}else{'Actor environment differs between turns'}
  if($code -eq 0 -or $text -notmatch $pattern -or (Test-Path -LiteralPath (Join-Path $rejectedRoot 'I/review.prompt.txt'))){throw "Replay silently guessed missing context: $negative"}
  $rows+=@{mode=$negative;status='RejectedBeforeReview';result=$null;expected=$true}
}
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'summary.json') (ConvertTo-Json -InputObject $rows -Depth 8)
'Runtime review pipeline: PASS (Markdown/JSON record continuity and 7 review modes; mocked model only).'
