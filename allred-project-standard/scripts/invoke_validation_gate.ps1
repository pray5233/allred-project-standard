param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [Parameter(Mandatory = $true)]
  [ValidateSet('DECISION', 'READY', 'EXECUTION')]
  [string]$ToStage,
  [string]$ExecutionRecordPath = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding
. (Join-Path $PSScriptRoot 'state_validation_common.ps1')

function Get-AllredPowerShellExecutable {
  $current = (Get-Process -Id $PID).Path
  if (-not [string]::IsNullOrWhiteSpace($current) -and (Test-Path -LiteralPath $current -PathType Leaf)) {
    return $current
  }

  foreach ($name in @('pwsh', 'powershell')) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($null -ne $command) { return $command.Source }
  }
  throw 'No PowerShell executable is available for isolated validator execution.'
}

function Resolve-AllredExecutionRecordPath {
  param([string]$StatePath, [string]$ExplicitPath)

  $candidate = $ExplicitPath
  if ([string]::IsNullOrWhiteSpace($candidate)) {
    $state = Read-AllredProjectState -Path $StatePath
    $preflight = Get-AllredProperty $state 'preflight'
    $record = Get-AllredProperty $preflight 'execution_record'
    $candidate = [string](Get-AllredProperty $record 'path')
  }
  if ([string]::IsNullOrWhiteSpace($candidate)) {
    throw 'READY and EXECUTION require preflight.execution_record.path or -ExecutionRecordPath.'
  }

  if (-not (Test-AllredAbsolutePath -Path $candidate)) {
    $candidate = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $StatePath).Path) $candidate
  }
  return (Resolve-Path -LiteralPath $candidate).Path
}

function Invoke-AllredValidatorProcess {
  param(
    [string]$Name,
    [string]$ScriptPath,
    [string[]]$Arguments,
    [string]$PowerShellExecutable
  )

  if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    return [pscustomobject]@{ Name = $Name; ExitCode = 1; Output = @("Validator not found: $ScriptPath") }
  }

  $processArguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $Arguments
  $output = @(& $PowerShellExecutable @processArguments 2>&1 | ForEach-Object { [string]$_ })
  $exitCode = $LASTEXITCODE
  return [pscustomobject]@{ Name = $Name; ExitCode = $exitCode; Output = $output }
}

$results = [System.Collections.Generic.List[object]]::new()
$powerShellExecutable = Get-AllredPowerShellExecutable
$statePath = (Resolve-Path -LiteralPath $Path).Path

$results.Add((Invoke-AllredValidatorProcess -Name 'stage-transition' -ScriptPath (Join-Path $PSScriptRoot 'validate_stage_transition.ps1') -Arguments @('-Path', $statePath, '-ToStage', $ToStage) -PowerShellExecutable $powerShellExecutable)) | Out-Null
$results.Add((Invoke-AllredValidatorProcess -Name 'decision-frontier' -ScriptPath (Join-Path $PSScriptRoot 'validate_decision_frontier.ps1') -Arguments @('-Path', $statePath) -PowerShellExecutable $powerShellExecutable)) | Out-Null

if ($ToStage -in @('READY', 'EXECUTION')) {
  $results.Add((Invoke-AllredValidatorProcess -Name 'discovery-coverage' -ScriptPath (Join-Path $PSScriptRoot 'validate_discovery_coverage.ps1') -Arguments @('-Path', $statePath) -PowerShellExecutable $powerShellExecutable)) | Out-Null
  try {
    $recordPath = Resolve-AllredExecutionRecordPath -StatePath $statePath -ExplicitPath $ExecutionRecordPath
    $results.Add((Invoke-AllredValidatorProcess -Name 'execution-record' -ScriptPath (Join-Path $PSScriptRoot 'validate_execution_record.ps1') -Arguments @('-Path', $recordPath) -PowerShellExecutable $powerShellExecutable)) | Out-Null
    $results.Add((Invoke-AllredValidatorProcess -Name 'decision-coverage' -ScriptPath (Join-Path $PSScriptRoot 'validate_decision_coverage.ps1') -Arguments @('-Path', $recordPath) -PowerShellExecutable $powerShellExecutable)) | Out-Null
  } catch {
    $results.Add([pscustomobject]@{ Name = 'execution-record-path'; ExitCode = 1; Output = @($_.Exception.Message) }) | Out-Null
  }

  $results.Add((Invoke-AllredValidatorProcess -Name 'ready-scope' -ScriptPath (Join-Path $PSScriptRoot 'validate_ready_scope.ps1') -Arguments @('-Path', $statePath) -PowerShellExecutable $powerShellExecutable)) | Out-Null
  $results.Add((Invoke-AllredValidatorProcess -Name 'change-traceability' -ScriptPath (Join-Path $PSScriptRoot 'validate_change_traceability.ps1') -Arguments @('-Path', $statePath) -PowerShellExecutable $powerShellExecutable)) | Out-Null
}

$failed = @($results | Where-Object { $_.ExitCode -ne 0 })
foreach ($result in $results) {
  $status = if ($result.ExitCode -eq 0) { 'PASS' } else { 'FAIL' }
  "[$status] $($result.Name)"
  foreach ($line in @($result.Output)) { "  $line" }
}

if ($failed.Count -gt 0) {
  'Allred validation gate: FAIL'
  "Target stage: $ToStage"
  "Failed validators: $($failed.Name -join ', ')"
  exit 1
}

'Allred validation gate: PASS'
"Target stage: $ToStage"
"Validators completed: $($results.Count)"
