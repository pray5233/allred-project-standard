param(
  [string]$LabRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$StandardRoot = (Join-Path (Split-Path -Parent $LabRoot) 'allred-project-standard')
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($relative in @(
  'SKILL.md',
  'agents\openai.yaml',
  'references\architecture-decision.md',
  'references\Skill流程优化模式.md',
  'references\Skill测试验收.md',
  'references\调试与优化建议.md',
  'templates\Skill测试验收记录.md',
  'tests\behavior-cases.test.json',
  'tests\behavior-cases.oracle.json',
  'tests\review-result.schema.json',
  'tests\behavior-trial-aggregation-fixtures.json',
  'scripts\check_behavior_manifest.ps1',
  'scripts\aggregate_behavior_trials.ps1',
  'scripts\check_candidate_harness.ps1',
  'scripts\invoke_candidate_validation.ps1',
  'scripts\run_ci_behavior.ps1'
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $LabRoot $relative))) { $failures.Add("Missing lab file: $relative") | Out-Null }
}

$skillText = Get-Content -LiteralPath (Join-Path $LabRoot 'SKILL.md') -Raw -Encoding UTF8
$yamlText = Get-Content -LiteralPath (Join-Path $LabRoot 'agents\openai.yaml') -Raw -Encoding UTF8
if (-not $skillText.Contains('name: allred-project-lab')) { $failures.Add('Unexpected lab Skill name.') | Out-Null }
if (-not $yamlText.Contains('allow_implicit_invocation: false')) { $failures.Add('Lab must remain explicit-only.') | Out-Null }
if (-not (Test-Path -LiteralPath (Join-Path $StandardRoot 'scripts\run_behavior_eval.ps1'))) { $failures.Add('Standard behavior runner is unavailable.') | Out-Null }

& (Join-Path $LabRoot 'scripts\check_behavior_manifest.ps1') -SkillRoot $LabRoot | Out-Null
if (-not $?) { $failures.Add('Lab behavior manifest failed.') | Out-Null }

& (Join-Path $LabRoot 'scripts\check_candidate_harness.ps1') -LabRoot $LabRoot -StandardRoot $StandardRoot | Out-Null
if (-not $?) { $failures.Add('Candidate-validation harness failed.') | Out-Null }

if ($failures.Count -gt 0) {
  'Lab structure check: FAIL'
  foreach ($failure in $failures) { "- $failure" }
  exit 1
}
'Lab structure check: PASS'
