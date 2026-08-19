param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
  $script:failures.Add($message) | Out-Null
}

function Test-RequiredText([string]$text, [string]$pattern, [string]$label) {
  if ($text -notmatch [regex]::Escape($pattern)) {
    Add-Failure "Missing required text: $label"
  }
}

$skillPath = Join-Path $SkillRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillPath)) {
  throw "SKILL.md not found: $skillPath"
}

$skillText = Get-Content -LiteralPath $skillPath -Raw
$lines = Get-Content -LiteralPath $skillPath

if ($lines.Count -lt 4 -or $lines[0] -ne '---' -or $lines[3] -ne '---') {
  Add-Failure 'Frontmatter delimiters are invalid or missing.'
}

if ($lines[1] -notmatch '^name:\s*allred-project-standard\s*$') {
  Add-Failure 'Frontmatter name is missing or unexpected.'
}

if ($lines[2] -notmatch '^description:\s+\S') {
  Add-Failure 'Frontmatter description is missing.'
}

$linked = [regex]::Matches($skillText, '`((?:references|templates|scripts)/[^`]+)`') |
  ForEach-Object { $_.Groups[1].Value } |
  Sort-Object -Unique

foreach ($relative in $linked) {
  $path = Join-Path $SkillRoot ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
  if (-not (Test-Path -LiteralPath $path)) {
    Add-Failure "Linked file is missing: $relative"
  }
}

$requiredTexts = @(
  @('allred新项目', 'new project trigger'),
  @('allred新手项目', 'beginner trigger'),
  @('继续项目', 'ongoing project trigger'),
  @('长期任务优化', 'long-term optimization trigger'),
  @('references/新项目启动模式.md', 'new project reference'),
  @('references/Skill流程优化模式.md', 'skill optimization reference'),
  @('references/长期任务模式.md', 'long-term reference'),
  @('references/Skill测试验收.md', 'skill acceptance reference'),
  @('Do not start implementation or task execution until the user confirms', 'confirmation stop rule')
)

foreach ($item in $requiredTexts) {
  Test-RequiredText $skillText $item[0] $item[1]
}

$referencePath = Join-Path $SkillRoot 'references'
$templatePath = Join-Path $SkillRoot 'templates'

if (-not (Test-Path -LiteralPath $referencePath)) {
  Add-Failure 'references directory is missing.'
}

if (-not (Test-Path -LiteralPath $templatePath)) {
  Add-Failure 'templates directory is missing.'
}

$obsoleteSpecificExample = -join ([char[]](0x5173, 0x8282, 0x81C2))
if ($skillText -match [regex]::Escape($obsoleteSpecificExample)) {
  Add-Failure 'Obsolete specific project example remains in SKILL.md.'
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
"Linked files checked: $($linked.Count)"
"SKILL.md lines: $($lines.Count)"
