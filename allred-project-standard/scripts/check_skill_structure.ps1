param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$ReleaseRoot = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) {
  $script:failures.Add($Message) | Out-Null
}

function Get-RelativePath([string]$Root, [string]$Path) {
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $rootUri = [System.Uri]::new($rootFull)
  $pathUri = [System.Uri]::new($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

function Invoke-IsolatedScriptExitCode {
  param([string]$ScriptPath, [string[]]$Arguments)
  $powerShellExecutable = (Get-Process -Id $PID).Path
  & $powerShellExecutable -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1 | Out-Null
  return [int]$LASTEXITCODE
}

function Require-Path([string]$RelativePath) {
  $path = Join-Path $SkillRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path)) { Add-Failure "Required file missing: $RelativePath" }
}

function Require-Contains([string]$Text, [string]$Marker, [string]$Label) {
  if (-not $Text.Contains($Marker)) { Add-Failure "Missing structural marker: $Label" }
}

function Require-Match([string]$Text, [string]$Pattern, [string]$Label) {
  if ($Text -notmatch $Pattern) { Add-Failure "Missing structural contract: $Label" }
}

$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$skillPath = Join-Path $SkillRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillPath)) { throw "SKILL.md not found: $skillPath" }
$skillLines = @(Get-Content -LiteralPath $skillPath -Encoding UTF8)
$skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8

if ($skillLines.Count -lt 4 -or $skillLines[0] -ne '---' -or $skillLines[3] -ne '---') {
  Add-Failure 'Frontmatter must contain name and description between delimiters.'
}
if ($skillLines[1] -notmatch '^name:\s*allred-project-standard\s*$') { Add-Failure 'Unexpected Skill name.' }
if ($skillLines[2] -notmatch '^description:\s+\S') { Add-Failure 'Frontmatter description is missing.' }
if ($skillLines[2].Length -gt 500) { Add-Failure 'Frontmatter description is too broad.' }
if ($skillLines.Count -gt 260) { Add-Failure "SKILL.md exceeds entrypoint budget: $($skillLines.Count) lines." }

foreach ($heading in @('## Post-Event First Action', '## Runtime Hard Stops', '## Activation And Routing', '## Required Reading', '## Shared Invariants', '## Conversation Topology')) {
  Require-Contains $skillText $heading $heading
}
Require-Contains $skillText 'allred-project-lab' 'maintainer Skill ownership'
Require-Contains $skillText 'After any tool/event result changes evidence or stage' 'post-event route reload hard stop'
Require-Contains $skillText '-Route non-software -Stage decision -Variant training' 'training event exact decision route'
Require-Contains $skillText '$draft | & scripts/validate_question_packet.ps1 -Profile training -PassThrough' 'training event exact question-packet lint'
Require-Contains $skillText 'Evidence-only audience or absent/unrequested content is never `已确认` or `资料已支持`' 'training evidence candidates remain unconfirmed'
Require-Contains $skillText 'A completed training baseline with no current gap is a prerequisite, not a review/reteach/use choice' 'training completed baseline stays closed at entry'
Require-Contains $skillText 'Learning outcome, exercise endpoint, and acceptance are distinct' 'training outcome and acceptance stay separate at entry'
Require-Contains $skillText 'A prerequisite such as `不要求编程基础` is not a curriculum exclusion' 'training prerequisite does not become exclusion'
Require-Contains $skillText 'the visible final reply is exactly the approved block, including its execution boundary' 'training final reply preserves approved execution boundary'
Require-Contains $skillText 'never merge a failed draft with a passed draft' 'training passed and failed drafts never merge'
Require-Contains $skillText 'If either call is missing or fails, report evidence only and ask nothing' 'training event missing-gate fallback'
Require-Contains $skillText 'An unvalidated new-project DECISION call is not a user-facing blocker' 'premature decision redirects without exposing internals'
Require-Contains $skillText 'a partial reply re-presents every unanswered sibling before technical preflight' 'partial decision siblings precede preflight'
Require-Contains $skillText 'A recommendation that someone should not act does not settle the unanswered owner' 'negative recommendation does not settle owner'
Require-Contains $skillText 'Scale or volume input does not settle measurable acceptance' 'scale does not replace acceptance'
Require-Contains $skillText 'do not call EVIDENCE or begin read-only/technical preflight' 'partial reply cannot escape through evidence preflight'
Require-Contains $skillText 'Immediately show every remaining consequential sibling' 'partial reply immediately renders remaining siblings'
Require-Contains $skillText 'An exact read-only inspection needs a locatable path, attachment, or sample' 'exact inspection requires target'
Require-Contains $skillText 'Selecting a shared-tracking parent alone remains INTAKE' 'shared parent remains intake'
Require-Contains $skillText 'sensitivity explicitly covers current volume, frequency, variation, and highest-impact pain' 'shared intake sensitivity coverage'
Require-Contains $skillText 'these facts size the shared update boundary, evidence sample, and later acceptance' 'shared intake sensitivity consequence'
Require-Contains $skillText 'Shared INTAKE environment means current location, devices, access conditions, availability, and sensitivity only' 'shared intake current environment boundary'
Require-Contains $skillText 'Planned platform, vendor, shared drive, internal system, hosting, and future access ownership are DECISION topics after evidence' 'shared intake defers platform decisions'
Require-Contains $skillText 'implementation details remain Codex-owned' 'technical implementation stays Codex-owned'
Require-Contains $skillText 'A candidate delivery or integration path remains visibly unverified' 'candidate path persists until integration'
Require-Contains $skillText 'extensibility/configuration owner, historical handling, correction/void lifecycle, operating scale, or measurable acceptance' 'open lifecycle facets remain independent'
Require-Contains $skillText 'never invent numeric targets or let a recommendation settle ownership' 'open lifecycle facets preserve provenance'
Require-Contains $skillText 'an explicit state such as `relevant`, `irrelevant`, or `unknown`' 'semantic source state is explicit'
Require-Contains $skillText 'Beginner-facing READY hides source trees' 'beginner READY hides implementation structure'
Require-Contains $skillText '-Overlays external-source|shared-collaboration|company-office-delivery' 'conditional overlay selector'
Require-Contains $skillText 'only toggles beginner/standard expression' 'expression-only toggle boundary'
Require-Contains $skillText 'Do not restate or re-ask its facts, materials, or decisions' 'expression toggle does not repeat pending questions'
Require-Contains $skillText 'the same response must actually run every currently available read-only' 'answer-independent preflight runs in the current response'
Require-Contains $skillText 'do not stop after saying these will be done' 'future preflight promise is incomplete'
Require-Contains $skillText 'first make a bounded current-workspace search' 'missing material locator begins with local discovery'
Require-Contains $skillText 'promised materials have not yet been supplied' 'explicitly absent promised materials do not trigger workspace search'
Require-Contains $skillText 'every still-missing independent readiness facet' 'missing materials do not serialize independent intake'
Require-Contains $skillText '`-GuardsOnly` is never the first or only route load' 'guards-only cannot replace routed evidence context'
Require-Contains $skillText 'do not use it to postpone project-root/write-boundary' 'missing locator cannot block independent preflight'

