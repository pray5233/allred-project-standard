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
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

function Require-Text([string]$Text, [string]$Pattern, [string]$Label) {
  if ($Text -notmatch [regex]::Escape($Pattern)) {
    Add-Failure "Missing required behavior marker: $Label"
  }
}

$skillPath = Join-Path $SkillRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillPath)) {
  throw "SKILL.md not found: $skillPath"
}

$skillLines = Get-Content -LiteralPath $skillPath -Encoding UTF8
$skillText = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8

if ($skillLines.Count -lt 4 -or $skillLines[0] -ne '---' -or $skillLines[3] -ne '---') {
  Add-Failure 'Frontmatter must contain name and description between delimiters.'
}
if ($skillLines[1] -notmatch '^name:\s*allred-project-standard\s*$') {
  Add-Failure 'Frontmatter name is missing or unexpected.'
}
if ($skillLines[2] -notmatch '^description:\s+\S') {
  Add-Failure 'Frontmatter description is missing.'
}
if ($skillLines[2].Length -gt 700) {
  Add-Failure 'Frontmatter description is too broad; keep discovery concise.'
}
if ($skillLines.Count -gt 260) {
  Add-Failure "SKILL.md is too large for the lightweight entrypoint budget: $($skillLines.Count) lines."
}
Require-Text $skillText 'Conversation Topology' 'lifecycle stages are not conversation turns'
Require-Text $skillText 'Codex owns the default work of searching and selecting a comparable benchmark' 'method work stays Codex-owned'
Require-Text $skillText 'Superpowers is a method benchmark, not a runtime dependency' 'Superpowers is adapted, not layered'
Require-Text $skillText 'Do not use TDD or Red-Green as the execution order' 'TDD/Red-Green execution order is disabled'
Require-Text $skillText '`allred新手`' 'unambiguous short beginner alias'
Require-Text $skillText 'assumption-first alignment' 'assumption-first routing is visible in the entrypoint'
Require-Text $skillText 'Evidence proves facts and feasibility; it does not authorize new product behavior' 'evidence does not grant product authorization'
Require-Text $skillText 'runtime data/logs/caches' 'runtime effects are part of the write boundary'
Require-Text $skillText 'A recommendation enters the visible contract only when it serves an approved outcome' 'recommendations pass a necessity filter'
Require-Text $skillText 'Codex execution record' 'technical mechanics remain Codex-owned'
Require-Text $skillText 'document-heavy internal projects' 'non-software projects are first-class'
Require-Text $skillText 'Do not create or require a company-context Skill' 'company context remains explicit and separate'
Require-Text $skillText 'Choose one primary route for the current stage' 'route bundles are not stacked by default'
Require-Text $skillText 'do not also load `new-standard` merely because it is new' 'new non-software work avoids software-route duplication'
Require-Text $skillText 'build a gray-area map' 'entrypoint supports discussion-area selection'
Require-Text $skillText 'Each important item states why it is needed now' 'entrypoint requires useful question context'
Require-Text $skillText 'Every active `U/D` scope decision must map' 'entrypoint requires decision coverage'

$requiredLinks = @(
  'references/核心执行流程.md',
  'references/交互与确认规则.md',
  'references/动态项目契约.md',
  'references/新项目启动模式.md',
  'references/新手模式.md',
  'references/项目阶段分流.md',
  'references/功能调试.md',
  'references/新增功能.md',
  'references/界面优化.md',
  'references/本轮验收与复盘.md',
  'references/长期任务模式.md',
  'references/Skill流程优化模式.md',
  'references/Skill测试验收.md',
  'references/开发依据与能力复用.md',
  'references/项目级别问法.md',
  'references/公开信息监测项目.md',
  'references/外部内容安全.md',
  'references/非软件项目模式.md'
)

foreach ($relative in $requiredLinks) {
  Require-Text $skillText $relative $relative
}

$markdownFiles = Get-ChildItem -LiteralPath $SkillRoot -Recurse -File -Filter '*.md'
$linkPattern = [regex]'\x60((?:references|templates|scripts|tests)/[^\x60<>]+)\x60'

