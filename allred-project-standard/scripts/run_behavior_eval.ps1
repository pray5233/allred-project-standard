param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$SuiteRoot = '',
  [string[]]$CaseIds = @('V01'),
  [string]$OutputRoot = (Join-Path (Get-Location) ("behavior-eval-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
  [string]$CodexCommand = 'codex',
  [string]$Model = '',
  [ValidateSet('default', 'low', 'medium', 'high', 'xhigh', 'ultra', 'max')]
  [string]$ReasoningEffort = 'default',
  [switch]$UseUserConfig,
  [switch]$DisablePlugins,
  [ValidateRange(10, 3600)]
  [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

function Read-Json([string]$Path) {
  Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Utf8([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Quote-Arg([string]$Value) {
  if ($Value -notmatch '[\s"]') { return $Value }
  return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-CodexTurn {
  param(
    [string]$Prompt,
    [string]$RunDirectory,
    [string]$Prefix,
    [string]$SessionId = '',
    [string]$SchemaPath = '',
    [switch]$Ephemeral
  )

  New-Item -ItemType Directory -Force -Path $RunDirectory | Out-Null
  $promptPath = Join-Path $RunDirectory "$Prefix.prompt.txt"
  $stdoutPath = Join-Path $RunDirectory "$Prefix.events.jsonl"
  $stderrPath = Join-Path $RunDirectory "$Prefix.stderr.txt"
  $finalPath = Join-Path $RunDirectory "$Prefix.final.txt"
  Write-Utf8 $promptPath $Prompt

  $args = [System.Collections.Generic.List[string]]::new()
  $args.Add('exec')
  if ($SessionId) {
    $args.Add('resume')
    $args.Add('--json')
    if (-not $UseUserConfig) { $args.Add('--ignore-user-config') }
    if ($DisablePlugins) {
      $args.Add('--disable'); $args.Add('plugins')
      $args.Add('--disable'); $args.Add('remote_plugin')
    }
    $args.Add('--skip-git-repo-check')
    if ($Model) { $args.Add('-m'); $args.Add($Model) }
    if ($ReasoningEffort -ne 'default') { $args.Add('-c'); $args.Add("model_reasoning_effort=`"$ReasoningEffort`"") }
    if ($SchemaPath) { $args.Add('--output-schema'); $args.Add($SchemaPath) }
    $args.Add('-o'); $args.Add($finalPath)
    $args.Add($SessionId)
    $args.Add('-')
  } else {
    $args.Add('--json')
    if (-not $UseUserConfig) { $args.Add('--ignore-user-config') }
    if ($DisablePlugins) {
      $args.Add('--disable'); $args.Add('plugins')
      $args.Add('--disable'); $args.Add('remote_plugin')
    }
    $args.Add('--sandbox'); $args.Add('read-only')
    $args.Add('--skip-git-repo-check')
    $args.Add('-C'); $args.Add($RunDirectory)
    if ($Ephemeral) { $args.Add('--ephemeral') }
    if ($Model) { $args.Add('-m'); $args.Add($Model) }
    if ($ReasoningEffort -ne 'default') { $args.Add('-c'); $args.Add("model_reasoning_effort=`"$ReasoningEffort`"") }
    if ($SchemaPath) { $args.Add('--output-schema'); $args.Add($SchemaPath) }
    $args.Add('-o'); $args.Add($finalPath)
    $args.Add('-')
  }

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
    $launchArgs.Add('-NoProfile')
    $launchArgs.Add('-ExecutionPolicy'); $launchArgs.Add('Bypass')
    $launchArgs.Add('-File'); $launchArgs.Add($commandInfo.Source)
  }
  foreach ($arg in $args) { $launchArgs.Add($arg) }

  $argumentLine = ($launchArgs | ForEach-Object { Quote-Arg $_ }) -join ' '
  $process = Start-Process -FilePath $launchFile -ArgumentList $argumentLine -WorkingDirectory $RunDirectory -RedirectStandardInput $promptPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -NoNewWindow -PassThru
  $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
  if ($timedOut) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
  } else {
    $process.WaitForExit()
  }

  $events = @()
  if (Test-Path -LiteralPath $stdoutPath) {
    foreach ($line in Get-Content -LiteralPath $stdoutPath -Encoding UTF8) {
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      try { $events += ($line | ConvertFrom-Json) } catch { }
    }
  }
  $started = $events | Where-Object type -eq 'thread.started' | Select-Object -First 1
  $errors = @($events | Where-Object type -eq 'error' | ForEach-Object message)
  $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8 } else { '' }
  $final = if (Test-Path -LiteralPath $finalPath) { Get-Content -LiteralPath $finalPath -Raw -Encoding UTF8 } else { '' }

  [pscustomobject]@{
    ExitCode = if ($timedOut) { 124 } else { $process.ExitCode }
    TimedOut = $timedOut
    SessionId = if ($started) { [string]$started.thread_id } else { $SessionId }
    Final = $final.Trim()
    Errors = @($errors)
    Stderr = $stderr.Trim()
  }
}

function Test-InfrastructureFailure($Run) {
  if ($Run.TimedOut) { return $true }
  if ($Run.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($Run.Final)) { return $false }
  $combined = (@($Run.Errors) + @($Run.Stderr)) -join "`n"
  if ($Run.ExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($Run.Final)) { return $true }
  return $combined -match '401 Unauthorized|INVALID_API_KEY|authentication required|rate limit|timed out|connection|network|model.*not found'
}

function Get-InfrastructureReason($Run) {
  if ($Run.TimedOut) { return "Codex CLI exceeded ${TimeoutSeconds}s." }
  $combined = (@($Run.Errors) + @($Run.Stderr)) -join "`n"
  if ($combined.Length -gt 600) { $combined = $combined.Substring(0, 600) }
  if (-not [string]::IsNullOrWhiteSpace($combined)) { return $combined }
  return "Codex CLI exited with code $($Run.ExitCode) without a final response."
}

$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path
$SuiteRoot = if ([string]::IsNullOrWhiteSpace($SuiteRoot)) { $SkillRoot } else { (Resolve-Path -LiteralPath $SuiteRoot).Path }
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$testPath = Join-Path $SuiteRoot 'tests\behavior-cases.test.json'
$oraclePath = Join-Path $SuiteRoot 'tests\behavior-cases.oracle.json'
$schemaPath = Join-Path $SuiteRoot 'tests\review-result.schema.json'
$manifestCheck = Join-Path $SuiteRoot 'scripts\check_behavior_manifest.ps1'

& $manifestCheck -SkillRoot $SuiteRoot
if (-not $?) { throw 'Behavior manifest validation failed; runtime evaluation was not started.' }

$testSuite = Read-Json $testPath
$oracleSuite = Read-Json $oraclePath
$selected = @($testSuite.cases | Where-Object { $_.id -in $CaseIds })
foreach ($id in $CaseIds) {
  if ($id -notin @($selected.id)) { throw "Unknown case id: $id" }
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$userConfigPath = Join-Path $HOME '.codex\config.toml'
$runConfig = [ordered]@{
  schema_version = 1
  generated_at_utc = [DateTime]::UtcNow.ToString('o')
  skill_root = $SkillRoot
  suite_root = $SuiteRoot
  skill_md_sha256 = (Get-FileHash -LiteralPath (Join-Path $SkillRoot 'SKILL.md') -Algorithm SHA256).Hash.ToLowerInvariant()
  test_suite_sha256 = (Get-FileHash -LiteralPath $testPath -Algorithm SHA256).Hash.ToLowerInvariant()
  oracle_suite_sha256 = (Get-FileHash -LiteralPath $oraclePath -Algorithm SHA256).Hash.ToLowerInvariant()
  case_ids = @($CaseIds)
  model_override = $Model
  reasoning_effort_override = $ReasoningEffort
  timeout_seconds = $TimeoutSeconds
  use_user_config = [bool]$UseUserConfig
  disable_plugins = [bool]$DisablePlugins
  user_config_sha256 = if ($UseUserConfig -and (Test-Path -LiteralPath $userConfigPath)) { (Get-FileHash -LiteralPath $userConfigPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { $null }
}
Write-Utf8 (Join-Path $OutputRoot 'run-config.json') ($runConfig | ConvertTo-Json -Depth 5)
$summary = [System.Collections.Generic.List[object]]::new()

foreach ($case in $selected) {
  $caseDir = Join-Path $OutputRoot $case.id
  New-Item -ItemType Directory -Force -Path $caseDir | Out-Null
  $oracle = $oracleSuite.cases | Where-Object id -eq $case.id | Select-Object -First 1
  $transcript = [System.Collections.Generic.List[object]]::new()
  $infrastructureFailure = $false
  $sessionId = ''
  $turnNumber = 0
  $needsResume = @($case.visible_turns).Count + @($case.tool_event_ids).Count + @($case.post_event_turns).Count -gt 1

  $opening = @"
You are the test group evaluating one installed Skill. Start from this Skill source:
$SkillRoot\SKILL.md

You may read only the supporting references, templates, or scripts that this SKILL.md routes to. Do not read files under tests/, validation reports, release mirrors, or prior conversations.

This is a behavior simulation. Do not inspect the host machine for the simulated project's files or capabilities, and do not actually modify files, install software, use Git, publish, deploy, or contact external services. Treat later TEST TOOL EVENT messages as the result of the normal read, implementation, or verification action requested by the user. Do not expose these harness restrictions as a user permission problem, do not ask the user to lift them, and do not claim an action succeeded before its event. Artifact labels name only what the simulated project claims exists; do not claim their contents until a later event provides them.

Artifact labels: $((@($case.artifact_labels) | ConvertTo-Json -Compress))

Respond to the user naturally as Codex using the Skill. Do not discuss this evaluation harness.

USER:
$($case.visible_turns[0])
"@

  $turnNumber++
  $run = Invoke-CodexTurn -Prompt $opening -RunDirectory $caseDir -Prefix ("test-{0:d2}" -f $turnNumber) -Ephemeral:(-not $needsResume)
  $sessionId = $run.SessionId
  $transcript.Add([pscustomobject]@{ turn = $turnNumber; input_type = 'user'; input = $case.visible_turns[0]; response = $run.Final })
  if (Test-InfrastructureFailure $run) { $infrastructureFailure = $true }

  if (-not $infrastructureFailure) {
    for ($i = 1; $i -lt @($case.visible_turns).Count; $i++) {
      $turnNumber++
      $run = Invoke-CodexTurn -Prompt ("USER:`n" + $case.visible_turns[$i]) -RunDirectory $caseDir -Prefix ("test-{0:d2}" -f $turnNumber) -SessionId $sessionId
      $transcript.Add([pscustomobject]@{ turn = $turnNumber; input_type = 'user'; input = $case.visible_turns[$i]; response = $run.Final })
      if (Test-InfrastructureFailure $run) { $infrastructureFailure = $true; break }
    }
  }

  if (-not $infrastructureFailure) {
    foreach ($eventId in @($case.tool_event_ids)) {
      $event = $oracle.tool_events.PSObject.Properties[$eventId]
      if ($null -eq $event) { continue }
      $turnNumber++
      $eventPrompt = "TEST TOOL EVENT $eventId (simulated read-only observation; use only from this turn onward):`n$($event.Value)"
      $run = Invoke-CodexTurn -Prompt $eventPrompt -RunDirectory $caseDir -Prefix ("test-{0:d2}" -f $turnNumber) -SessionId $sessionId
      $transcript.Add([pscustomobject]@{ turn = $turnNumber; input_type = 'tool_event'; input = $eventId; event = $event.Value; response = $run.Final })
      if (Test-InfrastructureFailure $run) { $infrastructureFailure = $true; break }

      foreach ($postTurn in @($case.post_event_turns | Where-Object after -eq $eventId)) {
        $turnNumber++
        $run = Invoke-CodexTurn -Prompt ("USER:`n" + $postTurn.text) -RunDirectory $caseDir -Prefix ("test-{0:d2}" -f $turnNumber) -SessionId $sessionId
        $transcript.Add([pscustomobject]@{ turn = $turnNumber; input_type = 'user'; input = $postTurn.text; response = $run.Final })
        if (Test-InfrastructureFailure $run) { $infrastructureFailure = $true; break }
      }
      if ($infrastructureFailure) { break }
    }
  }

  $transcriptPath = Join-Path $caseDir 'transcript.json'
  Write-Utf8 $transcriptPath ($transcript | ConvertTo-Json -Depth 8)

  if ($infrastructureFailure) {
    $summary.Add([pscustomobject]@{ case_id = $case.id; priority = $case.priority; status = 'InfrastructureFailure'; result = $null; first_divergent_turn = $null; report = $null; infrastructure_reason = (Get-InfrastructureReason $run) })
    continue
  }

  $reviewPrompt = @"
You are the independent check group. Judge only the observed transcript against the supplied Oracle. Do not improve or rewrite the test response. Missing evidence is not success. A hard failure makes the result Fail. Partial means at least one material assertion is unmet without a hard failure. Return only JSON matching the provided schema.

CASE ID: $($case.id)
STOP CONDITION: $($case.stop_condition)
ASSERTIONS:
$((@($oracle.assertions) | ConvertTo-Json -Depth 5))
HARD FAILURES:
$((@($oracle.hard_failures) | ConvertTo-Json -Depth 5))
OBSERVED TRANSCRIPT:
$(Get-Content -LiteralPath $transcriptPath -Raw -Encoding UTF8)
"@
  $review = Invoke-CodexTurn -Prompt $reviewPrompt -RunDirectory $caseDir -Prefix 'review' -SchemaPath $schemaPath -Ephemeral
  if (Test-InfrastructureFailure $review) {
    $summary.Add([pscustomobject]@{ case_id = $case.id; priority = $case.priority; status = 'InfrastructureFailure'; result = $null; first_divergent_turn = $null; report = $null; infrastructure_reason = (Get-InfrastructureReason $review) })
    continue
  }

  $reviewPath = Join-Path $caseDir 'review.json'
  Write-Utf8 $reviewPath $review.Final
  try {
    $reviewResult = $review.Final | ConvertFrom-Json
    $summary.Add([pscustomobject]@{ case_id = $case.id; priority = $case.priority; status = 'Evaluated'; result = $reviewResult.result; first_divergent_turn = $reviewResult.first_divergent_turn; report = $reviewPath })
  } catch {
    $summary.Add([pscustomobject]@{ case_id = $case.id; priority = $case.priority; status = 'ReviewerOutputInvalid'; result = $null; first_divergent_turn = $null; report = $reviewPath })
  }
}

$summaryPath = Join-Path $OutputRoot 'summary.json'
Write-Utf8 $summaryPath (ConvertTo-Json -InputObject @($summary) -Depth 8)

'Behavior runtime evaluation complete.'
"Output: $OutputRoot"
$summary | Format-Table case_id, priority, status, result, first_divergent_turn -AutoSize

if (@($summary | Where-Object { $_.status -ne 'Evaluated' -or $_.result -ne 'Pass' }).Count -gt 0) { exit 2 }
exit 0
