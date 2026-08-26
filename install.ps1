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
$sourceVersionPath = Join-Path $source 'VERSION'

if (-not (Test-Path -LiteralPath $sourceSkill)) {
    throw "Cannot find source Skill: $sourceSkill"
}
if (-not (Test-Path -LiteralPath $sourceCheck)) {
    throw "Cannot find structure check: $sourceCheck"
}
if (-not (Test-Path -LiteralPath $sourceVersionPath)) {
    throw "Cannot find source version: $sourceVersionPath"
}
$sourceVersion = (Get-Content -LiteralPath $sourceVersionPath -Raw -Encoding UTF8).Trim()
if ($sourceVersion -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') {
    throw "Invalid source VERSION: $sourceVersion"
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
$previousVersion = 'not-installed'
if (Test-Path -LiteralPath (Join-Path $dest 'VERSION')) {
    $previousVersion = (Get-Content -LiteralPath (Join-Path $dest 'VERSION') -Raw -Encoding UTF8).Trim()
}
$stage = Join-Path $resolvedRoot ('.allred-project-standard.installing-' + [guid]::NewGuid().ToString('N'))
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$safePreviousVersion = $previousVersion -replace '[^0-9A-Za-z.-]', '_'
$backup = Join-Path $resolvedRoot ('.allred-project-standard.backup-v' + $safePreviousVersion + '-' + $stamp)
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

$installedVersion = (Get-Content -LiteralPath (Join-Path $dest 'VERSION') -Raw -Encoding UTF8).Trim()
if ($installedVersion -ne $sourceVersion) {
    throw "Installed version mismatch: expected $sourceVersion, found $installedVersion"
}

$sourceCommit = $null
$sourceState = 'package-without-git'
$gitCommand = Get-Command 'git.exe' -ErrorAction SilentlyContinue
if ($null -ne $gitCommand) {
    try {
        $packageStatus = @(& $gitCommand.Source -C $repoRoot status --porcelain -- . 2>$null)
        if ($LASTEXITCODE -eq 0) {
            if ($packageStatus.Count -eq 0) {
                $candidateCommit = (& $gitCommand.Source -C $repoRoot rev-parse HEAD 2>$null).Trim()
                if ($LASTEXITCODE -eq 0 -and $candidateCommit -match '^[0-9a-f]{40}$') {
                    $sourceCommit = $candidateCommit
                    $sourceState = 'clean-commit'
                }
            } else {
                $sourceState = 'uncommitted-package'
            }
        }
    } catch { }
}

$receipt = [ordered]@{
    schema_version = 1
    skill = 'allred-project-standard'
    installed_version = $installedVersion
    previous_version = $previousVersion
    installed_at_utc = [DateTime]::UtcNow.ToString('o')
    destination = $dest
    source_state = $sourceState
    source_commit = $sourceCommit
    skill_md_sha256 = (Get-FileHash -LiteralPath (Join-Path $dest 'SKILL.md') -Algorithm SHA256).Hash.ToLowerInvariant()
}
$receiptPath = Join-Path $resolvedRoot '.allred-project-standard-installation.json'
$receiptTemp = $receiptPath + '.tmp-' + [guid]::NewGuid().ToString('N')
[System.IO.File]::WriteAllText($receiptTemp, ($receipt | ConvertTo-Json -Depth 4), [System.Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $receiptTemp -Destination $receiptPath -Force

Write-Host "Installed allred-project-standard v$installedVersion to $dest"
Write-Host "Installation receipt: $receiptPath"
if (Test-Path -LiteralPath $backup) {
    Write-Host "Previous version ($previousVersion) preserved at $backup"
}
Write-Host 'Open a new Codex task to use the updated Skill.'
