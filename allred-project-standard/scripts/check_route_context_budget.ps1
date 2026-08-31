param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$selector = Join-Path $PSScriptRoot 'get_route_context.ps1'
$limits = @(
  @{ route = 'new-standard'; overlays = @('external-source'); externalMode = 'one-time'; interaction = 'beginner'; stage = 'evidence'; maxLines = 475; maxCharacters = 32000 },
  @{ route = 'new-standard'; overlays = @('external-source'); externalMode = 'monitoring'; interaction = 'beginner'; stage = 'decision'; maxLines = 550; maxCharacters = 45000 },
  @{ route = 'new-standard'; overlays = @('shared-collaboration'); stage = 'decision'; maxLines = 470; maxCharacters = 40000 },
  @{ route = 'new-standard'; overlays = @('company-office-delivery'); interaction = 'beginner'; stage = 'evidence'; maxLines = 420; maxCharacters = 28800 },
  @{ route = 'new-standard'; interaction = 'standard'; stage = 'intake'; maxLines = 230; maxCharacters = 13500 },
  @{ route = 'existing-debug'; stage = 'intake'; maxLines = 260; maxCharacters = 18000 },
  @{ route = 'non-software'; variant = 'contract'; stage = 'intake'; maxLines = 360; maxCharacters = 26000 },
  @{ route = 'non-software'; variant = 'training'; stage = 'intake'; maxLines = 300; maxCharacters = 20000 },
  @{ route = 'non-software'; variant = 'training'; stage = 'decision'; maxLines = 360; maxCharacters = 32000 },
  @{ route = 'non-software'; variant = 'training'; stage = 'verification'; maxLines = 220; maxCharacters = 16000 }
)

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($limit in $limits) {
  $variant = if ($limit.ContainsKey('variant')) { $limit.variant } else { 'none' }
  $interaction = if ($limit.ContainsKey('interaction')) { $limit.interaction } else { 'standard' }
  $overlays = if ($limit.ContainsKey('overlays')) { @($limit.overlays) } else { @() }
  $externalMode = if ($limit.ContainsKey('externalMode')) { $limit.externalMode } else { 'none' }
  $json = & $selector -SkillRoot $SkillRoot -Route $limit.route -Interaction $interaction -Variant $variant -Stage $limit.stage -Overlays $overlays -ExternalMode $externalMode -MetricsOnly
  if (-not $?) { $failures.Add("Selector failed for $($limit.route)/$($limit.stage)") | Out-Null; continue }
  $metric = $json | ConvertFrom-Json
  if ($metric.lines -gt $limit.maxLines) { $failures.Add("Line budget exceeded for $($limit.route)/$($limit.stage): $($metric.lines)/$($limit.maxLines)") | Out-Null }
  if ($metric.characters -gt $limit.maxCharacters) { $failures.Add("Character budget exceeded for $($limit.route)/$($limit.stage): $($metric.characters)/$($limit.maxCharacters)") | Out-Null }
  if ($metric.control_characters -gt 0) { $failures.Add("Control characters found for $($limit.route)/$($limit.stage): $($metric.control_characters)") | Out-Null }
  $overlayLabel = if ($overlays.Count -gt 0) { '+' + ($overlays -join '+') } else { '' }
  $label = if ($variant -eq 'none') { "$($metric.route)$overlayLabel/$($metric.interaction)/$($metric.stage)" } else { "$($metric.route)$overlayLabel/$($metric.interaction)/$variant/$($metric.stage)" }
  "${label}: $($metric.lines) lines, $($metric.characters) characters, $($metric.source_sections) sections"
}

if ($failures.Count -gt 0) {
  'Route context budget check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

'Route context budget check: PASS'
