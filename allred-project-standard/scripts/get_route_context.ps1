param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('new-standard', 'new-public', 'existing-debug', 'existing-feature', 'existing-ui', 'non-software', 'long-term')]
  [string]$Route,
  [ValidateSet('standard', 'beginner')]
  [string]$Interaction = 'standard',
  [ValidateSet('none', 'training', 'policy', 'knowledge', 'bid', 'contract', 'inspection')]
  [string]$Variant = 'none',
  [ValidateSet('intake', 'evidence', 'decision', 'external-read', 'execution', 'verification')]
  [string]$Stage = 'intake',
  [string[]]$Overlays = @(),
  [ValidateSet('none', 'one-time', 'monitoring')]
  [string]$ExternalMode = 'none',
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$StatePath = '',
  [string]$ValidatedEventId = '',
  [switch]$GuardsOnly,
  [switch]$MetricsOnly
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$compatibilityAlias = $false
if ($Route -eq 'new-public') {
  $Route = 'new-standard'
  $Overlays += 'external-source'
  if ($ExternalMode -eq 'none') { $ExternalMode = 'monitoring' }
  $compatibilityAlias = $true
}

$allowedOverlays = @('external-source', 'shared-collaboration', 'company-office-delivery')
$Overlays = @($Overlays | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
foreach ($overlay in $Overlays) {
  if ($overlay -notin $allowedOverlays) { throw "Unknown overlay: $overlay" }
}
if ($ExternalMode -ne 'none' -and 'external-source' -notin $Overlays) {
  throw 'ExternalMode requires the external-source overlay.'
}
$newProjectRoutes = @('new-standard')
$validatedByEvent = $false

if (-not $MetricsOnly -and -not [string]::IsNullOrWhiteSpace($ValidatedEventId)) {
  if ($Route -notin $newProjectRoutes -or $Stage -ne 'decision') {
    throw 'ValidatedEventId is valid only for -Route new-standard -Stage decision. A trusted READY event must load decision context before rendering a READY card.'
  }
}

if (-not $MetricsOnly -and $GuardsOnly -and $Stage -eq 'decision') {
  throw 'GuardsOnly cannot load DECISION context. Rerun the same route, interaction, variant, and overlays at -Stage decision without -GuardsOnly before any question or READY packet.'
}

if (-not $MetricsOnly -and $Route -in $newProjectRoutes -and $Stage -in @('decision', 'execution')) {
  if (-not [string]::IsNullOrWhiteSpace($ValidatedEventId)) {
    if (-not [string]::IsNullOrWhiteSpace($StatePath)) { throw 'Use either StatePath or ValidatedEventId, not both.' }
    if ($ValidatedEventId -notmatch '^E[0-9A-Za-z_-]+$') { throw 'ValidatedEventId must be the exact current trusted tool/event ID.' }
    $validatedByEvent = $true
  } elseif ([string]::IsNullOrWhiteSpace($StatePath)) {
    if ($Stage -eq 'decision') {
      @(
        '## Decision Redirect Guard'
        ''
        'DECISION is not validated. Do not expose this internal gate as a user blocker, do not show a partial decision packet, and do not start technical preflight.'
        'If this is the first broad new-project packet and user/workflow, materials, initial idea/must-haves, or useful result is missing, next load get_route_context.ps1 -Route new-standard -Stage intake -Interaction <current> and ask the complete concentrated INTAKE packet.'
        'If the user answered only part of an existing packet, preserve every still-consequential sibling and re-present them now with their original meaning before any technical preflight. A recommendation about who should not act does not answer who owns configuration; scale inputs do not replace measurable acceptance targets. Never replace siblings with "少量待确认事项", postpone them until after preflight, or restart generic intake.'
        'Use -StatePath only after the aggregate DECISION gate passes, or -ValidatedEventId only for the exact trusted aggregate event.'
      )
      exit 0
    }
    throw 'StatePath is required before loading EXECUTION for a non-trivial new project.'
  } else {
    $targetStage = if ($Stage -eq 'decision') { 'DECISION' } else { 'EXECUTION' }
    $validator = Join-Path $PSScriptRoot 'invoke_validation_gate.ps1'
    $validationOutput = & $validator -Path $StatePath -ToStage $targetStage 2>&1
    if (-not $?) {
      throw "Stage transition to $targetStage was blocked:`n$($validationOutput -join [Environment]::NewLine)"
    }
  }
}

function Add-Spec([System.Collections.Generic.List[object]]$Specs, [string]$Path, [string[]]$Sections) {
  $Specs.Add([pscustomobject]@{ path = $Path; sections = @($Sections) }) | Out-Null
}

function Get-Sections([string]$RelativePath, [string[]]$SectionNames) {
  $path = Join-Path $SkillRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { throw "Route context source not found: $RelativePath" }
  $lines = @(Get-Content -LiteralPath $path -Encoding UTF8)
  $output = [System.Collections.Generic.List[string]]::new()
  $output.Add("<!-- source: $RelativePath -->") | Out-Null

  foreach ($name in $SectionNames) {
    $heading = "## $name"
    $start = [Array]::IndexOf($lines, $heading)
    if ($start -lt 0) { throw "Section '$heading' not found in $RelativePath" }
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^## ') { $end = $i; break }
    }
    for ($i = $start; $i -lt $end; $i++) { $output.Add($lines[$i]) | Out-Null }
    $output.Add('') | Out-Null
  }
  return $output
}

