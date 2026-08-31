param(
  [ValidatePattern('^[A-Za-z0-9._-]{1,48}$')]
  [string]$Purpose = 'evidence'
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
$base = Join-Path $systemTemp 'allred-project-standard\evidence'
$name = '{0}-{1}-{2}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $Purpose, ([guid]::NewGuid().ToString('N'))
$path = Join-Path $base $name

New-Item -ItemType Directory -Path $path -Force | Out-Null
$resolved = (Resolve-Path -LiteralPath $path).Path
if (-not $resolved.StartsWith($systemTemp + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Evidence directory escaped system temp: $resolved"
}

[pscustomobject]@{
  path = $resolved
  purpose = $Purpose
  disposable = $true
  created_utc = [DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json -Compress
