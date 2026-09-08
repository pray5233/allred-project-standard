param(
  [string]$StandardRoot = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'allred-project-standard'),
  [string]$OutputRoot = (Join-Path ([System.IO.Path]::GetTempPath()) ('allred-builder-tests-' + [guid]::NewGuid().ToString('N')))
)
$ErrorActionPreference = 'Stop'
$shell = (Get-Process -Id $PID).Path
$null = New-Item -ItemType Directory -Path $OutputRoot -Force
$OutputRoot = (Resolve-Path -LiteralPath $OutputRoot).Path
$builder = Join-Path $StandardRoot 'scripts/build_start_record.ps1'
$gate = Join-Path $StandardRoot 'scripts/invoke_validation_gate.ps1'
$results = [System.Collections.Generic.List[object]]::new()
function Save($Path, $Value) { [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 60), [System.Text.UTF8Encoding]::new($false)) }
function Check([string]$Name, [bool]$Passed) {
  $results.Add([pscustomobject]@{name=$Name; passed=$Passed})
  if (-not $Passed) { throw "Failed: $Name" }
}
function Run([string]$Script, [string[]]$Arguments) {
  $previous = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = @(& $shell -NoProfile -NonInteractive -File $Script @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $code = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previous }
  return [pscustomobject]@{code=$code; text=($output -join "`n")}
}
function Fixture {
  $s = Get-Content -Raw -Encoding UTF8 (Join-Path $StandardRoot 'tests/project-state.valid-ready.json') | ConvertFrom-Json
  $s.write_boundary.project_root = Join-Path $OutputRoot 'product'
  $s.write_boundary.allowed_write_roots = @($s.write_boundary.project_root)
  $s.write_boundary.planned_paths = @(Join-Path $s.write_boundary.project_root 'main.txt')
  $s.write_boundary.read_only_inputs = @(Join-Path $OutputRoot 'original.txt')
  $s.user_sources[0].meaning = "Literal | table value`n## not a heading"
  $plan = [pscustomobject]@{
    target_environment='Synthetic test environment, no product execution'
    scope_steps=@($s.scope | ForEach-Object { [pscustomobject]@{scope_id=$_.id; target=$s.write_boundary.planned_paths[0]; proof=('Observe exact requirement for ' + $_.id)} })
    files=@([pscustomobject]@{path=$s.write_boundary.planned_paths[0]; action='create'; purpose='Synthetic plan only'; scope_ids=@($s.scope.id)})
    commands=@([pscustomobject]@{command='None'; effect='No process started'; proof='Synthetic plan only'})
    mutations=@(@('Development-time', 'Runtime', 'External/system') | ForEach-Object { [pscustomobject]@{layer=$_; target='None'; effect='Synthetic test; no effect'; basis=@('U1'); rollback='No product changes'} })
    effects_review=[pscustomobject]@{complete=$true; hidden_recommendations=@(); hidden_behaviors=@(); hidden_effects=@(); surfaced='Fixture recommendation remains pending in the final scope'}
  }
  $s | Add-Member -NotePropertyName execution_plan -NotePropertyValue $plan
  return $s
}
function Build($State, [string]$Name) {
  $path = Join-Path $OutputRoot "$Name.input.json"
  Save $path $State
  $hash = (Get-FileHash -LiteralPath $path).Hash
  $evidence = switch ($Name) {
    'evidence-product' { $State.write_boundary.project_root }
    'evidence-protected' { $State.write_boundary.read_only_inputs[0] }
    'evidence-wildcard' { Join-Path $OutputRoot '*' }
    'evidence-relative' { './internal-evidence' }
    default { Join-Path $OutputRoot 'internal-evidence' }
  }
  Push-Location $OutputRoot
  try { $r = Run $builder @('-StatePath', $path, '-EvidenceRoot', $evidence) } finally { Pop-Location }
  [System.IO.File]::WriteAllText((Join-Path $OutputRoot "$Name.log"), $r.text)
  Check "$Name input unchanged" ((Get-FileHash -LiteralPath $path).Hash -eq $hash)
  return $r
}

