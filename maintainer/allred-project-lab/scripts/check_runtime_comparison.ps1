param(
  [string]$OutputRoot = (Join-Path ([IO.Path]::GetTempPath()) ('allred-comparison-check-' + [Guid]::NewGuid().ToString('N'))),
  [string]$StandardRoot = ''
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $OutputRoot) { throw 'Use a new output directory.' }
$lab = Split-Path -Parent $PSScriptRoot
$parent = Split-Path -Parent $lab
if (-not $StandardRoot) {
  $StandardRoot = @((Join-Path $parent 'allred-project-standard'),(Join-Path (Split-Path -Parent $parent) 'allred-project-standard')) |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ 'SKILL.md') } | Select-Object -First 1
}
if (-not $StandardRoot) { throw 'Supply StandardRoot for this layout.' }
$standard = Join-Path $OutputRoot 'input-standard'
[void][IO.Directory]::CreateDirectory($OutputRoot)
Copy-Item -LiteralPath $StandardRoot -Destination $standard -Recurse
$runner = Join-Path $PSScriptRoot 'run_runtime_comparison.ps1'
$ps = (Get-Process -Id $PID).Path
$checks = [Collections.Generic.List[object]]::new()
function Check($Name, $Condition) {
  $checks.Add([pscustomobject]@{name=$Name;passed=[bool]$Condition})
  if (-not $Condition) { throw "Comparison contract failed: $Name" }
}
$prepared = Join-Path $OutputRoot 'prepared'
$output = & $ps -NoProfile -File $runner -BaselineSkillRoot $standard -CandidateSkillRoot $standard -CaseIds A01 -OutputRoot $prepared -PrepareOnly
Check 'prepare-without-model' ($LASTEXITCODE -eq 0)
$sourceSuite = Get-Content -LiteralPath (Join-Path $lab 'tests/runtime-dialogues.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$original = $sourceSuite.cases | Where-Object id -eq 'A01'
$suite = Get-Content -LiteralPath (Join-Path $prepared 'suite.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Check 'selected-cases-only' ($suite.cases.Count -eq 1 -and $suite.cases[0].id -eq 'A01')
Check 'outcome-scope-explicit' ($suite.evaluation_scope -eq 'outcome-only')
Check 'original-suite-scope-unchanged' (-not ($sourceSuite.PSObject.Properties.Name -contains 'evaluation_scope'))
Check 'user-turns-unchanged' (($original.turns | ConvertTo-Json -Compress) -ceq ($suite.cases[0].turns | ConvertTo-Json -Compress))
Check 'material-bytes-unchanged' (($original.files | ConvertTo-Json -Compress) -ceq ($suite.cases[0].files | ConvertTo-Json -Compress))
Check 'outcome-contract-no-runtime-call-requirement' (($suite.cases[0].assertions -join ' ') -notmatch 'must invoke|run the actual READY|Use existing-debug')
$config = Get-Content -LiteralPath (Join-Path $prepared 'comparison.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Check 'manifest-hashes-match' (@($config.files | Where-Object { (Get-FileHash -LiteralPath (Join-Path $prepared $_.path)).Hash -ne $_.sha256 }).Count -eq 0)
Check 'no-model-evidence-created' (@(Get-ChildItem -LiteralPath $prepared -Filter '*.events.jsonl' -Recurse).Count -eq 0)
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$output = @(& $ps -NoProfile -File $runner -BaselineSkillRoot $standard -CaseIds A01 -OutputRoot $prepared -PrepareOnly 2>&1 | ForEach-Object { [string]$_ })
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previous
Check 'existing-evidence-rejected' ($exitCode -ne 0 -and ($output -join ' ') -match 'do not overwrite')
# Synthetic completion fixtures validate failure accounting without model calls.
# Change only the disposable input copy after freezing, as an editor could do.
[IO.File]::AppendAllText((Join-Path $standard 'VERSION'), '-fixture-change')
foreach ($arm in @('baseline','candidate','native')) {
  $armRoot = Join-Path $prepared $arm
  $runtime = Join-Path $armRoot 'runtime-snapshot'
  $harness = Join-Path $armRoot 'harness-snapshot'
  New-Item -ItemType Directory -Path $runtime,$harness -Force | Out-Null
  $frozenSource = Join-Path $prepared $(if ($arm -eq 'baseline') { 'baseline-source' } else { 'candidate-source' })
  foreach ($name in @('SKILL.md','VERSION','agents','references','scripts','templates')) { Copy-Item -LiteralPath (Join-Path $frozenSource $name) -Destination $runtime -Recurse }
  Copy-Item -LiteralPath (Join-Path $prepared 'suite.json') -Destination $harness
  $manifest = [ordered]@{
    instruction_mode=$(if ($arm -eq 'native') { 'Native' } else { 'Skill' })
    files=@(Get-ChildItem $runtime -File -Recurse | ForEach-Object { @{path=$_.FullName.Substring($runtime.Length+1);sha256=(Get-FileHash $_.FullName).Hash} })
    harness_files=@(@{path='suite.json';sha256=(Get-FileHash (Join-Path $harness 'suite.json')).Hash})
  }
  [IO.File]::WriteAllText((Join-Path $armRoot 'manifest.json'),($manifest | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText((Join-Path $armRoot 'summary.json'),'[{"case_id":"A01","status":"Evaluated","result":"Fail"}]',[Text.UTF8Encoding]::new($false))
}
$workers = @('baseline','candidate','native') | ForEach-Object { @{arm=$_;exit_code=1} }
[IO.File]::WriteAllText((Join-Path $prepared 'workers.json'),(ConvertTo-Json -InputObject @($workers)),[Text.UTF8Encoding]::new($false))
$output = & $ps -NoProfile -File $runner -OutputRoot $prepared -ValidateEvidenceOnly
Check 'behavior-failure-is-valid-evidence' ($LASTEXITCODE -eq 0 -and ($output -join ' ') -match 'not behavioral acceptance')
Check 'live-edits-do-not-change-frozen-fixtures' ((Get-FileHash (Join-Path $standard 'VERSION')).Hash -ne (Get-FileHash (Join-Path $prepared 'baseline/runtime-snapshot/VERSION')).Hash)
function Reject-Evidence($Name,$Pattern) {
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $output = @(& $ps -NoProfile -File $runner -OutputRoot $prepared -ValidateEvidenceOnly 2>&1 | ForEach-Object { [string]$_ })
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previous
  Check $Name ($exitCode -ne 0 -and ($output -join ' ') -match $Pattern)
}
$summaryPath = Join-Path $prepared 'candidate/summary.json'
$summaryText = [IO.File]::ReadAllText($summaryPath)
[IO.File]::WriteAllText($summaryPath,'[]')
Reject-Evidence 'missing-case-rejected' 'Incomplete case accounting'
[IO.File]::WriteAllText($summaryPath,'[{"case_id":"A01","status":"Evaluated","result":"Pass"}]')
Reject-Evidence 'worker-crash-cannot-look-like-pass' 'Worker exit disagrees'
[IO.File]::WriteAllText($summaryPath,$summaryText)
$runtimeFile = Join-Path $prepared 'candidate/runtime-snapshot/VERSION'
$runtimeBytes = [IO.File]::ReadAllBytes($runtimeFile)
[IO.File]::AppendAllText($runtimeFile,'tamper')
Reject-Evidence 'changed-runtime-snapshot-rejected' 'Evidence snapshot changed'
[IO.File]::WriteAllBytes($runtimeFile,$runtimeBytes)
$harnessFile = Join-Path $prepared 'candidate/harness-snapshot/suite.json'
$harnessBytes = [IO.File]::ReadAllBytes($harnessFile)
[IO.File]::AppendAllText($harnessFile,'tamper')
Reject-Evidence 'changed-harness-snapshot-rejected' 'Evidence snapshot changed'
[IO.File]::WriteAllBytes($harnessFile,$harnessBytes)
. (Join-Path $PSScriptRoot 'config_equivalence.ps1')
$fixtureConfig = Join-Path $OutputRoot 'config-fixture.toml'
$fixturePaths = @((Join-Path $OutputRoot 'fixture-a/workspace'),(Join-Path $OutputRoot 'fixture-b/workspace'))
$baseConfig = 'model = "fixture"' + "`n`n"
$registrations = @($fixturePaths | ForEach-Object { "[projects.'$_']`ntrust_level = `"trusted`"`n`n" })
[IO.File]::WriteAllText($fixtureConfig,$baseConfig,[Text.UTF8Encoding]::new($false))
$baseHash = (Get-FileHash $fixtureConfig).Hash
[IO.File]::WriteAllText($fixtureConfig,($baseConfig + $registrations[0]),[Text.UTF8Encoding]::new($false))
$oneHash = (Get-FileHash $fixtureConfig).Hash
$completeConfig = $baseConfig + ($registrations -join '')
[IO.File]::WriteAllText($fixtureConfig,$completeConfig,[Text.UTF8Encoding]::new($false))
$currentHash = (Get-FileHash $fixtureConfig).Hash
$proof = Get-AllredConfigTrustEquivalence -ConfigPath $fixtureConfig -KnownHashes @($baseHash,$oneHash) -WorkspacePaths $fixturePaths
Check 'fixture-trust-only-equivalence-proven' ($proof.matches.Count -eq 2 -and $proof.source_sha256 -eq $currentHash)
Check 'config-equivalence-does-not-write-config' ((Get-FileHash $fixtureConfig).Hash -eq $currentHash)
function Reject-Config($Name,$Contents,$AllowedPaths) {
  [IO.File]::WriteAllText($fixtureConfig,$Contents,[Text.UTF8Encoding]::new($false))
  $rejected = $false
  try { $null = Get-AllredConfigTrustEquivalence -ConfigPath $fixtureConfig -KnownHashes @($baseHash,$oneHash) -WorkspacePaths $AllowedPaths }
  catch { $rejected = $_.Exception.Message -match 'equivalence unproven' }
  Check $Name $rejected
}
Reject-Config 'model-change-cannot-be-ignored' ($completeConfig.Replace('model = "fixture"','model = "different"')) $fixturePaths
Reject-Config 'unrelated-project-trust-cannot-be-ignored' $completeConfig @($fixturePaths[0])
Reject-Config 'extra-project-setting-cannot-be-ignored' ($completeConfig.Replace('trust_level = "trusted"',"trust_level = `"trusted`"`nsandbox_mode = `"read-only`"")) $fixturePaths
# Tamper only with the disposable test snapshot, never a real comparison.
[IO.File]::AppendAllText((Join-Path $prepared 'candidate-source/VERSION'), 'tamper',[Text.UTF8Encoding]::new($false))
$ErrorActionPreference = 'Continue'
$output = @(& $ps -NoProfile -File $runner -OutputRoot $prepared -CompareOnly 2>&1 | ForEach-Object { [string]$_ })
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previous
Check 'tampered-input-rejected-before-model' ($exitCode -ne 0 -and ($output -join ' ') -match 'Frozen input changed')
[IO.File]::WriteAllText((Join-Path $OutputRoot 'checks.json'),(ConvertTo-Json -InputObject @($checks)),[Text.UTF8Encoding]::new($false))
"Comparison contracts: PASS ($($checks.Count) deterministic checks; no behavioral acceptance)"
