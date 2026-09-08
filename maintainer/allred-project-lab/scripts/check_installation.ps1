param(
  [Parameter(Mandatory=$true)][string]$PackageRoot,
  [Parameter(Mandatory=$true)][string]$OutputRoot
)
$ErrorActionPreference='Stop'
$PackageRoot=(Resolve-Path -LiteralPath $PackageRoot).Path
$OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
if(Test-Path -LiteralPath $OutputRoot) { throw 'Use a new evidence directory.' }
[void][IO.Directory]::CreateDirectory($OutputRoot)
$package=Join-Path $OutputRoot 'package'
[void][IO.Directory]::CreateDirectory($package)
foreach($name in @('allred-project-standard','maintainer','install.ps1')) {
  Copy-Item -LiteralPath (Join-Path $PackageRoot $name) -Destination $package -Recurse
}
$results=[Collections.Generic.List[object]]::new()
function Check([string]$Name,[bool]$Passed) {
  $results.Add([pscustomobject]@{name=$Name;passed=$Passed})
  if(-not $Passed) { throw "Installation check failed: $Name" }
}
function Inventory([string]$Path) {
  $entries=@(Get-ChildItem -LiteralPath $Path -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
    ($_.FullName.Substring($Path.Length+1))+' '+(Get-FileHash -LiteralPath $_.FullName).Hash
  })
  return $entries -join "`n"
}
function Run-Installer([string]$Shell,[string]$Destination,[string]$Name) {
  $previous=$ErrorActionPreference
  try {
    $ErrorActionPreference='Continue'
    $output=@(& $Shell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $package 'install.ps1') -DestinationRoot $Destination 2>&1 | ForEach-Object { [string]$_ })
    $code=$LASTEXITCODE
  } finally { $ErrorActionPreference=$previous }
  [IO.File]::WriteAllText((Join-Path $OutputRoot ($Name+'.log')),($output -join "`n"),[Text.UTF8Encoding]::new($false))
  return $code
}
$shells=@((Get-Process -Id $PID).Path)
$legacy=Get-Command powershell.exe -ErrorAction SilentlyContinue
if($legacy -and $legacy.Source -notin $shells) { $shells+= $legacy.Source }
$source=Join-Path $package 'allred-project-standard'
$sourceInventory=Inventory $source
foreach($shell in $shells) {
  $label=if($shell -match '[\\/]powershell\.exe$'){'ps51'}else{'current'}
  $destination=Join-Path $OutputRoot ('installed-'+$label)
  $installed=Join-Path $destination 'allred-project-standard'
  Check "$label fresh install" ((Run-Installer $shell $destination "$label-fresh") -eq 0)
  Check "$label exact copied bytes" ((Inventory $installed) -ceq $sourceInventory)
  $receiptPath=Join-Path $destination '.allred-project-standard-installation.json'
  $receipt=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Check "$label receipt scope" ($receipt.validation -eq 'package-structure-and-copy-integrity; not behavior acceptance')
  Check "$label receipt file count" ($receipt.installed_file_count -eq @(Get-ChildItem $installed -Recurse -File -Force).Count)
  Check "$label repeat install" ((Run-Installer $shell $destination "$label-repeat") -eq 0)
  $backups=@(Get-ChildItem -LiteralPath $destination -Directory -Force | Where-Object Name -Like '.allred-project-standard.backup-*')
  Check "$label old installation preserved" ($backups.Count -eq 1 -and (Inventory $backups[0].FullName) -ceq $sourceInventory)
  $receiptHash=(Get-FileHash -LiteralPath $receiptPath).Hash
  $missing=Join-Path $source 'scripts/get_route_context.ps1'
  # This is a generated test-package file, never the source or installed copy.
  if(-not $missing.StartsWith($package+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Fault fixture escapes package.' }
  $bytes=[IO.File]::ReadAllBytes($missing)
  try {
    Remove-Item -LiteralPath $missing
    Check "$label incomplete package rejected" ((Run-Installer $shell $destination "$label-incomplete") -ne 0)
    Check "$label failed update preserves installed bytes" ((Inventory $installed) -ceq $sourceInventory)
    Check "$label failed update preserves receipt" ((Get-FileHash -LiteralPath $receiptPath).Hash -eq $receiptHash)
  } finally { [IO.File]::WriteAllBytes($missing,$bytes) }
}
Check 'package source unchanged' ((Inventory $source) -ceq $sourceInventory)
[IO.File]::WriteAllText((Join-Path $OutputRoot 'summary.json'),(ConvertTo-Json -InputObject @($results.ToArray())),[Text.UTF8Encoding]::new($false))
"Installation contracts: PASS ($($results.Count) assertions; actual isolated installs, no model calls)"