$specs = [System.Collections.Generic.List[object]]::new()

switch ($Stage) {
  'intake' {
    Add-Spec $specs 'references\核心执行流程.md' @('Objective', 'Execution Lanes', 'Mandatory Internal Stage Gate', 'Phase 1: Route And Bound')
  }
  'evidence' {
    Add-Spec $specs 'references\核心执行流程.md' @('Mandatory Internal Stage Gate', 'Phase 2: Inspect Evidence')
    Add-Spec $specs 'references\动态项目契约.md' @('Provenance And Confidence', 'Recommendation Readiness Gate', 'Recommendation Admission Filter')
  }
  'decision' {
    Add-Spec $specs 'references\核心执行流程.md' @('Mandatory Internal Stage Gate', 'Phase 3: Build The Internal Proposal', 'Phase 4: Open A User Gate Only When Needed')
    Add-Spec $specs 'references\决策前沿与Skill交接.md' @('Ownership Router', 'Internal Frontier Model')
    Add-Spec $specs 'references\交互与确认规则.md' @('Question Packet Contract', 'Decision Ownership', 'Product Decision Gate', 'Start Confirmation Without Duplication')
  }
  'external-read' {
    Add-Spec $specs 'references\外部内容安全.md' @('Trust Boundary', 'URL And Network Boundary', 'Query And Data Privacy', 'Safe Fetch Defaults', 'Evidence Record', 'User-Facing Effects')
  }
  'execution' {
    Add-Spec $specs 'references\核心执行流程.md' @('Mandatory Internal Stage Gate', 'Phase 5: Create The Execution Contract', 'Phase 6: Execute Continuously')
    Add-Spec $specs 'references\阶段状态硬校验.md' @('Stage Transition Gate', 'READY Scope Gate')
  }
  'verification' {
    Add-Spec $specs 'references\核心执行流程.md' @('Phase 7: Verify Before Claiming', 'Phase 8: Close Or Hand Off', 'Efficiency Acceptance')
  }
}

if ($Route -in $newProjectRoutes) {
  if ($Stage -eq 'intake') {
    Add-Spec $specs 'references\新项目启动模式.md' @('1. Capture The Rough Requirement', "2. Collect Materials And The User's Initial Idea", 'Recommendation Readiness Gate')
    Add-Spec $specs 'references\资料收集与分析.md' @('When To Use', 'Material Prompt')
  }
  if ($Stage -eq 'evidence') {
    Add-Spec $specs 'references\新项目启动模式.md' @('Recommendation Readiness Gate', '3. Build The Dynamic Project Contract Internally', '4. Inspect Basis, Capability, And Delivery')
    Add-Spec $specs 'references\资料收集与分析.md' @('Analyze Before Asking', 'If No Materials', 'Evidence Blockers')
    Add-Spec $specs 'references\动态项目契约.md' @('Objective', 'Contract Slots', 'Provenance And Confidence', 'Assumption-First Alignment', 'Recommendation Readiness Gate', 'Dynamic Decisions, Not Fixed Cards', 'Recommendation Admission Filter', 'Reproducible Evidence Record', 'Context Read Ledger')
  }
  if ($Stage -eq 'decision') {
    Add-Spec $specs 'references\新项目启动模式.md' @('5. Draft Total And Current Scope', '6. Use Concentrated Interaction Without Duplicate Gates')
    Add-Spec $specs 'references\动态项目契约.md' @('Approval Envelope', 'Contract Consistency Lint', 'User Confirmation And Codex Execution Record')
    Add-Spec $specs 'references\阶段状态硬校验.md' @('READY Scope Gate')
  }
  if ($Stage -eq 'execution') { Add-Spec $specs 'references\新项目启动模式.md' @('7. Execute And Verify') }
}

