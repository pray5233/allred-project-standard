param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$ReleaseRoot = '',
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ('allred-structure-' + [guid]::NewGuid().ToString('N')))
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$failures = [System.Collections.Generic.List[string]]::new()
$ps = (Get-Process -Id $PID).Path
$skillLines = @(Get-Content -LiteralPath (Join-Path $SkillRoot 'SKILL.md') -Encoding UTF8)
$skillText = $skillLines -join [Environment]::NewLine
if ($skillLines.Count -lt 4 -or $skillLines[0] -ne '---' -or $skillLines[3] -ne '---' -or
    $skillLines[1] -ne 'name: allred-project-standard' -or $skillLines[2] -notmatch '^description:\s+\S') {
  $failures.Add('Invalid Skill frontmatter.') | Out-Null
}
if ($skillLines.Count -gt 200) { $failures.Add('Entrypoint exceeds 200 lines.') | Out-Null }
$version = (Get-Content -LiteralPath (Join-Path $SkillRoot 'VERSION') -Raw -Encoding UTF8).Trim()
if ($version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') { $failures.Add('Invalid VERSION.') | Out-Null }
foreach ($match in [regex]::Matches($skillText, '(?:references|templates|scripts)[\\/][^\x60''"\s)]+\.(?:md|json|ps1)')) {
  if (-not (Test-Path -LiteralPath (Join-Path $SkillRoot $match.Value))) { $failures.Add("Missing reference: $($match.Value)") | Out-Null }
}
foreach ($script in Get-ChildItem -LiteralPath (Join-Path $SkillRoot 'scripts') -Filter '*.ps1' -File) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors) | Out-Null
  foreach ($error in @($errors)) { $failures.Add("Parse failure in $($script.Name): $($error.Message)") | Out-Null }
}
foreach ($name in @('check_invariants.ps1','check_runtime_generality.ps1','check_behavior_manifest.ps1','check_route_context_budget.ps1')) {
  & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $SkillRoot "scripts/$name") -SkillRoot $SkillRoot
  if ($LASTEXITCODE -ne 0) { $failures.Add("$name failed.") | Out-Null }
}
& $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $SkillRoot 'scripts/check_runtime_contracts.ps1') -SkillRoot $SkillRoot -OutputRoot $OutputRoot
if ($LASTEXITCODE -ne 0) { $failures.Add('Runtime contract regressions failed.') | Out-Null }
foreach ($name in @('validate_execution_record.ps1','validate_decision_coverage.ps1')) {
  & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $SkillRoot "scripts/$name") -Path (Join-Path $SkillRoot 'tests/execution-record.valid.md')
  if ($LASTEXITCODE -ne 0) { $failures.Add("$name rejected the preserved valid execution record.") | Out-Null }
}
if ($ReleaseRoot) {
  $ReleaseRoot = (Resolve-Path -LiteralPath $ReleaseRoot).Path
  foreach ($pair in @(@{from=$SkillRoot;to=$ReleaseRoot},@{from=$ReleaseRoot;to=$SkillRoot})) {
    foreach ($file in Get-ChildItem -LiteralPath $pair.from -Recurse -File) {
      $relative = $file.FullName.Substring($pair.from.TrimEnd('\','/').Length + 1)
      $other = Join-Path $pair.to $relative
      if (-not (Test-Path -LiteralPath $other) -or (Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $other).Hash) {
        $failures.Add("Release mismatch: $relative") | Out-Null
      }
    }
  }
}
if ($failures.Count -gt 0) {
  'Skill structure check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}
'Skill structure check: PASS'
"SKILL.md lines: $($skillLines.Count)"
"Runtime contract evidence: $OutputRoot"
