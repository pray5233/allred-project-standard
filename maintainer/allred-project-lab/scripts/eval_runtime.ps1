$ErrorActionPreference = 'Stop'
$script:AllredEvalEncoding = [System.Text.UTF8Encoding]::new($false)

function Write-AllredEvalUtf8 {
  param([string]$Path, [string]$Text)
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, $script:AllredEvalEncoding)
}

function ConvertTo-AllredQuotedArgument {
  param([string]$Value)
  if ($Value -notmatch '[\s"]') { return $Value }
  return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-AllredCodexEval {
  param(
    [string]$Prompt,
    [string]$RunDirectory,
    [string]$Prefix,
    [string]$SchemaPath = '',
    [string]$CodexCommand = 'codex',
    [string]$Model = '',
    [string]$ModelProvider = '',
    [string]$ProviderEnvKey = '',
    [string]$ReasoningEffort = 'default',
    [bool]$UseUserConfig = $false,
    [bool]$DisablePlugins = $false,
    [int]$TimeoutSeconds = 240
  )

  New-Item -ItemType Directory -Force -Path $RunDirectory | Out-Null
  $promptPath = Join-Path $RunDirectory "$Prefix.prompt.txt"
  $eventsPath = Join-Path $RunDirectory "$Prefix.events.jsonl"
  $stderrPath = Join-Path $RunDirectory "$Prefix.stderr.txt"
  $finalPath = Join-Path $RunDirectory "$Prefix.final.txt"
  Write-AllredEvalUtf8 -Path $promptPath -Text $Prompt

  $arguments = [System.Collections.Generic.List[string]]::new()
  $arguments.Add('exec')
  $arguments.Add('--json')
  if (-not $UseUserConfig) { $arguments.Add('--ignore-user-config') }
  if ($DisablePlugins) {
    $arguments.Add('--disable'); $arguments.Add('plugins')
    $arguments.Add('--disable'); $arguments.Add('remote_plugin')
  }
  $arguments.Add('--sandbox'); $arguments.Add('read-only')
  $arguments.Add('--skip-git-repo-check')
  $arguments.Add('--ephemeral')
  $arguments.Add('-C'); $arguments.Add($RunDirectory)
  if ($Model) { $arguments.Add('-m'); $arguments.Add($Model) }
  if ($ModelProvider) {
    if ($ModelProvider -notmatch '^[A-Za-z0-9_-]+$') { throw 'ModelProvider contains unsupported characters.' }
    $arguments.Add('-c'); $arguments.Add("model_provider=`"$ModelProvider`"")
    if ($ProviderEnvKey) {
      if ($ProviderEnvKey -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { throw 'ProviderEnvKey is not a valid environment-variable name.' }
      if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($ProviderEnvKey))) { throw "Provider environment variable is not set: $ProviderEnvKey" }
      $arguments.Add('-c'); $arguments.Add("model_providers.$ModelProvider.env_key=`"$ProviderEnvKey`"")
    }
  } elseif ($ProviderEnvKey) {
    throw 'ProviderEnvKey requires ModelProvider.'
  }
  if ($ReasoningEffort -ne 'default') {
    $arguments.Add('-c'); $arguments.Add("model_reasoning_effort=`"$ReasoningEffort`"")
  }
  if ($SchemaPath) { $arguments.Add('--output-schema'); $arguments.Add($SchemaPath) }
  $arguments.Add('-o'); $arguments.Add($finalPath)
  $arguments.Add('-')

  $commandInfo = Get-Command $CodexCommand -ErrorAction Stop
  $launchFile = $commandInfo.Source
  $launchArguments = [System.Collections.Generic.List[string]]::new()
  $codexJs = Join-Path (Split-Path -Parent $commandInfo.Source) 'node_modules\@openai\codex\bin\codex.js'
  $nodeCommand = Get-Command 'node.exe' -ErrorAction SilentlyContinue
  if ([System.IO.Path]::GetFileName($commandInfo.Source) -eq 'codex.ps1' -and $null -ne $nodeCommand -and (Test-Path -LiteralPath $codexJs)) {
    $launchFile = $nodeCommand.Source
    $launchArguments.Add($codexJs)
  } elseif ($commandInfo.CommandType -eq 'ExternalScript' -or [System.IO.Path]::GetExtension($launchFile) -eq '.ps1') {
    $launchFile = (Get-Process -Id $PID).Path
    $launchArguments.Add('-NoProfile')
    $launchArguments.Add('-ExecutionPolicy'); $launchArguments.Add('Bypass')
    $launchArguments.Add('-File'); $launchArguments.Add($commandInfo.Source)
  }
  foreach ($argument in $arguments) { $launchArguments.Add($argument) }

  $argumentLine = ($launchArguments | ForEach-Object { ConvertTo-AllredQuotedArgument $_ }) -join ' '
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  $process = Start-Process -FilePath $launchFile -ArgumentList $argumentLine -WorkingDirectory $RunDirectory -RedirectStandardInput $promptPath -RedirectStandardOutput $eventsPath -RedirectStandardError $stderrPath -NoNewWindow -PassThru
  $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
  if ($timedOut) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
  } else {
    $process.WaitForExit()
  }
  $stopwatch.Stop()

  $events = @()
  if (Test-Path -LiteralPath $eventsPath) {
    foreach ($line in Get-Content -LiteralPath $eventsPath -Encoding UTF8) {
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      try { $events += ($line | ConvertFrom-Json) } catch { }
    }
  }
  $errors = @($events | Where-Object type -eq 'error' | ForEach-Object message)
  $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8 } else { '' }
  $final = if (Test-Path -LiteralPath $finalPath) { Get-Content -LiteralPath $finalPath -Raw -Encoding UTF8 } else { '' }

  [pscustomobject]@{
    ExitCode = if ($timedOut) { 124 } else { $process.ExitCode }
    TimedOut = $timedOut
    DurationMs = [int64]$stopwatch.ElapsedMilliseconds
    Final = $final.Trim()
    Errors = @($errors)
    Stderr = $stderr.Trim()
  }
}

function Test-AllredEvalInfrastructureFailure {
  param($Run)
  if ($Run.TimedOut) { return $true }
  if ($Run.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($Run.Final)) { return $false }
  $combined = (@($Run.Errors) + @($Run.Stderr)) -join "`n"
  if ($Run.ExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($Run.Final)) { return $true }
  return $combined -match '401 Unauthorized|INVALID_API_KEY|authentication required|rate limit|timed out|connection|network|model.*not found'
}

function Get-AllredEvalInfrastructureReason {
  param($Run, [int]$TimeoutSeconds)
  if ($Run.TimedOut) { return "Codex CLI exceeded ${TimeoutSeconds}s." }
  $combined = (@($Run.Errors) + @($Run.Stderr)) -join "`n"
  if ($combined.Length -gt 600) { $combined = $combined.Substring(0, 600) }
  if (-not [string]::IsNullOrWhiteSpace($combined)) { return $combined }
  return "Codex CLI exited with code $($Run.ExitCode) without a final response."
}
