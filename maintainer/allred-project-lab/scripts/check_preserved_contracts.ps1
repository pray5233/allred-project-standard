param(
  [string]$SkillRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [Parameter(Mandatory = $true)][string]$OutputRoot
)
$ErrorActionPreference = 'Stop'
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$hostPs = (Get-Process -Id $PID).Path
$results = [Collections.Generic.List[object]]::new()
function Check([string]$Name,[bool]$Pass,[string]$Evidence) {
  $results.Add([pscustomobject]@{name=$Name; passed=$Pass; evidence=$Evidence}) | Out-Null
  "${Name}: $Pass"
}
function Script-Check([string]$Name,[string]$Script,[string[]]$Arguments,[bool]$Pass=$true) {
  $output = @(& $hostPs -NoProfile -ExecutionPolicy Bypass -File (Join-Path $SkillRoot "scripts/$Script") @Arguments)
  Check $Name (($LASTEXITCODE -eq 0) -eq $Pass) ($output -join [Environment]::NewLine)
}
$record = Get-Content -LiteralPath (Join-Path $SkillRoot 'tests/execution-record.valid.md') -Raw -Encoding UTF8
foreach ($ending in @('LF','CRLF')) {
  $text = $record -replace '\r?\n', "`n"
  if ($ending -eq 'CRLF') { $text = $text.Replace("`n", "`r`n") }
  $path = Join-Path $OutputRoot "record-$ending.md"
  [IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
  Script-Check "record-$ending" 'validate_execution_record.ps1' @('-Path',$path)
  Script-Check "coverage-$ending" 'validate_decision_coverage.ps1' @('-Path',$path)
}
$selector = Join-Path $SkillRoot 'scripts/get_route_context.ps1'
foreach ($fixture in (Get-Content -LiteralPath (Join-Path $PSScriptRoot '../tests/preserved-training-handoffs.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) {
  $path = Join-Path $OutputRoot ($fixture.id + '.md')
  [IO.File]::WriteAllText($path,$fixture.text,[Text.UTF8Encoding]::new($false))
  Script-Check $fixture.id 'validate_training_handoff.ps1' @('-Path',$path) ([bool]$fixture.pass)
}
$alias = & $selector -Route new-public -Stage evidence -MetricsOnly | ConvertFrom-Json
Check 'legacy-route-alias' ($alias.route -eq 'new-standard' -and $alias.compatibility_alias -and 'external-source' -in $alias.overlays) 'Alias remains a monitoring overlay, not a separate workflow.'
$ps51 = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($ps51) {
  $output = & $ps51.Source -NoProfile -ExecutionPolicy Bypass -File $selector -Route new-standard -Stage intake -MetricsOnly
  Check 'ps51-no-explicit-skill-root' ($LASTEXITCODE -eq 0 -and ($output | ConvertFrom-Json).route -eq 'new-standard') ($output -join [Environment]::NewLine)
}
. (Join-Path $SkillRoot 'scripts/state_validation_common.ps1')
$inside = Join-Path $OutputRoot 'project'
$outside = Join-Path $OutputRoot 'outside'
New-Item -ItemType Directory -Path $inside,$outside -Force | Out-Null
$link = Join-Path $inside 'alias'
New-Item -ItemType Junction -Path $link -Target $outside | Out-Null
Check 'actual-junction-rejected' (-not (Test-AllredNoLinkTraversal -Path (Join-Path $link 'output.txt'))) 'Existing junction resolves outside the project; no output written through it.'
Check 'ordinary-ancestor-accepted' (Test-AllredNoLinkTraversal -Path (Join-Path $inside 'output.txt')) 'Ordinary ancestor remains usable.'
$temp = & (Join-Path $SkillRoot 'scripts/new_evidence_temp.ps1') -Purpose 'preserved-contract' | ConvertFrom-Json
$systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
Check 'disposable-evidence-boundary' (Test-AllredPathWithin -Root $systemTemp -Candidate $temp.path) ($temp | ConvertTo-Json -Compress)
# Remove only the empty directory returned and verified above, never recursively.
if ((Test-AllredPathWithin -Root $systemTemp -Candidate $temp.path) -and @(Get-ChildItem -LiteralPath $temp.path -Force).Count -eq 0) { [IO.Directory]::Delete($temp.path) }
[IO.File]::WriteAllText((Join-Path $OutputRoot 'preserved-contracts.json'),(ConvertTo-Json -InputObject @($results) -Depth 6),[Text.UTF8Encoding]::new($false))
if (@($results | Where-Object { -not $_.passed }).Count -gt 0) { exit 1 }
'Preserved contracts: PASS'