if ($Interaction -eq 'beginner') {
  if ($Stage -eq 'intake') {
    Add-Spec $specs 'references\新手表达层.md' @('Boundary And Toggle', 'Rendering Defaults')
    if ($Route -in $newProjectRoutes) {
      Add-Spec $specs 'references\新手表达层.md' @('New-Project Opening Rendering')
    } else {
      Add-Spec $specs 'references\新手表达层.md' @('Existing Or Continuing Work Rendering')
    }
  }
  if ($Stage -eq 'evidence') { Add-Spec $specs 'references\新手表达层.md' @('Evidence Rendering') }
  if ($Stage -eq 'decision') { Add-Spec $specs 'references\新手表达层.md' @('Decision And READY Rendering') }
  if ($Stage -eq 'external-read') { Add-Spec $specs 'references\新手表达层.md' @('Rendering Defaults') }
  if ($Stage -eq 'execution') { Add-Spec $specs 'references\新手表达层.md' @('Execution Rendering') }
  if ($Stage -eq 'verification') { Add-Spec $specs 'references\新手表达层.md' @('Verification And Delivery Rendering', 'Expression-Layer Validation') }
}

if ('external-source' -in $Overlays) {
  if ($Stage -eq 'intake') { Add-Spec $specs 'references\external-source.md' @('Boundary And Activation', 'Route Approval Boundary') }
  if ($Stage -eq 'evidence') {
    $externalSections = @('Boundary And Activation', 'Minimum Validation Definition', 'Source And Benchmark Selection')
    if ($ExternalMode -eq 'one-time') { $externalSections += 'One-Time Query' }
    if ($ExternalMode -eq 'monitoring') { $externalSections += @('Continuous Monitoring', 'Search Decisions Stay Separate', 'First-Round Evidence Strategy') }
    Add-Spec $specs 'references\external-source.md' $externalSections
  }
  if ($Stage -eq 'external-read') { Add-Spec $specs 'references\external-source.md' @('Source And Benchmark Selection', 'Semantic Relevance Gate', 'Credentials And Client Architecture') }
  if ($Stage -eq 'decision') {
    $externalSections = @('Acceptance Metric Provenance', 'Summary Provenance', 'Classification', 'Acceptance')
    if ($ExternalMode -eq 'one-time') { $externalSections += 'One-Time Query' }
    if ($ExternalMode -eq 'monitoring') { $externalSections += @('Continuous Monitoring', 'Monitoring Scope Draft') }
    Add-Spec $specs 'references\external-source.md' $externalSections
  }
}

if ('shared-collaboration' -in $Overlays) {
  if ($Stage -eq 'intake') { Add-Spec $specs 'references\shared-collaboration.md' @('Boundary And Activation', 'Intake Handoff') }
  if ($Stage -eq 'evidence') { Add-Spec $specs 'references\shared-collaboration.md' @('Boundary And Activation', 'Evidence And Ownership') }
  if ($Stage -eq 'decision') { Add-Spec $specs 'references\shared-collaboration.md' @('Decision Packet', 'Conflict Audit And Recovery') }
  if ($Stage -eq 'execution') { Add-Spec $specs 'references\shared-collaboration.md' @('Conflict Audit And Recovery') }
  if ($Stage -eq 'verification') { Add-Spec $specs 'references\shared-collaboration.md' @('Verification') }
}