$required = @(
  'VERSION',
  'agents\openai.yaml',
  'references\核心执行流程.md',
  'references\新项目启动模式.md',
  'references\新手表达层.md',
  'references\决策前沿与Skill交接.md',
  'references\交互与确认规则.md',
  'references\阶段状态硬校验.md',
  'references\开发依据与能力复用.md',
  'references\运行环境与交付形态.md',
  'references\external-source.md',
  'references\shared-collaboration.md',
  'references\company-office-delivery.md',
  'references\非软件项目模式.md',
  'references\功能调试.md',
  'references\长期任务模式.md',
  'scripts\get_route_context.ps1',
  'scripts\check_route_context_budget.ps1',
  'scripts\check_invariants.ps1',
  'scripts\check_runtime_generality.ps1',
  'scripts\check_behavior_manifest.ps1',
  'scripts\run_behavior_eval.ps1',
  'scripts\run_entry_guard_eval.ps1',
  'scripts\new_evidence_temp.ps1',
  'scripts\invoke_validation_gate.ps1',
  'scripts\validate_stage_transition.ps1',
  'scripts\validate_decision_frontier.ps1',
  'scripts\validate_discovery_coverage.ps1',
  'scripts\validate_ready_scope.ps1',
  'scripts\validate_change_traceability.ps1',
  'scripts\validate_execution_record.ps1',
  'scripts\validate_decision_coverage.ps1',
  'scripts\validate_question_packet.ps1',
  'scripts\validate_training_handoff.ps1',
  'tests\invariants.json',
  'tests\behavior-cases.test.json',
  'tests\behavior-cases.oracle.json',
  'tests\project-state.valid-ready.json',
  'tests\project-state.invalid-stage.json',
  'tests\project-state.invalid-frontier.json',
  'tests\project-state.invalid-ready.json',
  'tests\execution-record.valid.md',
  'tests\review-result.schema.json'
)
foreach ($relative in $required) { Require-Path $relative }

foreach ($removed in @('references\公开信息监测项目.md', 'references\Skill流程优化模式.md', 'references\Skill测试验收.md')) {
  if (Test-Path -LiteralPath (Join-Path $SkillRoot $removed)) { Add-Failure "Removed runtime owner still exists: $removed" }
}
foreach ($obsolete in @('Selector routes are `new-standard`, `new-public`', '| Skill/workflow improvement |', 'references/公开信息监测项目.md')) {
  if ($skillText.Contains($obsolete)) { Add-Failure "Obsolete runtime routing remains: $obsolete" }
}

$version = (Get-Content -LiteralPath (Join-Path $SkillRoot 'VERSION') -Raw -Encoding UTF8).Trim()
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') { Add-Failure "Invalid VERSION: $version" }

$openAiYaml = Get-Content -LiteralPath (Join-Path $SkillRoot 'agents\openai.yaml') -Raw -Encoding UTF8
foreach ($marker in @('display_name: "Allred Project Standard"', 'default_prompt: "Use $allred-project-standard', 'allow_implicit_invocation: true')) {
  Require-Contains $openAiYaml $marker "agents/openai.yaml $marker"
}

