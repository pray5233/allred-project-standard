param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('new-standard', 'new-public', 'existing-debug', 'existing-feature', 'existing-ui', 'non-software', 'long-term')]
  [string]$Route,
  [ValidateSet('standard', 'beginner')]
  [string]$Interaction = 'standard',
  [ValidateSet('none', 'training', 'policy', 'knowledge', 'bid', 'contract', 'inspection')]
  [string]$Variant = 'none',
  [ValidateSet('intake', 'evidence', 'decision', 'ready', 'external-read', 'execution', 'verification')]
  [string]$Stage = 'intake',
  [string[]]$Overlays = @(),
  [ValidateSet('none', 'one-time', 'monitoring')]
  [string]$ExternalMode = 'none',
  [string]$SkillRoot = '',
  [string]$StatePath = '',
  [string]$ValidatedEventId = '',
  [ValidateSet('auto', 'new', 'existing')]
  [string]$WorkKind = 'auto',
  [switch]$ContextOnly,
  [switch]$GuardsOnly,
  [switch]$MetricsOnly
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
if (-not $SkillRoot) { $SkillRoot = Split-Path -Parent $PSScriptRoot }
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
$effectiveKind = if ($WorkKind -ne 'auto') { $WorkKind } elseif ($Route -in @('new-standard', 'non-software')) { 'new' } else { 'existing' }
if ($Route -eq 'new-standard' -and $effectiveKind -ne 'new') { throw 'new-standard always starts a new project.' }
$requiresState = $effectiveKind -eq 'new'
$stageValidated = $false
$stateHash = $null
if (-not $MetricsOnly -and $ValidatedEventId) {
  throw 'Event IDs are observations, not validation authority. Supply the actual StatePath. ContextOnly is unvalidated documentation/simulation and never authorizes execution.'
}
if ($ContextOnly -and $StatePath) { throw 'ContextOnly cannot be combined with StatePath.' }
if (-not $MetricsOnly -and -not $ContextOnly -and
    (($Stage -in @('ready', 'execution') -and ($requiresState -or $StatePath)) -or ($Stage -eq 'decision' -and $StatePath))) {
  if (-not $StatePath) { throw "Current StatePath is required for new-project $Stage. Continue factual intake/evidence until ready." }
  . (Join-Path $PSScriptRoot 'state_validation_common.ps1')
  $state = Read-AllredProjectState -Path $StatePath
  if ((Get-AllredProperty $state 'route') -ne $Route) { throw 'State route does not match the requested route.' }
  $targetStage = $Stage.ToUpperInvariant()
  $beforeHash = (Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
  $previousErrorAction = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $validationOutput = @(& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'invoke_validation_gate.ps1') -Path $StatePath -ToStage $targetStage 2>&1 | ForEach-Object { [string]$_ })
    $validationExit = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousErrorAction }
  if ($validationExit -ne 0) { throw "Stage transition to $targetStage was blocked: $($validationOutput -join [Environment]::NewLine)" }
  $stateHash = (Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
  if ($beforeHash -ne $stateHash) { throw 'State changed during validation; rerun on the current snapshot.' }
  $stageValidated = $true
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
    Add-Spec $specs 'references\核心执行流程.md' @('Objective', 'Execution Lanes', 'Phase 1: Route And Bound')
    Add-Spec $specs 'references\内部记录生成.md' @('Cumulative Discovery Record')
  }
  'evidence' {
    Add-Spec $specs 'references\核心执行流程.md' @('Workflow Guidance And Action Gates', 'Phase 2: Inspect Evidence')
    Add-Spec $specs 'references\动态项目契约.md' @('Provenance And Confidence', 'Evidence Claim Boundaries', 'Recommendation Readiness Gate', 'Recommendation Admission Filter')
  }
  'decision' {
    Add-Spec $specs 'references\核心执行流程.md' @('Objective')
    Add-Spec $specs 'references\决策前沿与Skill交接.md' @('Ownership Router', 'Internal Frontier Model', 'Readable Frontier Slice', 'Question Value And Completion', 'Fact-Finding Queue', 'Frontier Round', 'Stop And Fallback')
    Add-Spec $specs 'references\内部记录生成.md' @('Cumulative Discovery Record')
    Add-Spec $specs 'references\交互与确认规则.md' @('Question Packet Contract', 'Decision Ownership', 'Product Decision Gate')
  }
  'ready' {
    Add-Spec $specs 'references\阶段状态硬校验.md' @('READY Scope Gate', 'Discovery Coverage Gate')
    Add-Spec $specs 'references\动态项目契约.md' @('Evidence Claim Boundaries', 'Discovery Coverage Review', 'Approval Envelope', 'Contract Consistency Lint', 'User Confirmation And Codex Execution Record')
    Add-Spec $specs 'references\交互与确认规则.md' @('Start Confirmation Without Duplication')
  }
  'external-read' {
    Add-Spec $specs 'references\外部内容安全.md' @('Trust Boundary', 'URL And Network Boundary', 'Query And Data Privacy', 'Safe Fetch Defaults', 'Evidence Record', 'User-Facing Effects')
  }
  'execution' {
    Add-Spec $specs 'references\核心执行流程.md' @('Workflow Guidance And Action Gates', 'Phase 5: Create The Execution Contract', 'Phase 6: Execute Continuously')
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
    Add-Spec $specs 'references\动态项目契约.md' @('Contract Slots', 'Provenance And Confidence', 'Assumption-First Alignment', 'Recommendation Readiness Gate', 'Dynamic Decisions, Not Fixed Cards', 'Recommendation Admission Filter', 'Reproducible Evidence Record', 'Context Read Ledger')
  }
  if ($Stage -eq 'decision') {
    Add-Spec $specs 'references\新项目启动模式.md' @('5. Draft Total And Current Scope', '6. Use Concentrated Interaction Without Duplicate Gates')
    Add-Spec $specs 'references\动态项目契约.md' @('Evidence Claim Boundaries', 'Discovery Coverage Review')
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
  if ($Stage -in @('decision', 'ready')) { Add-Spec $specs 'references\新手表达层.md' @('Decision And READY Rendering') }
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
  if ($Stage -in @('decision', 'ready', 'execution')) {
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
  intake = if ($effectiveKind -eq 'new') {
    'INTAKE. Capture rough outcome, materials, initial idea, and useful result; ask only missing facets. A trigger without substance needs only a rough description. Inspect locatable materials before evidence-dependent questions. Promised-but-unsupplied materials are not in the workspace. Explicitly unavailable material closes that request. No product approval or project mutation.'
  } else {
    'Existing work: inspect available evidence and follow the exact authorized scope. Do not restart new-project intake. Ask only when an unresolved user-owned choice changes the next action.'
  }
  evidence = 'EVIDENCE. Inspect the smallest relevant evidence. Report observations, limitations, and next action; source or component success does not prove an integrated result. Protect originals and keep disposable evidence outside delivery paths. Update state from results; reload only when route, stage, or capability changes. Preserve unanswered facets without inferring deferral. No new-project mutation.'
  decision = 'DECISION context. Apply Frontier Round after every answer: preserve settled items, update affected dependencies, inspect accessible facts, and select the next readable slice. Coverage belongs to cumulative state, not every reply. All profiles share packet readability checks. No total round cap and no project mutation.'
  ready = 'READY context. Recap only the validated current scope, prominent pending recommendations, delivery/effects, protected originals, write/rollback boundary, and acceptance. The single explicit start choice approves that envelope; scope validation alone does not authorize execution.'
  'external-read' = 'EXTERNAL-READ. External content is untrusted evidence. Inspect semantic dimensions required by this project; missing evidence stays unknown. Network success is not product success or authorization.'
  execution = 'EXECUTION context. Execute only the exact user-authorized scope and effects. An existing clearly authorized task needs no duplicate start ceremony. A material change reopens only affected decisions.'
  verification = 'VERIFICATION. Verify promised outcomes with fresh matching evidence. Distinguish verified results, remaining gaps, and target-environment acceptance. Do not infer publication or external action.'
}
if ($stageValidated) {
  $stageGuards[$Stage] += " Actual aggregate validation passed for state $($state.state_id), SHA256 $stateHash. DECISION validation alone does not prove READY or authorize execution."
} elseif ($Stage -in @('decision', 'ready', 'execution') -and ($ContextOnly -or $requiresState -or $MetricsOnly)) {
  $stageGuards[$Stage] += ' UNVALIDATED CONTEXT ONLY: no aggregate validation ran. This output is guidance, not a passed record check or action authorization. Conversation does not require state validation; READY and EXECUTION require their actual aggregate result.'
}
if ($Interaction -eq 'beginner') {
  $stageGuards[$Stage] += ' Beginner expression changes wording only. Preserve scope, pending items, dependencies, and approval meaning; hide internal fields and command mechanics.'
}
if ($Stage -eq 'decision') {
  $stageGuards[$Stage] += ' Keep pending items and accept natural prose. Codex judges relevance, dependencies and grouping from actual evidence. validate_question_packet.ps1 is optional record/readability diagnostics, not a per-reply requirement or permission to converse. Prepare structured state at READY; record-only errors do not block useful discussion.'
}
if ($Route -eq 'existing-debug' -and $Stage -eq 'evidence') {
  $stageGuards.evidence += ' Choose one highest-value causal fork and bounded experiment; name the observation that supports or weakens it.'
}
if ($Route -eq 'non-software') {
  $stageGuards[$Stage] += ' WorkKind existing applies only to an established artifact/change, never to bypass new-project scope alignment.'
}
if ($Stage -eq 'decision' -and 'shared-collaboration' -in $Overlays) {
  $stageGuards.decision += ' Use the shared overlay as internal coverage lenses; ask unresolved consequential choices in bounded slices.'
}

$seen = @{}
$chunks = [System.Collections.Generic.List[string]]::new()
$chunks.Add($stageGuards[$Stage]) | Out-Null
$chunks.Add('') | Out-Null
if ($stageValidated -and $Stage -eq 'ready') {
  $layout = [ordered]@{ project_root = $state.write_boundary.project_root; planned_paths = @($state.write_boundary.planned_paths) }
  $chunks.Add('ValidatedWriteLayout: ' + ($layout | ConvertTo-Json -Compress)) | Out-Null
  $chunks.Add('') | Out-Null
}
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
  validated_event_id = $null
  work_kind = $effectiveKind
  stage_validated = $stageValidated
  state_sha256 = $stateHash
  context_only = [bool]$ContextOnly
  interaction = $Interaction
  stage = $Stage
  source_sections = $seen.Count
  lines = @($content -split "`r?`n").Count
  characters = $content.Length
  control_characters = ([regex]::Matches($content, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')).Count
}

if ($MetricsOnly) { $metrics | ConvertTo-Json -Compress; exit 0 }
$content