if ('company-office-delivery' -in $Overlays) {
  if ($Stage -in @('intake', 'evidence')) { Add-Spec $specs 'references\company-office-delivery.md' @('Activation Boundary', 'Office Defaults') }
  if ($Stage -eq 'decision') { Add-Spec $specs 'references\company-office-delivery.md' @('Office Defaults', 'Office Acceptance') }
  if ($Stage -in @('execution', 'verification')) { Add-Spec $specs 'references\company-office-delivery.md' @('Office Acceptance') }
}

if ($Route -eq 'non-software') {
  if ($Stage -eq 'intake') {
    Add-Spec $specs 'references\非软件项目模式.md' @('Route Boundary', 'Artifact And Tool Routing')
    $variantSection = @{
      training = 'Training Project'
      policy = 'Policy And Procedure'
      knowledge = 'Knowledge Base'
      bid = 'Bid And Tender'
      contract = 'Contract'
      inspection = 'Inspection And Quality Record'
    }
    if ($Variant -ne 'none') {
      $variantSections = @($variantSection[$Variant])
      if ($Variant -eq 'training') { $variantSections += 'Training Alignment Gate' }
      Add-Spec $specs 'references\非软件项目模式.md' $variantSections
    }
  }
  if ($Stage -eq 'evidence') { Add-Spec $specs 'references\非软件项目模式.md' @('Shared Evidence Contract', 'Source And Document State') }
  if ($Stage -in @('decision', 'execution')) {
    $controlledSections = @('Controlled Execution')
    if ($Stage -eq 'decision' -and $Variant -eq 'training') { $controlledSections += 'Training Alignment Gate' }
    Add-Spec $specs 'references\非软件项目模式.md' $controlledSections
  }
  if ($Stage -eq 'verification') { Add-Spec $specs 'references\非软件项目模式.md' @('Review And Acceptance') }
}

switch ($Route) {
  'existing-debug' { if ($Stage -in @('intake', 'evidence', 'execution', 'verification')) { Add-Spec $specs 'references\功能调试.md' @('Debug Contract', 'Evidence First', 'Hypothesis Discipline', 'User Gates', 'Completion') } }
  'existing-feature' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\新增功能.md' @('Classify First', 'Feature Contract', 'User Gate', 'Execution And Verification') } }
  'existing-ui' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\界面优化.md' @('Inspect Before Designing', 'User Gate', 'Execute And Verify') } }
  'long-term' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\长期任务模式.md' @('State Model', 'Review Depth', 'Current-Round Contract', 'Execute And Update State', 'Round Closure') } }
}

