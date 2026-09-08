# Interpretation Context Experiment

Status: completed experiment, not accepted for runtime integration. Maintenance
evidence only; Standard source remains identical to the frozen starting tree.
No runtime flow, trigger, dependency, version, commit or publication change.

## Problem And Benchmark

The answer-binding prototype preserved a wrong interpretation. A01's reviewer
also accepted that inference. Users need both unresolved alternatives retained
and explicit combined/custom choices applied without another approval round.

Local references inspected 2026-09-08: actual A01/A12 answer-binding transcripts,
the existing CLI evaluator and structured review/citation helpers, the frozen
full/focused interpretation probes, stable-ID updater, and official installed
skill-creator's scope preservation and progressive disclosure. Reuse those tools
without adding a model dependency to ordinary projects or changing their rubric.

## Experiment

1. Freeze current Standard and Lab, evaluator, source transcripts and cases.
2. Compare fresh calls with full prior tool-aware context against fresh calls
   containing the actual materials, visible question, decision roster and reply.
   Both get the same interpretation instruction and schema. This tests context
   selection in replay, not a native persistent-session or latency effect.
3. Use the actual ambiguous A01 and explicit A12 replies, plus explicit exclusion
   and training ambiguity/combined-answer controls. Two trials per arm/case.
   Expected results stay outside model input. Exact source quotes and IDs are
   mechanically checked; meaning still requires independent review.
4. Apply trial-one interpretations for the two actual cases in separate temporary
   workspaces and resume the same conversation through actual CLI tools. Preserve
   original traces; identify relocated fixture state as replay, never new proof.
5. Keep original reviewer assertions, raw judgments and maintainer disagreements.
   Failed/incomplete calls are retained, not retried until a pass appears. An
   interpretation pass alone is insufficient for runtime integration.

Acceptance: no unsupported choice/omission, clear answers advance, pending topics
remain visible to the next worker, no user-facing internal diagnostics or added
approval ceremony, original data and runtime source hashes unchanged. Time and
total interview rounds are not quality criteria. A small experiment cannot prove
general reliability or justify a mandatory extra inference call on other hosts.

## Progress

- [x] Freeze cases, inputs and unchanged criteria.
- [x] Compare interpretation outcomes in both contexts.
- [x] Resume actual cases and audit the resulting conversations.
- [x] Record limitations and decide whether integration is justified.

## Results And Limits

Evidence root:
`F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-interpretation-isolation`.
See its `report.md`, verbatim `dialogues.md`, `integrity.json`, raw event streams,
and unmodified independent reviews. Model: `gpt-5.6-sol`, low effort, same user
config hash, plugins disabled. HEAD remains
`2ade4dc988a6b6b75f3672019c83b2e2b60ce253`; version remains `0.8.0-rc15`.
The starting tree already had uncommitted work; equality is against the frozen
tree, not a claim that it equals HEAD or a published release.

- Full-context interpretation matched expected decision IDs in 9/10 calls;
  focused interpretation matched in 8/10. Both focused R01 trials incorrectly
  settled the no-date alternative. All 20 passed mechanical checks. These are
  ID/serialization observations, not semantic pass rates or meaningful statistics.
- Focused R02 selected the correct ID but compressed an explicit every-edit,
  pre-edit-content requirement into a vague modification-trace summary. The
  source quote remained available; a correct ID did not ensure a faithful choice.
- A supplementary claim audit rejected unsupported narrowing and accepted explicit
  answers in binary direction, but strict category plus literal quote criteria
  passed only 3/6. One category disagreed and two quotes added punctuation.
  Preserve those failures; do not normalize them into successful original runs.
- An exploratory third arm audited the actual focused trial-one choices. It
  rejected unsupported narrowing and the weakened summary, with valid quotes in
  both checks. This was added after seeing isolation fail, not a pre-registered
  comparison or a calibrated production reviewer.
- Three arms resumed A01/A12 using trial one regardless of outcome: six bounded
  conversations, nine fresh turns, six repeated historical first turns. Full A01
  retained the unsupported date exclusion. Focused A01 reopened the date question,
  but narrowed its option presentation. Audited A01 kept the date meaning open.
- All three A12 final answers understood the explicit combined rule without
  asking it again. Full and audited stored its key conditions; focused retained
  the vague summary despite its precise final reply. Audited wrote from the older
  root, leaving two sibling state leaves. No content loss was demonstrated in this
  fixture; latest-state continuity was not followed and requires separate work.
- Every continuation exposed internal mechanics in user-facing progress. The
  review group returned five invalidly grounded judgments and one grounded Fail
  (audited A12, internal validator narration). None constitutes an accepted Pass.
  Raw Pass labels in invalid reviews remain invalid, not usable acceptance.

The full A12 review additionally alleged a false missing-output claim. Original
`turn-02.events.jsonl` shows command start at line 14, the progress message at 15,
and completion at 16. The command was pending when the message was emitted.
Separated message/command arrays lost this ordering. Preserve that disagreement:
internal diagnostic narration and redundant completed-command retries are real
issues; claiming the message contradicted already available output is unsupported.
Likewise, ordinary reversible defaults are not automatically unauthorized business
decisions merely because the reviewer labels them that way.

Final export checked 256 evidence/continuity conditions: 255 met and one failed
(the two state leaves above). Six original source hashes, all 132 frozen files,
and all 74 live Standard files matched. All six material copies matched; boundary
inventories reported no unexpected product files. The 28 interpretation/audit
calls used no tools. Hashes and inventories cannot prove every possible transient
or outside-workspace action; command/event review remains necessary. The original
manifest omitted the expectations-file hash; final inventory is not pre-run
cryptographic attestation of that file.

## Decision And Next Experiment

Do not install this extra model step in the ordinary workflow. Isolation alone
did not solve the observed failure; claim auditing has a useful signal but lacks
reliable end-to-end acceptance. This round changes only Lab documentation and
evidence scripts, preserving mature intake, user keywords and approval behavior.

Next, reuse the original ordered CLI events for reviewer citations before
accepting any new reviewer design. Benchmark locally against the existing exact
quote checks and this counterexample; retain stable event identities and state
paths rather than relying on renumbered independent arrays. Then test faithful
interpretation repair that keeps all explicit qualifiers, preserves unanswered
alternatives and advances from the current state. Pair ambiguous inputs with
explicit/custom answers so caution cannot force unnecessary user confirmation.
Only after that bounded experiment passes should a small runtime candidate be
considered. Do not add domain keywords, mandatory auditors, another ledger or an
extra user approval gate to compensate for these failures.