# Every resource linked by the entrypoint or selector must exist.
$selectorPath = Join-Path $SkillRoot 'scripts\get_route_context.ps1'
$selectorText = Get-Content -LiteralPath $selectorPath -Raw -Encoding UTF8
Require-Contains $selectorText '[switch]$GuardsOnly' 'selector guards-only switch'
Require-Contains $selectorText '[string]$ValidatedEventId' 'trusted event validation input'
$linkText = $skillText + "`n" + $selectorText
$matches = [regex]::Matches($linkText, '(?:references|templates)[\\/][^`''"\s)]+\.(?:md|json)')
foreach ($match in $matches) {
  $relative = $match.Value.Replace('/', '\')
  if (-not (Test-Path -LiteralPath (Join-Path $SkillRoot $relative))) { Add-Failure "Linked resource missing: $relative" }
}

# Route isolation is deterministic: overlays appear only when selected.
$baseEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence) -join "`n"
foreach ($source in @('references\external-source.md', 'references\shared-collaboration.md', 'references\company-office-delivery.md')) {
  if ($baseEvidence.Contains("<!-- source: $source -->")) { Add-Failure "Unselected overlay leaked into base route: $source" }
}

$eventDecision = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage decision -ValidatedEventId E_FIXTURE_READY) -join "`n"
Require-Contains $eventDecision 'Trusted-event validation source: E_FIXTURE_READY' 'trusted event decision routing'
Require-Contains $eventDecision 'otherwise ask only its decision frontier' 'trusted decision event boundary'
Require-Contains $eventDecision 'Never EXECUTION' 'trusted event cannot authorize execution'
Require-Contains $eventDecision 'how does not settle scope/owner' 'decision route preserves unanswered sibling facets'
$decisionGuardsOnlyBlocked = $false
try { & $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage decision -ValidatedEventId E_FIXTURE_READY -GuardsOnly 2>&1 | Out-Null } catch { $decisionGuardsOnlyBlocked = $true }
if (-not $decisionGuardsOnlyBlocked) { Add-Failure 'GuardsOnly was accepted as a DECISION route load.' }
$eventEvidenceBlocked = $false
try { & $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -ValidatedEventId E_FIXTURE_READY 2>&1 | Out-Null } catch { $eventEvidenceBlocked = $true }
if (-not $eventEvidenceBlocked) { Add-Failure 'Trusted READY event was accepted outside the decision stage.' }
$eventExecutionBlocked = $false
try { & $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage execution -ValidatedEventId E_FIXTURE_READY 2>&1 | Out-Null } catch { $eventExecutionBlocked = $true }
if (-not $eventExecutionBlocked) { Add-Failure 'Trusted READY event incorrectly authorized EXECUTION context.' }

$externalOneTime = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Overlays external-source -ExternalMode one-time) -join "`n"
Require-Contains $externalOneTime '<!-- source: references\external-source.md -->' 'external-source overlay routing'
Require-Contains $externalOneTime 'Semantic sample guard:' 'external-source evidence semantic guard'
Require-Contains $externalOneTime '## One-Time Query' 'one-time external mode'
if ($externalOneTime.Contains('## Continuous Monitoring')) { Add-Failure 'One-time external mode loaded monitoring behavior.' }

$externalMonitoring = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Overlays external-source -ExternalMode monitoring) -join "`n"
Require-Contains $externalMonitoring '## Continuous Monitoring' 'monitoring external mode'

$shared = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Overlays shared-collaboration) -join "`n"
Require-Contains $shared '<!-- source: references\shared-collaboration.md -->' 'shared collaboration overlay routing'
if ($shared.Contains('references\external-source.md')) { Add-Failure 'Shared overlay loaded external-source rules.' }

$sharedIntake = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage intake -Overlays shared-collaboration) -join "`n"
Require-Contains $sharedIntake '## Intake Handoff' 'shared intake-only guidance'
Require-Contains $sharedIntake 'Remain INTAKE; do not load shared DECISION yet' 'shared intake blocks future governance'
Require-Contains $sharedIntake 'plus sensitivity: volume, frequency, variation, highest-impact pain' 'shared intake route sensitivity coverage'
Require-Contains $sharedIntake 'Never ask planned platform/vendor/shared drive/internal system/hosting or future access ownership in INTAKE' 'shared intake route defers platform choices'
if ($sharedIntake.Contains('## Evidence And Ownership') -or $sharedIntake.Contains('## Decision Packet')) {
  Add-Failure 'Shared intake route leaked later-stage collaboration guidance.'
}

$debugEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route existing-debug -Stage evidence) -join "`n"
Require-Contains $debugEvidence '## Hypothesis Discipline' 'debug evidence hypothesis discipline'
Require-Contains $debugEvidence 'support versus weaken' 'bounded debug experiment outcomes'

