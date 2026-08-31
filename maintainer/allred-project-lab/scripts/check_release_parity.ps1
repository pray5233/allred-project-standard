param(
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$ReleaseRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\allred-project-standard-release')).Path
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Get-RelativeFileMap {
  param([string]$Root)
  $map = @{}
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $rootUri = New-Object System.Uri($rootFull)
  foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File) {
    $fileUri = New-Object System.Uri($file.FullName)
    $relative = [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString()).Replace('\', '/')
    $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  return $map
}

function Compare-Tree {
  param([string]$Name, [string]$Source, [string]$Mirror)
  if (-not (Test-Path -LiteralPath $Source)) { $script:failures.Add("Missing source tree: $Source") | Out-Null; return }
  if (-not (Test-Path -LiteralPath $Mirror)) { $script:failures.Add("Missing release tree: $Mirror") | Out-Null; return }
  $sourceMap = Get-RelativeFileMap -Root $Source
  $mirrorMap = Get-RelativeFileMap -Root $Mirror
  foreach ($path in $sourceMap.Keys) {
    if (-not $mirrorMap.ContainsKey($path)) { $script:failures.Add("$Name release missing: $path") | Out-Null }
    elseif ($sourceMap[$path] -ne $mirrorMap[$path]) { $script:failures.Add("$Name release differs: $path") | Out-Null }
  }
  foreach ($path in $mirrorMap.Keys) {
    if (-not $sourceMap.ContainsKey($path)) { $script:failures.Add("$Name release has extra file: $path") | Out-Null }
  }
  "$Name files: source=$($sourceMap.Count), release=$($mirrorMap.Count)"
}

Compare-Tree -Name 'Standard' -Source $StandardRoot -Mirror (Join-Path $ReleaseRoot 'allred-project-standard')
Compare-Tree -Name 'Lab' -Source $LabRoot -Mirror (Join-Path $ReleaseRoot 'maintainer\allred-project-lab')
if ($failures.Count -gt 0) {
  'Release parity: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}
'Release parity: PASS'
