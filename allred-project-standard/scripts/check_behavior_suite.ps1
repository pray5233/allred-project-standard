param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$manifestCheck = Join-Path $PSScriptRoot 'check_behavior_manifest.ps1'

Write-Warning 'check_behavior_suite.ps1 is a compatibility alias. It validates the test manifest only and does not run Codex behavior evaluations.'
& $manifestCheck -SkillRoot $SkillRoot
if (-not $?) { exit 1 }
exit 0
