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
- `Changed` resolves affected cases from Git changes, then runs fixed-record replay and only the selected behavior cases.
- `Candidate` adds the release matrix, low/high runs, old/new blind comparison, write-boundary probe, official validation, isolated installation, and source/release parity.
- Treat infrastructure failures as inconclusive. Do not convert a missing login, invalid key, timeout, or unavailable validator into a Skill pass or fail.
- The generated `report.html` is the default review artifact. Ask the user for one final real-machine pilot only after the candidate pipeline passes.

For the Lab's own maintenance scenario, run the target Skill's evaluator with separate suite ownership:

```powershell
pwsh -NoProfile -File <allred-project-standard>\scripts\run_behavior_eval.ps1 `
  -SkillRoot <allred-project-lab> `
  -SuiteRoot <allred-project-lab> `
  -CaseIds L01
```

## Maintenance Loop

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
