param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$selector = Join-Path $PSScriptRoot 'get_route_context.ps1'
$limits = @(
  @{ route = 'new-beginner-public'; stage = 'intake'; maxLines = 650; maxCharacters = 42000 },
  @{ route = 'new-beginner-public'; stage = 'decision'; maxLines = 650; maxCharacters = 45000 },
  @{ route = 'new-beginner-public'; stage = 'external-read'; maxLines = 420; maxCharacters = 30000 },
  @{ route = 'existing-debug'; stage = 'intake'; maxLines = 260; maxCharacters = 18000 },
  @{ route = 'non-software'; variant = 'contract'; stage = 'intake'; maxLines = 360; maxCharacters = 26000 },
  @{ route = 'non-software'; variant = 'training'; stage = 'intake'; maxLines = 300; maxCharacters = 20000 },
  @{ route = 'non-software'; variant = 'training'; stage = 'verification'; maxLines = 220; maxCharacters = 16000 }
)

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($limit in $limits) {
  $variant = if ($limit.ContainsKey('variant')) { $limit.variant } else { 'none' }
  $json = & $selector -SkillRoot $SkillRoot -Route $limit.route -Variant $variant -Stage $limit.stage -MetricsOnly
  if (-not $?) { $failures.Add("Selector failed for $($limit.route)/$($limit.stage)") | Out-Null; continue }
  $metric = $json | ConvertFrom-Json
  if ($metric.lines -gt $limit.maxLines) { $failures.Add("Line budget exceeded for $($limit.route)/$($limit.stage): $($metric.lines)/$($limit.maxLines)") | Out-Null }
  if ($metric.characters -gt $limit.maxCharacters) { $failures.Add("Character budget exceeded for $($limit.route)/$($limit.stage): $($metric.characters)/$($limit.maxCharacters)") | Out-Null }
  $label = if ($variant -eq 'none') { "$($metric.route)/$($metric.stage)" } else { "$($metric.route)/$variant/$($metric.stage)" }
  "${label}: $($metric.lines) lines, $($metric.characters) characters, $($metric.source_sections) sections"
}

if ($failures.Count -gt 0) {
  'Route context budget check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Route context budget check: PASS'