$stageGuards = @{
  intake = if ($Route -in $newProjectRoutes) {
    "## Active Stage Guard`n`nCurrent stage: INTAKE. Track user/workflow/pain, material state, idea/delegation, and useful result. Ask each missing independent item once. Explicitly unavailable material is closed; do not request it again. Promised but unlocated material: do not search the workspace for it; request location with unanswered workflow, first-version boundary, and useful-result facts. Ask only for location/sample for one exact inspection or when other readiness is known. Pending material postpones evidence-dependent recommendations, not independent intake. Each visible group gives one plain-language consequence; topic-only groups and decision-card templates are incomplete. `资料未归拢`/`有资料` means available-uninspected: request location/sample. A Codex-draft request fills only idea/delegation. No product D/READY or mutation. Before render/extract disclose unchanged originals/project; disposable evidence stays in isolated system temp."
  } elseif ($Route -eq 'existing-debug') {
    "## Active Route Guard`n`nCurrent route: EXISTING DEBUG. Inspect and reproduce from evidence already available in the project before asking the user. Do not request files, logs, or results that the user says are already local. Ask only for evidence that cannot be obtained locally and changes the next diagnostic step. An exact safe local fix request already authorizes diagnosis, the smallest evidence-backed fix, and narrow verification."
  } elseif ($Route -eq 'non-software') {
    "## Active Stage Guard`n`nCurrent internal stage: INTAKE for a substantial non-software project. Do not treat a newly requested training, policy, knowledge-base, bid, contract, or inspection deliverable as existing or continuing work merely because this route also serves established documents. Keep one temporary ledger for intended outcome/audience, source or material state, the user's initial emphasis or required content, known boundaries, and a recognizable useful result. Ask every missing independent baseline in one concentrated packet; requesting a material path or sample must not postpone independent questions that the user can answer now. The only exception is an explicit exact read-only inspection request whose result must precede any useful scope discussion. Do not invent sections, omissions, delivery format, or acceptance values before evidence and user alignment, and do not mutate project files from INTAKE."
  } else {
    "## Active Route Guard`n`nCurrent route is existing or continuing work. Inspect the current project evidence before asking factual questions. Do not restart new-project discovery or add a ceremonial start gate when the exact safe local work is already authorized."
  }
  evidence = "## Active Stage Guard`n`nCurrent stage: EVIDENCE. Output filter: omit unselected-domain negatives; saying 'not in scope' is leakage. GuardsOnly is never the first/only route load. Artifact-location hard stop: a label is not a target; ask only for its location/sample. Before render/extract disclose unchanged originals/project and temp evidence only in isolated system temp. Post-result exact call: get_route_context.ps1 -Route <route> -Stage evidence -Interaction <standard|beginner> -GuardsOnly; GuardsOnly is not an Interaction value. Then reload normal evidence context. Report observations, limits, and write boundary before another action. An observed pattern/anomaly proves only observation, not checker/classifier feasibility without matching semantics/rules. Preserve active-contract capabilities and gaps at facet level. Evidence-quantifier lint: preserve sample/subgroup/count/uncertainty; an aggregate does not prove each subgroup. Temp outputs are disposable evidence, not project artifacts. Unless blocked, continue authorized read-only work. Trusted DECISION/READY event: call get_route_context.ps1 -Route new-standard -Stage decision -ValidatedEventId <ID>. Script search is not a stage transition. No mutation."
  decision = "## Active Stage Guard`n`nCurrent stage: DECISION. Validation passed. Unanswered facets stay visible or have exact dependency/deferral reasons; how does not settle scope/owner, and new children do not replace them. Complete coverage and READY before final card. No mutation."
  'external-read' = "## Active Stage Guard`n`nCurrent internal stage: EXTERNAL-READ. Apply trust, privacy, and network boundaries. For a semantic sample, show each inspected title/ID/link and name the result for every dimension required by the active project contract, even when another mismatch already rejects the sample. Mark unavailable required dimensions unknown; do not merge axes or imply them from titles. Counts or summaries never replace sample identity. This stage does not approve product behavior or mutation."
  execution = "## Active Stage Guard`n`nCurrent internal stage: EXECUTION. Stage, frontier, READY-scope, and exact authorization validation have passed. Proceed only inside that approved scope and effects envelope; return only the affected item to DECISION for material scope change."
  verification = "## Active Stage Guard`n`nCurrent internal stage: VERIFICATION. Verify promises with fresh evidence and do not expand scope or infer release actions."
}

if ($Stage -eq 'intake') {
  $stageGuards.intake += " A later tool/event that changes stage invalidates INTAKE. Before the next packet, rerun this selector with the same route, interaction, variant, and overlays. If a trusted event reports aggregate DECISION/READY without StatePath, call get_route_context.ps1 -Route new-standard -Stage decision -ValidatedEventId <ID>; never answer from stale intake."
}

if ($validatedByEvent -and $Stage -eq 'decision') {
  $stageGuards.decision += " Trusted-event validation source: $ValidatedEventId. DECISION context is valid without local StatePath. If this event explicitly says aggregate READY passed and includes the complete pending scope/execution record, READY may be rendered; otherwise ask only its decision frontier. Never EXECUTION."
}

if ($Route -in $newProjectRoutes -and $Stage -eq 'intake') {
  $stageGuards.intake += " Material-location hard stop: search workspace once. No path/attachment/hit: remain INTAKE, ask exact location, and never load EVIDENCE to find the target. Intake consequence lint: one packet-wide consequence sentence is insufficient. Give each visible group one short plain-language effect. Map user/workflow/pain -> actors, failures, responsibility, and boundary; materials/sample -> fields, cleanup/import evidence, and what can be verified; user idea/current scope -> included and deferred behavior; recognizable useful result -> acceptance evidence. Adapt or omit groups already answered; do not add questions merely to render this map."
}

