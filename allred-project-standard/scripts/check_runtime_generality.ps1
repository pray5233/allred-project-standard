param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$failures = [System.Collections.Generic.List[string]]::new()
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path

function Get-RelativePathValue {
  param([string]$Root, [string]$Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

$excluded = @(
  'references/首次触发示例.md',
  'scripts/check_behavior_manifest.ps1',
  'scripts/check_runtime_generality.ps1',
  'scripts/run_behavior_eval.ps1',
  'scripts/run_entry_guard_eval.ps1'
)

# These are regression-fixture subjects, not forbidden user domains. They may
# appear in examples and tests, but never in active runtime policy owners.
$fixtureTerms = @(
  '关节臂测量机',
  '激光甲烷遥测仪',
  '合同盖章',
  'PDF实时翻译',
  'PDF 实时翻译',
  '厂家池',
  'FARO',
  '海克斯康'
)

$deprecatedFixedPhrases = @(
  'subject, information category, language, and region',
  'render `课程暂缓/排除` and `当前执行边界` as sibling sections',
  'say `无` when no curriculum deferral is confirmed'
)

$files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($relative in @('SKILL.md', 'agents\openai.yaml')) {
  $path = Join-Path $SkillRoot $relative
  if (Test-Path -LiteralPath $path) { $files.Add((Get-Item -LiteralPath $path)) | Out-Null }
}
foreach ($folder in @('references', 'scripts')) {
  $path = Join-Path $SkillRoot $folder
  if (Test-Path -LiteralPath $path) {
    foreach ($file in Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object Extension -in @('.md', '.ps1', '.yaml', '.yml')) {
      $files.Add($file) | Out-Null
    }
  }
}

foreach ($file in $files) {
  $relative = Get-RelativePathValue -Root $SkillRoot -Path $file.FullName
  if ($relative -in $excluded) { continue }
  $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  foreach ($term in $fixtureTerms) {
    if ($text.Contains($term)) { $failures.Add("Scenario fixture term leaked into runtime policy: $relative -> $term") | Out-Null }
  }
  foreach ($phrase in $deprecatedFixedPhrases) {
    if ($text.Contains($phrase)) { $failures.Add("Deprecated fixed runtime contract remains: $relative -> $phrase") | Out-Null }
  }
}

$requiredContracts = @(
  @{ file = 'SKILL.md'; text = 'Keep runtime policy domain-neutral.' },
  @{ file = 'references\external-source.md'; text = 'required semantic dimensions from the active project contract' },
  @{ file = 'references\非软件项目模式.md'; text = 'No empty heading' },
  @{ file = 'scripts\get_route_context.ps1'; text = 'derive the required semantic dimensions from the active project contract' }
)
foreach ($contract in $requiredContracts) {
  $path = Join-Path $SkillRoot $contract.file
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("Generality owner missing: $($contract.file)") | Out-Null
    continue
  }
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if (-not $text.Contains($contract.text)) {
    $failures.Add("Generality contract missing: $($contract.file) -> $($contract.text)") | Out-Null
  }
}

if ($failures.Count -gt 0) {
  'Runtime generality check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Runtime generality check: PASS'
"Runtime policy files checked: $(@($files | Where-Object { (Get-RelativePathValue -Root $SkillRoot -Path $_.FullName) -notin $excluded }).Count)"
"Example/test-only files excluded: $($excluded.Count)"
