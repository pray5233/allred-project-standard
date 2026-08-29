param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
# Validates manifest integrity and declared coverage only; it never invokes Codex.
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) {
  $script:failures.Add($Message) | Out-Null
}

function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    Add-Failure "Missing suite file: $Path"
    return $null
  }

  try {
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Add-Failure "Invalid JSON in ${Path}: $($_.Exception.Message)"
    return $null
  }
}

$testPath = Join-Path $SkillRoot 'tests\behavior-cases.test.json'
$oraclePath = Join-Path $SkillRoot 'tests\behavior-cases.oracle.json'
$testSuite = Read-Json $testPath
$oracleSuite = Read-Json $oraclePath

$requiredCoverage = [ordered]@{
  'activation-routing' = 4
  'interaction-confirmation' = 8
  'new-project' = 6
  'beginner' = 5
  'materials-evidence' = 7
  'classification-strategy' = 3
  'benchmark-capability' = 5
  'runtime-delivery' = 3
  'public-monitoring' = 2
  'stage-routing' = 2
  'debugging' = 4
  'new-feature' = 2
  'ui-optimization' = 2
  'acceptance-review' = 1
  'long-term' = 4
  'evidence-level' = 1
  'write-boundary' = 3
  'skill-improvement' = 1
  'execution-closure' = 10
  'workflow-efficiency' = 6
  'memory-notes-boundary' = 1
  'adaptive-alignment' = 17
  'external-content-safety' = 4
  'semantic-sampling' = 3
  'non-software-project' = 6
  'training-project' = 1
  'policy-document' = 1
  'knowledge-base' = 1
  'bid-document' = 1
  'contract-document' = 1
  'inspection-record' = 1
  'training-alignment' = 3
  'adaptive-interview' = 3
  'gray-area-map' = 2
  'question-packet' = 4
  'decision-coverage' = 4
  'question-decision-separation' = 3
  'frontier-routing' = 5
  'skill-discovery-gate' = 4
  'optional-dependency-routing' = 5
  'existing-project' = 3
  'change-traceability' = 2
  'regression-baseline' = 1
}

if ($testSuite -and $oracleSuite) {
  if ($testSuite.schema_version -ne 1 -or $oracleSuite.schema_version -ne 1) {
    Add-Failure 'Unsupported behavior suite schema version.'
  }

  $testCases = @($testSuite.cases)
  $oracleCases = @($oracleSuite.cases)
  if ($testCases.Count -eq 0) {
    Add-Failure 'Test-group suite contains no cases.'
  }

  $duplicateTestIds = $testCases | Group-Object id | Where-Object Count -gt 1
  $duplicateOracleIds = $oracleCases | Group-Object id | Where-Object Count -gt 1
  foreach ($group in $duplicateTestIds) { Add-Failure "Duplicate test case id: $($group.Name)" }
  foreach ($group in $duplicateOracleIds) { Add-Failure "Duplicate oracle case id: $($group.Name)" }

  $testIds = @($testCases.id | Sort-Object)
  $oracleIds = @($oracleCases.id | Sort-Object)
  foreach ($id in $testIds) {
    if ($id -notin $oracleIds) { Add-Failure "Missing oracle case: $id" }
  }
  foreach ($id in $oracleIds) {
    if ($id -notin $testIds) { Add-Failure "Oracle-only case: $id" }
  }

  $testRaw = Get-Content -LiteralPath $testPath -Raw -Encoding UTF8
  foreach ($forbidden in @('"assertions"', '"hard_failures"', '"expected_answer"', '"root_cause"', '"max_decision_turns"', '"expected_authorization_gates"')) {
    if ($testRaw.Contains($forbidden)) {
      Add-Failure "Test-group suite leaks checker field: $forbidden"
    }
  }

  foreach ($case in $testCases) {
    if ([string]::IsNullOrWhiteSpace($case.id)) { Add-Failure 'A test case has no id.'; continue }
    if ($case.priority -notin @('P0', 'P1')) { Add-Failure "Invalid priority for $($case.id): $($case.priority)" }
    if (@($case.modules).Count -eq 0) { Add-Failure "Case has no module coverage: $($case.id)" }
    if (@($case.visible_turns).Count -eq 0) { Add-Failure "Case has no visible user turn: $($case.id)" }
    if ([string]::IsNullOrWhiteSpace($case.stop_condition)) { Add-Failure "Case has no stop condition: $($case.id)" }

    if ('workflow-efficiency' -in @($case.modules)) {
      if (@($case.forbidden_questions).Count -eq 0) {
        Add-Failure "Efficiency case needs forbidden_questions: $($case.id)"
      }
    }

    if ($null -ne $case.post_event_turns) {
      foreach ($turn in @($case.post_event_turns)) {
        if ([string]::IsNullOrWhiteSpace($turn.text)) { Add-Failure "Post-event turn has no text: $($case.id)" }
        if ($turn.after -notin @($case.tool_event_ids)) {
          Add-Failure "Post-event turn references unknown event '$($turn.after)' in $($case.id)"
        }
      }
    }

    foreach ($module in @($case.modules)) {
      if (-not $requiredCoverage.Contains($module)) {
        Add-Failure "Unknown module '$module' in $($case.id)"
      }
    }

    $oracle = $oracleCases | Where-Object id -eq $case.id | Select-Object -First 1
    if ($oracle) {
      if (@($oracle.assertions).Count -eq 0) { Add-Failure "Oracle has no assertions: $($case.id)" }
      if (@($oracle.hard_failures).Count -eq 0) { Add-Failure "Oracle has no hard failures: $($case.id)" }

      foreach ($eventId in @($case.tool_event_ids)) {
        $eventNames = @($oracle.tool_events.PSObject.Properties.Name)
        if ($eventId -notin $eventNames) {
          Add-Failure "Missing tool event '$eventId' in oracle case $($case.id)"
        }
      }
    }
  }

  foreach ($module in $requiredCoverage.Keys) {
    $count = @($testCases | Where-Object { $module -in @($_.modules) }).Count
    if ($count -lt $requiredCoverage[$module]) {
      Add-Failure "Insufficient coverage for ${module}: $count/$($requiredCoverage[$module])"
    }
  }

  $p0Count = @($testCases | Where-Object priority -eq 'P0').Count
  if ($p0Count -lt 12) {
    Add-Failure "Too few P0 cases: $p0Count (minimum 12)"
  }
}

if ($testSuite -and -not ([string]$testSuite.instructions).Contains('no fixed turn or decision-count limit')) {
  Add-Failure 'Test instructions must reject fixed interaction-count limits.'
}

if ($failures.Count -gt 0) {
  'Behavior manifest check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}

$coverageOutput = foreach ($module in $requiredCoverage.Keys) {
  $count = @($testSuite.cases | Where-Object { $module -in @($_.modules) }).Count
  "- ${module}: $count"
}

'Behavior manifest check: PASS'
"Cases checked: $(@($testSuite.cases).Count)"
"P0 cases: $(@($testSuite.cases | Where-Object priority -eq 'P0').Count)"
'Runtime behavior evaluated: NO'
'Module coverage:'
$coverageOutput