$sharedDecision = (& $selectorPath -SkillRoot $SkillRoot -Route long-term -Stage decision -Overlays shared-collaboration) -join "`n"
Require-Contains $sharedDecision '<!-- source: references\shared-collaboration.md -->' 'shared decision overlay routing'
Require-Contains $sharedDecision 'Begin with three independent current Qs: participants/responsibilities; records/workflow/source; use environment (location/devices/access/availability)' 'shared current-fact coverage'
Require-Contains $sharedDecision 'Future behavior is D and cannot replace Q or mix current owner with future hosting' 'shared current-fact versus future-decision separation'
Require-Contains $sharedDecision 'Create/edit/approve-close/reopen/delete stay separate' 'shared action-axis separation'
Require-Contains $sharedDecision 'one why/basis per group, then each facet one compact question+影响+回复 line; never repeat a five-line mini-card' 'shared compact grouped rendering'
Require-Contains $sharedDecision 'Lint via scripts/validate_question_packet.ps1; send only PASS draft' 'shared deterministic question-packet lint'
Require-Contains $sharedDecision 'Natural prose reply allowed' 'shared natural reply contract'
Require-Contains $sharedDecision "Shared hard stops: no invented days/hours/counts/retention; use '由你指定'" 'shared quantitative provenance hard stop'
Require-Contains $sharedDecision "可暂缓任一项；对应设计/实现/验收保持未定，不开发" 'shared discovery deferral hard stop'
Require-Match $sharedDecision '(?is)(ID-free groups|ID-free headings)' 'shared group-heading separation'

$beginnerEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Interaction beginner) -join "`n"
Require-Contains $beginnerEvidence 'never echo internal English labels' 'beginner evidence plain-language guard'
$beginnerIntake = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage intake -Interaction beginner) -join "`n"
Require-Contains $beginnerIntake 'state one reversible planning assumption and what later evidence may change' 'beginner no-sample reversible assumption'
$beginnerDecision = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage decision -Interaction beginner -ValidatedEventId E_FIXTURE_READY) -join "`n"
Require-Contains $beginnerDecision 'Separate `已确认需求`, `待批准建议`, `技术检查结论`, `尚未验证`, and `验收`' 'beginner READY evidence and recommendation separation'
Require-Contains $beginnerDecision 'Beginner READY rendering: hide source trees' 'beginner decision hides implementation internals'
$decisionRedirect = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage decision -Interaction standard) -join "`n"
Require-Contains $decisionRedirect '## Decision Redirect Guard' 'unvalidated new-project decision redirect'
Require-Contains $decisionRedirect 'next load get_route_context.ps1 -Route new-standard -Stage intake -Interaction <current>' 'first-packet redirect to intake'
Require-Contains $decisionRedirect 're-present them now with their original meaning before any technical preflight' 'partial-packet sibling preservation redirect'
Require-Contains $decisionRedirect 'does not answer who owns configuration; scale inputs do not replace measurable acceptance targets' 'redirect preserves owner and acceptance facets'
if ($decisionRedirect.Contains('Current stage: DECISION. Validation passed.')) { Add-Failure 'Unvalidated decision route exposed validated DECISION context.' }

$newProjectIntake = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage intake -Interaction standard) -join "`n"
Require-Contains $newProjectIntake 'one packet-wide consequence sentence is insufficient' 'new-project intake per-group consequence lint'
Require-Contains $newProjectIntake 'aggregate DECISION/READY without StatePath' 'intake trusted event handoff'
Require-Contains $newProjectIntake 'never load EVIDENCE to find the target' 'intake material-location stage boundary'
Require-Contains $newProjectIntake 'Track user/workflow/pain' 'new-project workflow pain intake'
Require-Contains $newProjectIntake 'Explicitly unavailable material is closed; do not request it again' 'unavailable material is not re-requested'
Require-Contains $newProjectIntake 'recognizable useful result -> acceptance evidence' 'new-project success effect coverage'
Require-Contains $newProjectIntake 'do not search the workspace for it' 'intake guard respects explicitly unsupplied materials'
Require-Contains $newProjectIntake 'Pending material postpones evidence-dependent recommendations, not independent intake' 'missing material preserves independent intake packet'

$office = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Overlays company-office-delivery) -join "`n"
Require-Contains $office '<!-- source: references\company-office-delivery.md -->' 'company office overlay routing'

