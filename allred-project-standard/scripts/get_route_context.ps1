param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('new-standard', 'new-beginner', 'new-public', 'new-beginner-public', 'existing-debug', 'existing-feature', 'existing-ui', 'non-software', 'long-term', 'skill-improvement')]
  [string]$Route,
  [ValidateSet('none', 'training', 'policy', 'knowledge', 'bid', 'contract', 'inspection')]
  [string]$Variant = 'none',
  [ValidateSet('intake', 'evidence', 'decision', 'external-read', 'execution', 'verification')]
  [string]$Stage = 'intake',
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [switch]$MetricsOnly
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path

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
  }
  'verification' {
    Add-Spec $specs 'references\核心执行流程.md' @('Phase 7: Verify Before Claiming', 'Phase 8: Close Or Hand Off', 'Efficiency Acceptance')
  }
}

if ($Route -in @('new-standard', 'new-beginner', 'new-public', 'new-beginner-public')) {
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
    Add-Spec $specs 'references\动态项目契约.md' @('Approval Envelope', 'Contract Consistency Lint', 'Mutation Ledger', 'Acceptance Ledger', 'User Confirmation And Codex Execution Record')
  }
  if ($Stage -eq 'execution') { Add-Spec $specs 'references\新项目启动模式.md' @('7. Execute And Verify') }
}

if ($Route -in @('new-beginner', 'new-beginner-public')) {
  if ($Stage -eq 'intake') { Add-Spec $specs 'references\新手模式.md' @('Trigger Guard And Exit', 'Beginner Defaults', 'Opening', 'Direction Before Background Work') }
  if ($Stage -eq 'decision') { Add-Spec $specs 'references\新手模式.md' @('Beginner Project Classification', 'Environment And Delivery', 'Escalation') }
  if ($Stage -eq 'verification') { Add-Spec $specs 'references\新手模式.md' @('Ongoing Stages', 'Validation') }
}

if ($Route -in @('new-public', 'new-beginner-public')) {
  if ($Stage -eq 'intake') { Add-Spec $specs 'references\公开信息监测项目.md' @('Route Approval Boundary') }
  if ($Stage -eq 'evidence') { Add-Spec $specs 'references\公开信息监测项目.md' @('Minimum Validation Definition', 'Search Decisions Stay Separate', 'First-Round Evidence Strategy', 'Source And Benchmark Selection') }
  if ($Stage -eq 'external-read') { Add-Spec $specs 'references\公开信息监测项目.md' @('Source And Benchmark Selection', 'Semantic Relevance Gate', 'Credentials And Client Architecture') }
  if ($Stage -eq 'decision') { Add-Spec $specs 'references\公开信息监测项目.md' @('Acceptance Metric Provenance', 'Summary Provenance', 'Classification', 'Acceptance', 'Monitoring Scope Draft') }
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
  if ($Stage -in @('decision', 'execution')) { Add-Spec $specs 'references\非软件项目模式.md' @('Controlled Execution') }
  if ($Stage -eq 'verification') { Add-Spec $specs 'references\非软件项目模式.md' @('Review And Acceptance') }
}

switch ($Route) {
  'existing-debug' { if ($Stage -in @('intake', 'execution', 'verification')) { Add-Spec $specs 'references\功能调试.md' @('Debug Contract', 'Evidence First', 'Hypothesis Discipline', 'User Gates', 'Completion') } }
  'existing-feature' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\新增功能.md' @('Classify First', 'Feature Contract', 'User Gate', 'Execution And Verification') } }
  'existing-ui' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\界面优化.md' @('Inspect Before Designing', 'User Gate', 'Execute And Verify') } }
  'long-term' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\长期任务模式.md' @('State Model', 'Review Depth', 'Current-Round Contract', 'Execute And Update State', 'Round Closure') } }
  'skill-improvement' { if ($Stage -in @('intake', 'decision', 'execution', 'verification')) { Add-Spec $specs 'references\Skill流程优化模式.md' @('Evidence', 'Preflight', 'Change Classification', 'Architecture Gate', 'Execution Authorization', 'Validation', 'Completion') } }
}

$newProjectRoutes = @('new-standard', 'new-beginner', 'new-public', 'new-beginner-public')
$stageGuards = @{
  intake = if ($Route -in $newProjectRoutes) {
    "## Active Stage Guard`n`nCurrent internal stage: INTAKE. Maintain the four-item recommendation-readiness ledger across turns: intended use/user, material state/inspection, user idea or explicit request for a Codex draft, and recognizable useful result. After a partial reply, carry every still-missing item into one factual/open Q packet; a request for a Codex recommendation fills only the idea/delegation item. Do not present product D alternatives, a complete product package, READY/start gate, or mutate."
  } elseif ($Route -eq 'existing-debug') {
    "## Active Route Guard`n`nCurrent route: EXISTING DEBUG. Inspect and reproduce from evidence already available in the project before asking the user. Do not request files, logs, or results that the user says are already local. Ask only for evidence that cannot be obtained locally and changes the next diagnostic step. An exact safe local fix request already authorizes diagnosis, the smallest evidence-backed fix, and narrow verification."
  } else {
    "## Active Route Guard`n`nCurrent route is existing or continuing work. Inspect the current project evidence before asking factual questions. Do not restart new-project discovery or add a ceremonial start gate when the exact safe local work is already authorized."
  }
  evidence = "## Active Stage Guard`n`nCurrent internal stage: EVIDENCE. Perform read-only inspection and report facts/feasibility only. Evidence cannot choose product behavior. Do not present a READY/start gate or mutate."
  decision = "## Active Stage Guard`n`nCurrent internal stage: DECISION. Ask only concentrated user-owned material choices. One ID owns one axis. Do not mutate. A request for a final card does not establish READY: complete read-only technical preflight and the internal execution record first, and never show start options in the same response that initiates or awaits that preflight."
  'external-read' = "## Active Stage Guard`n`nCurrent internal stage: EXTERNAL-READ. Apply trust, privacy, and network boundaries. This stage does not approve product behavior or mutation."
  execution = "## Active Stage Guard`n`nCurrent internal stage: EXECUTION. Proceed only inside an explicitly approved READY scope and effects envelope; return to DECISION for material scope change."
  verification = "## Active Stage Guard`n`nCurrent internal stage: VERIFICATION. Verify promises with fresh evidence and do not expand scope or infer release actions."
}

$seen = @{}
$chunks = [System.Collections.Generic.List[string]]::new()
$chunks.Add($stageGuards[$Stage]) | Out-Null
$chunks.Add('') | Out-Null
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

$content = $chunks -join [Environment]::NewLine
$metrics = [pscustomobject]@{
  route = $Route
  stage = $Stage
  source_sections = $seen.Count
  lines = @($content -split "`r?`n").Count
  characters = $content.Length
}

if ($MetricsOnly) { $metrics | ConvertTo-Json -Compress; exit 0 }
$content
