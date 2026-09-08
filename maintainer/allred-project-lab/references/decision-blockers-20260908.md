# Confirmed Decisions And Pending Blockers

## Problem And Benchmark

The unchanged audited A12 continuation records D1 as confirmed, including the
exact pre-change-history requirement, but leaves its B1 decision blocker open.
B2 and B3 are still unanswered. This can cause repeated questions or prevent
READY despite a valid answer. Users should not repair this bookkeeping.

Baseline: live working tree on 2026-09-08, HEAD
`2ade4dc988a6b6b75f3672019c83b2e2b60ce253`, Standard `0.8.0-rc15`.
The working tree differs from that commit. Its 133 Standard/Lab files are frozen
under `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-decision-blockers/before`.

Local benchmarks: `update_project_state.ps1` already derives dependent scope
bookkeeping and invalidates stale receipts without extra user approval;
`Get-AllredBlockerSources` preserves all three existing link shapes;
`Get-AllredDecisionEvolutionFailures` prevents losing an unanswered decision.
The installed official `skill-creator` guidance favors deterministic scripts
for fragile bookkeeping and prohibits turning a case into a universal domain rule.
No new dependency or external tool is needed.

## Smallest Change

Reconcile only explicitly typed decision blockers. Every source across
`source_ids`, `basis` and `source` must reference a fully confirmed decision with
a nonempty choice, an exposed question and a literal user source. Recorded
remaining facets, mixed evidence links, missing links, conflicts and unresolved
siblings prevent automatic closure. Do not infer meaning from quoted answers.

Mark generated closures with `resolution_mode: confirmed-decisions`, so a later
reopened decision reopens its dependent blocker. Explicit manual/lifecycle
resolutions remain authored. Apply this to ordinary upserts and optional answer
maps in the common updater, before contract/receipt invalidation. Keep all
existing stage and authorization gates. This resolves a bookkeeping condition,
not requirement completeness or semantic correctness.

The different issue of selecting an older valid parent is recorded separately.
Do not silently select a file by modification time or invent a shared mutable
head across independent sessions. This patch preserves existing parent/hash
checks; it does not claim to solve latest-head selection.

## Acceptance

- Explicit confirmation closes only its own eligible blocker; all prerequisites
  of a multi-source blocker must be confirmed.
- Partial/ambiguous stored states, missing authority, evidence blockers and
  remaining facets stay unresolved; siblings and exact choices are unchanged.
- A correction/reopening restores a generated blocker. A no-op preserves it.
- Parent, user inputs and original project files remain unchanged. Authorization
  remains pending, and substantive changes invalidate cached record/coverage.
- Exercise ordinary updates, answer maps, legacy links and PS7/PS5.1 contracts.
- Run fresh A12 and A01 dialogues with real tools; review actual states and full
  visible responses. Keep semantic defects separate from structural results.
- Source/release parity and official validation remain required. No publication
  or stable-quality claim follows from this patch alone.

## Results

The unchanged historical A12 state reproduces the failure with the frozen
updater and resolves only B1 with the candidate. B2/B3 stay open; the actual
READY validator rejects them but no longer reports B1. The original hash and
all decision contents are unchanged.

PS7 and PS5.1 each pass 386 updater and 77 answer-map assertions. The 100 existing
runtime contracts pass on PS7. Structure, invariant, context-budget, generality,
official UTF-8 validation and source/release parity pass (Standard 74 / Lab 60).
The first official call's GBK decoding failure is retained as environment
evidence; `python -X utf8` fixes the invocation without configuration changes.

Fresh low-effort A12 (two turns) actually invokes the common updater without
manually closing B1; the resulting state closes it, preserves the full explicit
history qualifier and keeps independent D2/D3 open. A01 (three turns) preserves
the ambiguous date question and unknown volume. Both use latest returned parent
states in this sample and leave materials/product boundaries intact.

Both whole-dialogue reviews remain Fail. A12 exposes validator mechanics and
claims no readable output after a completed command already returned a full
packet (turn 2, raw event lines 14 then 15). A01 reviewers disagree about decision
identity versus a sole-remaining-question claim. The maintainer verified that
D2 stays open, the identity alternatives remain and D1 remains pending; retain
those disagreements rather than labeling state loss proven. Its final wording
can still be clearer. Grounded citations do not certify semantic judgments.

The scoped bookkeeping acceptance is met; stable overall behavior is not.
Preserve raw Fail results, the A12 citation repair and all event logs. Next
investigate result consumption/reuse and user-facing progress; calibrate semantic
continuity separately. No source-specific rule, new trigger or publication.
Full evidence and transcripts: the evidence root above, `report.md`,
`dialogues.md`, `maintainer-review.json` and `integrity.json`.