$trainingDecision = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Stage decision -Variant training) -join "`n"
Require-Contains $trainingDecision 'omit future format unless it changes curriculum/acceptance' 'training current-result boundary excludes speculative format'
Require-Contains $trainingDecision 'Existing handouts prove material exists, not learner completion.' 'training material-versus-completion evidence boundary'
Require-Contains $trainingDecision 'No empty heading' 'training final-handoff empty-section lint'
Require-Contains $trainingDecision 'put requested `none confirmed` once in a nonempty boundary' 'training requested-empty-category rendering'
Require-Contains $trainingDecision '$draft | & scripts/validate_question_packet.ps1 -Profile training -PassThrough' 'training deterministic question-packet lint'
Require-Contains $trainingDecision '-AllowCompletedBaselineReview' 'training completed-baseline review escape is explicit'
Require-Contains $trainingDecision 'Final defer/exclude lists copy only user-confirmed items' 'training final boundaries require user provenance'
Require-Contains $trainingDecision 'never convert prerequisites, endpoints, risks, or execution limits' 'training inferred boundaries do not become exclusions'
Require-Contains $trainingDecision 'Packets omit empty sections' 'training decision packet omits empty boundary sections'
Require-Contains $trainingDecision "show '暂无已确认课程内容暂缓项' only in a requested final summary" 'training requested boundary summary remains explicit'
Require-Contains $trainingDecision '$draft | & scripts/validate_training_handoff.ps1 -PassThrough' 'training deterministic handoff lint'
Require-Contains $trainingDecision 'send only APPROVED text unchanged; re-lint edits' 'training passed text is final text'
Require-Contains $trainingDecision 'No-file=in-chat' 'training current no-file execution boundary'

$evidenceGuardOnly = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -GuardsOnly) -join "`n"
Require-Contains $evidenceGuardOnly 'Current stage: EVIDENCE.' 'evidence guards-only routing'
Require-Contains $evidenceGuardOnly 'never the first/only route load' 'evidence route entry requires full context'
Require-Contains $evidenceGuardOnly 'Post-result exact call: get_route_context.ps1 -Route <route> -Stage evidence -Interaction <standard|beginner> -GuardsOnly' 'post-event exact guards-only routing'
Require-Contains $evidenceGuardOnly 'Then reload normal evidence context' 'post-event synthesis requires full evidence context'
Require-Contains $evidenceGuardOnly 'Artifact-location hard stop:' 'missing inspection target evidence stop'
Require-Contains $evidenceGuardOnly 'a label is not a target' 'descriptive artifact label is not locatable evidence'
Require-Contains $evidenceGuardOnly 'ask only for its location/sample' 'narrow missing-target question'
Require-Contains $evidenceGuardOnly 'Report observations, limits, and write boundary before another action' 'post-event evidence report ordering'
Require-Contains $evidenceGuardOnly "Output filter: omit unselected-domain negatives; saying 'not in scope' is leakage" 'post-event conditional-overlay isolation'
Require-Contains $evidenceGuardOnly 'An observed pattern/anomaly proves only observation, not checker/classifier feasibility without matching semantics/rules' 'observed anomaly cannot prove checker feasibility'
Require-Contains $evidenceGuardOnly 'Preserve active-contract capabilities and gaps at facet level' 'named negative evidence coverage'
Require-Contains $evidenceGuardOnly 'Evidence-quantifier lint:' 'evidence population and subgroup boundary'
Require-Contains $evidenceGuardOnly 'an aggregate does not prove each subgroup' 'aggregate evidence cannot expand to subgroups'
Require-Contains $evidenceGuardOnly 'Temp outputs are disposable evidence, not project artifacts' 'isolated evidence artifact classification'
Require-Contains $evidenceGuardOnly 'Before render/extract disclose unchanged originals/project and temp evidence only in isolated system temp' 'pre-inspection disposable evidence disclosure'
Require-Contains $evidenceGuardOnly 'Unless blocked, continue authorized read-only work' 'post-report read-only continuation'
Require-Contains $evidenceGuardOnly 'Trusted DECISION/READY event: call get_route_context.ps1 -Route new-standard -Stage decision -ValidatedEventId <ID>' 'trusted event exact decision route'
Require-Contains $evidenceGuardOnly 'Script search is not a stage transition' 'decision route cannot be replaced by source search'
if ($evidenceGuardOnly.Contains('<!-- source:')) { Add-Failure 'Guards-only routing loaded reference sections.' }

$knowledgeEvidenceGuard = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Variant knowledge -Stage evidence -GuardsOnly) -join "`n"
Require-Contains $knowledgeEvidenceGuard 'Pre-evidence artifact guard:' 'non-software pre-evidence artifact guard'

$nonSoftwareIntake = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Variant training -Stage intake -GuardsOnly) -join "`n"
Require-Contains $nonSoftwareIntake 'INTAKE for a substantial non-software project' 'non-software new-project intake boundary'
Require-Contains $nonSoftwareIntake 'one concentrated packet' 'non-software concentrated intake'
Require-Contains $nonSoftwareIntake 'requesting a material path or sample must not postpone independent questions' 'non-software material-path dependency boundary'
if ($nonSoftwareIntake.Contains('Current route is existing or continuing work')) { Add-Failure 'Non-software intake regressed to the existing-work guard.' }