if ($Interaction -eq 'beginner' -and $Stage -eq 'intake') {
  $stageGuards.intake += " Expression-toggle guard: changing wording preserves the complete pending ledger. Either refer to the whole prior packet without summarizing it, or restate every still-open fact and decision; never replace it with a shorter partial list."
}

if ($Interaction -eq 'beginner' -and $Stage -eq 'evidence') {
  $stageGuards.evidence += ' Beginner wording: use familiar Chinese; never echo internal English labels or unexplained route/stage/preflight terms. Say "只查看，不改原文件；临时查看材料放在项目外的临时位置" instead of internal evidence jargon.'
}

if ($Route -eq 'non-software' -and $Variant -eq 'training' -and $Stage -in @('intake', 'evidence')) {
  $stageGuards[$Stage] += " Training material-first hard stop: when project materials/feedback are locatable, inspect before asking completion, reuse, audience, or curriculum. After any training evidence event, before a visible packet/synthesis call get_route_context.ps1 -Route non-software -Stage decision -Variant training -Interaction <current>; stale intake/evidence is invalid."
  $stageGuards[$Stage] += " Training visible-packet gate after evidence: the same packet covers every unresolved audience confirmation, learning outcome, candidate topics plus an add-topic path, exercise endpoint, current result, each evidence-only absence classification, and acceptance unless an exact dependency is recorded. Evidence-only audience/absence is never `已确认` or `资料已支持`: ask confirm/correct audience and include/exclude/unclassified absence. If any independent facet is missing, report evidence only and ask nothing."
  $stageGuards[$Stage] += " Training handoff guard: before any post-evidence packet or curriculum handoff, account internally for outcome/audience, must-teach content, exercise, material deliverable/format, explicit exclusions/deferrals, and learning acceptance. Use a coverage ledger, not a fixed questionnaire; group related dimensions and show only nonempty user-relevant parts. A missing material path must not postpone independent learner/work-scenario, practice-outcome, or success questions; inspect supplied material before evidence-dependent recommendations. Label evidence-only values `资料显示` or `候选`, never `已确认`. An evidence-only audience or absent/unrequested topic remains a candidate; confirm it before it enters audience or excluded scope. Mention in a summary or option does not settle it. Do not invent negative scope or print placeholder deferred/excluded sections. A current no-file instruction is execution-only."
  $stageGuards[$Stage] += " Training output-boundary lint: deliverable/format means the current requested result, not a speculative future document package. When the user says not to generate documents and future file format does not change current curriculum or acceptance, keep it out of the visible packet; an in-chat design is enough until requested."
  $stageGuards[$Stage] += " Training topic-coverage lint: evidence-derived gaps are candidate minimums, never the exhaustive must-teach list. The first post-evidence packet must let the user confirm or correct those candidates and add any other required topics."
  $stageGuards[$Stage] += " Training baseline lint: existing handouts prove availability only, not learner completion or no-repeat. Ask completion/reuse only when consequential. Once user/evidence establishes completion and no current gap, inherit it as baseline: do not offer repeat, review, or re-teach; reuse in an exercise is not repetition."
  if ($Stage -eq 'evidence') {
    $stageGuards.evidence = "## Training Transition Hard Stop`n`nAfter the post-event GuardsOnly refresh, if this same visible reply will contain any training question or curriculum synthesis, its next tool call must load `get_route_context.ps1 -Route non-software -Stage decision -Variant training -Interaction <current>`. Do not draft the packet first; GuardsOnly never substitutes for decision. If no packet is due, report the evidence and continue only authorized read-only work. Do not end with a future consistency-check or packet promise.`n`n" + $stageGuards.evidence
  }
}

if ($Route -eq 'non-software' -and $Stage -eq 'evidence') {
  $stageGuards.evidence += " Pre-evidence artifact guard: when the user asks to analyze existing materials before a proposal, the pre-event reply states inspection actions only. Do not draft structure, taxonomy, fields, output package, or acceptance until evidence returns."
}

