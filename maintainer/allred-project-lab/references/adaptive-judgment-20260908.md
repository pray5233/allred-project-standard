# AI Judgment And Objective Guards

## Problem And Scope

Ordinary and beginner users need relevant, understandable decisions that adapt
to their replies. The packet validator rejected drafts for inferred question
counts, line/character counts and phrase matches. These heuristics cannot establish
semantic quality; a passing state also cannot certify customer understanding.
The earlier simplification comparison had mixed results, so it is not an accepted
baseline and does not justify removing intake, continuity or start authorization.

Freeze: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-adaptive-judgment/baseline`,
140 files from the inherited dirty working tree, with an adjacent SHA256 manifest.
This round changes presentation authority only, not the schema or stage gates.

## Benchmarks Inspected

- Local rc15 Question Packet Contract and runtime checks, inspected 2026-09-08:
  preserve compact questions, unanswered siblings, prerequisite checks and actual
  authorization. Reuse the existing validator's separate error and result paths.
- Installed official `skill-creator/SKILL.md`, inspected 2026-09-08: leave judgment
  to the model for open-ended work; reserve deterministic requirements for fragile
  operations. No external dependency or new runtime Skill is needed.
- Installed `grilling/SKILL.md`, inspected 2026-09-08: recompute the decision tree
  after answers and let the agent investigate facts. Do not adopt its instruction
  to expose the entire frontier, dispatch subagents or interview every branch;
  Allred's user feedback requires readable groups and scoped completion.
- Local `core-simplification-20260907.md` and `review-context-20260908.md`: retain
  original failures and separate reviewer accuracy from actor behavior. A lab
  correction is not proof of a better project conversation.

## Ownership Decision

AI chooses what to inspect, which unknowns matter, how to group questions and when
the evidence supports continuing. User-owned facts remain unknown until supplied
or observed; material product trade-offs follow the user's choices or explicit
delegation. The existing start authorization remains unchanged.

The script checks declared identifiers, recorded prerequisite consistency, intake
source presence and state integrity. Text heuristics become advisory warnings;
they neither block an otherwise valid packet nor certify its meaning. Counts are
not quotas. In particular, many short facts can be easier than one complex choice.
Warnings may prompt useful revision but not a mandatory repair loop. The same
unanswered queue, scope provenance and authorization checks remain in force.

Reuse schema-v1 output with additive `warnings` and `semantic_validation` fields;
use `review_presentation` when warnings exist and `repair_input` for hard errors.
Do not change existing outcome assertions to manufacture a behavioral pass.

## Acceptance

1. PS7/PS5.1: presentation warnings preserve exact draft and input hashes, return
   success without semantic approval, and never grant execution authority.
2. Hard negative controls still reject incomplete intake, unselected/missing IDs,
   unresolved parents, unsupported evidence and settled questions even when a
   packet also produces presentation warnings.
3. Retain old behavioral cases and compare their actual replies with prior evidence:
   partial-answer software A01, training A02, complete-input A07 and combined-answer
   A12. Evaluate usefulness, answer fidelity, pending branches, scope and actual
   tools separately. No elapsed-time or round-count quality score.
4. Quick, official validation, source/mirror parity and frozen-source integrity.
   Single trials are bounded evidence, not stability or release acceptance.

## Limits

The per-packet state gate and broader record protocol still exist. This scoped
change cannot prove they are efficient or that AI reasoning is now reliable.
Do not generalize from numeric-lint removal to deleting objective guards. Future
changes need an outcome-based comparison with an environment-complete reviewer;
the separate three-arm pair-review context gap remains outside this round.

No version bump, Git commit or publication in this continuation.

## Observed Results

PS7 and PS5.1 each passed 242 focused assertions after fixing a test-only string
interpolation typo; retain both initial failed attempts. Quick passed 16/16 and
both Skills passed the installed official validator. An identical five-question
draft/state contrast changed from a numeric rejection before the actual guard
to advisory output with the actual guard executed. This is mechanism evidence,
not conversational quality evidence.

Four actual-tool dialogues completed nine user turns on gpt-5.6-sol low. Original
grounded reviews: A01 Fail (7/8), A02 Fail (5/8), A07 Pass (7/7), A12 Fail (3/6).
A02/A07 needed one citation-only repair each, with judgments unchanged. Existing
wide-frontier V144 separately returned Partial; it uses a legacy tool-event
scenario and cannot prove an integrated state gate. No rubric was weakened.

Maintainer inspection supports the diagnostic-narration finding and A02's overly
strong claims about a proposed arrangement and remaining choices. A07 passed its
case while still narrating record repair, showing that a case pass is not full UX
acceptance. A12 assertions 2 and 6 have unsupported violations: the two confirmed
rows retain the full editing/history requirement with an explicit dependency and
shared literal source; listing two current questions does not claim an exhaustive
future frontier. Preserve the original review and these disagreements separately.
Do not add runtime rules to satisfy those disputed findings.

Overall behavioral acceptance is not met. Next prioritize a bounded comparison
of conversational judgment versus per-round record obligations, with separate
experience and contract criteria. Preserve materials-first intake, cumulative
unanswered facets and actual start authorization; do not infer permission to
remove them from this experiment. The original pair-review context gap must be
resolved before claiming a complete three-arm comparison.

Full evidence, transcripts and audit are under the frozen experiment's parent
directory in `验证报告.md`, `对话记录.md` and `audit.json`. The runtime snapshot
differs from the final source only in the corrected test helper, not the executed
validator or conversation references. No publication or stability claim.
