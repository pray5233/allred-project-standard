param([Parameter(Mandatory=$true)][string]$OutputRoot, [string]$SkillRoot='')
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $OutputRoot){throw 'Use a new output directory.'}
if(-not $SkillRoot){$SkillRoot=Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'}
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
[void][IO.Directory]::CreateDirectory($OutputRoot)
$mock=Join-Path $OutputRoot 'mock-codex.ps1'
Write-AllredEvalUtf8 $mock @'
$prompt=[Console]::In.ReadToEnd()
$output=$args[[Array]::IndexOf($args,'-o')+1]
$id=if($output -match '[\\/]J[\\/]'){'12345678-1111-2222-3333-000000000002'}else{'12345678-1111-2222-3333-000000000001'}
if($prompt.StartsWith('contract:')){
  if($prompt -eq 'contract:wrong'){$id='12345678-1111-2222-3333-000000000003'}
  if($prompt -ne 'contract:missing'){@{type='thread.started';thread_id=$id}|ConvertTo-Json -Compress}
  if($prompt -eq 'contract:ambiguous'){@{type='thread.started';thread_id=$id}|ConvertTo-Json -Compress}
  [IO.File]::WriteAllText($output,($args|ConvertTo-Json -Compress))
  '{"type":"turn.completed"}'
  return
}
@{type='thread.started';thread_id=$id}|ConvertTo-Json -Compress
if('--output-schema' -notin $args){$final='Still discussing.'}
else{
  $case=if($prompt -match '(?m)^CASE: (I|J)\s*$'){$Matches[1]}else{throw 'Missing case.'}
  $checks=@(foreach($index in 1..3){@{assertion_index=$index;result='Met';reason='Mock observation only.';evidence=@(@{evidence_id='T01-R';quote='Still discussing.'})}})
  $final=@{case_id=$case;result='Pass';first_divergent_turn=$null;failed_assertions=@();hard_failures=@();notes='Mock pipeline only.';assertion_checks=$checks}|ConvertTo-Json -Depth 10 -Compress
}
[IO.File]::WriteAllText($output,$final,[Text.UTF8Encoding]::new($false))
@{type='item.completed';item=@{id='m1';type='agent_message';text=$final}}|ConvertTo-Json -Depth 10 -Compress
'{"type":"turn.completed"}'
'@
$settings=@{RunDirectory=(Join-Path $OutputRoot 'contracts');CodexCommand=$mock;TimeoutSeconds=30;Sandbox='workspace-write'}
$replay=Invoke-AllredCodexEval -Prompt 'contract:replay' -Prefix replay @settings
$initial=Invoke-AllredCodexEval -Prompt 'contract:initial' -Prefix initial -PersistSession $true @settings
$resumed=Invoke-AllredCodexEval -Prompt 'contract:resume' -Prefix resume -PersistSession $true -SessionId $initial.SessionId @settings
$replayArgs=@($replay.Final|ConvertFrom-Json|ForEach-Object {$_})
$initialArgs=@($initial.Final|ConvertFrom-Json|ForEach-Object {$_})
$resumeArgs=@($resumed.Final|ConvertFrom-Json|ForEach-Object {$_})
$checks=@(
  @{name='default replay stays ephemeral';passed=('--ephemeral' -in $replayArgs -and 'resume' -notin $replayArgs)},
  @{name='native start persists';passed=($initial.SessionValid -and '--ephemeral' -notin $initialArgs -and 'resume' -notin $initialArgs)},
  @{name='exact session resume';passed=($resumed.SessionValid -and 'resume' -in $resumeArgs -and $initial.SessionId -in $resumeArgs -and '--last' -notin $resumeArgs -and '--ephemeral' -notin $resumeArgs)},
  @{name='root and sandbox kept';passed=($resumeArgs[1] -eq '--sandbox' -and $resumeArgs[2] -eq 'workspace-write' -and $resumeArgs[3] -eq '-C' -and $resumeArgs[4] -eq $settings.RunDirectory)}
)
foreach($mode in @('missing','wrong','ambiguous')){
  $run=Invoke-AllredCodexEval -Prompt "contract:$mode" -Prefix $mode -PersistSession $true -SessionId $initial.SessionId @settings
  $checks+=@{name="reject $mode identity";passed=($run.ExitCode -eq 125 -and (Test-AllredEvalInfrastructureFailure $run))}
}
foreach($bad in @(@{id='bad';persist=$true},@{id=$initial.SessionId;persist=$false})){
  $rejected=$false
  try{$null=Invoke-AllredCodexEval -Prompt 'contract:bad' -Prefix bad -PersistSession $bad.persist -SessionId $bad.id @settings}catch{$rejected=$true}
  $checks+=@{name='reject invalid resume request';passed=$rejected}
}
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'contracts.json') ($checks|ConvertTo-Json -Depth 5)
if(@($checks|Where-Object {-not $_.passed}).Count){throw 'Native CLI argument or identity contract failed.'}
$suitePath=Join-Path $OutputRoot 'suite.json'
$cases=@(foreach($id in @('I','J')){@{id=$id;group='session-binding';files=@{};turns=@('Discuss only, do not execute.',"Continue $id, keeping prior context.");assertions=@('Continue discussion without execution.')}})
Write-AllredEvalUtf8 $suitePath (@{schema_version=1;cases=$cases}|ConvertTo-Json -Depth 8)
$runRoot=Join-Path $OutputRoot 'native'
$pwsh=(Get-Process -Id $PID).Path
$log=@(& $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'run_runtime_dialogues.ps1') -SkillRoot $SkillRoot -OutputRoot $runRoot -SuitePath $suitePath -SessionMode Native -CodexCommand $mock -TimeoutSeconds 30 2>&1)
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'native.log') ($log -join "`n")
if($LASTEXITCODE -ne 0){throw 'Mock native dialogue pipeline failed.'}
$identities=@()
foreach($case in $cases){
  $workspace=Join-Path $runRoot "$($case.id)/workspace"
  $turns=@(Get-Content -LiteralPath (Join-Path $runRoot "$($case.id)/transcript.json") -Raw -Encoding UTF8|ConvertFrom-Json|ForEach-Object {$_})
  if($turns.Count -ne 2 -or @($turns.session_id|Select-Object -Unique).Count -ne 1 -or $turns[1].requested_session_id -ne $turns[0].session_id){throw 'Session continuity was not recorded.'}
  if((Get-Content -LiteralPath (Join-Path $workspace 'turn-02.prompt.txt') -Raw -Encoding UTF8) -cne $case.turns[1]){throw 'Native next turn re-injected instructions or history.'}
  $identities+=$turns[0].session_id
  $envArgs=@{PromptPath=(Join-Path $workspace 'turn-02.prompt.txt');Turn=$turns[1];InitialPromptPath=(Join-Path $workspace 'turn-01.prompt.txt');InitialEventsPath=(Join-Path $workspace 'turn-01.events.jsonl');EventsPath=(Join-Path $workspace 'turn-02.events.jsonl')}
  $environment=Read-AllredNativeTurnEnvironment @envArgs
  if($environment -cne (Read-AllredActorEnvironment $envArgs.InitialPromptPath)){throw 'Original environment changed during native replay.'}
  foreach($negative in @('identity','requested-identity','prompt','events')){
    $argsForCheck=$envArgs.Clone()
    $turn=$turns[1]|ConvertTo-Json -Depth 8|ConvertFrom-Json
    switch($negative){
      'identity' {$turn.session_id='12345678-1111-2222-3333-000000000003'}
      'requested-identity' {$turn.requested_session_id=''}
      'prompt' {$p=Join-Path $OutputRoot "bad-$($case.id).prompt.txt";Write-AllredEvalUtf8 $p 'Injected authority.';$argsForCheck.PromptPath=$p}
      'events' {$p=Join-Path $OutputRoot "bad-$($case.id).events.jsonl";Write-AllredEvalUtf8 $p '{"type":"thread.started","thread_id":"12345678-1111-2222-3333-000000000003"}';$argsForCheck.EventsPath=$p}
    }
    $argsForCheck.Turn=$turn
    $rejected=$false
    try{$null=Read-AllredNativeTurnEnvironment @argsForCheck}catch{$rejected=$true}
    if(-not $rejected){throw "Unbound native review accepted: $negative"}
  }
}
if(@($identities|Select-Object -Unique).Count -ne 2){throw 'Cases shared a session.'}
$summary=@()
foreach($id in @('I','J')){
  $reviewRoot=Join-Path $OutputRoot "native-review-$id"
  $log=@(& $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'run_ordered_review.ps1') -OutputRoot $reviewRoot -ReplayRoot $runRoot -SuitePath $suitePath -CaseIds $id -CodexCommand $mock -TimeoutSeconds 30 2>&1)
  Write-AllredEvalUtf8 (Join-Path $OutputRoot "native-review-$id.log") ($log -join "`n")
  if($LASTEXITCODE -ne 0){throw "Native dialogue review replay failed: $id"}
  $summary+=@(Get-Content -LiteralPath (Join-Path $reviewRoot 'summary.json') -Raw -Encoding UTF8|ConvertFrom-Json|ForEach-Object {$_})
}
if($summary.Count -ne 2 -or @($summary|Where-Object {-not $_.source_unchanged -or $_.result -ne 'Pass'}).Count){throw 'Native replay changed sources or lost its review.'}
[pscustomobject]@{mock_pipeline='passed';cli_contracts=$checks.Count;cases=2;turns_per_case=2;negative_bindings=8;original_environment_recovered=$true;independent_case_sessions=$true;semantic_quality_proven=$false}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $OutputRoot 'result.json') -Encoding UTF8
'Native session pipeline: PASS (mocked model; session/input/context binding, cross-case isolation, original-evidence replay).'
