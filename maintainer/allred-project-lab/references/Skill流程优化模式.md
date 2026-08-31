# Skill 流程优化模式

Use this reference when a Skill, prompt workflow, project standard, training workflow, release package, or reusable operating method is the product being improved.

Also use `skill-creator` when available and read `references/交互与确认规则.md`.

## Evidence

Treat these as evidence:

- current `SKILL.md` and directly routed references
- observed behavior from a realistic prompt
- user feedback tied to an actual interaction
- structure and validation results
- release/install behavior when distribution is in scope
- official Skill-authoring guidance or a maintained local reference

One complaint or failed prompt is a reproduction case. Generalize only when the cause is structural, repeatable, or protects scope, safety, evidence, or handoff.

## Preflight

Inspect only what affects the change:

1. current entrypoint
2. directly relevant references/templates/scripts
3. `skill-creator`
4. current behavior tests
5. release/README/install files only when distribution is part of the request

Map:

- trigger and routing ownership
- shared rule ownership
- mode-specific ownership
- duplicate or contradictory instructions
- unreferenced resources
- validation coverage
- source/release drift

Do not decide the edit boundary, ownership, or release-sync policy before this read-only preflight. If an exact release mirror exists, determine whether the local project treats parity as an invariant. Updating the source while knowingly leaving an established mirror stale is a design decision, not a harmless default.

## Change Classification

| Change | Preferred owner |
| --- | --- |
| discovery description and top-level routing | `SKILL.md` |
| shared interaction or confirmation | one shared reference |
| one stage's behavior | that stage reference |
| repeated record/output | template |
| deterministic invariant | script |
| behavioral expectation | test reference |
| distribution instructions | release README/install files |

Do not patch every observed failure into `SKILL.md`. Fix the smallest correct owner and remove superseded duplicates.

## Architecture Gate

For substantial restructuring, use `references/开发依据与能力复用.md`. Record:

- current problem and measurable objective
- benchmark source/version/date
- chosen ownership model
- deliberate differences
- acceptance metrics and known gaps

Prefer a lightweight router plus progressive disclosure. Keep only instructions that change decisions.

When adapting another workflow, extract decision-changing invariants instead of adding the external workflow as another mandatory layer. Measure user gates, duplicated ownership, verification strength, and runtime dependencies before and after the change.

## Execution Authorization

A direct request such as “scan the whole Skill and refactor unreasonable parts” authorizes in-scope Skill file edits after read-only preflight. A follow-up such as “按照建议修改” authorizes the previously displayed scope.

Use `【开始执行前确认】` only when the rewrite boundary, release synchronization, deletion, installation, publication, Git operation, or other consequential action is not already explicit. Do not ask for a duplicate ceremony.

After preflight:

- if the release directory is an exact local mirror and parity is an established project invariant, include source-to-release synchronization in the displayed execution scope without implying commit or publication permission
- if the release directory has independent content or its ownership is unclear, leave it untouched and report the resulting gap
- ask only when deletion, independent release content, publication, installation, Git, or another consequential boundary actually needs a user decision

Never infer permission to commit, push, publish, install dependencies, or change unrelated files.

## Validation

Run:

1. dependency-free structure check
2. official validator when its dependencies are available
3. diff/format check
4. relevant realistic behavior walkthroughs
5. source/release parity when distributed

Behavior tests should inspect decisions and side effects, not require exact prose. Add a regression case only for a demonstrated or high-risk failure.

For a process-efficiency refactor, include:

- clear task: zero unnecessary decision questions
- interaction depth follows unresolved information and decision dependencies; batch currently knowable items and reject duplicate gates
- exact prior authorization: no duplicate start confirmation
- debugging: evidence and one hypothesis before a fix; architecture review after three failed hypotheses
- completion: fresh verification evidence
- no TDD/Red-Green execution order, Superpowers invocation, worktree, subagent, or per-task commit

## Completion

Report:

- architecture or behavior changed
- files added/removed
- validation evidence
- remaining gaps
- release synchronization
- Git state when relevant

Record the design decision in `references/调试与优化建议.md`.