$draft = Run $gate @('-Path', (Join-Path $StandardRoot 'templates/project-state.draft.json'), '-ToStage', 'READY')
Check 'neutral draft is not READY' ($draft.code -ne 0)
$s = Fixture
$r = Build $s 'valid'
Check 'valid construction' ($r.code -eq 0)
$path = [regex]::Match($r.text, '(?m)^StatePath: (.+)$').Groups[1].Value.Trim()
Check 'returned state exists' (Test-Path -LiteralPath $path)
Check 'explicit evidence root is respected' ($path.StartsWith((Join-Path $OutputRoot 'internal-evidence') + [IO.Path]::DirectorySeparatorChar))
$generated = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
Check 'authorization stays pending' ($generated.authorization.state -eq 'pending' -and $null -eq $generated.authorization.approval_source)
Check 'technical certainty stays candidate' ($generated.technical_conclusions[0].status -eq 'candidate')
Check 'no product directory' (-not (Test-Path -LiteralPath $s.write_boundary.project_root))
$record = Get-Content -LiteralPath $generated.preflight.execution_record.path -Raw -Encoding UTF8
Check 'table and heading injection escaped' ($record.Contains('Literal &#124; table value<br>## not a heading') -and $record -notmatch '(?m)^## not a heading')
Check 'recommendation and direct scope are retained' ($record.Contains('P-S3') -and $record.Contains('recommended') -and $record.Contains('pending start'))
$copy = $generated | ConvertTo-Json -Depth 60 | ConvertFrom-Json
$copy.preflight.execution_record = $s.preflight.execution_record
Check 'all non-record state fields preserved' (($copy | ConvertTo-Json -Depth 60 -Compress) -ceq ($s | ConvertTo-Json -Depth 60 -Compress))
$ready = Run $gate @('-Path', $path, '-ToStage', 'READY')
[System.IO.File]::WriteAllText((Join-Path $OutputRoot 'valid-ready.log'), $ready.text)
Check 'actual aggregate READY accepts valid synthetic state' ($ready.code -eq 0)
Check 'direct READY includes intake and frontier checks' ($ready.text -match '\[PASS\] stage-transition' -and $ready.text -match '\[PASS\] decision-frontier')
$execution = Run $gate @('-Path', $path, '-ToStage', 'EXECUTION')
Check 'actual EXECUTION refuses pending authorization' ($execution.code -ne 0 -and $execution.text -match 'not been approved')

foreach ($name in @('missing-step','unknown-step','duplicate-step','outside-file','relative-plan','protected-file','review-open','review-hidden','review-missing','approved','delta','missing-source','evidence-product','evidence-protected','evidence-wildcard')) {
  $s = Fixture
  switch ($name) {
    'missing-step' { $s.execution_plan.scope_steps = @($s.execution_plan.scope_steps | Select-Object -Skip 1) }
    'unknown-step' { $s.execution_plan.scope_steps[0].scope_id = 'S-missing' }
    'duplicate-step' { $s.execution_plan.scope_steps += $s.execution_plan.scope_steps[0] }
    'outside-file' { $s.execution_plan.files[0].path = Join-Path $OutputRoot 'outside.txt' }
    'relative-plan' { $s.write_boundary.planned_paths = @('main.txt') }
    'protected-file' { $s.write_boundary.read_only_inputs = @($s.execution_plan.files[0].path) }
    'review-open' { $s.execution_plan.effects_review.complete = $false }
    'review-hidden' { $s.execution_plan.effects_review.hidden_effects = @('undeclared effect') }
    'review-missing' { $s.execution_plan.effects_review.PSObject.Properties.Remove('hidden_behaviors') }
    'approved' { $s.authorization.state = 'approved' }
    'delta' { $s.change_control.mode = 'delta' }
    'missing-source' { $s.scope[0].provenance = @('U-missing') }
  }
  $r = Build $s $name
  Check "$name rejected by builder" ($r.code -ne 0)
}
$relative = Build (Fixture) 'evidence-relative'
Check 'relative CLI evidence argument is normalized' ($relative.code -eq 0 -and $relative.text.Contains((Join-Path $OutputRoot 'internal-evidence')))
foreach ($name in @('coverage-open','preflight-open','unknown-question','open-decision')) {
  $s = Fixture
  switch ($name) {
    'coverage-open' { $s.discovery_coverage.status = 'open' }
    'preflight-open' { $s.preflight.status = 'open' }
    'unknown-question' { $s | Add-Member -NotePropertyName questions -NotePropertyValue @([pscustomobject]@{id='Q1'; status='unknown'; source='U1'; remaining_facets=@('future volume')}) }
    'open-decision' { $s.decisions += [pscustomobject]@{id='D4'; axis='unresolved-axis'; status='open'; choice=''; authority='required'; depends_on=@(); exposed=$false; trigger='user:U1'; approval_source=$null; recommendation=$null} }
  }
  $r = Build $s $name
  Check "$name construction preserves state" ($r.code -eq 0)
  $path = [regex]::Match($r.text, '(?m)^StatePath: (.+)$').Groups[1].Value.Trim()
  $g = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($name -eq 'unknown-question') { Check 'unknown fact is not replaced' ($g.questions[0].status -eq 'unknown'); continue }
  $r = Run $gate @('-Path', $path, '-ToStage', 'READY')
  Check "$name remains blocked at actual READY" ($r.code -ne 0)
}
Save (Join-Path $OutputRoot 'summary.json') @($results)
"Start record builder contracts: PASS ($($results.Count) assertions; synthetic unit tests, not model behavior evidence)"
"Evidence: $OutputRoot"
