---
name: allred-project-lab
description: Explicit maintainer workflow for improving, evaluating, and releasing allred-project-standard. Use only when invoked as $allred-project-lab or when the user explicitly asks to maintain the Allred Skill itself; never use for ordinary project delivery.
---

# Allred Project Lab

Maintain `allred-project-standard` without turning maintainer rules into user runtime context.

## Boundary

- This Skill owns architecture review, workflow refactoring, invariant ownership, scenario evaluation, regression analysis, release-candidate review, source/release parity, and publication evidence.
- `allred-project-standard` remains the only ordinary project entry and owns runtime stage gates plus conditional project overlays.
- `allred-project-memory` and `allred-obsidian-notes` remain explicit post-work capabilities. Verify their handoff boundaries; do not let them collect project requirements or alter runtime routing.
- Do not introduce new ordinary-user trigger words from maintenance work.

## Required Reading

1. Read `references/architecture-decision.md` for current ownership and benchmarks.
2. Read `references/Skill流程优化模式.md` before structural changes.
3. Read `references/Skill测试验收.md` before adding or running evaluations.
4. Read the target Skill's `SKILL.md`, changed owners, invariant manifest, relevant behavior cases, and release scripts only as needed.

Do not claim that required reading or benchmark inspection is complete until fresh evidence is available. Before both the target preflight and benchmark record are available, state only the next read-only action; defer ownership, architecture, and implementation conclusions.

For ordinary maintenance, use the automated validation entrypoint instead of asking the user to repeat the same manual conversations:

```powershell
pwsh -NoProfile -File scripts\invoke_candidate_validation.ps1 -Mode Quick
pwsh -NoProfile -File scripts\invoke_candidate_validation.ps1 -Mode Changed
pwsh -NoProfile -File scripts\invoke_candidate_validation.ps1 -Mode Candidate -BaselineRef <accepted-ref>
```

- `Quick` runs dependency-free structure, invariant, route, and harness checks.
- `Changed` resolves affected cases from Git changes, then runs fixed-record replay and only the selected behavior cases. A non-pass is automatically retried and reported as stable, variable, or infrastructure-inconclusive evidence.
- `Candidate` adds the release matrix, low/high multi-trial consistency runs, old/new blind comparison, write-boundary probe, official validation, isolated installation, and source/release parity.
- Treat infrastructure failures as inconclusive. Do not convert a missing login, invalid key, timeout, or unavailable validator into a Skill pass or fail, and do not treat one stochastic pass as stable release evidence.
- Runtime-state changes also require `scripts/run_runtime_dialogues.ps1 -OutputRoot <new-evidence-directory>` and the deterministic `check_runtime_contracts.ps1` suite. These use actual files and validator output. The old tool-event simulation measures conversation only; an `OracleIncompatible` result is a migration gap, never a pass or a product regression.
- The generated `report.html` is the default review artifact. Ask the user for one final real-machine pilot only after the candidate pipeline passes.

For a simplification hypothesis, use `scripts/run_runtime_comparison.ps1 -BaselineSkillRoot <frozen-source> -OutputRoot <new-directory> -UseUserConfig`. It freezes a common outcome rubric and compares old Skill, candidate and native Codex on actual dialogues. Original Skill-conformance checks stay separate. A tie or native win is valid evidence; do not change the rubric to require a candidate win. See `references/core-simplification-20260907.md` for scope and limitations.

For the collaboration-bridge change, follow `references/bridge-workflow-20260908.md`.
Reports label `contract-and-behavior` and `outcome-only` separately. Optional
question diagnostics are not per-turn runtime obligations. Preserve original
assertions and failures in frozen evidence; judge source fidelity, useful
discovery and actual authorization independently of the script-call schedule.

For the Lab's own maintenance scenario, run the target Skill's evaluator with separate suite ownership:

```powershell
pwsh -NoProfile -File <allred-project-standard>\scripts\run_behavior_eval.ps1 `
  -SkillRoot <allred-project-lab> `
  -SuiteRoot <allred-project-lab> `
  -CaseIds L01
```

## Maintenance Loop

Normal runtime dialogues use the ordered evidence-ID interface with the existing
reviewer assertions; `-ReviewerFormat Legacy` preserves the prior diagnostic
format. See `references/review-interface-20260908.md` for verification and limits.
For review-evidence calibration, use `scripts/run_ordered_review.ps1 -OutputRoot
<new-directory> -UseUserConfig`. Optional `-ReplayRoot`, `-SuitePath` and
hash-bound `-EventMapPath` re-review unchanged dialogues with their original
event order. See `references/ordered-review-20260908.md`. This opt-in Lab path
does not replace normal dialogue evaluation or certify a release.

For dialogue-continuity diagnosis, `run_runtime_dialogues.ps1 -SessionMode Native`
uses an exact per-case CLI session; the default `Replay` keeps historical replay
as a control. `-ReviewMethod Counterevidence` is an optional review method on the
dialogue, ordered-review and calibration runners. It does not change assertions,
guarantee semantic correctness or authorize runtime promotion. See
`references/native-dialogue-review-20260908.md` for commands, original-context
binding, retained disagreements and the measured limits.

For goal-inheritance calibration, see
`references/goal-inheritance-review-20260908.md` and controls C17-C26. The source
comparison experiment remains isolated because some supporting judgments were
incorrect or disputed. Preserve the distinction between outcome, proof method
and actual authority; do not promote a runtime change from an aggregate verdict.

For the subsequent per-assertion experiment and source-attribution correction,
see `references/assertion-isolation-review-20260908.md`. Both tested combinations
remain isolated; the default reviewer and runtime workflow are unchanged.

For selective source-attribution findings and the unaccepted record-correction
experiment, see `references/source-attribution-review-20260908.md`. Its helpers
remain isolated; valid citations alone do not establish faithful record updates.

```text
freeze baseline -> classify owner -> change smallest owner -> static validation
-> targeted behavior evaluation -> adjacent regression -> release review
```

1. Freeze the accepted baseline in Git before a substantial refactor when the user authorizes it.
2. Classify each change as runtime core, conditional overlay, deterministic validator, behavior test, release packaging, or maintainer documentation.
3. Keep domain or delivery rules out of the shared core unless every routed project needs them.
4. Record durable invariants structurally. Scripts check ownership, references, coverage, and deterministic contracts; behavior tests judge semantic execution.
5. Test the changed scenario first, then adjacent routes and model-effort variants proportional to risk.
6. Publish only after source/release parity, structure, official validation, behavior acceptance, and a reviewable Git diff pass.
7. Compare a substantial candidate with the accepted baseline. A material blind-comparison loss blocks promotion even when both versions satisfy coarse assertions.

## Release Decision

Do not promote a candidate when any changed P0 case fails, an invariant has no owner or behavior coverage, a conditional overlay leaks into unrelated route context, the release mirror differs from source, or validation evidence is stale.

Report the baseline commit, changed ownership, exact checks, low/high behavior results, residual gaps, candidate version, and whether publication was authorized.