foreach ($trainingStage in @('intake', 'evidence')) {
  $trainingContext = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Variant training -Stage $trainingStage) -join "`n"
  Require-Contains $trainingContext 'Training plain-language contrast: this is cross-role project-practice content design, not software architecture.' "training $trainingStage content-design contrast"
  Require-Contains $trainingContext 'Training material-first hard stop:' "training $trainingStage material-first gate"
  Require-Contains $trainingContext 'Training visible-packet gate after evidence:' "training $trainingStage visible-packet coverage gate"
  Require-Contains $trainingContext 'ask confirm/correct audience and include/exclude/unclassified absence' "training $trainingStage evidence-candidate confirmation"
  Require-Contains $trainingContext 'Training handoff guard:' "training $trainingStage handoff guard"
  Require-Contains $trainingContext 'Training output-boundary lint:' "training $trainingStage output-boundary lint"
  Require-Contains $trainingContext 'Training topic-coverage lint:' "training $trainingStage topic-coverage lint"
  Require-Contains $trainingContext 'Training baseline lint:' "training $trainingStage baseline lint"
}
$trainingEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Variant training -Stage evidence) -join "`n"
Require-Contains $trainingEvidence '## Training Transition Hard Stop' 'training post-evidence decision transition'
Require-Contains $trainingEvidence 'GuardsOnly never substitutes for decision' 'training guards-only transition boundary'

$trainingLint = Join-Path $SkillRoot 'scripts\validate_training_handoff.ps1'
$trainingLintText = Get-Content -LiteralPath $trainingLint -Raw -Encoding UTF8
Require-Contains $trainingLintText '[switch]$PassThrough' 'training handoff pass-through switch'
Require-Contains $trainingLintText '---BEGIN APPROVED TRAINING HANDOFF---' 'training handoff approved-text begin marker'
Require-Contains $trainingLintText 'Training handoff SHA256:' 'training handoff approved-text hash'
Require-Contains $trainingLintText 'Exercise or project deferred-item practice was classified as curriculum deferral.' 'training exercise deferral separation'
$trainingLintTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('allred-training-lint-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $trainingLintTemp | Out-Null
try {
  $validTrainingDraft = Join-Path $trainingLintTemp 'valid.md'
  $validPlainTrainingDraft = Join-Path $trainingLintTemp 'valid-plain.txt'
  $invalidTrainingDraft = Join-Path $trainingLintTemp 'invalid.md'
  $invalidExerciseDeferralDraft = Join-Path $trainingLintTemp 'invalid-exercise-deferral.md'
  [System.IO.File]::WriteAllText($validTrainingDraft, "## 范围边界`n`n- 课程内容暂无已确认暂缓项。`n`n## 当前执行边界`n`n本轮不生成文件；已批准交付不变。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($validPlainTrainingDraft, "暂缓与排除`n`n暂无已确认的课程内容暂缓项。`n`n【执行边界】`n`n本轮不生成文件；已批准交付不变。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidTrainingDraft, "## 暂缓与排除`n`n- 已确认暂缓：本轮不生成文件。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidExerciseDeferralDraft, "## 暂缓与排除`n`n- 已确认暂缓：员工练习需要填写项目暂缓项。`n`n## 当前执行边界`n`n本轮不生成文件。", [System.Text.UTF8Encoding]::new($false))
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $validTrainingDraft)) -ne 0) { Add-Failure 'Training handoff lint rejected valid execution-boundary placement.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $validPlainTrainingDraft)) -ne 0) { Add-Failure 'Training handoff lint rejected a valid plain-language execution heading.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $invalidTrainingDraft)) -eq 0) { Add-Failure 'Training handoff lint accepted no-generation as curriculum deferral.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $invalidExerciseDeferralDraft)) -eq 0) { Add-Failure 'Training handoff lint accepted exercise-level deferred items as curriculum deferral.' }
  $powerShellExecutable = (Get-Process -Id $PID).Path
  $passThroughOutput = @(& $powerShellExecutable -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $trainingLint -Path $validTrainingDraft -PassThrough 2>&1 | ForEach-Object { [string]$_ })
  if ($LASTEXITCODE -ne 0) { Add-Failure 'Training handoff pass-through rejected a valid draft.' }
  $passThroughText = $passThroughOutput -join "`n"
  Require-Contains $passThroughText 'Training handoff lint: PASS' 'training handoff pass-through PASS result'
  Require-Contains $passThroughText '---BEGIN APPROVED TRAINING HANDOFF---' 'training handoff pass-through begin marker'
  Require-Contains $passThroughText '---END APPROVED TRAINING HANDOFF---' 'training handoff pass-through end marker'
  $approvedMatch = [regex]::Match($passThroughText, '(?s)---BEGIN APPROVED TRAINING HANDOFF---\r?\n(?<text>.*?)\r?\n---END APPROVED TRAINING HANDOFF---')
  $expectedApproved = (Get-Content -LiteralPath $validTrainingDraft -Raw -Encoding UTF8) -replace "`r`n", "`n"
  if (-not $approvedMatch.Success -or (($approvedMatch.Groups['text'].Value -replace "`r`n", "`n") -ne $expectedApproved.TrimEnd("`r", "`n"))) {
    Add-Failure 'Training handoff pass-through did not preserve the exact approved draft.'
  }
} finally {
  if (Test-Path -LiteralPath $trainingLintTemp) { Remove-Item -LiteralPath $trainingLintTemp -Recurse -Force }
}

