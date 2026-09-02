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

foreach ($heading in @('## Runtime Hard Stops', '## Activation And Routing', '## Required Reading', '## Shared Invariants', '## Conversation Topology')) {
  Require-Contains $skillText $heading $heading
}
Require-Contains $skillText 'allred-project-lab' 'maintainer Skill ownership'
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
if ($sharedIntake.Contains('## Evidence And Ownership') -or $sharedIntake.Contains('## Decision Packet')) {
  Add-Failure 'Shared intake route leaked later-stage collaboration guidance.'
}

$debugEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route existing-debug -Stage evidence) -join "`n"
Require-Contains $debugEvidence '## Hypothesis Discipline' 'debug evidence hypothesis discipline'
Require-Contains $debugEvidence 'support versus weaken' 'bounded debug experiment outcomes'

$sharedDecision = (& $selectorPath -SkillRoot $SkillRoot -Route long-term -Stage decision -Overlays shared-collaboration) -join "`n"
Require-Contains $sharedDecision '<!-- source: references\shared-collaboration.md -->' 'shared decision overlay routing'
Require-Contains $sharedDecision 'Q is current reality; future behavior is D' 'shared current-fact versus future-decision separation'
Require-Contains $sharedDecision 'Facts cover participants, workflow/records, and environment' 'shared current-fact coverage'
Require-Contains $sharedDecision 'Keep create, edit, approve/close, reopen, and delete as separate suffixes' 'shared action-axis separation'
Require-Match $sharedDecision '(?is)Each suffix bullet.{0,100}影响：.{0,100}回复：.{0,180}group text or examples never substitute' 'shared per-facet consequence and reply contract'
Require-Contains $sharedDecision 'Pipe the exact draft through scripts/validate_question_packet.ps1; after PASS send it unchanged or re-lint' 'shared deterministic question-packet lint'
Require-Contains $sharedDecision 'Allow one natural-prose reply' 'shared natural reply contract'
Require-Contains $sharedDecision "Shared hard stops: no invented days/hours/counts/retention; use '由你指定'" 'shared quantitative provenance hard stop'
Require-Contains $sharedDecision "可暂缓任一项；对应设计/实现/验收保持未定，不开发" 'shared discovery deferral hard stop'
Require-Match $sharedDecision '(?is)(ID-free groups|ID-free headings)' 'shared group-heading separation'

$beginnerEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Interaction beginner) -join "`n"
Require-Contains $beginnerEvidence 'never echo internal English labels' 'beginner evidence plain-language guard'

$newProjectIntake = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage intake -Interaction standard) -join "`n"
Require-Contains $newProjectIntake 'one packet-wide consequence sentence is insufficient' 'new-project intake per-group consequence lint'
Require-Contains $newProjectIntake 'aggregate DECISION/READY without StatePath' 'intake trusted event handoff'
Require-Contains $newProjectIntake 'never load EVIDENCE to find the target' 'intake material-location stage boundary'
Require-Contains $newProjectIntake 'recognizable useful result -> acceptance evidence' 'new-project success effect coverage'
Require-Contains $newProjectIntake 'do not search the workspace for it' 'intake guard respects explicitly unsupplied materials'
Require-Contains $newProjectIntake 'Pending material postpones evidence-dependent recommendations, not independent intake' 'missing material preserves independent intake packet'

$office = (& $selectorPath -SkillRoot $SkillRoot -Route new-standard -Stage evidence -Overlays company-office-delivery) -join "`n"
Require-Contains $office '<!-- source: references\company-office-delivery.md -->' 'company office overlay routing'