foreach ($file in $markdownFiles) {
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  foreach ($match in $linkPattern.Matches($text)) {
    $relative = $match.Groups[1].Value
    $target = Join-Path $SkillRoot ($relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
    if (-not (Test-Path -LiteralPath $target)) {
      Add-Failure "Linked file is missing: $relative (from $(Get-RelativePath $SkillRoot $file.FullName))"
    }
  }
}

$activeText = ($markdownFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
$resourceFiles = Get-ChildItem -LiteralPath (Join-Path $SkillRoot 'references') -File |
  Where-Object { $_.Extension -eq '.md' }
$resourceFiles += Get-ChildItem -LiteralPath (Join-Path $SkillRoot 'templates') -File |
  Where-Object { $_.Extension -eq '.md' }

foreach ($file in $resourceFiles) {
  $relative = Get-RelativePath $SkillRoot $file.FullName
  if ($activeText -notmatch [regex]::Escape($relative)) {
    Add-Failure "Active resource is orphaned: $relative"
  }
}

$sharedPath = Join-Path $SkillRoot 'references\交互与确认规则.md'
$corePath = Join-Path $SkillRoot 'references\核心执行流程.md'
$contractPath = Join-Path $SkillRoot 'references\动态项目契约.md'
$benchmarkPath = Join-Path $SkillRoot 'references\开发依据与能力复用.md'
$levelPath = Join-Path $SkillRoot 'references\项目级别问法.md'
$monitoringPath = Join-Path $SkillRoot 'references\公开信息监测项目.md'
$externalSafetyPath = Join-Path $SkillRoot 'references\外部内容安全.md'
$runtimePath = Join-Path $SkillRoot 'references\运行环境与交付形态.md'
$materialsPath = Join-Path $SkillRoot 'references\资料收集与分析.md'
$skillFlowPath = Join-Path $SkillRoot 'references\Skill流程优化模式.md'
$skillTestPath = Join-Path $SkillRoot 'references\Skill测试验收.md'
$projectTypePath = Join-Path $SkillRoot 'references\项目类型问题库.md'
$beginnerPath = Join-Path $SkillRoot 'references\新手模式.md'
$writeBoundaryPath = Join-Path $SkillRoot 'references\写入边界说明.md'
$nonSoftwarePath = Join-Path $SkillRoot 'references\非软件项目模式.md'
$behaviorCheckPath = Join-Path $SkillRoot 'scripts\check_behavior_manifest.ps1'
$behaviorRunnerPath = Join-Path $SkillRoot 'scripts\run_behavior_eval.ps1'
$reviewSchemaPath = Join-Path $SkillRoot 'tests\review-result.schema.json'
$executionTemplatePath = Join-Path $SkillRoot 'templates\Codex执行记录.md'
$executionValidatorPath = Join-Path $SkillRoot 'scripts\validate_execution_record.ps1'
$decisionCoverageValidatorPath = Join-Path $SkillRoot 'scripts\validate_decision_coverage.ps1'
$executionFixturePath = Join-Path $SkillRoot 'tests\execution-record.valid.md'
$routeContextPath = Join-Path $SkillRoot 'scripts\get_route_context.ps1'
$routeBudgetPath = Join-Path $SkillRoot 'scripts\check_route_context_budget.ps1'
$versionPath = Join-Path $SkillRoot 'VERSION'
$openAiYamlPath = Join-Path $SkillRoot 'agents\openai.yaml'

foreach ($requiredPath in @($corePath, $sharedPath, $contractPath, $benchmarkPath, $levelPath, $monitoringPath, $externalSafetyPath, $runtimePath, $materialsPath, $skillFlowPath, $projectTypePath, $beginnerPath, $writeBoundaryPath, $nonSoftwarePath, $behaviorCheckPath, $behaviorRunnerPath, $reviewSchemaPath, $executionTemplatePath, $executionValidatorPath, $decisionCoverageValidatorPath, $executionFixturePath, $routeContextPath, $routeBudgetPath, $versionPath, $openAiYamlPath)) {
  if (-not (Test-Path -LiteralPath $requiredPath)) {
    Add-Failure "Required architecture reference is missing: $requiredPath"
  }
}

if (Test-Path -LiteralPath $versionPath) {
  $version = (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim()
  if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') { Add-Failure "VERSION is not valid SemVer: $version" }
}

if (Test-Path -LiteralPath $openAiYamlPath) {
  $openAiYaml = Get-Content -LiteralPath $openAiYamlPath -Raw -Encoding UTF8
  foreach ($marker in @('display_name: "Allred Project Standard"', 'short_description:', 'default_prompt: "Use $allred-project-standard', 'allow_implicit_invocation: true')) {
    if (-not $openAiYaml.Contains($marker)) { Add-Failure "agents/openai.yaml missing marker: $marker" }
  }
}

if (Test-Path -LiteralPath $projectTypePath) {
  $projectTypeText = Get-Content -LiteralPath $projectTypePath -Raw -Encoding UTF8
  if ($projectTypeText.Contains('First question:')) { Add-Failure 'Project-type guidance still contains a fixed first-question template.' }
  if ($projectTypeText.Contains('Current-scope default:')) { Add-Failure 'Project-type guidance still contains a type-based scope default.' }
  Require-Text $projectTypeText 'without `U` or `D` provenance' 'project-type hints cannot authorize scope'
}

if (Test-Path -LiteralPath $beginnerPath) {
  $beginnerText = Get-Content -LiteralPath $beginnerPath -Raw -Encoding UTF8
  if ($beginnerText.Contains('关注主流厂家的最新动态')) { Add-Failure 'Beginner guidance still embeds a domain-specific initial idea.' }
}

if (Test-Path -LiteralPath $writeBoundaryPath) {
  $writeBoundaryText = Get-Content -LiteralPath $writeBoundaryPath -Raw -Encoding UTF8
  Require-Text $writeBoundaryText '不自动创建、提交或合并' 'Git isolation is conditional rather than automatic'
}

if (Test-Path -LiteralPath $nonSoftwarePath) {
  $nonSoftwareText = Get-Content -LiteralPath $nonSoftwarePath -Raw -Encoding UTF8
  foreach ($marker in @('## Training Project', '## Training Alignment Gate', '## Policy And Procedure', '## Knowledge Base', '## Bid And Tender', '## Contract', '## Inspection And Quality Record', '## Review And Acceptance')) {
    if (-not $nonSoftwareText.Contains($marker)) { Add-Failure "Non-software route missing marker: $marker" }
  }
  Require-Text $nonSoftwareText 'Use `开始执行前确认`, not `开始开发前确认`' 'non-software route uses execution wording'
  Require-Text $nonSoftwareText 'does not create or require `allred-company-context`' 'company context is not required'
  Require-Text $nonSoftwareText 'Never fill a missing measurement' 'inspection records prohibit fabricated evidence'
  Require-Text $nonSoftwareText 'does not replace authorized legal or commercial judgment' 'contract review remains human-owned'
  Require-Text $nonSoftwareText 'Do not invent qualifications' 'bid responses require evidence'
  Require-Text $nonSoftwareText 'the complete-system route is materially more complex' 'training complexity is disclosed before selection'
  Require-Text $nonSoftwareText 'what the first phase will not teach' 'training omissions stay user-owned'
  Require-Text $nonSoftwareText 'show one complete proposed directory' 'training content is confirmed before file creation'
  Require-Text $nonSoftwareText 'Structural checks such as file count' 'training acceptance checks content fit'
}

if (Test-Path -LiteralPath $executionTemplatePath) {
  $executionTemplateText = Get-Content -LiteralPath $executionTemplatePath -Raw -Encoding UTF8
  foreach ($marker in @('## Evidence Ledger', '## Approved Scope Ledger', '## Exact Commands', '## Mutation Ledger', '## Significant Effects Reconciliation', '## Decision Coverage Ledger', '## Acceptance Ledger', '## Rollback And Checkpoint')) {
    if (-not $executionTemplateText.Contains($marker)) { Add-Failure "Execution record template missing marker: $marker" }
  }
}

if ((Test-Path -LiteralPath $executionValidatorPath) -and (Test-Path -LiteralPath $executionFixturePath)) {
  & $executionValidatorPath -Path $executionFixturePath | Out-Null
  if (-not $?) { Add-Failure 'Execution record validator rejected the valid fixture.' }

  $crlfFixturePath = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-valid-crlf-" + [guid]::NewGuid().ToString('N') + '.md')
  try {
    $fixtureText = (Get-Content -LiteralPath $executionFixturePath -Raw -Encoding UTF8) -replace "`r`n?", "`n"
    [System.IO.File]::WriteAllText($crlfFixturePath, ($fixtureText -replace "`n", "`r`n"), [System.Text.UTF8Encoding]::new($false))
    & $executionValidatorPath -Path $crlfFixturePath | Out-Null
    if (-not $?) { Add-Failure 'Execution record validator rejected the valid CRLF fixture.' }
  } finally {
    Remove-Item -LiteralPath $crlfFixturePath -Force -ErrorAction SilentlyContinue
  }
}

if ((Test-Path -LiteralPath $decisionCoverageValidatorPath) -and (Test-Path -LiteralPath $executionFixturePath)) {
  & $decisionCoverageValidatorPath -Path $executionFixturePath | Out-Null
  if (-not $?) { Add-Failure 'Decision coverage validator rejected the valid fixture.' }

  $invalidCoveragePath = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-invalid-coverage-" + [guid]::NewGuid().ToString('N') + '.md')
  try {
    $invalidCoverage = (Get-Content -LiteralPath $executionFixturePath -Raw -Encoding UTF8).Replace('- Active scope decision IDs: D1', '- Active scope decision IDs: D1, D2')
    [System.IO.File]::WriteAllText($invalidCoveragePath, $invalidCoverage, [System.Text.UTF8Encoding]::new($false))
    & $decisionCoverageValidatorPath -Path $invalidCoveragePath | Out-Null
    if ($?) { Add-Failure 'Decision coverage validator accepted a fixture with a missing active decision row.' }
  } finally {
    Remove-Item -LiteralPath $invalidCoveragePath -Force -ErrorAction SilentlyContinue
  }

  $closedInvalidPath = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-closed-invalid-" + [guid]::NewGuid().ToString('N') + '.md')
  $closedValidPath = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-closed-valid-" + [guid]::NewGuid().ToString('N') + '.md')
  $sharedPromisePath = Join-Path ([System.IO.Path]::GetTempPath()) ("allred-shared-promise-" + [guid]::NewGuid().ToString('N') + '.md')
  try {
    $fixtureText = Get-Content -LiteralPath $executionFixturePath -Raw -Encoding UTF8
    $closedInvalid = $fixtureText.Replace('- Record status: ready', '- Record status: closed')
    [System.IO.File]::WriteAllText($closedInvalidPath, $closedInvalid, [System.Text.UTF8Encoding]::new($false))
    & $decisionCoverageValidatorPath -Path $closedInvalidPath | Out-Null
    if ($?) { Add-Failure 'Decision coverage validator accepted a closed record with a planned decision.' }

    $closedValid = $closedInvalid.Replace('| D1 | validator accepts the valid execution record fixture | tests/execution-record.valid.md | P1 | planned |', '| D1 | validator accepts the valid execution record fixture | tests/execution-record.valid.md | P1 | verified |')
    $closedValid = $closedValid.Replace('| P1 | validator accepts valid fixture | run validator | isolated fixture | planned |', '| P1 | validator accepts valid fixture | run validator | isolated fixture | verified |')
    $closedValid = $closedValid.Replace('| P1 | not run | isolated fixture | unverified | execute validator |', '| P1 | fresh validator run | isolated fixture | passed | None |')
    [System.IO.File]::WriteAllText($closedValidPath, $closedValid, [System.Text.UTF8Encoding]::new($false))
    & $decisionCoverageValidatorPath -Path $closedValidPath | Out-Null
    if (-not $?) { Add-Failure 'Decision coverage validator rejected a complete closed record.' }

    $sharedPromise = $fixtureText.Replace('- Active scope decision IDs: D1', '- Active scope decision IDs: D1, D2')
    $sharedPromise = $sharedPromise.Replace('| D1 | validator accepts the valid execution record fixture | fixture scope S1 | active |', "| D1 | validator accepts the valid execution record fixture | fixture scope S1 | active |`n| D2 | validator rejects generic promise collapse | fixture scope S1 | active |")
    $sharedPromise = $sharedPromise.Replace('| D1 | validator accepts the valid execution record fixture | tests/execution-record.valid.md | P1 | planned |', "| D1 | validator accepts the valid execution record fixture | tests/execution-record.valid.md | P1 | planned |`n| D2 | validator rejects generic promise collapse | tests/execution-record.valid.md | P1 | planned |")
    [System.IO.File]::WriteAllText($sharedPromisePath, $sharedPromise, [System.Text.UTF8Encoding]::new($false))
    & $decisionCoverageValidatorPath -Path $sharedPromisePath | Out-Null
    if ($?) { Add-Failure 'Decision coverage validator accepted two active decisions collapsed into one generic Promise.' }
  } finally {
    Remove-Item -LiteralPath $closedInvalidPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $closedValidPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $sharedPromisePath -Force -ErrorAction SilentlyContinue
  }
}

if (Test-Path -LiteralPath $routeBudgetPath) {
  & $routeBudgetPath -SkillRoot $SkillRoot | Out-Null
  if (-not $?) { Add-Failure 'Route context budget check failed.' }
}
if (Test-Path -LiteralPath $skillTestPath) {
  $skillTestText = Get-Content -LiteralPath $skillTestPath -Raw -Encoding UTF8
  Require-Text $skillTestText 'must not manufacture the behavior' 'test fixtures do not inject duplicate approval'
}

if (Test-Path -LiteralPath $sharedPath) {
  $sharedText = Get-Content -LiteralPath $sharedPath -Raw -Encoding UTF8
  Require-Text $sharedText 'Low interruption is not no communication' 'communication is preserved'
  Require-Text $sharedText 'Adaptive Interview And Decision Flow' 'interaction uses adaptive concentrated discovery'
  Require-Text $sharedText 'Do not impose a fixed question count' 'interaction is not limited by a numeric budget'
  Require-Text $sharedText 'Information questions and decisions are different' 'discovery is separated from approval'
  Require-Text $sharedText 'Batch independent questions' 'currently knowable questions are concentrated'
  Require-Text $sharedText 'Independent Baseline Sweep' 'parent decisions retain independent discovery coverage'
  Require-Text $sharedText 'Every unresolved `ask now` item appears in the same packet' 'independent facts are not deferred behind a parent choice'
  Require-Text $sharedText 'section headings do not substitute for field values' 'visible gray maps keep orthogonal fields explicit'
  Require-Text $sharedText 'Question Packet Contract' 'visible questions use a stable usability contract'
  Require-Text $sharedText 'Use stable type prefixes' 'information, decisions, and actions use distinct identifiers'
  Require-Text $sharedText '`Q` obtains information' 'Q cannot approve product behavior'
  Require-Text $sharedText '`D` records a product/business decision' 'D owns approval semantics'
  Require-Text $sharedText 'a model guess alone cannot justify a product recommendation' 'D recommendations require user or evidence basis'
  Require-Text $sharedText 'Classify by the meaning of the answer' 'Q and D are typed by semantic effect'
  Require-Text $sharedText 'which evidence and conditions make the result acceptable -> `D`' 'acceptance meaning is a decision'
  Require-Text $sharedText 'a mixed item containing both fact and choice must be split' 'mixed Q/D items are separated'
  Require-Text $sharedText 'say `无依据推荐` and present neutral trade-offs' 'unsupported decisions remain neutral'
  Require-Text $sharedText 'consequential authorization is never placed in a `Q` or `D` packet' 'action authorization remains separate'
  Require-Text $sharedText 'Interaction Topology Selection' 'map, packet, and scope synthesis are mutually selected'
  Require-Text $sharedText '为什么现在问' 'questions explain their current decision value'
  Require-Text $sharedText 'keep the same question open' 'clarification requests do not silently advance'
  Require-Text $sharedText 'compare every option against the same relevant dimensions' 'decision explanations are complete and comparable'
  Require-Text $sharedText 'every `D` choice visibly includes a custom-answer path' 'decision choices preserve user correction'
  Require-Text $sharedText 'every `D` states `dependency: None` or exact prerequisite IDs' 'decision dependencies are explicit'
  Require-Text $sharedText 'recommendation deferred pending <IDs>' 'unresolved dependencies cannot support recommendations'
  Require-Text $sharedText 'Permission mapping or role maintenance alone is not an audit explanation' 'permission comparisons include real audit consequences'
  Require-Text $sharedText '`多人共享` does not prove `多人写入`' 'evidence paraphrases cannot broaden scope'
  Require-Text $sharedText 'record the decision in the user' 'confirmed decisions preserve exact operative meaning'
  Require-Text $sharedText '`全部按推荐` is valid only for recommendations visibly included' 'compact replies have narrow approval semantics'
  Require-Text $sharedText 'Product Decision Gate' 'product decisions use one gate'
  Require-Text $sharedText 'Consequential Authorization Gate' 'consequential actions use a separate gate'
  Require-Text $sharedText '【开始开发前确认】' 'prominent start confirmation remains available'
  Require-Text $sharedText 'D1=' 'unambiguous multi-decision reply'
  Require-Text $sharedText 'Approval Scope And Traceability' 'current-scope provenance gate'
  Require-Text $sharedText 'number of rounds follows dependency depth and consequence' 'follow-up depth is evidence driven'
  Require-Text $sharedText 'Decision Ownership' 'user and Codex responsibilities stay separate'
  Require-Text $sharedText 'Quantitative acceptance targets also need provenance' 'numeric acceptance needs evidence'
  Require-Text $sharedText '【项目方向确认】' 'beginner-visible scope uses plain language'
  Require-Text $sharedText 'same gate as scope approval' 'scope approval and unchanged start authorization can be combined'
  Require-Text $sharedText 'selecting one option or axis does not approve other `R` recommendations' 'numeric replies cannot over-approve recommendations'
  Require-Text $sharedText 'significant/consequential effects' 'start gate surfaces user-relevant side effects'
  Require-Text $sharedText 'recommendation admission filter' 'interaction filters unnecessary recommendations'
  Require-Text $sharedText 'Codex execution record rather than the user' 'technical detail is not a user approval burden'
}
if (Test-Path -LiteralPath $corePath) {
  $coreText = Get-Content -LiteralPath $corePath -Raw -Encoding UTF8
  Require-Text $coreText 'Fast' 'fast execution lane'
  Require-Text $coreText 'Standard' 'standard execution lane'
  Require-Text $coreText 'Deep' 'deep execution lane'
  Require-Text $coreText 'If three distinct root-cause hypotheses fail' 'debugging architecture stop'
  Require-Text $coreText 'Fresh evidence is mandatory' 'fresh verification before completion'
  Require-Text $coreText 'Do not use TDD or Red-Green as the execution order' 'no TDD/Red-Green execution order'
  Require-Text $coreText 'development-time, runtime, and external/system mutation ledger' 'core execution contract includes three mutation layers'
  Require-Text $coreText 'promise-by-promise acceptance ledger' 'core execution contract includes acceptance ledger'
  Require-Text $coreText 'decision coverage from every active `U/D` item' 'core maps approved scope to implementation and proof'
  Require-Text $coreText 'Apply the recommendation admission filter' 'core excludes unnecessary recommendations'
  Require-Text $coreText 'label unchanged `U/D`, technical `E`, new `R`, and removed `X` separately' 'contract deltas stay explicit'
  Require-Text $coreText 'no fixed interaction or decision-count target' 'core efficiency has no hard turn quota'
}
if (Test-Path -LiteralPath $contractPath) {
  $contractText = Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8
  Require-Text $contractText 'Assumption-First Alignment' 'assumption-first project alignment'
  Require-Text $contractText 'Gray-Area Map' 'unresolved discussion areas are mapped before questioning'
  Require-Text $contractText '| resolution |' 'gray resolution is orthogonal'
  Require-Text $contractText '| need/owner |' 'gray owner/need is orthogonal'
  Require-Text $contractText '| timing |' 'gray timing is orthogonal'
  Require-Text $contractText 'Selecting discussion areas authorizes discussion only' 'area selection cannot approve scope'
  Require-Text $contractText 'Do not use a confidence percentage' 'interview stops on coverage rather than a numeric proxy'
  Require-Text $contractText 'A visible decision must satisfy all of these' 'dynamic decision exposure filter'
  Require-Text $contractText 'Contract Consistency Lint' 'pre-gate contract consistency check'
  Require-Text $contractText 'Coverage Shape' 'coverage axes are derived from the task'
  Require-Text $contractText 'complete replacement contract or scope' 'corrections produce a complete active scope'
  Require-Text $contractText 'Context Read Ledger' 'unchanged references are not loaded repeatedly'
  Require-Text $contractText 'Approval Envelope' 'recommendations need an explicit approval envelope'
  Require-Text $contractText 'Mutation Ledger' 'all mutation layers are identified'
  Require-Text $contractText 'Acceptance Ledger' 'promises map to planned evidence'
  Require-Text $contractText '`E` can prove feasibility' 'evidence is not authorization'
  Require-Text $contractText 'convert only the listed `R` items to `D`' 'partial approval stays narrow'
  Require-Text $contractText 'These state codes are internal or durable-record notation' 'state tracking does not burden beginner conversation'
  Require-Text $contractText 'Documenting rollback does not automatically authorize deleting pre-existing' 'rollback plans do not grant destructive authority'
  Require-Text $contractText 'Recommendation Admission Filter' 'visible recommendations are necessary'
  Require-Text $contractText 'Reproducible Evidence Record' 'scope evidence is reproducible'
  Require-Text $contractText 'response success is not outcome success' 'retrieval evidence requires semantic validation'
  Require-Text $contractText 'User Confirmation And Codex Execution Record' 'user scope and technical mechanics are separated'
  Require-Text $contractText 'Name concrete initial working-set items' 'user confirmation names visible presets'
  Require-Text $contractText 'Approvable does not mean worth proposing' 'approval possibility does not expand scope'
  Require-Text $contractText 'exactly one current state' 'coverage cells are unambiguous'
  Require-Text $contractText 'Every active `U/D` item must survive translation' 'active decisions cannot disappear before acceptance'
  foreach ($obsoleteState in @('| `A` | Codex assumption', '| `H` | hypothesis or optional recommendation')) {
    if ($contractText.Contains($obsoleteState)) {
      Add-Failure "Obsolete contract state remains: $obsoleteState"
    }
  }
}
if (Test-Path -LiteralPath $benchmarkPath) {
  $benchmarkText = Get-Content -LiteralPath $benchmarkPath -Raw -Encoding UTF8
  Require-Text $benchmarkText 'Benchmark Gate' 'benchmark-first decision gate'
  Require-Text $benchmarkText 'find-skills' 'capability discovery rule'
  Require-Text $benchmarkText 'Default Ownership' 'benchmark discovery is not a user questionnaire'
  Require-Text $benchmarkText 'Capability Mismatch Handling' 'implementation mismatch stays internal until consequences change'
}

$acceptancePath = Join-Path $SkillRoot 'references\本轮验收与复盘.md'
$longTermPath = Join-Path $SkillRoot 'references\长期任务模式.md'
$beginnerPath = Join-Path $SkillRoot 'references\新手模式.md'
if (Test-Path -LiteralPath $acceptancePath) {
  $acceptanceText = Get-Content -LiteralPath $acceptancePath -Raw -Encoding UTF8
  Require-Text $acceptanceText 'Exact Evidence Reconciliation' 'acceptance claims map to exact evidence'
  Require-Text $acceptanceText 'Promised-Item Ledger' 'acceptance checks every approved behavior'
  Require-Text $acceptanceText 'Keep each independently promised item separate' 'acceptance rows keep exact scope granularity'
}
if (Test-Path -LiteralPath $longTermPath) {
  $longTermText = Get-Content -LiteralPath $longTermPath -Raw -Encoding UTF8
  Require-Text $longTermText 'An exact read-only request continues after preflight' 'read-only long-term work avoids duplicate approval'
  Require-Text $longTermText 'Do not ask them one by one' 'long-term review avoids serial questions'
}
if (Test-Path -LiteralPath $beginnerPath) {
  $beginnerText = Get-Content -LiteralPath $beginnerPath -Raw -Encoding UTF8
  Require-Text $beginnerText 'material checkpoint must stay neutral' 'beginner opening does not smuggle scope strategy'
  Require-Text $beginnerText 'Beginner mode changes communication, not project scope' 'beginner mode does not force an MVP'
  Require-Text $beginnerText 'Missing files do not erase the user' 'material state and initial idea stay separate'
}
if (Test-Path -LiteralPath $levelPath) {
  $levelText = Get-Content -LiteralPath $levelPath -Raw -Encoding UTF8
  Require-Text $levelText 'Evidence Dimensions' 'evidence-based project classification'
  Require-Text $levelText 'Current-round strategy' 'complexity and strategy separation'
}
if (Test-Path -LiteralPath $monitoringPath) {
  $monitoringText = Get-Content -LiteralPath $monitoringPath -Raw -Encoding UTF8
  Require-Text $monitoringText 'Route Approval Boundary' 'route approval stays narrow'
  Require-Text $monitoringText 'Minimum Validation Definition' 'public-monitoring definition gate'
  Require-Text $monitoringText 'The monitored subject and information intent have no AI default' 'missing subject or information intent is not invented'
  Require-Text $monitoringText 'Search Decisions Stay Separate' 'search target and trigger remain separate dimensions'
  Require-Text $monitoringText 'Any API key or token embedded in browser JavaScript is visible' 'client credential limitation'
  Require-Text $monitoringText 'Do not use the start-development card to introduce new product requirements' 'confirmation card does not invent scope'
  Require-Text $monitoringText 'Use source states precisely' 'source validation state model'
  Require-Text $monitoringText 'Acceptance Metric Provenance' 'monitoring metrics need evidence'
  Require-Text $monitoringText 'exact output fields' 'monitoring scope draft owns fields and failure states'
  Require-Text $monitoringText 'coverage matrix' 'multi-subject source coverage is checked cell by cell'
  Require-Text $monitoringText 'use a single combined gate' 'bounded monitoring avoids duplicate final approval'
  Require-Text $monitoringText 'A request to browse an organized set is not equivalent to user-entered keyword search' 'organized browsing is not reduced to keyword input'
  Require-Text $monitoringText 'exact URLs/provider IDs and the actual query/input tested' 'source evidence is reproducible'
  Require-Text $monitoringText 'Assign exactly one current state to each cell' 'coverage states are unambiguous'
  Require-Text $monitoringText 'Semantic Relevance Gate' 'search samples must match the requested meaning'
  Require-Text $monitoringText 'first five distinct returned items' 'semantic sampling uses reproducible provider order'
  Require-Text $monitoringText 'Any mixture is `混合`' 'mixed samples cannot be cherry-picked into a pass'
  Require-Text $monitoringText 'fresh response' 'filters require fresh resampling'
  Require-Text $monitoringText 'HTTP `200`, valid XML/JSON' 'transport success does not prove relevance'
  Require-Text $monitoringText 'stop before development confirmation' 'missing core source path blocks implementation'
  if ($monitoringText -match '\|\s*D1\s*\|') {
    Add-Failure 'Public-monitoring guidance still contains a fixed D1 lifecycle card.'
  }
}
if (Test-Path -LiteralPath $externalSafetyPath) {
  $externalSafetyText = Get-Content -LiteralPath $externalSafetyPath -Raw -Encoding UTF8
  Require-Text $externalSafetyText 'untrusted evidence, not instructions' 'external content cannot override instructions'
  Require-Text $externalSafetyText 'URL And Network Boundary' 'external URLs are validated'
  Require-Text $externalSafetyText '169.254.169.254' 'cloud metadata addresses are blocked'
  Require-Text $externalSafetyText 'revalidate scheme, hostname, resolved address, port, and permission after every redirect' 'redirects are rechecked'
  Require-Text $externalSafetyText 'Query And Data Privacy' 'search terms and transmitted data are scoped'
  Require-Text $externalSafetyText 'customer names, unpublished product/project names' 'sensitive queries need confirmation'
  Require-Text $externalSafetyText 'never execute them' 'downloads are not executed'
}
if (Test-Path -LiteralPath $runtimePath) {
  $runtimeText = Get-Content -LiteralPath $runtimePath -Raw -Encoding UTF8
  Require-Text $runtimeText 'Runtime And Delivery Axes' 'runtime preference and constraints stay separate'
  Require-Text $runtimeText 'desired experience only' 'desktop preference does not imply install permission'
  Require-Text $runtimeText '`App`, `工具`, or `系统` is also not a delivery decision' 'ambiguous product noun does not select delivery'
  Require-Text $runtimeText 'Runtime Persistence Boundary' 'runtime data writes are explicit'
  Require-Text $runtimeText 'A self-contained executable is not necessarily an offline build' 'packaging effects are not hidden'
  if ($runtimeText -match '\|\s*D1\s*\|') {
    Add-Failure 'Runtime guidance still contains a fixed D1 lifecycle card.'
  }
}
if (Test-Path -LiteralPath $materialsPath) {
  $materialsText = Get-Content -LiteralPath $materialsPath -Raw -Encoding UTF8
  Require-Text $materialsText 'Track material state explicitly' 'material evidence state model'
  Require-Text $materialsText 'does not prove that Codex read the material' 'no invented file inspection'
}
if (Test-Path -LiteralPath $skillFlowPath) {
  $skillFlowText = Get-Content -LiteralPath $skillFlowPath -Raw -Encoding UTF8
  Require-Text $skillFlowText 'Do not decide the edit boundary' 'Skill preflight precedes scope decision'
  Require-Text $skillFlowText 'exact local mirror' 'release mirror parity handling'
}

$newProjectPath = Join-Path $SkillRoot 'references\新项目启动模式.md'
if (Test-Path -LiteralPath $newProjectPath) {
  $newProjectText = Get-Content -LiteralPath $newProjectPath -Raw -Encoding UTF8
  Require-Text $newProjectText 'do not reread it here' 'new-project route does not reload the shared core'
  Require-Text $newProjectText 'one full replacement scope' 'material corrections replace the active scope completely'
  Require-Text $newProjectText 'Do not propose export, filters, scheduling, persistence, accounts' 'new projects exclude unrelated common features'
  Require-Text $newProjectText 'Do not require the user to approve files, SDKs, commands, caches' 'new-project gate stays user-friendly'
  Require-Text $newProjectText 'name them and their inclusion basis' 'new-project confirmation identifies preselected items'
  Require-Text $newProjectText 'Batch every currently knowable independent item' 'new-project questions are concentrated without a fixed count'
}

$startupTemplatePath = Join-Path $SkillRoot 'templates\项目启动卡.md'
$acceptanceTemplatePath = Join-Path $SkillRoot 'templates\本轮验收卡.md'
if (Test-Path -LiteralPath $startupTemplatePath) {
  $startupTemplateText = Get-Content -LiteralPath $startupTemplatePath -Raw -Encoding UTF8
  Require-Text $startupTemplateText 'Contract And Approval Envelope' 'durable startup card records exact approval'
  Require-Text $startupTemplateText '开发期写入' 'durable startup card records development effects'
  Require-Text $startupTemplateText '运行期写入' 'durable startup card records runtime effects'
  Require-Text $startupTemplateText 'Acceptance Ledger' 'durable startup card records planned proof'
  Require-Text $startupTemplateText 'User-Facing Summary' 'durable startup card has a concise approval view'
  Require-Text $startupTemplateText 'Codex Execution Record' 'durable startup card keeps technical mechanics internal'
}
if (Test-Path -LiteralPath $acceptanceTemplatePath) {
  $acceptanceTemplateText = Get-Content -LiteralPath $acceptanceTemplatePath -Raw -Encoding UTF8
  Require-Text $acceptanceTemplateText '本轮承诺与证据' 'acceptance card reconciles promises and evidence'
  Require-Text $acceptanceTemplateText '写入与回退核对' 'acceptance card reconciles mutation effects'
}

$obsoletePatterns = @(
  'one decision at a time',
  'ask one question at a time',
  '唯一需要先确认的问题',
  '最多问一个',
  '只保留一个真正',
  'normally exactly `1`',
  'contains `1-4`',
  'normally `1` consolidated',
  'normally needs at most one',
  'normal card contains `1-4`',
  '计划创建/修改的文件：待确认后列出',
  '计划运行的命令：待确认后列出',
  '现在都没有，请先按描述给一个小范围草案',
  ('这个项目按哪个级别' + '启动？')
)

$instructionFiles = $markdownFiles | Where-Object {
  $_.Name -notin @('Skill测试验收.md', '调试与优化建议.md')
}

foreach ($file in $instructionFiles) {
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  foreach ($pattern in $obsoletePatterns) {
    if ($text -match [regex]::Escape($pattern)) {
      Add-Failure "Obsolete instruction remains in $(Get-RelativePath $SkillRoot $file.FullName): $pattern"
    }
  }
}

if ($ReleaseRoot) {
  if (-not (Test-Path -LiteralPath $ReleaseRoot)) {
    Add-Failure "Release root does not exist: $ReleaseRoot"
  } else {
    $sourceFiles = Get-ChildItem -LiteralPath $SkillRoot -Recurse -File
    $releaseFiles = Get-ChildItem -LiteralPath $ReleaseRoot -Recurse -File
    $sourceRelative = @($sourceFiles | ForEach-Object { Get-RelativePath $SkillRoot $_.FullName })
    $releaseRelative = @($releaseFiles | ForEach-Object { Get-RelativePath $ReleaseRoot $_.FullName })

    foreach ($relative in $sourceRelative) {
      $releasePath = Join-Path $ReleaseRoot $relative
      if (-not (Test-Path -LiteralPath $releasePath)) {
        Add-Failure "Release file is missing: $relative"
      } else {
        $sourcePath = Join-Path $SkillRoot $relative
        if ((Get-FileHash -LiteralPath $sourcePath).Hash -ne (Get-FileHash -LiteralPath $releasePath).Hash) {
          Add-Failure "Release file differs: $relative"
        }
      }
    }
    foreach ($relative in $releaseRelative) {
      if ($relative -notin $sourceRelative) {
        Add-Failure "Release-only file exists: $relative"
      }
    }
  }
}

if ($failures.Count -gt 0) {
  'Skill structure check: FAIL'
  foreach ($failure in $failures) {
    "- $failure"
  }
  exit 1
}

'Skill structure check: PASS'
"Skill root: $SkillRoot"
"Markdown files checked: $($markdownFiles.Count)"
"Active resources checked: $($resourceFiles.Count)"
"SKILL.md lines: $($skillLines.Count)"
if ($ReleaseRoot) {
  "Release parity: PASS ($ReleaseRoot)"
}