$questionLint = Join-Path $SkillRoot 'scripts\validate_question_packet.ps1'
$questionLintText = Get-Content -LiteralPath $questionLint -Raw -Encoding UTF8
Require-Contains $questionLintText "[ValidateSet('generic', 'training')]" 'question packet training profile'
Require-Contains $questionLintText 'Training packet reopens a completed baseline without -AllowCompletedBaselineReview.' 'training completed-baseline lint'
Require-Contains $questionLintText 'Training packet states a negative curriculum boundary before user confirmation.' 'training negative-boundary provenance lint'
Require-Contains $questionLintText 'Training packet asks for a future artifact format that does not affect the current in-chat result.' 'training speculative-format lint'
Require-Contains $questionLintText '---BEGIN APPROVED QUESTION PACKET---' 'question packet approved-text marker'
$questionLintTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('allred-question-lint-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $questionLintTemp | Out-Null
try {
  $validQuestionDraft = Join-Path $questionLintTemp 'valid.md'
  $invalidQuestionDraft = Join-Path $questionLintTemp 'invalid.md'
  $validTrainingQuestionDraft = Join-Path $questionLintTemp 'training-valid.md'
  $invalidTrainingQuestionDraft = Join-Path $questionLintTemp 'training-invalid.md'
  $prematureTrainingBoundaryDraft = Join-Path $questionLintTemp 'training-premature-boundary.md'
  $speculativeTrainingFormatDraft = Join-Path $questionLintTemp 'training-speculative-format.md'
  [System.IO.File]::WriteAllText($validQuestionDraft, "## Roles`n`n- **Question: Who submits?** Impact: controls the entry authority. Reply: name the role.`n- **Question: Who approves?**`n  Impact: controls when the record becomes final.`n  Reply: name the role and condition.", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidQuestionDraft, "## Roles`n`n- **Question: Who submits?**`n  Why now: authority depends on this answer.`n  Basis: unknown.`n  Reply: name the role.", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($validTrainingQuestionDraft, "请确认或增删学员岗位。课程目标希望员工达到什么学习结果？除候选内容外还有哪些必讲主题需要补充？练习希望做到什么终点或成果？当前本轮只在对话中确认范围，不生成讲义或练习表。未请求内容请选择纳入、排除或暂不分类。怎样的验证证据算达到验收标准？", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidTrainingQuestionDraft, "学员已完成基础培训。请选择安排简短复习还是独立复习环节。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($prematureTrainingBoundaryDraft, "请确认或增删学员岗位。不包含财务内容。课程目标希望员工达到什么学习结果？除候选内容外还有哪些必讲主题需要补充？练习希望做到什么终点或成果？当前本轮只在对话中确认范围，不生成讲义或练习表。未请求内容请选择纳入、排除或暂不分类。怎样的验证证据算达到验收标准？", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($speculativeTrainingFormatDraft, "请确认或增删学员岗位。课程目标希望员工达到什么学习结果？除候选内容外还有哪些必讲主题需要补充？练习希望做到什么终点或成果？当前本轮只在对话中确认范围，不生成讲义或练习表。本次需要交付什么培训材料？未请求内容请选择纳入、排除或暂不分类。怎样的验证证据算达到验收标准？", [System.Text.UTF8Encoding]::new($false))
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $validQuestionDraft)) -ne 0) { Add-Failure 'Question packet lint rejected valid adjacent impact and reply guidance.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $invalidQuestionDraft)) -eq 0) { Add-Failure 'Question packet lint accepted why-now text as a substitute for facet impact.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $validTrainingQuestionDraft, '-Profile', 'training', '-PassThrough')) -ne 0) { Add-Failure 'Training question packet lint rejected complete concentrated coverage.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $invalidTrainingQuestionDraft, '-Profile', 'training')) -eq 0) { Add-Failure 'Training question packet lint accepted reopening a completed baseline.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $prematureTrainingBoundaryDraft, '-Profile', 'training')) -eq 0) { Add-Failure 'Training question packet lint accepted an unconfirmed negative boundary.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $speculativeTrainingFormatDraft, '-Profile', 'training')) -eq 0) { Add-Failure 'Training question packet lint accepted a speculative future artifact decision.' }
} finally {
  if (Test-Path -LiteralPath $questionLintTemp) { Remove-Item -LiteralPath $questionLintTemp -Recurse -Force }
}

$compatibilityMetric = & $selectorPath -SkillRoot $SkillRoot -Route new-public -Stage evidence -MetricsOnly | ConvertFrom-Json
if ($compatibilityMetric.route -ne 'new-standard' -or -not $compatibilityMetric.compatibility_alias -or 'external-source' -notin @($compatibilityMetric.overlays)) {
  Add-Failure 'Deprecated new-public compatibility mapping is broken.'
}

foreach ($relative in @('scripts\check_invariants.ps1', 'scripts\check_runtime_generality.ps1', 'scripts\check_behavior_manifest.ps1', 'scripts\check_route_context_budget.ps1')) {
  $path = Join-Path $SkillRoot $relative
  $code = Invoke-IsolatedScriptExitCode -ScriptPath $path -Arguments @('-SkillRoot', $SkillRoot)
  if ($code -ne 0) { Add-Failure "$relative failed with exit code $code" }
}