$trainingDecision = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Stage decision -Variant training) -join "`n"
Require-Contains $trainingDecision 'Existing handouts prove material exists, not learner completion.' 'training material-versus-completion evidence boundary'
Require-Contains $trainingDecision "Same packet confirms each evidence-only absence/non-request as exclusion or leaves it unclassified; never call it '已确认'" 'training evidence-only exclusion confirmation'
Require-Contains $trainingDecision 'No empty headings' 'training final-handoff empty-section lint'
Require-Contains $trainingDecision "put requested 'none confirmed' in a nonempty boundary" 'training requested-empty-category rendering'
Require-Contains $trainingDecision 'Defer only exact user-confirmed curriculum items' 'training deferral provenance allowlist'
Require-Contains $trainingDecision 'Lint final draft with scripts/validate_training_handoff.ps1; after PASS send it unchanged or re-lint' 'training deterministic handoff lint'
Require-Contains $trainingDecision 'No-file instruction belongs only under 执行边界' 'training current no-file execution boundary'

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
  Require-Contains $trainingContext 'Training handoff guard:' "training $trainingStage handoff guard"
  Require-Contains $trainingContext 'Training output-boundary lint:' "training $trainingStage output-boundary lint"
  Require-Contains $trainingContext 'Training topic-coverage lint:' "training $trainingStage topic-coverage lint"
  Require-Contains $trainingContext 'Training baseline lint:' "training $trainingStage baseline lint"
}
$trainingEvidence = (& $selectorPath -SkillRoot $SkillRoot -Route non-software -Variant training -Stage evidence) -join "`n"
Require-Contains $trainingEvidence '## Training Transition Hard Stop' 'training post-evidence decision transition'
Require-Contains $trainingEvidence 'GuardsOnly never substitutes for decision' 'training guards-only transition boundary'

$trainingLint = Join-Path $SkillRoot 'scripts\validate_training_handoff.ps1'
$trainingLintTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('allred-training-lint-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $trainingLintTemp | Out-Null
try {
  $validTrainingDraft = Join-Path $trainingLintTemp 'valid.md'
  $validPlainTrainingDraft = Join-Path $trainingLintTemp 'valid-plain.txt'
  $invalidTrainingDraft = Join-Path $trainingLintTemp 'invalid.md'
  [System.IO.File]::WriteAllText($validTrainingDraft, "## 范围边界`n`n- 课程内容暂无已确认暂缓项。`n`n## 当前执行边界`n`n本轮不生成文件；已批准交付不变。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($validPlainTrainingDraft, "暂缓与排除`n`n暂无已确认的课程内容暂缓项。`n`n【执行边界】`n`n本轮不生成文件；已批准交付不变。", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidTrainingDraft, "## 暂缓与排除`n`n- 已确认暂缓：本轮不生成文件。", [System.Text.UTF8Encoding]::new($false))
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $validTrainingDraft)) -ne 0) { Add-Failure 'Training handoff lint rejected valid execution-boundary placement.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $validPlainTrainingDraft)) -ne 0) { Add-Failure 'Training handoff lint rejected a valid plain-language execution heading.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $trainingLint -Arguments @('-Path', $invalidTrainingDraft)) -eq 0) { Add-Failure 'Training handoff lint accepted no-generation as curriculum deferral.' }
} finally {
  if (Test-Path -LiteralPath $trainingLintTemp) { Remove-Item -LiteralPath $trainingLintTemp -Recurse -Force }
}

$questionLint = Join-Path $SkillRoot 'scripts\validate_question_packet.ps1'
$questionLintTemp = Join-Path ([System.IO.Path]::GetTempPath()) ('allred-question-lint-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $questionLintTemp | Out-Null
try {
  $validQuestionDraft = Join-Path $questionLintTemp 'valid.md'
  $invalidQuestionDraft = Join-Path $questionLintTemp 'invalid.md'
  [System.IO.File]::WriteAllText($validQuestionDraft, "## Roles`n`n- **Question: Who submits?** Impact: controls the entry authority. Reply: name the role.`n- **Question: Who approves?**`n  Impact: controls when the record becomes final.`n  Reply: name the role and condition.", [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText($invalidQuestionDraft, "## Roles`n`n- **Question: Who submits?**`n  Why now: authority depends on this answer.`n  Basis: unknown.`n  Reply: name the role.", [System.Text.UTF8Encoding]::new($false))
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $validQuestionDraft)) -ne 0) { Add-Failure 'Question packet lint rejected valid adjacent impact and reply guidance.' }
  if ((Invoke-IsolatedScriptExitCode -ScriptPath $questionLint -Arguments @('-Path', $invalidQuestionDraft)) -eq 0) { Add-Failure 'Question packet lint accepted why-now text as a substitute for facet impact.' }
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
