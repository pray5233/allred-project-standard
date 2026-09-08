# rc15 Incremental Runtime Repair

## Status

- Local candidate: `0.8.0-rc15`; not published, not promoted to stable.
- Baseline: `9e666a979016f37b07f87137f9673c28b2d995a4`, preserved by `codex/allred-rc14-baseline-20260907`.
- Implementation is incremental. Material-first intake, total/current scope, user decision ownership, adaptive interviewing, beginner expression, and one start authorization remain.
- Deterministic acceptance passed. Cross-model behavioral and release acceptance remain incomplete; do not describe this candidate as fully qualified.
- Authoritative evidence root: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-07_allred-rc15/`.

## Change Coverage

| Finding | Implemented change | Evidence |
| --- | --- | --- |
| Event text bypassed the stage gate | New software and document stages validate actual state; event-ID authority rejected; context previews explicitly unvalidated | missing state, fake event, route mismatch, actual READY/EXECUTION tests |
| Prefix paths permitted traversal | Normalize with .NET paths, enforce separator boundaries, reject reparse ancestors | traversal, sibling-prefix, protected alias, real junction tests |
| Domain questionnaires forced all topics into one reply | Same bounded readability contract across profiles; completeness belongs to cumulative READY review | all five profiles accept a single remaining question and reject twelve-question packets |
| Domain rules leaked into shared runtime | Short generic guards and conditional domain owners | sixteen invariants, routed source/section checks |
| Frontier updates were omitted from routed context | Load Frontier Round, Fact-Finding Queue and Stop And Fallback; preserve partial answers and changed-parent effects | context contracts and waiting/parent-change tests |
| State vocabularies diverged | Shared canonical statuses, waiting-child rules, explicit distinction from informal planning labels | dependency, enum, READY unresolved/proposal tests |
| Wording checks enforced historical patches | Check state IDs, dependencies, scope and reply load rather than compulsory impact/reply phrases; reduce entrypoint | natural-prose tests; SKILL.md 260 to 127 lines |
| Simulated passed events hid runtime defects | Add actual-file dialogues, raw tool/state snapshots, protected-file hashes, independent review and deterministic contracts | six dialogue groups; old simulation evidence explicitly classified |

Internal `ready` context separates the complete start envelope from ordinary question rounds. Monitoring/beginner decision context decreased from 542 lines / 44,991 characters at rc14 to 427 lines / 35,882 characters. This is a context-volume comparison, not a proven conversation-speed improvement.

## Verification

- PowerShell 7 structural run: `structure-r2-ps7`, 57/57 deterministic contracts passed.
- PowerShell 5.1 structural run: `structure-r3-ps51`, 57/57 deterministic contracts passed after fixing direct-file default-root and explicit-Text handling.
- Focused PowerShell 5.1 question run: `questions-final-ps51`, 31/31 checks passed; its scope is explicitly narrower than the full suite.
- Preserved compatibility: `preserved-contracts-r2`, 13/13 checks passed, including LF/CRLF, training handoff boundaries, the old route alias and an actual junction.
- Official `skill-creator/scripts/quick_validate.py`: both Standard and Lab passed using the existing isolated PyYAML environment.
- Lab harness checks passed; source/release parity is checked again at handoff.
- Original behavior case and Oracle files remain unchanged. V143 still demands retired event-ID authority; it now reports `OracleIncompatible` rather than a false pass. Its migration and the broader baseline comparison remain release work.

## Behavioral Evidence

- `dialogues-low-r1/A01`: a three-turn actual-file software interview passed independent review, but used an earlier repair snapshot. It is supporting evidence, not final-candidate acceptance.
- `dialogues-final-low`: A01-A03 exceeded the 240-second per-turn limit; A06 passed. A04 and A05 initially received Fail reviews.
- A04 review correction: the reviewer had not received the explicit authorization for isolated `.allred-control` writes and demanded a final delivery choice during intake. The unchanged transcript passed a fresh independent review in `review-correction-A04-low`; the original Fail report is preserved. The review prompt and offline-report assertion were clarified, without changing runtime behavior to fit that scenario.
- A05 exposed a genuine breadth issue: the response requested four evidence categories instead of selecting one discriminating observation. The generic debugging owner now distinguishes an internal search list from a user questionnaire. Both `debug-retest-low` and `debug-retest-xhigh` passed after this correction.
- `dialogues-final-xhigh`: A05 passed; A01-A04 and A06 exceeded the 300-second per-turn limit. The targeted current debugging rerun passed at both efforts. Timeouts are incomplete evidence, not a Skill pass, and do not by themselves identify a network or model defect.
- These broad dialogues used frozen snapshots made before the last PowerShell Text compatibility and documentation-coherence corrections. They cannot certify the final exact snapshot. No full cross-model or baseline-comparison acceptance is claimed.

## Remaining Work

1. Complete low/high behavioral acceptance for the current exact snapshot, retaining all failed and timeout attempts. Diagnose tool/startup cost separately from semantic interaction quality.
2. Migrate the frozen V143 gate assertion to actual-state evidence without discarding its mature no-extra-question behavior; complete the broader candidate/baseline comparison.
3. Run isolated installation and final release checks before any publication. No GitHub push or Release is authorized by this maintenance turn.

The CLI configuration originally pointed at a missing model-catalog file. Tests used a per-process `ModelCatalogPath` override to an existing catalog; the user's global configuration was not edited. No original user project, personal knowledge base, memory Skill, or notes Skill was modified.
