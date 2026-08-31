param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$testPath = Join-Path $SkillRoot 'tests\behavior-cases.test.json'
$oraclePath = Join-Path $SkillRoot 'tests\behavior-cases.oracle.json'
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { $script:failures.Add("Missing: $Path") | Out-Null; return $null }
  try { Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch { $script:failures.Add("Invalid JSON: $Path") | Out-Null; return $null }
}

$test = Read-Json $testPath
$oracle = Read-Json $oraclePath
if ($test -and $oracle) {
  $testIds = @($test.cases.id)
  $oracleIds = @($oracle.cases.id)
  foreach ($id in $testIds) { if ($id -notin $oracleIds) { $failures.Add("Missing oracle: $id") | Out-Null } }
  foreach ($id in $oracleIds) { if ($id -notin $testIds) { $failures.Add("Oracle-only case: $id") | Out-Null } }
  foreach ($case in @($test.cases)) {
    if (@($case.visible_turns).Count -eq 0 -or @($case.modules).Count -eq 0 -or [string]::IsNullOrWhiteSpace($case.stop_condition)) {
      $failures.Add("Incomplete case: $($case.id)") | Out-Null
    }
    $expected = $oracle.cases | Where-Object id -eq $case.id | Select-Object -First 1
    if ($expected -and (@($expected.assertions).Count -eq 0 -or @($expected.hard_failures).Count -eq 0)) {
      $failures.Add("Incomplete oracle: $($case.id)") | Out-Null
    }
  }
}

if ($failures.Count -gt 0) {
  'Lab behavior manifest: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}
'Lab behavior manifest: PASS'
"Cases: $(@($test.cases).Count)"
