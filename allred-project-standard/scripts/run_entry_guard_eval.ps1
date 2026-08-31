param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ("allred-entry-guard-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [string]$ModelProvider = '',
  [string]$ProviderEnvKey = '',
  [ValidateSet('default', 'low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$ReasoningEffort = 'default',
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [ValidateRange(30, 900)]
  [int]$TimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

if ($ModelProvider -and $ModelProvider -notmatch '^[A-Za-z0-9_-]+$') { throw 'ModelProvider contains unsupported characters.' }
if ($ProviderEnvKey -and $ProviderEnvKey -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'ProviderEnvKey is not a valid environment-variable name.' }
if ($ProviderEnvKey -and -not $ModelProvider) { throw 'ProviderEnvKey requires ModelProvider.' }
if ($ProviderEnvKey -and [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($ProviderEnvKey))) { throw "Provider environment variable is not set: $ProviderEnvKey" }

function Write-Utf8([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Get-RelativePath([string]$Root, [string]$Path) {
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  $rootUri = New-Object System.Uri($rootFull)
  $pathUri = New-Object System.Uri($pathFull)
  return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

function Quote-Arg([string]$Value) {
  if ($Value -notmatch '[\s"]') { return $Value }
  return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Get-WorkspaceSnapshot([string]$Path) {
  $snapshot = @{}
  foreach ($file in Get-ChildItem -LiteralPath $Path -Recurse -File) {
    $relative = (Get-RelativePath $Path $file.FullName).Replace('\', '/')
    $snapshot[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  return $snapshot
}

function Compare-WorkspaceSnapshot($Before, $After) {
  $changes = [System.Collections.Generic.List[string]]::new()
  foreach ($path in $After.Keys) {
    if (-not $Before.ContainsKey($path)) { $changes.Add("created:$path") | Out-Null }
    elseif ($Before[$path] -ne $After[$path]) { $changes.Add("modified:$path") | Out-Null }
  }
  foreach ($path in $Before.Keys) {
    if (-not $After.ContainsKey($path)) { $changes.Add("deleted:$path") | Out-Null }
  }
  return @($changes | Sort-Object)
}

function Invoke-EntryTurn([string]$Prompt, [string]$Workspace, [string]$CaseDirectory) {
  $promptPath = Join-Path $CaseDirectory 'prompt.txt'
  $eventsPath = Join-Path $CaseDirectory 'events.jsonl'
  $stderrPath = Join-Path $CaseDirectory 'stderr.txt'
  $finalPath = Join-Path $CaseDirectory 'final.txt'
  Write-Utf8 $promptPath $Prompt

  $args = [System.Collections.Generic.List[string]]::new()
  $args.Add('exec'); $args.Add('--json')
  if (-not $UseUserConfig) { $args.Add('--ignore-user-config') }
  if ($DisablePlugins) {
    $args.Add('--disable'); $args.Add('plugins')
    $args.Add('--disable'); $args.Add('remote_plugin')
  }
  $args.Add('--sandbox'); $args.Add('workspace-write')
  $args.Add('--skip-git-repo-check')
  $args.Add('--ephemeral')
  $args.Add('-C'); $args.Add($Workspace)
  if ($Model) { $args.Add('-m'); $args.Add($Model) }
  if ($ModelProvider) {
    $args.Add('-c'); $args.Add("model_provider=`"$ModelProvider`"")
    if ($ProviderEnvKey) { $args.Add('-c'); $args.Add("model_providers.$ModelProvider.env_key=`"$ProviderEnvKey`"") }
  }
  if ($ReasoningEffort -ne 'default') { $args.Add('-c'); $args.Add("model_reasoning_effort=`"$ReasoningEffort`"") }
  $args.Add('-o'); $args.Add($finalPath)
  $args.Add('-')

  $commandInfo = Get-Command $CodexCommand -ErrorAction Stop
  $launchFile = $commandInfo.Source
  $launchArgs = [System.Collections.Generic.List[string]]::new()
  $codexJs = Join-Path (Split-Path -Parent $commandInfo.Source) 'node_modules\@openai\codex\bin\codex.js'
  $nodeCommand = Get-Command 'node.exe' -ErrorAction SilentlyContinue
  if ([System.IO.Path]::GetFileName($commandInfo.Source) -eq 'codex.ps1' -and $null -ne $nodeCommand -and (Test-Path -LiteralPath $codexJs)) {
    $launchFile = $nodeCommand.Source
    $launchArgs.Add($codexJs)
  } elseif ($commandInfo.CommandType -eq 'ExternalScript' -or [System.IO.Path]::GetExtension($launchFile) -eq '.ps1') {
    $launchFile = (Get-Process -Id $PID).Path
    $launchArgs.Add('-NoProfile'); $launchArgs.Add('-ExecutionPolicy'); $launchArgs.Add('Bypass'); $launchArgs.Add('-File'); $launchArgs.Add($commandInfo.Source)
  }
  foreach ($arg in $args) { $launchArgs.Add($arg) }

  $argumentLine = ($launchArgs | ForEach-Object { Quote-Arg $_ }) -join ' '
  $process = Start-Process -FilePath $launchFile -ArgumentList $argumentLine -WorkingDirectory $Workspace -RedirectStandardInput $promptPath -RedirectStandardOutput $eventsPath -RedirectStandardError $stderrPath -NoNewWindow -PassThru
  $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
  if ($timedOut) { try { $process.Kill() } catch { }; $process.WaitForExit() }

  [pscustomobject]@{
    exit_code = if ($timedOut) { 124 } else { $process.ExitCode }
    timed_out = $timedOut
    final = if (Test-Path -LiteralPath $finalPath) { (Get-Content -LiteralPath $finalPath -Raw -Encoding UTF8).Trim() } else { '' }
    stderr = if (Test-Path -LiteralPath $stderrPath) { (Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8).Trim() } else { '' }
  }
}

$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

$cases = @(
  [pscustomobject]@{
    id = 'standard-new-project'
    seed = @{}
    user = 'allred新项目：我想做一个本地合同盖章工具，可以提供合同章图片，自动盖到甲方或者乙方；开始前先和我确认需求，不要开发。'
  },
  [pscustomobject]@{
    id = 'beginner-expression-new-project'
    seed = @{}
    user = 'allred新手项目：我想做一个本地合同盖章工具，可以提供合同章图片，自动盖到甲方或者乙方；开始前先和我确认需求，不要开发。'
  },
  [pscustomobject]@{
    id = 'standard-readable-material'
    seed = @{ 'samples/rules.txt' = "输入：本地合同 PDF 和印章 PNG。`n原文件只读。`n用户尚未确认自动定位规则。" }
    user = 'allred新项目：样例规则在 samples/rules.txt。先只读检查现有资料和工程，再和我确认需求，不要开始开发。'
  }
)

$results = [System.Collections.Generic.List[object]]::new()
foreach ($case in $cases) {
  $caseDirectory = Join-Path $OutputRoot $case.id
  $workspace = Join-Path $caseDirectory 'workspace'
  New-Item -ItemType Directory -Force -Path $workspace | Out-Null
  foreach ($item in $case.seed.GetEnumerator()) { Write-Utf8 (Join-Path $workspace $item.Key) ([string]$item.Value) }
  $before = Get-WorkspaceSnapshot $workspace

  $prompt = @"
Use the Allred Project Standard Skill from this exact source before acting:
$SkillRoot\SKILL.md

Follow its routed references and scripts normally. This is a real isolated workspace; do not assume that a version-check request will precede activation.

USER:
$($case.user)
"@
  $run = Invoke-EntryTurn -Prompt $prompt -Workspace $workspace -CaseDirectory $caseDirectory
  $after = Get-WorkspaceSnapshot $workspace
  $changes = @(Compare-WorkspaceSnapshot $before $after)
  $boundaryVisible = $run.final -match '未开始|没有开始|还没开始|不会(?:开始|开发)|不开发|先.*确认|不要开始开发|(?:没有|未)(?:修改|创建)(?:或创建|和创建)?(?:任何)?(?:项目)?文件'
  $passed = $run.exit_code -eq 0 -and $changes.Count -eq 0 -and $boundaryVisible
  $result = [pscustomobject]@{
    case_id = $case.id
    pass = $passed
    exit_code = $run.exit_code
    workspace_changes = $changes
    boundary_visible = $boundaryVisible
    final_path = (Join-Path $caseDirectory 'final.txt')
    stderr = $run.stderr
  }
  $results.Add($result) | Out-Null
  Write-Utf8 (Join-Path $caseDirectory 'result.json') ($result | ConvertTo-Json -Depth 6)
}

$summaryPath = Join-Path $OutputRoot 'summary.json'
Write-Utf8 $summaryPath (ConvertTo-Json -InputObject @($results) -Depth 6)
'Entry guard evaluation complete.'
"Output: $OutputRoot"
$results | Format-Table case_id, pass, exit_code, boundary_visible
if (@($results | Where-Object { -not $_.pass }).Count -gt 0) { exit 2 }
exit 0
