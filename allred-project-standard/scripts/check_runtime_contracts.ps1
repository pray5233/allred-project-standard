param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ('allred-runtime-contracts-' + [guid]::NewGuid().ToString('N'))),
  [string]$OnlyScript = ''
)
$ErrorActionPreference = 'Stop'
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$ps = (Get-Process -Id $PID).Path
$results = [System.Collections.Generic.List[object]]::new()
$selectedRunCount = 0
. (Join-Path $SkillRoot 'scripts/state_validation_common.ps1')

function Check([string]$Name, [bool]$Passed, [string]$Evidence) {
  $results.Add([pscustomobject]@{ name = $Name; passed = $Passed; evidence = $Evidence }) | Out-Null
  "{0}: {1}" -f $(if ($Passed) { 'PASS' } else { 'FAIL' }), $Name
}
function Run([string]$Name, [string]$Script, [string[]]$Arguments, [bool]$ExpectedPass = $true, [string]$RejectPattern = '(?i)validation: FAIL|packet lint: FAIL') {
  if ($OnlyScript -and $Script -ne $OnlyScript) { return }
  $script:selectedRunCount++
  $previousErrorAction = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = @(& $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $SkillRoot "scripts/$Script") @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousErrorAction }
  $evidence = $output -join [Environment]::NewLine
  $passed = if ($ExpectedPass) { $code -eq 0 } else { $code -ne 0 -and $evidence -match $RejectPattern }
  Check $Name $passed $evidence
}
function New-State {
  Get-Content -LiteralPath (Join-Path $SkillRoot 'tests/project-state.valid-ready.json') -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Save-State([string]$Name, [object]$State) {
  $path = Join-Path $OutputRoot "$Name.json"
  $State.preflight.execution_record.path = Join-Path $SkillRoot 'tests/execution-record.valid.md'
  [System.IO.File]::WriteAllText($path, ($State | ConvertTo-Json -Depth 25), [System.Text.UTF8Encoding]::new($false))
  return $path
}

Check 'path-normalized-escape' (-not (Test-AllredPathWithin -Root 'C:/review/project' -Candidate 'C:/review/project/../outside.txt')) 'Parent segment must escape the allowed root.'
Check 'path-child' (Test-AllredPathWithin -Root 'C:/review/project' -Candidate 'C:/review/project/src/file.txt') 'A normal child remains allowed.'
Check 'path-sibling-prefix' (-not (Test-AllredPathWithin -Root 'C:/review/project' -Candidate 'C:/review/project-other/file.txt')) 'A sibling with a shared prefix is outside.'
Check 'path-dot-normalization' (Test-AllredPathWithin -Root 'C:/review/project' -Candidate 'C:/review/project/src/../file.txt') 'An internal parent segment can still resolve inside.'

Run 'event-id-is-not-authority' 'get_route_context.ps1' @('-Route','new-standard','-Stage','decision','-ValidatedEventId','E_NOT_REAL') $false 'Event IDs are observations'
Run 'new-software-conversation-without-state' 'get_route_context.ps1' @('-Route','new-standard','-Stage','decision')
Run 'new-document-conversation-without-state' 'get_route_context.ps1' @('-Route','non-software','-Variant','training','-Stage','decision')
Run 'new-software-ready-needs-state' 'get_route_context.ps1' @('-Route','new-standard','-Stage','ready') $false 'Current StatePath is required'
Run 'new-software-execution-needs-state' 'get_route_context.ps1' @('-Route','new-standard','-Stage','execution') $false 'Current StatePath is required'
Run 'new-document-ready-needs-state' 'get_route_context.ps1' @('-Route','non-software','-Variant','training','-Stage','ready') $false 'Current StatePath is required'
foreach ($interaction in @('standard','beginner')) {
  $decisionContext = (& (Join-Path $SkillRoot 'scripts/get_route_context.ps1') -Route new-standard -Stage decision -Interaction $interaction) -join [Environment]::NewLine
  Check "conversation-guidance-no-authority-$interaction" ($decisionContext.Contains('UNVALIDATED CONTEXT ONLY') -and -not $decisionContext.Contains('Actual aggregate validation passed') -and -not $decisionContext.Contains('ValidatedWriteLayout:')) 'Discussion guidance is available without granting readiness or execution.'
}
Run 'new-document-needs-state' 'get_route_context.ps1' @('-Route','non-software','-Variant','training','-Stage','execution') $false 'Current StatePath is required'
$context = (& (Join-Path $SkillRoot 'scripts/get_route_context.ps1') -Route non-software -Variant training -Stage execution -ContextOnly) -join [Environment]::NewLine
Check 'context-preview-is-unvalidated' ($context.Contains('UNVALIDATED CONTEXT ONLY') -and -not $context.Contains('Actual aggregate validation passed') -and -not $context.Contains('ValidatedWriteLayout:')) 'Documentation cannot claim a passed gate or validated layout.'
$existing = (& (Join-Path $SkillRoot 'scripts/get_route_context.ps1') -Route non-software -WorkKind existing -Stage execution) -join [Environment]::NewLine
Check 'existing-document-no-fake-pass' (-not $existing.Contains('Actual aggregate validation passed')) 'Existing authorization is not machine-validation evidence.'

$short = "1. Who will use it?" + [Environment]::NewLine + "2. What outcome matters most?"
$one = 'What should participants complete during the exercise? This determines the practice task.'
$wide = (1..12 | ForEach-Object { '{0}. Who owns step {0}?' -f $_ }) -join [Environment]::NewLine
Run 'packet-lint-output' 'validate_question_packet.ps1' @('-Text',$short,'-PassThrough')
$packetOutput = @($results | Where-Object name -eq 'packet-lint-output')
if ($packetOutput.Count) {
  Check 'packet-lint-is-not-approval' ($packetOutput[0].evidence.Contains('---BEGIN LINTED QUESTION PACKET---') -and -not $packetOutput[0].evidence.Contains('APPROVED QUESTION PACKET') -and $packetOutput[0].evidence.Contains('Neither readability nor that guard establishes complete discovery, READY, or execution authorization')) 'A packet-lint result cannot approve product decisions, discovery, or execution.'
}
foreach ($profile in @('generic','decision-frontier','training','shared-collaboration','inspection-discovery')) {
  Run "natural-questions-$profile" 'validate_question_packet.ps1' @('-Text',$short,'-Profile',$profile)
  Run "remaining-followup-$profile" 'validate_question_packet.ps1' @('-Text',$one,'-Profile',$profile)
  Run "oversized-packet-advisory-$profile" 'validate_question_packet.ps1' @('-Text',$wide,'-Profile',$profile)
}
Run 'long-packet-advisory' 'validate_question_packet.ps1' @('-Text',('What changes? ' + ('x' * 1801)))
Run 'repeated-reply-instructions-advisory' 'validate_question_packet.ps1' @('-Text',("1. Who uses it?" + [Environment]::NewLine + "Reply: name them." + [Environment]::NewLine + "2. What result?" + [Environment]::NewLine + "Reply: describe it."))

$validPath = Save-State 'valid-ready' (New-State)
Run 'ready-context-loads-real-state' 'get_route_context.ps1' @('-Route','new-standard','-Stage','ready','-StatePath',$validPath,'-GuardsOnly')
$readyContextTest = @($results | Where-Object name -eq 'ready-context-loads-real-state')
if ($readyContextTest.Count) {
  $layoutText = [regex]::Match($readyContextTest[0].evidence, '(?m)^ValidatedWriteLayout: (.+)$').Groups[1].Value
  $layout = if ($layoutText) { $layoutText | ConvertFrom-Json } else { $null }
  $expectedLayout = (New-State).write_boundary
  Check 'ready-layout-matches-state' ($null -ne $layout -and $layout.project_root -eq $expectedLayout.project_root -and ($layout.planned_paths -join '|') -ceq ($expectedLayout.planned_paths -join '|')) 'The visible envelope receives the exact validated paths, not a reconstructed layout.'
}
Run 'ready-preview-is-not-execution' 'get_route_context.ps1' @('-Route','new-standard','-Stage','execution','-StatePath',$validPath) $false 'EXECUTION was blocked'
Run 'existing-valid-ready' 'invoke_validation_gate.ps1' @('-Path',$validPath,'-ToStage','READY')
Run 'pending-start-rejected' 'invoke_validation_gate.ps1' @('-Path',$validPath,'-ToStage','EXECUTION') $false
$approved = New-State
$approved.user_sources += [pscustomobject]@{ id='U4'; quote='Approve the complete C1 scope and start implementation.'; meaning='Start the exact C1 scope.'; authority='requirement' }
$approved.authorization.state = 'approved'
$approved.authorization.approval_source = 'U4'
Run 'exact-start-accepted' 'invoke_validation_gate.ps1' @('-Path',(Save-State 'approved-start' $approved),'-ToStage','EXECUTION')
foreach ($fixture in @(
  @{ name='invalid-stage'; stage='DECISION' },
  @{ name='invalid-frontier'; stage='DECISION' },
  @{ name='invalid-ready'; stage='READY' }
)) {
  Run ("legacy-" + $fixture.name) 'invoke_validation_gate.ps1' @('-Path',(Join-Path $SkillRoot ("tests/project-state." + $fixture.name + ".json")),'-ToStage',$fixture.stage) $false
}

$state = New-State
$state.decisions[1].status = 'open'
$state.decisions[1].choice = ''
$state.decisions[1].approval_source = $null
$state.decisions[2].status = 'waiting'
$state.decisions[2].choice = ''
$state.decisions[2].approval_source = $null
$state.decisions[2].exposed = $false
$state.decisions[2] | Add-Member -NotePropertyName reason -NotePropertyValue 'The parent service choice controls whether credentials are needed.'
$state.decisions[2].recommendation = $null
$waitingPath = Save-State 'waiting-child' $state
Run 'waiting-child-retained' 'validate_decision_frontier.ps1' @('-Path',$waitingPath)
Run 'waiting-child-not-visible' 'validate_question_packet.ps1' @('-Text','Who stores the credential?','-StatePath',$waitingPath,'-QuestionIds','D3') $false
Run 'answered-parent-not-reasked' 'validate_question_packet.ps1' @('-Text','Which delivery?','-StatePath',$waitingPath,'-QuestionIds','D1') $false
Run 'open-parent-eligible' 'validate_question_packet.ps1' @('-Text','Which service route?','-StatePath',$waitingPath,'-QuestionIds','D2')
Run 'anonymous-state-slice-rejected' 'validate_question_packet.ps1' @('-Text','Which service route?','-StatePath',$waitingPath) $false 'require QuestionIds'
Run 'visible-slice-mismatch-rejected' 'validate_question_packet.ps1' @('-Text','D3: Who stores the credential?','-StatePath',$waitingPath,'-QuestionIds','D2') $false 'outside the selected state slice'
Run 'estimated-question-mapping-advisory' 'validate_question_packet.ps1' @('-Text',$short,'-StatePath',$waitingPath,'-QuestionIds','D2')
$unknown = New-State
$unknown | Add-Member -NotePropertyName questions -NotePropertyValue @([pscustomobject]@{ id='Q1'; status='unknown'; source='U1'; value=$null })
Run 'unknown-fact-not-reasked' 'validate_question_packet.ps1' @('-Text','What is the volume?','-StatePath',(Save-State 'unknown-fact' $unknown),'-QuestionIds','Q1') $false

function New-PacketState {
  $packetState = New-State
  $packetState.decisions = @([pscustomobject]@{ id='D1'; axis='desired-behavior'; status='open'; choice=$null; exposed=$false; trigger='user:U1'; depends_on=@(); approval_source=$null; recommendation=$null })
  $packetState | Add-Member -NotePropertyName questions -NotePropertyValue @([pscustomobject]@{ id='Q1'; status='open'; source='U1'; value=$null })
  return $packetState
}

foreach ($route in @('new-standard', 'non-software')) {
  $packetState = New-PacketState
  $packetState.route = $route
  Run "packet-$route-valid" 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State "packet-$route-valid" $packetState),'-QuestionIds','D1','-PassThrough')
  foreach ($facet in @('outcome', 'materials', 'initial_idea', 'useful_result', 'complexity')) {
    $packetState = New-PacketState
    $packetState.route = $route
    if ($facet -eq 'complexity') {
      $packetState.complexity.assessment = 'non-simple'
      $packetState.complexity.communicated = $false
      $diagnostic = 'complexity was not communicated'
    } else {
      $packetState.intake.$facet.status = 'open'
      $diagnostic = "readiness item $facet is not complete"
    }
    $packetPath = Save-State "packet-$route-missing-$facet" $packetState
    Run "packet-$route-blocks-$facet" 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',$packetPath,'-QuestionIds','D1','-PassThrough') $false $diagnostic
  }
}
$packetState = New-PacketState
$packetState.intake.materials.status = 'open'
$packetPath = Save-State 'packet-incomplete' $packetState
$packetHash = (Get-FileHash -LiteralPath $packetPath).Hash
Run 'packet-failed-stage' 'invoke_validation_gate.ps1' @('-Path',$packetPath,'-ToStage','DECISION') $false 'readiness item materials is not complete'
Run 'packet-failed-stage-cannot-pass-draft' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',$packetPath,'-QuestionIds','D1','-PassThrough') $false 'Product decision packet blocked'
Run 'packet-factual-intake-remains-usable' 'validate_question_packet.ps1' @('-Text','Where are the materials?','-PassThrough')
Run 'packet-q-label-cannot-bypass-stage' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',$packetPath,'-QuestionIds','Q1','-PassThrough') $false 'readiness item materials is not complete'
$qOnly = New-PacketState
$qOnly.decisions = @()
$qOnly.complexity.assessment = 'non-simple'
$qOnly.complexity.communicated = $false
Run 'packet-q-only-still-needs-communication' 'validate_question_packet.ps1' @('-Text','Which outcome is useful?','-StatePath',(Save-State 'q-only-uncommunicated' $qOnly),'-QuestionIds','Q1') $false 'complexity was not communicated'
$qOnly.complexity.communicated = $true
Run 'packet-q-only-valid-stage' 'validate_question_packet.ps1' @('-Text','Which outcome is useful?','-StatePath',(Save-State 'q-only-valid' $qOnly),'-QuestionIds','Q1')
Run 'packet-mixed-slice-needs-stage' 'validate_question_packet.ps1' @('-Text',("Q1: Where are the materials?" + [Environment]::NewLine + "D1: Which behavior is useful?"),'-StatePath',$packetPath,'-PassThrough') $false 'Product decision packet blocked'
Run 'packet-new-route-cannot-override-kind' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',$packetPath,'-QuestionIds','D1','-WorkKind','existing','-PassThrough') $false 'new-project route cannot'
$packetState.intake.materials.status = 'unavailable'
Run 'packet-resolved-intake-recovers' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-resolved' $packetState),'-QuestionIds','D1','-PassThrough')
$transportPath = Save-State 'packet-transport' $packetState
$twoQuestions = "1. Which behavior is useful?`n2. Where are the remaining materials?"
Run 'packet-cli-comma-separated-ids' 'validate_question_packet.ps1' @('-Text',$twoQuestions,'-StatePath',$transportPath,'-QuestionIds','D1,Q1')
Run 'packet-cli-comma-with-spaces' 'validate_question_packet.ps1' @('-Text',$twoQuestions,'-StatePath',$transportPath,'-QuestionIds',' D1, Q1 ')
Run 'packet-cli-comma-duplicate-rejected' 'validate_question_packet.ps1' @('-Text',$twoQuestions,'-StatePath',$transportPath,'-QuestionIds','D1,D1') $false 'IDs must be unique'
Run 'packet-cli-comma-empty-rejected' 'validate_question_packet.ps1' @('-Text',$twoQuestions,'-StatePath',$transportPath,'-QuestionIds','D1,') $false 'Question is not in current state'
Check 'packet-validation-preserves-input' ((Get-FileHash -LiteralPath $packetPath).Hash -eq $packetHash) 'Gate and packet validation must not repair the supplied state.'
foreach ($route in @('existing-debug', 'existing-feature', 'existing-ui', 'long-term', 'non-software')) {
  $packetState = New-PacketState
  $packetState.route = $route
  $packetState.intake = $null
  $packetState.complexity = $null
  $packetPath = Save-State "packet-existing-$route" $packetState
  $argsForPacket = @('-Text','Which changed behavior is intended?','-StatePath',$packetPath,'-QuestionIds','D1','-PassThrough')
  if ($route -eq 'non-software') { $argsForPacket += @('-WorkKind','existing') }
  Run "packet-existing-$route-no-intake" 'validate_question_packet.ps1' $argsForPacket
}
$packetState = New-PacketState
$packetState.decisions[0].recommendation = [pscustomobject]@{ option='candidate'; basis=@('E_NOT_REAL') }
Run 'packet-recommendation-needs-evidence' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-bad-basis' $packetState),'-QuestionIds','D1','-PassThrough') $false 'missing evidence basis'
$packetState.route = 'existing-feature'
$packetState.intake = $null
Run 'packet-existing-still-needs-frontier' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-existing-bad-basis' $packetState),'-QuestionIds','D1','-PassThrough') $false 'missing evidence basis'
$packetState = New-PacketState
$packetState.intake.materials.source = 'E_NOT_REAL'
Run 'packet-intake-source-must-exist' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-bad-intake-source' $packetState),'-QuestionIds','D1','-PassThrough') $false 'missing evidence source'
$packetState = New-PacketState
$packetState.decisions[0].depends_on = @([pscustomobject]@{ id='D2'; choices=@('yes') })
Run 'packet-parent-not-invented' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-missing-parent' $packetState),'-QuestionIds','D1','-PassThrough') $false 'dependency is not settled'
$packetState = New-PacketState
$packetState.decisions[0].id = 'Q2'
Run 'packet-decision-not-renamed-as-fact' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-wrong-prefix' $packetState),'-QuestionIds','Q2','-PassThrough') $false 'Invalid decisions ID'
$packetState = New-PacketState
$packetState.route = 'typo-route'
Run 'packet-unknown-route-rejected' 'validate_question_packet.ps1' @('-Text','Which behavior is useful?','-StatePath',(Save-State 'packet-unknown-route' $packetState),'-QuestionIds','D1','-PassThrough') $false 'Unknown state route'
if (-not $OnlyScript -or $OnlyScript -eq 'validate_question_packet.ps1') {
  $blockedPackets = @($results | Where-Object { $_.name -like 'packet-*' -and $_.evidence -match 'Question packet lint: FAIL' })
  Check 'packet-blocked-output-never-renders' ($blockedPackets.Count -gt 0 -and @($blockedPackets | Where-Object { $_.evidence.Contains('---BEGIN LINTED QUESTION PACKET---') -or $_.evidence.Contains('Question packet lint: PASS') -or $_.evidence.Contains('Decision packet guard: PASS') }).Count -eq 0) 'Rejected stage/frontier packets emit diagnostics only, never a draft or passing guard.'
  $validPacket = @($results | Where-Object name -eq 'packet-new-standard-valid')[0]
  Check 'packet-valid-has-actual-guard' ($validPacket.evidence.Contains('actual DECISION aggregate; current state') -and $validPacket.evidence.Contains('---BEGIN LINTED QUESTION PACKET---')) 'New decisions require a real current aggregate, not a prior pass label.'
  $factualPacket = @($results | Where-Object name -eq 'packet-factual-intake-remains-usable')[0]
  Check 'packet-factual-does-not-claim-stage' ($factualPacket.evidence.Contains('NOT RUN (unbound readability check)') -and -not $factualPacket.evidence.Contains('guard: PASS')) 'Initial intake is available without a state and acquires no stage authority.'
}
Run 'waiting-state-not-ready' 'invoke_validation_gate.ps1' @('-Path',$waitingPath,'-ToStage','READY') $false
$state.decisions[2].exposed = $true
Run 'waiting-child-exposure-rejected' 'validate_decision_frontier.ps1' @('-Path',(Save-State 'waiting-exposed' $state)) $false
$state = New-State
$state.decisions[1].choice = 'offline'
Run 'parent-change-invalidates-child' 'validate_decision_frontier.ps1' @('-Path',(Save-State 'changed-parent' $state)) $false
Check 'parent-change-keeps-unrelated-choice' ($state.decisions[0].choice -eq 'desktop') 'Unrelated confirmation is untouched.'
$state = New-State
$state.decisions[0].recommendation.basis = @('E_NOT_REAL')
Run 'missing-evidence-rejected' 'validate_decision_frontier.ps1' @('-Path',(Save-State 'missing-evidence' $state)) $false
$state = New-State
$state.decisions[0].depends_on = @([pscustomobject]@{ id='D3'; choices=@('os-encrypted') })
$state.decisions[1].depends_on = @([pscustomobject]@{ id='D1'; choices=@('desktop') })
Run 'dependency-cycle-rejected' 'validate_decision_frontier.ps1' @('-Path',(Save-State 'cycle' $state)) $false
$state = New-State
$state.write_boundary.planned_paths = @('F:/fixture/allred-project/../outside.txt')
Run 'ready-traversal-rejected' 'validate_ready_scope.ps1' @('-Path',(Save-State 'escaped-write' $state)) $false
$state = New-State
$state.write_boundary.planned_paths = @('F:/fixture/allred-project/../samples/input.pdf')
Run 'protected-alias-rejected' 'validate_ready_scope.ps1' @('-Path',(Save-State 'protected-alias' $state)) $false
$state = New-State
$state.route = 'non-software'
Run 'route-state-mismatch-rejected' 'get_route_context.ps1' @('-Route','new-standard','-Stage','decision','-StatePath',(Save-State 'wrong-route' $state)) $false 'State route does not match'
Run 'document-decision-actually-validates' 'get_route_context.ps1' @('-Route','non-software','-Variant','training','-Stage','decision','-GuardsOnly','-StatePath',(Save-State 'document-state' $state))
$state = New-State
$state.intake.materials.source = 'E_NOT_REAL'
Run 'intake-source-must-exist' 'validate_stage_transition.ps1' @('-Path',(Save-State 'missing-intake-evidence' $state),'-ToStage','DECISION') $false 'missing evidence source'
$state = New-State
$state.decisions += [pscustomobject]@{ id='D4'; axis='unanswered-extra'; status='open'; choice=''; exposed=$false; trigger='user:U1'; depends_on=@() }
Run 'untracked-open-decision-blocks-ready' 'validate_ready_scope.ps1' @('-Path',(Save-State 'untracked-open' $state)) $false 'unresolved decision'
$state.decisions[-1].status = 'proposed'
Run 'unlinked-proposal-blocks-ready' 'validate_ready_scope.ps1' @('-Path',(Save-State 'unlinked-proposal' $state)) $false 'no prominent pending scope'
$state.decisions[-1] | Add-Member -NotePropertyName scope_ids -NotePropertyValue @('S3')
Run 'prominent-proposal-in-ready-envelope' 'validate_ready_scope.ps1' @('-Path',(Save-State 'linked-proposal' $state))
$state = New-State
$state.discovery_coverage.status = 'incomplete'
$state.discovery_coverage.areas[2].status = 'open'
$state.discovery_coverage.areas[2].open_item_ids = @('Q-new-gap')
Run 'new-gap-blocks-ready' 'validate_discovery_coverage.ps1' @('-Path',(Save-State 'new-gap' $state)) $false

