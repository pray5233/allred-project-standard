# Answer Meaning And Factual Continuity

Status: scoped implementation and evaluation complete; behavioral acceptance not
met. Internal candidate only; no commit or publication.

## Problem And Benchmarks

Users need partial replies to preserve unanswered meaning while clear combined
answers advance without another confirmation. The previous B1 A01 promoted an
ambiguous workflow answer into an exclusion; B2 A02 recorded a topic as if the
earlier source question were settled. Several pending facets never entered state.
The deterministic continuity guard currently protects D rows only, not Q rows.

Benchmarks inspected 2026-09-08: the local updater's immutable snapshots, stable
ID upserts and D transition checks; the earlier answer-interpretation experiment's
successful partial-answer and clear-combined-answer behavior; installed grilling's
dependency tree and official skill-creator's proportional specificity. Reuse the
local PowerShell/.NET path and existing actual CLI evaluator. No dependency,
external interviewing Skill, new user trigger, subagent or approval is added.

PM Skills comparison remains the experiment benchmark recorded in
`core-simplification-20260907.md`. Its artifact comparisons do not prove multi-turn
interview quality. The current local baseline is frozen separately at
`F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-answer-state/baseline`.

## Bounded Implementation

1. Keep interpretation before record authoring: distinguish the literal answer,
   answered meaning and unresolved meaning. A proposed simplification is not a
   user-confirmed exclusion. Split independently answerable facets internally;
   they can still appear in one compact visible question or one combined reply.
2. Compose existing D continuity with Q continuity. Retain factual rows by ID;
   once provided, their axis is stable. Label refinements remain allowed. Reject
   a terminal factual row with explicit remaining facets. Unknown-answer handling
   remains a semantic acceptance check; do not parse business text or infer consent
   in a script. Legacy Q rows without axes remain readable.
3. Add paired reviewer controls for a source description versus concrete data
   and a pending proposal versus a settled unauthorized choice. Freeze expected
   verdicts before running. Preserve original controls and all raw judgments.
4. Run focused PS7/PS5.1 tests, runtime contracts and actual A01/A02/A12 dialogues.
   Inspect state and complete replies independently of the model verdict. Mirror
   source only after verification; do not commit or publish this batch.

## Acceptance And Limits

- No disappearance of recorded Q rows, identity replacement or closure while
  explicitly retaining unanswered facets; valid evidence/user answers and wording
  refinements must still pass. Rejected updates leave inputs and outputs intact.
- Clear combined replies must not be split into repeated user confirmations.
  Partial replies must not authorize omitted alternatives. Unknown is a valid
  answer, not an instruction to guess or a reason to ask the same question again.
- Reviewer controls must preserve genuine negative verdicts as well as accept
  valid pending proposals and honest evidence limits. Re-review is not a new
  product dialogue or evidence of improved behavior.
- Neither Q continuity nor exact source IDs proves semantic interpretation or
  discovers a facet the model never recorded. Report those gaps without claiming
  a script pass establishes interview completeness. Time is diagnostic only.

## Progress

- [x] Freeze current sources and inspect retained failures and local benchmarks.
- [x] Implement generic answer handling and Q continuity.
- [x] Run deterministic and reviewer calibration checks.
- [x] Run and review actual partial/changed/clear-answer dialogues.
- [x] Verify preservation, mirror parity and report acceptance gaps.

## Observed Reviewer Surface Follow-Up

The first ten controls matched, but fresh A12's assertion 4 was graded Met despite
literal progress messages narrating state/validator repair. Its final reply was
clean. Add C11/C12 using that unchanged assertion, one with routine repair in
`messages` and one with useful business-consequence progress. Expected outcomes
are frozen before evaluation. The calibration runner now preserves optional
messages and case assertions; `-ControlIds` selects only affected controls.

Both review prompts clarify that communication assertions apply to progress and
final replies. Internal tool/state logs alone are not user-facing messages. This
is an evaluation-scope correction, not a relaxed rubric or runtime fix. Re-review
unchanged A12 separately after the controls, retaining its original Fail and all
reasons. A new reason for Fail is not new participant behavior.

## Results And Interpretation

PS7/PS5.1 state-update checks each passed 266 assertions; full runtime contracts
passed 100. Structure, generality, route budgets, official Skill validation and
the evaluator's deterministic negative checks passed. The expanded state checks
are already called by the existing Quick entrypoint; this batch did not rerun
the entire Quick suite or a release matrix after every later Lab change.

Twelve distinct constructed reviewer controls matched expectations across 13
executions (C04 was repeated after optional progress/assertion support). An
unchanged A12 review-only follow-up then correctly identified progress narration;
it remained Fail but changed its reason. Preserve both judgments, including the
disagreement about a global-completion claim. Simple controls do not establish
arbitrary full-dialogue reviewer reliability.

Three fresh gpt-5.6-sol/low dialogues completed eight user turns. A01 is Fail:
an ambiguous answer still became a confirmed exclusion. It retained unknown
volume and an unanswered history rule, so the failure is semantic narrowing,
not disappearance of those tracked rows. A02 is raw Pass: group practice did
not settle time allocation, and new self-study questions retained the pending
work. Its long option blocks and multiple questions inside numbered items remain
UX concerns. A12 accepted editing plus every pre-edit value without re-asking;
its raw and follow-up reviews both remain Fail. No overall behavior pass.

A bounded diagnostic then asked the same three interpretation-only cases under
full reference context (45,633 characters) and only Frontier Round (2,472). Both
arms matched all three expected mappings. They made no actual state/tool calls
and used a structured-output task, not a live interview. This does not prove
context length caused the live failure or that a focused production layer would
fix it. It does establish that the isolated mapping can succeed while integrated
conversation execution fails. Next work should test that integration boundary,
not add more reminders or specific date/record rules to the shared workflow.

Evidence: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-answer-state`.
