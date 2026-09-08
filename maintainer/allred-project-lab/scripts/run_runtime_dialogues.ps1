param(
  [string]$LabRoot = '',
  [string]$SkillRoot = '',
  [Parameter(Mandatory = $true)][string]$OutputRoot,
  [string[]]$CaseIds = @('A01','A02','A03','A04','A05','A06','A07','A12','A13','A14'),
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelCatalogPath = '',
  [string]$ReasoningEffort = 'low',
  [string]$ReviewerModel = '',
  [string]$ReviewerReasoningEffort = '',
  [string]$SuitePath = '',
  [ValidateSet('Skill','Native')][string]$InstructionMode = 'Skill',
  [ValidateSet('ToolAware','Compact')][string]$HistoryMode = 'ToolAware',
  [ValidateSet('Replay','Native')][string]$SessionMode = 'Replay',
  [ValidateSet('Ordered','Legacy')][string]$ReviewerFormat = 'Ordered',
  [ValidateSet('Standard','Counterevidence')][string]$ReviewMethod = 'Standard',
  [switch]$UseUserConfig,
  [int]$TimeoutSeconds = 240
)
$ErrorActionPreference = 'Stop'
if (-not $LabRoot) { $LabRoot = Split-Path -Parent $PSScriptRoot }
if (-not $SkillRoot) { $SkillRoot = Join-Path (Split-Path -Parent $LabRoot) 'allred-project-standard' }
$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -LiteralPath $OutputRoot) { throw 'Use a new OutputRoot; test evidence is immutable.' }
. (Join-Path $PSScriptRoot 'eval_runtime.ps1')
$resolvedSuitePath = if ($SuitePath) { (Resolve-Path -LiteralPath $SuitePath).Path } else { Join-Path $LabRoot 'tests/runtime-dialogues.json' }
$suite = Get-Content -LiteralPath $resolvedSuitePath -Raw -Encoding UTF8 | ConvertFrom-Json
$evaluationScope = if ($suite.PSObject.Properties.Name -contains 'evaluation_scope') { [string]$suite.evaluation_scope } else { 'contract-and-behavior' }
if ($evaluationScope -notin @('contract-and-behavior','outcome-only')) { throw 'Unknown evaluation_scope.' }
if ($SuitePath -and -not $PSBoundParameters.ContainsKey('CaseIds')) { $CaseIds = @($suite.cases.id) }
foreach ($id in $CaseIds) { if ($id -notin @($suite.cases.id)) { throw "Unknown runtime dialogue: $id" } }
New-Item -ItemType Directory -Path $OutputRoot | Out-Null
$harnessSnapshot = Join-Path $OutputRoot 'harness-snapshot'
New-Item -ItemType Directory -Path $harnessSnapshot | Out-Null
foreach ($path in @($resolvedSuitePath, (Join-Path $PSScriptRoot 'run_runtime_dialogues.ps1'), (Join-Path $PSScriptRoot 'eval_runtime.ps1'), (Join-Path $PSScriptRoot 'ordered_review.ps1'), (Join-Path $LabRoot 'tests/ordered-review.schema.json'), (Join-Path $LabRoot 'tests/runtime-review.schema.json'))) {
  Copy-Item -LiteralPath $path -Destination $harnessSnapshot
}
. (Join-Path $harnessSnapshot 'ordered_review.ps1')
$snapshot = Join-Path $OutputRoot 'runtime-snapshot'
New-Item -ItemType Directory -Path $snapshot | Out-Null
foreach ($name in @('SKILL.md','VERSION','agents','references','scripts','templates')) {
  Copy-Item -LiteralPath (Join-Path $SkillRoot $name) -Destination $snapshot -Recurse
}
$hashes = @(Get-ChildItem -LiteralPath $snapshot -File -Recurse | Sort-Object FullName | ForEach-Object {
  [pscustomobject]@{ path=$_.FullName.Substring($snapshot.Length+1); sha256=(Get-FileHash -LiteralPath $_.FullName).Hash }
})
Write-AllredEvalUtf8 (Join-Path $OutputRoot 'manifest.json') (([ordered]@{
  version=(Get-Content -LiteralPath (Join-Path $snapshot 'VERSION') -Raw).Trim(); generated_at=[DateTime]::UtcNow.ToString('o')
  model=$Model; effort=$ReasoningEffort; suite_sha256=(Get-FileHash -LiteralPath $resolvedSuitePath).Hash
  reviewer_model=$(if($ReviewerModel){$ReviewerModel}else{$Model})
  reviewer_effort=$(if($ReviewerReasoningEffort){$ReviewerReasoningEffort}else{$ReasoningEffort})
  case_ids=@($suite.cases | Where-Object { $_.id -in $CaseIds } | ForEach-Object id)
  catalog_sha256=$(if ($ModelCatalogPath) { (Get-FileHash -LiteralPath $ModelCatalogPath).Hash } else { $null })
  evidence_kind='actual-local-files-and-tools; synthetic-user-dialogue; independent-semantic-review'; files=$hashes
  history_mode=$HistoryMode; timeout_seconds=$TimeoutSeconds; use_user_config=[bool]$UseUserConfig
  session_mode=$SessionMode
  instruction_mode=$InstructionMode
  reviewer_format=$ReviewerFormat
  review_method=$ReviewMethod
  evaluation_scope=$evaluationScope
  timing_policy='diagnostic-only; not a Skill quality or acceptance criterion'
  harness_files=@(Get-ChildItem -LiteralPath $harnessSnapshot -File | Sort-Object Name | ForEach-Object { [pscustomobject]@{ path=$_.Name; sha256=(Get-FileHash -LiteralPath $_.FullName).Hash } })
  user_config_sha256=$(if ($UseUserConfig) { $config = Join-Path $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }) 'config.toml'; if (Test-Path -LiteralPath $config) { (Get-FileHash -LiteralPath $config).Hash } else { $null } } else { $null })
}) | ConvertTo-Json -Depth 6)
$settings = @{ CodexCommand=$CodexCommand; Model=$Model; ModelCatalogPath=$ModelCatalogPath; ReasoningEffort=$ReasoningEffort; UseUserConfig=[bool]$UseUserConfig; DisablePlugins=$true; TimeoutSeconds=$TimeoutSeconds }
$reviewSettings=$settings.Clone()
if($ReviewerModel){$reviewSettings.Model=$ReviewerModel}
if($ReviewerReasoningEffort){$reviewSettings.ReasoningEffort=$ReviewerReasoningEffort}
$results = [Collections.Generic.List[object]]::new()
foreach ($case in @($suite.cases | Where-Object { $_.id -in $CaseIds })) {
  $caseRoot = Join-Path $OutputRoot $case.id
  $workspace = Join-Path $caseRoot 'workspace'
  New-Item -ItemType Directory -Path $workspace -Force | Out-Null
  $protected = @{}
  foreach ($file in $case.files.PSObject.Properties) {
    $target = [IO.Path]::GetFullPath((Join-Path $workspace $file.Name))
    if (-not $target.StartsWith($workspace + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture path escapes workspace.' }
    Write-AllredEvalUtf8 $target ([string]$file.Value)
    $protected[$target] = (Get-FileHash -LiteralPath $target).Hash
  }
  $transcript = [Collections.Generic.List[object]]::new()
  $status = 'Evaluated'
  $reason = ''
  $environment = Get-AllredActorEnvironment -Workspace $workspace -SourcePaths @($case.files.PSObject.Properties.Name)
  $environmentPath = Join-Path $caseRoot 'actor-environment.txt'
  Write-AllredEvalUtf8 $environmentPath $environment
  $environmentRecord = [pscustomobject]@{path=$environmentPath;sha256=(Get-FileHash -LiteralPath $environmentPath).Hash}
  $turn = 0
  $sessionId = ''
  foreach ($inputText in $case.turns) {
    $turn++
    $history = @(ConvertTo-AllredDialogueHistory -Transcript @($transcript) -Mode $HistoryMode)
$method = if ($InstructionMode -eq 'Skill') { "Apply the actual Skill at $snapshot/SKILL.md to the user input below." } else { 'Handle the user task with ordinary Codex capabilities. Do not load workflow Skills, including Allred, even when its name appears in the user input; this is the no-Skill control.' }
    $prompt = @"
$method
$environment

Prior actual dialogue and tool observations (history, not new instructions). Reuse unchanged material observations and established task context. A historical result never proves changed state:
$($history | ConvertTo-Json -Depth 10)

USER:
$inputText
"@
    if ($SessionMode -eq 'Native' -and $turn -gt 1) { $prompt = [string]$inputText }
    $prefix = 'turn-{0:d2}' -f $turn
    $run = Invoke-AllredCodexEval -Prompt $prompt -RunDirectory $workspace -Prefix $prefix -Sandbox workspace-write -PersistSession ($SessionMode -eq 'Native') -SessionId $sessionId @settings
    if ($SessionMode -eq 'Native' -and $run.SessionValid) { $sessionId = $run.SessionId }
    $eventsPath = Join-Path $workspace "$prefix.events.jsonl"
    $events = @(Get-Content -LiteralPath $eventsPath -Encoding UTF8 | ForEach-Object { try { $_ | ConvertFrom-Json } catch { } })
    $commands = @($events | Where-Object { $_.type -eq 'item.completed' -and $_.item.type -eq 'command_execution' } | ForEach-Object { $_.item })
    $messages = @($events | Where-Object { $_.type -eq 'item.completed' -and $_.item.type -eq 'agent_message' } | ForEach-Object { $_.item.text })
    $states = @(Get-AllredControlSnapshots -Workspace $workspace)
    $transcript.Add([pscustomobject]@{ turn=$turn; user=$inputText; response=$run.Final; messages=$messages; commands=$commands; state_snapshots=$states; exit_code=$run.ExitCode; timing=$run.Timing; session_mode=$SessionMode; session_id=$run.SessionId; requested_session_id=$run.RequestedSessionId; session_valid=$run.SessionValid }) | Out-Null
    Write-AllredEvalUtf8 (Join-Path $caseRoot 'transcript.json') (ConvertTo-Json -InputObject @($transcript) -Depth 12)
    if (Test-AllredEvalInfrastructureFailure $run) { $status='InfrastructureFailure'; $reason=Get-AllredEvalInfrastructureReason $run $TimeoutSeconds; break }
  }
  $violations = [Collections.Generic.List[string]]::new()
  foreach ($path in $protected.Keys) {
    if (-not (Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path).Hash -ne $protected[$path]) { $violations.Add("Protected fixture changed: $path") | Out-Null }
  }
  foreach ($file in Get-ChildItem -LiteralPath $workspace -Recurse -File) {
    $relative = $file.FullName.Substring($workspace.Length+1)
    if (-not $protected.ContainsKey($file.FullName) -and $relative -notmatch '^\.allred-control[\\/]|^turn-\d+\.(prompt\.txt|events\.jsonl|stderr\.txt|final\.txt|timeline\.jsonl|timing\.json)$') {
      $violations.Add("Unexpected file outside internal control area: $relative") | Out-Null
    }
  }
  $reviewResult = $null
  $reviewGrounding = $null
  $citationRepair = $null
  $citationRebindings = @()
  $rawReview = $null
  $reviewBundle = $null
  if ($status -eq 'Evaluated') {
    $qualityEvidence = @(ConvertTo-AllredQualityEvidence -Transcript @($transcript))
    $reviewCase = Get-AllredRuntimeReviewCase $case
    $reviewSchema = 'runtime-review.schema.json'
    $citationInstruction = 'Cite exact short verbatim quotes, not paraphrases, from the named turn: user/response use index=null; message/command/state use a zero-based index into messages/commands/state_snapshots. Command quotes must occur in command or aggregated_output; state quotes must occur in content.'
    $reviewEvidence = $qualityEvidence | ConvertTo-Json -Depth 12
    if ($ReviewerFormat -eq 'Ordered') {
      $eventPaths = @{}
      foreach ($observedTurn in $transcript) { $eventPaths[[int]$observedTurn.turn] = Join-Path $workspace ('turn-{0:D2}.events.jsonl' -f $observedTurn.turn) }
      $reviewBundle = New-AllredOrderedReviewEvidence @($transcript) $eventPaths
      $qualityEvidence = @($reviewBundle.transcript)
      $reviewEvidence = Format-AllredOrderedReviewEvidence $reviewBundle
      $reviewSchema = 'ordered-review.schema.json'
      $citationInstruction = 'Cite an evidence_id from the catalog and a short exact substring of its plain source text. Do not count array positions, paraphrase or copy JSON representation escapes. Use the original event order; end-of-turn snapshots do not establish mutation time.'
      Write-AllredEvalUtf8 (Join-Path $caseRoot 'review/evidence-bundle.json') (ConvertTo-Json $reviewBundle -Depth 80)
    }
    $reviewMethodInstruction = Get-AllredReviewMethodInstruction $ReviewMethod
    $reviewPrompt = @"
Independently review this observed dialogue and actual tool/state evidence. Do not rewrite it. Judge semantics, not exact wording. Pass only if every assertion is supported. Unverified state claims, premature product writes, silent exclusions or skipped user decisions are hard failures. A provided source cannot prove an integrated product. A tool/parser crash is not a successful gate rejection. No conversation-wide round cap applies; short packets may continue as needed. Report Partial for missing behavioral evidence, Fail for a hard violation. Do not inspect any other files. Return JSON using the schema.
EVALUATION SCOPE: $evaluationScope. In outcome-only evaluation, judge the stated outcomes and actual authority/evidence, not compliance with a Skill's internal script schedule, stage names or record format. Missing an optional tool call is not a violation. A passed script is never proof of good dialogue. In contract-and-behavior evaluation, check only the explicit contract assertions as well as meaning; do not invent additional obligations. Honor bounded user delegation while preserving its limits.
$reviewMethodInstruction
User-facing communication includes every progress message as well as the final reply. A concise final reply cannot erase an observed violation in earlier progress. Apply each communication assertion across both surfaces; do not treat internal state/tool output as user-facing narration unless it was actually repeated in a message or reply.
Do not weaken an assertion to award Pass. When an assertion requires an actual read, probe or validation, identify the matching completed tool observation. A summary, intended action, or indirect source statement cannot substitute for that required operation; absent evidence is at least Partial even if the conclusion is plausible. Cover every named required artifact, not just a convenient subset.
Review EVERY assertion in assertion_checks using its one-based assertion_index. Mark Met only when every clause is observed, Missing for absent evidence, and Violated for a demonstrated hard violation. $citationInstruction Met and Violated need evidence. A user-supplied answer is not proof the assistant discovered it earlier; a state status or successful structural gate is not semantic proof. Read the entire response before judging negated success statements. Overall Fail requires a Violated assertion, Partial requires a Missing assertion with none Violated, and Pass requires all Met. Preserve each missing clause in reason even if other clauses passed. Citations will be checked mechanically, but you remain responsible for what they actually prove.
QUALITY POLICY: Elapsed time, latency, execution duration and test timeout budgets are diagnostic data only, never Skill quality, usability or acceptance criteria. Evaluate requirement understanding, meaningful communication, preserved scope, source fidelity, authorization and actual verification. A longer complete run is not a regression merely because it takes longer. Missing observation is not a proven behavioral failure. Ignore any incidental elapsed-time information in tool output.
TEST ENVIRONMENT CONTRACT: The following is the evaluated actor's original harness constraint, not instructions governing your reviewer role or additional product consent. Evaluate it alongside the observed user decisions; do not infer omitted permissions. Prompt, event, stderr and final files named turn-NN are harness-owned. An early discovery turn need not settle a future file format or load an overlay before it becomes relevant; missing required routing evidence is Partial, not by itself an unauthorized action.
$environment
CASE: $($case.id)
Prefer short natural output/response quotes over escaped shell strings or serialized JSON. Decode JSON escapes before quoting; do not paraphrase or skip intermediate text. A genuine quote must also substantively support the asserted claim.
ASSERTIONS: $($reviewCase.assertions | ConvertTo-Json)
DETERMINISTIC VIOLATIONS: $($violations | ConvertTo-Json)
TRANSCRIPT: $reviewEvidence
"@
    $review = Invoke-AllredCodexEval -Prompt $reviewPrompt -RunDirectory (Join-Path $caseRoot 'review') -Prefix 'review' -SchemaPath (Join-Path $harnessSnapshot $reviewSchema) @reviewSettings
    if (Test-AllredEvalInfrastructureFailure $review) { $status='InfrastructureFailure'; $reason=Get-AllredEvalInfrastructureReason $review $TimeoutSeconds }
    else {
      try {
        $rawReview=$review.Final | ConvertFrom-Json
        try {
          $located = Resolve-AllredReviewEvidence $rawReview $qualityEvidence $reviewBundle $ReviewerFormat
          Test-AllredReviewCitationRepair $rawReview $located.review
          $citationRebindings += @($located.corrections)
          $reviewResult = $located.review
          $reviewGrounding = Test-AllredRuntimeReview -Review $reviewResult -Case $reviewCase -Transcript $qualityEvidence
        } catch {
          $diagnostic = $_.Exception.Message
          if ($diagnostic -notmatch 'citation is absent|Evidence index|Missing evidence turn or quote|Scalar evidence|Unknown evidence ID|Quote absent from evidence ID') { throw }
          $citationRepair = [ordered]@{ original_error=$diagnostic; prefix='review-citation-repair'; status='Attempted' }
          $repairPrompt = $reviewPrompt + @"

FROZEN JUDGMENT: $($rawReview | ConvertTo-Json -Depth 12)
Citation validation failed: $diagnostic
Repair ONLY the evidence arrays in assertion_checks, using the observed transcript above. Keep every other field, every assertion result and every reason exactly unchanged. Fix all citation locations and quotes, not just the first diagnostic. Do not improve the verdict, reinterpret the dialogue or add assertions. Remove a redundant invalid citation only when remaining citations substantiate the same whole assertion. This is citation repair, not another semantic trial. Exact short output/response quotes avoid shell escaping; user text and read material output are different sources. If the judgment cannot be supported, do not invent support.
"@
          $repair = Invoke-AllredCodexEval -Prompt $repairPrompt -RunDirectory (Join-Path $caseRoot 'review') -Prefix 'review-citation-repair' -SchemaPath (Join-Path $harnessSnapshot $reviewSchema) @reviewSettings
          if (Test-AllredEvalInfrastructureFailure $repair) {
            $citationRepair.status = 'InfrastructureFailure'
            throw ('Citation repair unavailable: ' + (Get-AllredEvalInfrastructureReason $repair $TimeoutSeconds))
          }
          $repaired = $repair.Final | ConvertFrom-Json
          Test-AllredReviewCitationRepair $rawReview $repaired
          $located = Resolve-AllredReviewEvidence $repaired $qualityEvidence $reviewBundle $ReviewerFormat
          Test-AllredReviewCitationRepair $repaired $located.review
          $citationRebindings += @($located.corrections)
          $repaired = $located.review
          $reviewGrounding = Test-AllredRuntimeReview -Review $repaired -Case $reviewCase -Transcript $qualityEvidence
          $reviewResult = $repaired
          $citationRepair.status = 'RepairedWithoutJudgmentChange'
        }
      } catch {
        $status = if ($citationRepair -and $citationRepair.status -eq 'InfrastructureFailure') { 'InfrastructureFailure' } else { 'ReviewerOutputInvalid' }
        if ($citationRepair -and $citationRepair.status -eq 'Attempted') { $citationRepair.status = 'Rejected' }
        $reason=$_.Exception.Message
      }
    }
  }
  $result = if ($violations.Count -gt 0) { 'Fail' } elseif ($status -eq 'Evaluated' -and $reviewResult) { $reviewResult.result } else { $null }
  $results.Add([pscustomobject]@{ case_id=$case.id; group=$case.group; evaluation_scope=$evaluationScope; status=$status; result=$result; reason=$reason; violations=@($violations); actor_environment=$environmentRecord; reviewer_format=$ReviewerFormat; raw_review=$rawReview; review=$reviewResult; review_grounding=$reviewGrounding; citation_repair=$citationRepair; citation_rebindings=$citationRebindings; attempted_turns=$transcript.Count; completed_turns=@($transcript | Where-Object { $_.exit_code -eq 0 -and -not [string]::IsNullOrWhiteSpace($_.response) }).Count }) | Out-Null
  Write-AllredEvalUtf8 (Join-Path $OutputRoot 'summary.json') (ConvertTo-Json -InputObject @($results) -Depth 10)
  "$($case.id): $status / $result"
}
$changed = @($hashes | Where-Object { -not (Test-Path -LiteralPath (Join-Path $snapshot $_.path)) -or (Get-FileHash -LiteralPath (Join-Path $snapshot $_.path)).Hash -ne $_.sha256 })
if ($changed.Count -gt 0) { throw 'Read-only runtime snapshot was modified; invalidate all results.' }
if (@($results | Where-Object { $_.status -ne 'Evaluated' -or $_.result -ne 'Pass' }).Count -gt 0) { exit 1 }
'Runtime dialogues: PASS (bounded synthetic dialogue, actual files/tools; not production acceptance)'
