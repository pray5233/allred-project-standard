# Ordered Review Evidence

Follow-up: `review-interface-20260908.md` records adoption of this evidence-ID
format in the normal runtime reviewer after additional tests. The observations
and opt-in experiment status below describe the original experiment unchanged.

Status: implemented and calibrated as an opt-in Lab tool; not a default semantic
release judge. Ordinary project discovery,
Standard sources, user keywords and approval behavior are outside this change.

## Problem And Benchmark

The previous experiment produced five invalid citations in six whole-dialogue
reviews. Its full/A12 reviewer also treated a later command result as available
before a progress message. Users need trustworthy maintenance judgments without
additional project questions. Success requires exact grounded citations, correct
start/message/completion order, preserved assertions and source files, rejection
of invented evidence, and honest failure/unknown results.

Inspected 2026-09-08: local `eval_runtime.ps1` exact quote and aggregate checks;
the actual full/A12 `turn-02.events.jsonl` start at line 14, message at 15 and
completion at 16; existing immutable calibration runner; installed official
skill-creator scope-preservation guidance. These match the current PowerShell
CLI toolchain. Reuse .NET hashing, raw CLI item events and the existing assertion
validator. No new Skill, plugin, network package, browser or dependency is needed.

## Decision

Add an opt-in ordered evidence adapter and reviewer schema in the Lab. Keep the
legacy reviewer and its assertions available. Evidence IDs identify the turn and
raw event line; state IDs bind path and content. A plain-text evidence catalog
removes the need to count arrays or quote JSON-escaped prose. A deterministic
adapter maps IDs back to actual sources for the unchanged assertion checks.

Include tool-start and tool-completion as distinct observations; a pending tool
has no completed output. End-of-turn state snapshots do not establish when a
mutation happened. If original events are unavailable, say order is unknown;
never reconstruct interleaving from separate command/message arrays. Check that
provided events actually match the transcript before admitting them. Preserve
raw transcripts, previous verdicts and all unsuccessful calibration attempts.

Test positive/negative chronology pairs, exact versus fabricated quotes, legacy
fallback, repeated text, state identity, tampered/mismatched logs and no timing
in quality input. Then re-review the six frozen dialogues without editing their
assertions. This is reviewer calibration, not new project execution or proof
that the Skill's existing behavioral failures were fixed. Do not promote a
review path based on quote validity alone or retry judgments until they pass.

## Progress

During calibration, a grounded focused/A12 Pass missed an explicit validator
reference in first-turn progress. Keep that review. Refine evidence presentation
by marking actual assistant messages as user-facing, tool observations as
internal, and listing final replies after their preceding progress. These are
source-role/order facts, not a new assertion or a scenario-specific rule. Repeat
that failed semantic review and the chronology controls on the changed formatter.

- [x] Freeze current source and inspect local benchmark.
- [x] Implement and verify evidence/ID adapter.
- [x] Calibrate chronology and re-review immutable dialogues.
- [x] Record disagreements, synchronize mirrors and report limits.

## Observed Results

Evidence: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-ordered-review`.
The final adapter passed 29 deterministic checks on PS7 and PS5.1. Legacy runtime
review/streaming contracts also passed on both hosts, including 14 bad-review
and six judgment-changing repair rejections. Quick now includes the adapter's
contracts. No default runtime reviewer, project Skill or keyword was changed.

Four constructed chronology/truth controls matched Pass/Fail/Partial/Fail in both
formatter versions. Actual re-reviews used gpt-5.6-sol/low and the original case
assertions. The initial full/focused replays had no first-turn event mapping:
three reviews grounded and one rejected a nonliteral quote. Those observations
remain, including their honest missing-chronology findings.

After adding hash-bound original first-turn logs, all six frozen-dialogue reviews
had valid citations on the first call (previous review format: one of six).
This improves evidence handling, not proof of better Skill behavior or reliable
semantic verdicts. The resulting judgments were full A01/A12 Fail/Fail, focused
A01/A12 Pass/Pass, and audited A01/A12 Fail/Fail. Source traces did not change.

Maintainer inspection rejected focused/A12's Pass: first-turn progress explicitly
described the validator, contrary to its unchanged assertion. After source roles
were made visible and final responses moved after progress, the targeted replay
returned a grounded Fail with the real communication defect. It also incorrectly
treated reversible date/search implementation details as an unauthorized
material choice without demonstrating the contract change. Preserve this false
positive alongside the corrected communication finding. A correct aggregate
Fail does not make every reason correct.

The audited/A12 review additionally identified a real stale B1 blocker in the
actual selected snapshot even though D1 was confirmed. The old root branch remains
visible too; no state was edited to remove either issue. Audited/A01's D2-to-D5
meaning-transfer finding is recorded for targeted continuity review, not silently
treated as a new universal workflow rule.

There were 19 model calls: eight controls, four incomplete-log re-reviews, six
complete-log re-reviews and one role-label correction replay. No call was retried
with unchanged inputs until it passed; no previous output or assertion was edited.
These are review-only experiments, not new application execution. All original
source hashes and 74 Standard source files were preserved; Lab mirror parity and
official validation passed. Only low effort was evaluated; do not claim high-model
or cross-provider reliability, population pass rates or full candidate acceptance.

Next use the proven evidence adapter while keeping explicit maintainer review for
semantic findings. Prioritize faithful decision summaries and clearing a resolved
decision's genuinely dependent blockers from the latest state, with the ambiguous
and explicit-answer controls retained. Keep routine implementation autonomy; do
not add user confirmations to satisfy a reviewer false positive. Default adoption
of the new semantic reviewer remains unapproved by this experiment.