if ($Route -eq 'existing-debug' -and $Stage -eq 'evidence') {
  $stageGuards.evidence += " Debug-evidence override: after reporting what the current evidence proves and does not prove, choose one highest-value causal fork. Name one bounded next diagnostic experiment, the single meaningful variable or comparison it controls, and the observable result that would support versus weaken the leading hypothesis. Other causal branches may remain open; do not replace this experiment with a broad list of additional logs, correlations, or possible follow-up work."
}

if ('external-source' -in $Overlays -and $Stage -eq 'evidence') {
  $stageGuards.evidence += " Semantic sample guard: derive the required semantic dimensions from the active project contract and claim. Report each by name even when another mismatch already rejects the sample; never merge axes or infer them from titles. Missing required evidence is unknown. Listed axes are examples only. Keep transport/schema/count separate, preserve sample identities, and never approve from a summary."
}

if ($Stage -eq 'intake' -and 'shared-collaboration' -in $Overlays) {
  $stageGuards.intake += " Shared-intake override: selecting shared tracking confirms only the parent direction, not future governance. Before the remaining current-fact questions, say briefly that participants, workflow/source, sensitivity, materials, and useful result determine the shared update boundary, evidence to inspect, and later acceptance. Reuse the preceding packet; do not reopen answered facts. If promised samples are absent, preserve all open current-fact clusters and ask for samples plus only unanswered current facts. Permissions, conflict, audit/history, truth source, operation/recovery, and final acceptance are DECISION questions after evidence."
}
if ($Stage -eq 'decision' -and 'shared-collaboration' -in $Overlays) {
  $stageGuards.decision += " Shared hard stops: no invented days/hours/counts/retention; use '由你指定'. Discovery-only ends '可暂缓任一项；对应设计/实现/验收保持未定，不开发'. Rendering: about five groups; one why/basis per group, then each facet one compact question+影响+回复 line; never repeat a five-line mini-card. Begin with three independent current Qs: participants/responsibilities; records/workflow/source; use environment (location/devices/access/availability). Future behavior is D and cannot replace Q or mix current owner with future hosting. Create/edit/approve-close/reopen/delete stay separate. Lint via scripts/validate_question_packet.ps1; send only PASS draft. Recommendations need evidence/benchmark; otherwise neutral. Natural prose reply allowed."
}
if ($Stage -eq 'decision' -and $Route -eq 'non-software' -and $Variant -eq 'training') {
  $stageGuards.decision += " Training packet: `$draft | & scripts/validate_question_packet.ps1 -Profile training -PassThrough`; send only APPROVED packet unchanged; re-lint edits. `-AllowCompletedBaselineReview` requires a current evidenced/user-confirmed gap. Final defer/exclude lists copy only user-confirmed items; never convert prerequisites, endpoints, risks, or execution limits. Packets omit empty sections; show '暂无已确认课程内容暂缓项' only in a requested final summary. No-file=in-chat; omit future format unless it changes curriculum/acceptance. Final handoff: `$draft | & scripts/validate_training_handoff.ps1 -PassThrough`; send only APPROVED text unchanged; re-lint edits."
}

$seen = @{}
$chunks = [System.Collections.Generic.List[string]]::new()
$chunks.Add($stageGuards[$Stage]) | Out-Null
$chunks.Add('') | Out-Null
if (-not $GuardsOnly) {
  foreach ($spec in $specs) {
    $newSections = @()
    foreach ($section in $spec.sections) {
      $key = "$($spec.path)|$section"
      if (-not $seen.ContainsKey($key)) { $seen[$key] = $true; $newSections += $section }
    }
    if ($newSections.Count -gt 0) {
      foreach ($line in Get-Sections $spec.path $newSections) { $chunks.Add($line) | Out-Null }
    }
  }
}

$content = $chunks -join [Environment]::NewLine
$metrics = [pscustomobject]@{
  route = $Route
  compatibility_alias = $compatibilityAlias
  overlays = @($Overlays)
  external_mode = $ExternalMode
  validated_event_id = if ($validatedByEvent) { $ValidatedEventId } else { $null }
  interaction = $Interaction
  stage = $Stage
  source_sections = $seen.Count
  lines = @($content -split "`r?`n").Count
  characters = $content.Length
  control_characters = ([regex]::Matches($content, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')).Count
}

if ($MetricsOnly) { $metrics | ConvertTo-Json -Compress; exit 0 }
$content
