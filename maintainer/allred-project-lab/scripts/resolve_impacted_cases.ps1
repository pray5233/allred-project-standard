param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$BaselineRef = 'HEAD',
  [string]$ImpactMapPath = '',
  [switch]$IncludeAdjacent,
  [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

function Get-RelativePathValue {
  param([string]$Root, [string]$Path)
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

function Add-UniqueValues {
  param([System.Collections.Generic.HashSet[string]]$Target, [object[]]$Values)
  foreach ($value in @($Values)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$value)) { $Target.Add([string]$value) | Out-Null }
  }
}

function Read-GitJsonAtRef {
  param([string]$Repository, [string]$Reference, [string]$RepositoryPath)
  $spec = "${Reference}:$RepositoryPath"
  $content = & git -c core.quotepath=false -c core.autocrlf=false -C $Repository show $spec 2>$null
  if ($LASTEXITCODE -ne 0 -or @($content).Count -eq 0) { return $null }
  try { return ($content -join "`n") | ConvertFrom-Json }
  catch { return $null }
}

function Get-ChangedJsonCaseIds {
  param([string]$CurrentPath, [string]$RepositoryPath, [string]$Repository, [string]$Reference)
  if (-not (Test-Path -LiteralPath $CurrentPath)) { return @() }
  $current = Get-Content -LiteralPath $CurrentPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $baseline = Read-GitJsonAtRef -Repository $Repository -Reference $Reference -RepositoryPath $RepositoryPath
  if ($null -eq $baseline) { return @($current.cases.id) }
  $baselineById = @{}
  foreach ($item in @($baseline.cases)) { $baselineById[[string]$item.id] = ($item | ConvertTo-Json -Depth 50 -Compress) }
  $changed = [System.Collections.Generic.List[string]]::new()
  foreach ($item in @($current.cases)) {
    $id = [string]$item.id
    $serialized = $item | ConvertTo-Json -Depth 50 -Compress
    if (-not $baselineById.ContainsKey($id) -or $baselineById[$id] -ne $serialized) { $changed.Add($id) | Out-Null }
  }
  # Baseline-only cases are deletion evidence, not runnable candidate cases.
  # Manifest and invariant checks validate the deletion itself.
  return @($changed | Sort-Object -Unique)
}

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$StandardRoot = (Resolve-Path -LiteralPath $StandardRoot).Path
$LabRoot = (Resolve-Path -LiteralPath $LabRoot).Path
if ([string]::IsNullOrWhiteSpace($ImpactMapPath)) { $ImpactMapPath = Join-Path $LabRoot 'tests\impact-map.json' }
$impact = Get-Content -LiteralPath $ImpactMapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$invariants = Get-Content -LiteralPath (Join-Path $StandardRoot 'tests\invariants.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$standardRepoPath = Get-RelativePathValue -Root $RepoRoot -Path $StandardRoot
$labRepoPath = Get-RelativePathValue -Root $RepoRoot -Path $LabRoot
$changedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($path in @(& git -c core.quotepath=false -c core.autocrlf=false -C $RepoRoot diff --name-only $BaselineRef -- $standardRepoPath $labRepoPath)) {
  if (-not [string]::IsNullOrWhiteSpace($path)) { $changedPaths.Add($path.Replace('\', '/')) | Out-Null }
}
foreach ($line in @(& git -c core.quotepath=false -c core.autocrlf=false -C $RepoRoot status --porcelain=v1 --untracked-files=all -- $standardRepoPath $labRepoPath)) {
  if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
  $path = $line.Substring(3).Trim('"')
  if ($path.Contains(' -> ')) { $path = ($path -split ' -> ')[-1] }
  $changedPaths.Add($path.Replace('\', '/')) | Out-Null
}

$caseIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$adjacentIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$labCaseIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$replayCaseIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$warnings = [System.Collections.Generic.List[string]]::new()
$standardChanged = $false
$labChanged = $false

foreach ($repositoryPath in @($changedPaths)) {
  if ($repositoryPath.StartsWith($standardRepoPath + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
    $standardChanged = $true
    $relative = $repositoryPath.Substring($standardRepoPath.Length + 1)
    foreach ($invariant in @($invariants.invariants)) {
      $ownedPaths = @([string]$invariant.owner) + @($invariant.enforcement)
      if ($relative -in $ownedPaths) { Add-UniqueValues -Target $caseIds -Values @($invariant.behavior_cases) }
    }
    foreach ($rule in @($impact.rules)) {
      if ($relative -like [string]$rule.path) {
        Add-UniqueValues -Target $caseIds -Values @($rule.case_ids)
        Add-UniqueValues -Target $adjacentIds -Values @($rule.adjacent_case_ids)
      }
    }

    if ($relative -in @('tests/behavior-cases.test.json', 'tests/behavior-cases.oracle.json')) {
      $currentPath = Join-Path $StandardRoot $relative.Replace('/', '\')
      Add-UniqueValues -Target $caseIds -Values @(Get-ChangedJsonCaseIds -CurrentPath $currentPath -RepositoryPath $repositoryPath -Repository $RepoRoot -Reference $BaselineRef)
    }
  } elseif ($repositoryPath.StartsWith($labRepoPath + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
    $labChanged = $true
  }
}

if ($labChanged) {
  Add-UniqueValues -Target $labCaseIds -Values @($impact.default_lab_case_ids)
  Add-UniqueValues -Target $replayCaseIds -Values @($impact.default_replay_case_ids)
}
if ($standardChanged -and $caseIds.Count -eq 0) {
  Add-UniqueValues -Target $caseIds -Values @($impact.default_release_case_ids)
  $warnings.Add('A Standard Skill change had no exact impact rule; release-matrix cases were selected as the safe fallback.') | Out-Null
}
if ($IncludeAdjacent) { Add-UniqueValues -Target $caseIds -Values @($adjacentIds) }

$currentBehavior = Get-Content -LiteralPath (Join-Path $StandardRoot 'tests\behavior-cases.test.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$knownCaseIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($id in @($currentBehavior.cases.id)) { $knownCaseIds.Add([string]$id) | Out-Null }
foreach ($id in @($caseIds)) {
  if (-not $knownCaseIds.Contains([string]$id)) {
    $caseIds.Remove([string]$id) | Out-Null
    $warnings.Add("Discarded non-runnable impact case: $id") | Out-Null
  }
}

$result = [ordered]@{
  schema_version = 1
  generated_at_utc = [DateTime]::UtcNow.ToString('o')
  baseline_ref = $BaselineRef
  standard_root = $StandardRoot
  lab_root = $LabRoot
  changed_paths = @($changedPaths | Sort-Object)
  standard_changed = $standardChanged
  lab_changed = $labChanged
  standard_case_ids = @($caseIds | Sort-Object)
  adjacent_case_ids = @($adjacentIds | Sort-Object)
  lab_case_ids = @($labCaseIds | Sort-Object)
  replay_case_ids = @($replayCaseIds | Sort-Object)
  warnings = @($warnings)
}
$json = $result | ConvertTo-Json -Depth 8
if ($OutputPath) {
  $parent = Split-Path -Parent $OutputPath
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.UTF8Encoding]::new($false))
}
$json
