param(
  [Parameter(Mandatory = $true)][string]$SummaryPath,
  [string]$MarkdownPath = '',
  [string]$HtmlPath = ''
)

$ErrorActionPreference = 'Stop'
$summary = Get-Content -LiteralPath $SummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$root = Split-Path -Parent $SummaryPath
if ([string]::IsNullOrWhiteSpace($MarkdownPath)) { $MarkdownPath = Join-Path $root 'report.md' }
if ([string]::IsNullOrWhiteSpace($HtmlPath)) { $HtmlPath = Join-Path $root 'report.html' }

function Encode-Html([string]$Text) { return [System.Net.WebUtility]::HtmlEncode($Text) }
function Get-ReportRelativeLink([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri([System.IO.Path]::GetFullPath($Path))
  return $rootUri.MakeRelativeUri($pathUri).ToString()
}
function Join-Display([object[]]$Items) {
  if (@($Items).Count -eq 0) { return '-' }
  return (@($Items) -join ', ')
}
$behaviorProperties = if ($summary.behavior_evidence) { @($summary.behavior_evidence.PSObject.Properties | Where-Object { $null -ne $_.Value }) } else { @() }

$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add('# Allred Candidate Validation Report')
$markdown.Add('')
$markdown.Add("- Result: **$($summary.result)**")
$markdown.Add("- Mode: $($summary.mode)")
$markdown.Add("- Baseline: $($summary.baseline_ref)")
$markdown.Add("- Started: $($summary.started_at_utc)")
$markdown.Add("- Finished: $($summary.finished_at_utc)")
$markdown.Add('')
$markdown.Add('## Selected Coverage')
$markdown.Add('')
$markdown.Add("- Standard cases: $(Join-Display @($summary.selection.standard_case_ids))")
$markdown.Add("- Lab cases: $(Join-Display @($summary.selection.lab_case_ids))")
$markdown.Add("- Replay cases: $(Join-Display @($summary.selection.replay_case_ids))")
$markdown.Add('')
$markdown.Add('## Steps')
$markdown.Add('')
$markdown.Add('| Step | Status | Exit | Duration | Log |')
$markdown.Add('| --- | --- | ---: | ---: | --- |')
foreach ($step in @($summary.steps)) {
  $duration = if ($null -ne $step.duration_ms) { "$($step.duration_ms) ms" } else { '-' }
  $log = if ($step.log) { "[$([System.IO.Path]::GetFileName($step.log))]($(Get-ReportRelativeLink $step.log))" } else { '-' }
  $markdown.Add("| $($step.name) | $($step.status) | $($step.exit_code) | $duration | $log |")
}
if ($behaviorProperties.Count -gt 0) {
  $markdown.Add('')
  $markdown.Add('## Behavior Consistency')
  $markdown.Add('')
  $markdown.Add('| Run | Cases | Stable pass | Stable fail | Variable | Infrastructure | Not run |')
  $markdown.Add('| --- | ---: | ---: | ---: | ---: | ---: | ---: |')
  foreach ($property in $behaviorProperties) {
    $evidence = $property.Value
    if ($null -eq $evidence) { continue }
    $markdown.Add("| $($property.Name) | $($evidence.total_cases) | $($evidence.counts.StablePass) | $($evidence.counts.StableFail) | $($evidence.counts.Variable) | $($evidence.counts.InfrastructureInconclusive) | $($evidence.counts.NotRun) |")
  }
}
if (@($summary.failures).Count -gt 0) {
  $markdown.Add('')
  $markdown.Add('## Failures')
  $markdown.Add('')
  foreach ($failure in @($summary.failures)) { $markdown.Add("- $failure") }
}
if (@($summary.impact.warnings).Count -gt 0) {
  $markdown.Add('')
  $markdown.Add('## Warnings')
  $markdown.Add('')
  foreach ($warning in @($summary.impact.warnings)) { $markdown.Add("- $warning") }
}
$markdown.Add('')
$markdown.Add('## Changed Paths')
$markdown.Add('')
foreach ($path in @($summary.impact.changed_paths)) { $markdown.Add("- $path") }
[System.IO.File]::WriteAllLines($MarkdownPath, $markdown, [System.Text.UTF8Encoding]::new($false))

$rows = foreach ($step in @($summary.steps)) {
  $statusClass = if ($step.status -eq 'Pass') { 'pass' } elseif ($step.status -in @('Skipped', 'Inconclusive')) { 'skip' } else { 'fail' }
  $logCell = if ($step.log) { "<a href='$(Get-ReportRelativeLink $step.log)'>log</a>" } else { '-' }
  "<tr><td>$(Encode-Html $step.name)</td><td class='$statusClass'>$(Encode-Html $step.status)</td><td>$($step.exit_code)</td><td>$($step.duration_ms) ms</td><td>$logCell</td></tr>"
}
$behaviorRows = @()
if ($behaviorProperties.Count -gt 0) {
  $behaviorRows = foreach ($property in $behaviorProperties) {
    $evidence = $property.Value
    if ($null -eq $evidence) { continue }
    "<tr><td>$(Encode-Html $property.Name)</td><td>$($evidence.total_cases)</td><td class='pass'>$($evidence.counts.StablePass)</td><td class='fail'>$($evidence.counts.StableFail)</td><td class='skip'>$($evidence.counts.Variable)</td><td class='skip'>$($evidence.counts.InfrastructureInconclusive)</td><td>$($evidence.counts.NotRun)</td></tr>"
  }
}
$behaviorHtml = if (@($behaviorRows).Count -eq 0) { '<p>No behavior run was recorded.</p>' } else { '<table><thead><tr><th>Run</th><th>Cases</th><th>Stable pass</th><th>Stable fail</th><th>Variable</th><th>Infrastructure</th><th>Not run</th></tr></thead><tbody>' + (@($behaviorRows) -join "`n") + '</tbody></table>' }
$failureHtml = if (@($summary.failures).Count -eq 0) { '<p>None.</p>' } else { '<ul>' + ((@($summary.failures) | ForEach-Object { '<li>' + (Encode-Html $_) + '</li>' }) -join '') + '</ul>' }
$changedHtml = if (@($summary.impact.changed_paths).Count -eq 0) { '<p>None.</p>' } else { '<ul>' + ((@($summary.impact.changed_paths) | ForEach-Object { '<li><code>' + (Encode-Html $_) + '</code></li>' }) -join '') + '</ul>' }
$resultClass = if ($summary.result -eq 'PASS') { 'pass' } elseif ($summary.result -eq 'INCONCLUSIVE') { 'skip' } else { 'fail' }
$html = @"
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>Allred Candidate Validation</title>
<style>
body{font-family:Segoe UI,Microsoft YaHei,sans-serif;max-width:1180px;margin:32px auto;padding:0 24px;color:#202124;background:#fff}h1{font-size:28px}h2{margin-top:30px;border-bottom:1px solid #dadce0;padding-bottom:8px}code{background:#f1f3f4;padding:2px 5px;border-radius:4px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #dadce0;padding:9px;text-align:left}th{background:#f8f9fa}.pass{color:#137333;font-weight:700}.fail{color:#b3261e;font-weight:700}.skip{color:#8a5d00;font-weight:700}.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:12px}.item{border:1px solid #dadce0;border-radius:6px;padding:12px}.label{color:#5f6368;font-size:13px}.value{margin-top:4px;font-weight:600;word-break:break-word}</style>
</head>
<body>
<h1>Allred Candidate Validation</h1>
<div class="summary">
<div class="item"><div class="label">Result</div><div class="value $resultClass">$(Encode-Html $summary.result)</div></div>
<div class="item"><div class="label">Mode</div><div class="value">$(Encode-Html $summary.mode)</div></div>
<div class="item"><div class="label">Baseline</div><div class="value">$(Encode-Html $summary.baseline_ref)</div></div>
<div class="item"><div class="label">Standard cases</div><div class="value">$(Encode-Html (Join-Display @($summary.selection.standard_case_ids)))</div></div>
</div>
<h2>Steps</h2>
<table><thead><tr><th>Step</th><th>Status</th><th>Exit</th><th>Duration</th><th>Evidence</th></tr></thead><tbody>$($rows -join "`n")</tbody></table>
<h2>Behavior Consistency</h2>$behaviorHtml
<h2>Failures</h2>$failureHtml
<h2>Changed Paths</h2>$changedHtml
<p><a href="$(Get-ReportRelativeLink $MarkdownPath)">Open Markdown report</a></p>
</body>
</html>
"@
[System.IO.File]::WriteAllText($HtmlPath, $html, [System.Text.UTF8Encoding]::new($false))
"Markdown report: $MarkdownPath"
"HTML report: $HtmlPath"
