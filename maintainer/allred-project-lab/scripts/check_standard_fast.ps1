param(
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard')
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$StandardRoot = (Resolve-Path -LiteralPath $StandardRoot).Path
$skillPath = Join-Path $StandardRoot 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillPath)) { throw "SKILL.md not found: $skillPath" }
$lines = @(Get-Content -LiteralPath $skillPath -Encoding UTF8)
$text = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8

if ($lines.Count -lt 4 -or $lines[0] -ne '---' -or $lines[1] -notmatch '^name:\s*allred-project-standard\s*$' -or $lines[2] -notmatch '^description:\s+\S' -or $lines[3] -ne '---') {
  $failures.Add('Invalid Skill frontmatter.') | Out-Null
}
if ($lines.Count -gt 260) { $failures.Add("SKILL.md exceeds entrypoint budget: $($lines.Count) lines.") | Out-Null }
foreach ($heading in @('## Runtime Hard Stops', '## Activation And Routing', '## Required Reading', '## Shared Invariants', '## Conversation Topology')) {
  if (-not $text.Contains($heading)) { $failures.Add("Missing entrypoint section: $heading") | Out-Null }
}

foreach ($match in [regex]::Matches($text, '(?:references|templates)[\/][^`''"\s)]+\.(?:md|json)')) {
  $relative = $match.Value.Replace('/', '\')
  if (-not (Test-Path -LiteralPath (Join-Path $StandardRoot $relative))) { $failures.Add("Linked resource missing: $relative") | Out-Null }
}

$versionPath = Join-Path $StandardRoot 'VERSION'
if (-not (Test-Path -LiteralPath $versionPath)) { $failures.Add('VERSION is missing.') | Out-Null }
elseif ((Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim() -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') { $failures.Add('VERSION is invalid.') | Out-Null }

$yamlPath = Join-Path $StandardRoot 'agents\openai.yaml'
if (-not (Test-Path -LiteralPath $yamlPath)) { $failures.Add('agents/openai.yaml is missing.') | Out-Null }
else {
  $yaml = Get-Content -LiteralPath $yamlPath -Raw -Encoding UTF8
  if (-not $yaml.Contains('allow_implicit_invocation: true')) { $failures.Add('Standard Skill implicit-invocation policy changed.') | Out-Null }
}

foreach ($script in Get-ChildItem -LiteralPath (Join-Path $StandardRoot 'scripts') -Filter '*.ps1' -File) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  foreach ($error in @($errors)) { $failures.Add("PowerShell parse failure in $($script.Name): $($error.Message)") | Out-Null }
}

if ($failures.Count -gt 0) {
  'Standard fast check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}
'Standard fast check: PASS'
"SKILL.md lines: $($lines.Count)"