$executionRecord = Join-Path $SkillRoot 'tests\execution-record.valid.md'
foreach ($relative in @('scripts\validate_execution_record.ps1', 'scripts\validate_decision_coverage.ps1')) {
  $code = Invoke-IsolatedScriptExitCode -ScriptPath (Join-Path $SkillRoot $relative) -Arguments @('-Path', $executionRecord)
  if ($code -ne 0) { Add-Failure "$relative rejected the valid execution record." }
}

$gate = Join-Path $SkillRoot 'scripts\invoke_validation_gate.ps1'
$validState = Join-Path $SkillRoot 'tests\project-state.valid-ready.json'
$validCode = Invoke-IsolatedScriptExitCode -ScriptPath $gate -Arguments @('-Path', $validState, '-ToStage', 'READY')
if ($validCode -ne 0) { Add-Failure 'Aggregate gate rejected valid READY state.' }
$coverageValidator = Join-Path $SkillRoot 'scripts\validate_discovery_coverage.ps1'
if ((Invoke-IsolatedScriptExitCode -ScriptPath $coverageValidator -Arguments @('-Path', $validState)) -ne 0) {
  Add-Failure 'Discovery coverage validator rejected valid READY state.'
}
$invalidCoverageTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('allred-invalid-coverage-' + [guid]::NewGuid().ToString('N') + '.json')
try {
  $invalidCoverageState = Get-Content -LiteralPath $validState -Raw -Encoding UTF8 | ConvertFrom-Json
  $invalidCoverageState.discovery_coverage.status = 'incomplete'
  $invalidCoverageState.discovery_coverage.areas[2].status = 'open'
  $invalidCoverageState.discovery_coverage.areas[2].open_item_ids = @('Q-LIFECYCLE')
  [System.IO.File]::WriteAllText($invalidCoverageTemp, ($invalidCoverageState | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $coverageValidator -Arguments @('-Path', $invalidCoverageTemp)) -eq 0) {
    Add-Failure 'Discovery coverage validator accepted an unresolved coverage area.'
  }
} finally {
  if (Test-Path -LiteralPath $invalidCoverageTemp) { Remove-Item -LiteralPath $invalidCoverageTemp -Force }
}
foreach ($invalid in @(
  @{ file = 'project-state.invalid-stage.json'; stage = 'DECISION' },
  @{ file = 'project-state.invalid-frontier.json'; stage = 'DECISION' },
  @{ file = 'project-state.invalid-ready.json'; stage = 'READY' }
)) {
  $code = Invoke-IsolatedScriptExitCode -ScriptPath $gate -Arguments @('-Path', (Join-Path $SkillRoot ('tests\' + $invalid.file)), '-ToStage', $invalid.stage)
  if ($code -eq 0) { Add-Failure "Aggregate gate accepted invalid fixture: $($invalid.file)" }
}

$tempHelper = Join-Path $SkillRoot 'scripts\new_evidence_temp.ps1'
$tempResult = (& $tempHelper -Purpose 'structure-check') | ConvertFrom-Json
$systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
$resolvedTemp = [System.IO.Path]::GetFullPath([string]$tempResult.path)
if (-not $resolvedTemp.StartsWith($systemTemp + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
  Add-Failure "Temporary evidence helper escaped system temp: $resolvedTemp"
}
if (Test-Path -LiteralPath $resolvedTemp) { Remove-Item -LiteralPath $resolvedTemp -Recurse -Force }

if ($ReleaseRoot) {
  if (-not (Test-Path -LiteralPath $ReleaseRoot)) { Add-Failure "Release root does not exist: $ReleaseRoot" }
  else {
    $sourceFiles = @(Get-ChildItem -LiteralPath $SkillRoot -Recurse -File)
    $releaseFiles = @(Get-ChildItem -LiteralPath $ReleaseRoot -Recurse -File)
    $sourceRelative = @($sourceFiles | ForEach-Object { Get-RelativePath $SkillRoot $_.FullName })
    $releaseRelative = @($releaseFiles | ForEach-Object { Get-RelativePath $ReleaseRoot $_.FullName })
    foreach ($relative in $sourceRelative) {
      $releasePath = Join-Path $ReleaseRoot $relative
      if (-not (Test-Path -LiteralPath $releasePath)) { Add-Failure "Release file missing: $relative" }
      elseif ((Get-FileHash -LiteralPath (Join-Path $SkillRoot $relative)).Hash -ne (Get-FileHash -LiteralPath $releasePath).Hash) { Add-Failure "Release file differs: $relative" }
    }
    foreach ($relative in $releaseRelative) {
      if ($relative -notin $sourceRelative) { Add-Failure "Release-only file exists: $relative" }
    }
  }
}

if ($failures.Count -gt 0) {
  'Skill structure check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Skill structure check: PASS'
"Skill root: $SkillRoot"
"SKILL.md lines: $($skillLines.Count)"
"Invariant manifest: PASS"
"Route isolation: PASS"
if ($ReleaseRoot) { "Release parity: PASS ($ReleaseRoot)" }
