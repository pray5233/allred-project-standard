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

$requiredLinks = @(
  'references/核心执行流程.md',
  'references/交互与确认规则.md',
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
  'references/公开信息监测项目.md'
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
$benchmarkPath = Join-Path $SkillRoot 'references\开发依据与能力复用.md'
$levelPath = Join-Path $SkillRoot 'references\项目级别问法.md'
$monitoringPath = Join-Path $SkillRoot 'references\公开信息监测项目.md'
$runtimePath = Join-Path $SkillRoot 'references\运行环境与交付形态.md'
$materialsPath = Join-Path $SkillRoot 'references\资料收集与分析.md'
$skillFlowPath = Join-Path $SkillRoot 'references\Skill流程优化模式.md'
$skillTestPath = Join-Path $SkillRoot 'references\Skill测试验收.md'
$behaviorCheckPath = Join-Path $SkillRoot 'scripts\check_behavior_suite.ps1'

foreach ($requiredPath in @($corePath, $sharedPath, $benchmarkPath, $levelPath, $monitoringPath, $runtimePath, $materialsPath, $skillFlowPath, $behaviorCheckPath)) {
  if (-not (Test-Path -LiteralPath $requiredPath)) {
    Add-Failure "Required architecture reference is missing: $requiredPath"
  }
}
if (Test-Path -LiteralPath $skillTestPath) {
  $skillTestText = Get-Content -LiteralPath $skillTestPath -Raw -Encoding UTF8
  Require-Text $skillTestText 'must not manufacture the behavior' 'test fixtures do not inject duplicate approval'
}

if (Test-Path -LiteralPath $sharedPath) {
  $sharedText = Get-Content -LiteralPath $sharedPath -Raw -Encoding UTF8
  Require-Text $sharedText 'Low interruption is not no communication' 'communication is preserved'
  Require-Text $sharedText 'Product Decision Gate' 'product decisions use one gate'
  Require-Text $sharedText 'Consequential Authorization Gate' 'consequential actions use a separate gate'
  Require-Text $sharedText '【开始开发前确认】' 'prominent start confirmation remains available'
  Require-Text $sharedText 'D1=' 'unambiguous multi-decision reply'
  Require-Text $sharedText 'Approval Scope And Traceability' 'current-scope provenance gate'
  Require-Text $sharedText 'one consolidated card' 'known decisions are compressed into useful rounds'
  Require-Text $sharedText 'Decision Ownership' 'user and Codex responsibilities stay separate'
  Require-Text $sharedText 'Quantitative acceptance targets also need provenance' 'numeric acceptance needs evidence'
  Require-Text $sharedText '范围草案 V1' 'related scope rules use one approved draft'
  Require-Text $sharedText 'same gate as scope approval' 'scope approval and unchanged start authorization can be combined'
}
if (Test-Path -LiteralPath $corePath) {
  $coreText = Get-Content -LiteralPath $corePath -Raw -Encoding UTF8
  Require-Text $coreText 'Fast' 'fast execution lane'
  Require-Text $coreText 'Standard' 'standard execution lane'
  Require-Text $coreText 'Deep' 'deep execution lane'
  Require-Text $coreText 'If three distinct root-cause hypotheses fail' 'debugging architecture stop'
  Require-Text $coreText 'Fresh evidence is mandatory' 'fresh verification before completion'
  Require-Text $coreText 'Do not use TDD or Red-Green as the execution order' 'no TDD/Red-Green execution order'
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
}
if (Test-Path -LiteralPath $runtimePath) {
  $runtimeText = Get-Content -LiteralPath $runtimePath -Raw -Encoding UTF8
  Require-Text $runtimeText 'Runtime And Delivery Axes' 'runtime preference and constraints stay separate'
  Require-Text $runtimeText 'desired experience only' 'desktop preference does not imply install permission'
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

$obsoletePatterns = @(
  'one decision at a time',
  'ask one question at a time',
  '唯一需要先确认的问题',
  '最多问一个',
  '只保留一个真正',
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
