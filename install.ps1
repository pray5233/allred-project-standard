$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $repoRoot "allred-project-standard"
$destRoot = Join-Path $env:USERPROFILE ".codex\skills"
$dest = Join-Path $destRoot "allred-project-standard"

if (-not (Test-Path -LiteralPath (Join-Path $source "SKILL.md"))) {
    throw "Cannot find allred-project-standard\SKILL.md next to install.ps1."
}

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null

if (Test-Path -LiteralPath $dest) {
    Remove-Item -LiteralPath $dest -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $dest -Recurse -Force

Write-Host "Installed allred-project-standard to $dest"
Write-Host "Open a new Codex conversation to use the updated skill."