# Exercise the public result contract through real validator processes in both modes.
function Packet-Result([string]$Name, [string]$Draft, [string[]]$Arguments, [bool]$Pass, [string]$GuardStatus, $GuardScope, [bool]$HasWarnings = $false) {
  if ($OnlyScript -and $OnlyScript -ne 'validate_question_packet.ps1') { return }
  $packetPath = Join-Path $OutputRoot "$Name.packet.txt"
  [IO.File]::WriteAllText($packetPath,$Draft,[Text.UTF8Encoding]::new($false))
  $hash = (Get-FileHash -LiteralPath $packetPath).Hash
  $argsForPacket = @('-Path',$packetPath) + $Arguments
  Run "$Name-text" 'validate_question_packet.ps1' $argsForPacket $Pass
  Run "$Name-json" 'validate_question_packet.ps1' ($argsForPacket + @('-AsJson')) $Pass '"status":\s*"blocked"'
  $result = $null
  try { $result = $results[$results.Count-1].evidence | ConvertFrom-Json } catch {}
  Check "$Name-one-result" ($null -ne $result -and $result -isnot [array] -and $result.schema_version -eq 1) 'Stdout must contain one structured result, without mixed diagnostics.'
  if ($null -eq $result) { return }
  $nextAction = if (-not $Pass) { 'repair_input' } elseif ($HasWarnings) { 'review_presentation' } else { 'present_questions' }
  Check "$Name-status" ($result.status -eq $(if($Pass){'passed'}else{'blocked'}) -and $result.next_action -eq $nextAction) 'Hard errors block; advisory presentation findings require contextual judgment, not an automatic repair loop.'
  Check "$Name-warning-scope" ((@($result.warnings).Count -gt 0) -eq $HasWarnings -and $result.semantic_validation -eq 'not_performed') 'Heuristic warnings never certify semantics, including when no warnings are present.'
  Check "$Name-guard-scope" ($result.decision_guard.status -eq $GuardStatus -and $result.decision_guard.scope -eq $GuardScope) 'Report the actual guard, not an implied stage or authorization.'
  Check "$Name-packet-visibility" $(if($Pass){$result.questions_text -is [string] -and $result.questions_text -ceq $Draft -and $result.errors.Count -eq 0}else{$null -eq $result.questions_text -and $result.errors.Count -gt 0}) 'Only accepted packets retain exact plain text, without filesystem metadata.'
  Check "$Name-no-authority" ($result.execution_authorized -ceq $false) 'Question output cannot start development.'
  Check "$Name-packet-binding" ($result.input.packet_sha256 -eq $hash -and (Get-FileHash -LiteralPath $packetPath).Hash -eq $hash) 'The result binds the unchanged packet bytes.'
  if ($result.input.state_path) {
    Check "$Name-state-binding" ($result.input.state_sha256 -eq (Get-FileHash -LiteralPath $result.input.state_path).Hash -and @($result.input.question_ids).Count -gt 0) 'The result binds the current state and selected IDs.'
  } else {
    Check "$Name-unbound" ($null -eq $result.input.state_sha256 -and @($result.input.question_ids).Count -eq 0) 'Readability-only output cannot invent a state binding.'
  }
}
Packet-Result 'json-unbound' $short @() $true 'not_run' $null
Packet-Result 'json-with-legacy-switch' $short @('-PassThrough') $true 'not_run' $null
Packet-Result 'json-overwide' $wide @() $true 'not_run' $null $true
Packet-Result 'json-indirect-request' 'Tell me what happens when a record is corrected.' @() $true 'not_run' $null $true
Packet-Result 'json-long-explanation' ('What changes? ' + ('x' * 1801)) @() $true 'not_run' $null $true
Packet-Result 'json-many-lines' ("What changes?`n" + ((1..19 | ForEach-Object { 'supporting detail' }) -join "`n")) @() $true 'not_run' $null $true
Packet-Result 'json-internal-field-advisory' "What changes?`nstate_id: example" @() $true 'not_run' $null $true
Packet-Result 'json-queue-phrase-advisory' 'Do not defer the queued 5 items without authority. Which choice matters now?' @() $true 'not_run' $null $true
Packet-Result 'json-new-project' $one @('-StatePath',$waitingPath,'-QuestionIds','D2') $true 'passed' 'new-project-decision'
Packet-Result 'json-already-answered' $one @('-StatePath',$waitingPath,'-QuestionIds','D1') $false 'not_run' $null
Packet-Result 'json-waiting-parent' $one @('-StatePath',$waitingPath,'-QuestionIds','D3') $false 'not_run' $null
$jsonState = Get-Content -LiteralPath $waitingPath -Raw -Encoding UTF8 | ConvertFrom-Json
$jsonState.intake.materials.status = 'pending'
$jsonBlocked = Save-State 'json-blocked-intake' $jsonState
Packet-Result 'json-blocked-intake' $one @('-StatePath',$jsonBlocked,'-QuestionIds','D2') $false 'failed' 'new-project-decision'
Packet-Result 'json-warning-still-checks-intake' $wide @('-StatePath',$jsonBlocked,'-QuestionIds','D2') $false 'failed' 'new-project-decision' $true
Packet-Result 'json-warning-still-checks-parent' $wide @('-StatePath',$waitingPath,'-QuestionIds','D3') $false 'not_run' $null $true
Packet-Result 'json-warning-still-checks-ids' $wide @('-StatePath',$waitingPath,'-QuestionIds','D_NOT_PRESENT') $false 'not_run' $null $true
$fiveState = New-PacketState
$fiveState.decisions = @(1..5 | ForEach-Object {
  [pscustomobject]@{ id="D$_"; axis="choice-$_"; status='open'; choice=$null; exposed=$false; trigger='user:U1'; depends_on=@(); approval_source=$null; recommendation=$null }
})
$fivePath = Save-State 'five-independent' $fiveState
$fiveDraft = (1..5 | ForEach-Object { "D${_}: Which outcome for step ${_}?" }) -join "`n"
Packet-Result 'json-five-independent-eligible' $fiveDraft @('-StatePath',$fivePath,'-QuestionIds','D1,D2,D3,D4,D5') $true 'passed' 'new-project-decision' $true
$jsonState.route = 'existing-feature'
$jsonExisting = Save-State 'json-existing' $jsonState
Packet-Result 'json-existing' $one @('-StatePath',$jsonExisting,'-QuestionIds','D2') $true 'passed' 'existing-work-frontier'

$report = [pscustomobject]@{
  generated_at = [DateTime]::UtcNow.ToString('o')
  selected_script = $OnlyScript
  selected_script_runs = $selectedRunCount
  version = (Get-Content -LiteralPath (Join-Path $SkillRoot 'VERSION') -Raw).Trim()
  runtime_files = @(Get-ChildItem -LiteralPath (Join-Path $SkillRoot 'scripts') -File -Filter '*.ps1' | Sort-Object Name | ForEach-Object { [pscustomobject]@{ name=$_.Name; sha256=(Get-FileHash -LiteralPath $_.FullName).Hash } })
  skill_root = $SkillRoot
  total = $results.Count
  passed = @($results | Where-Object passed).Count
  failed = @($results | Where-Object { -not $_.passed }).Count
  results = @($results)
}
$reportPath = Join-Path $OutputRoot 'runtime-contracts.json'
[System.IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
"Report: $reportPath"
if ($report.failed -gt 0) { exit 1 }
if ($OnlyScript -and $selectedRunCount -eq 0) { throw 'No test cases matched OnlyScript.' }
'Runtime contracts: PASS'
