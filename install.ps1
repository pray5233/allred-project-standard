param(
    [string]$DestinationRoot = (Join-Path $env:USERPROFILE '.codex\skills')
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $repoRoot 'allred-project-standard'
$sourceSkill = Join-Path $source 'SKILL.md'
$sourceCheck = Join-Path $source 'scripts\check_skill_structure.ps1'

if (-not (Test-Path -LiteralPath $sourceSkill)) {
    throw "Cannot find source Skill: $sourceSkill"
}
if (-not (Test-Path -LiteralPath $sourceCheck)) {
    throw "Cannot find structure check: $sourceCheck"
}

$validatorCommand = Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue
if ($null -eq $validatorCommand) {
    $validatorCommand = Get-Command 'powershell.exe' -ErrorAction SilentlyContinue
}
if ($null -eq $validatorCommand) {
    throw 'Cannot find PowerShell 7 or Windows PowerShell 5.1.'
}
$validatorHost = $validatorCommand.Source

& $validatorHost -NoProfile -File $sourceCheck -SkillRoot $source
if ($LASTEXITCODE -ne 0) {
    throw 'Source Skill validation failed. Installation stopped.'
}

New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
$resolvedRoot = (Resolve-Path -LiteralPath $DestinationRoot).Path
$dest = Join-Path $resolvedRoot 'allred-project-standard'
$stage = Join-Path $resolvedRoot ('.allred-project-standard.installing-' + [guid]::NewGuid().ToString('N'))
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $resolvedRoot ('.allred-project-standard.backup-' + $stamp)
if (Test-Path -LiteralPath $backup) {
    $backup += '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
}

$installed = $false
try {
    Copy-Item -LiteralPath $source -Destination $stage -Recurse
    & $validatorHost -NoProfile -File (Join-Path $stage 'scripts\check_skill_structure.ps1') -SkillRoot $stage
    if ($LASTEXITCODE -ne 0) {
        throw 'Staged Skill validation failed.'
    }

    if (Test-Path -LiteralPath $dest) {
        Move-Item -LiteralPath $dest -Destination $backup
    }

    Move-Item -LiteralPath $stage -Destination $dest
    $installed = $true
} catch {
    if ((-not (Test-Path -LiteralPath $dest)) -and (Test-Path -LiteralPath $backup)) {
        Move-Item -LiteralPath $backup -Destination $dest
    }
    throw
}

if (-not $installed) {
    throw 'Installation did not complete.'
}

Write-Host "Installed allred-project-standard to $dest"
if (Test-Path -LiteralPath $backup) {
    Write-Host "Previous version preserved at $backup"
}
Write-Host 'Open a new Codex task to use the updated Skill.'
