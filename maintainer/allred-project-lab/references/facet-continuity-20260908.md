# Pending Facet Continuity

## Problem And Benchmarks

The previous A01 high-effort run answered one part of a two-part Q, cleared the
whole remaining_facets array and marked the Q confirmed. The existing terminal
check rejects a nonempty array on a closed Q but accepts clearing it first.
This affects every multi-part factual question, independent of product domain.

Inspected 2026-09-08: local state_validation_common.ps1's stable Q identity and
source-linked D retirement/active replacement checks, update_project_state.ps1's
immutable incremental snapshots and parent hashes, and the partial factual
controls in check_state_updates.ps1. These are comparable because they already
protect accumulated unanswered meanings without another user interaction.
Installed official skill-creator recommends narrow deterministic protections for
fragile invariants, proportional instructions and preserving user-owned scope.
No additional skill, dependency, process or network lookup is required.

Baseline HEAD: 2ade4dc988a6b6b75f3672019c83b2e2b60ce253, with inherited changes.
137 source files were frozen under
F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-facet-continuity/before.
Original project data, transcripts and historical verdicts remain unchanged.

## Bounded Design

Reuse the current Q/D and parent comparison. A removed recorded facet needs one
facet_resolutions entry: an answered/unknown/not-applicable disposition with its
source, or a transfer to an active Q/D that still carries that exact facet.
User-backed dispositions carry an exact quoted substring; evidence-backed facts
and non-applicability carry a reason. Do not use an unresolved D as evidence.
Keeping a facet unchanged requires no record. Visible wording can improve
without renaming the internal facet key. The records belong to the existing
patch, not another user approval, CLI phase or question-count limit. Apply the
same check after a transfer into D; a later D update must not lose it either.
A decision cannot justify its own removed facet by citing itself as a parent.

New updater snapshots stamp this accounting contract in authoring. Old
unversioned history retains its former checks; applying a new update still
checks every removal. This avoids retrospectively invalidating legitimate old
closures that never had the new field. Unversioned/manual historical snapshots
cannot certify this additional continuity property.

The script checks accounting and exact source text, not semantic entailment.
Writing a related quote against every facet can still be wrong. This change
does not solve whole-D ambiguity or certify discovery. Keep existing semantic
review assertions, user qualifiers and routine implementation freedom.

## Acceptance

- Replay the exact old parent/patch: baseline saves the lossy state; candidate
  rejects it without writing a new snapshot or changing original evidence.
- Generic controls: partial and complete answers, explicit unknown, evidence,
  non-applicability, active transfers, missing/duplicate/wrong sources, fabricated
  quotes, inactive/self/unaccounted transfer, unrelated updates and legacy roots.
- Run the real updater and parent gate on PS7/PS5.1, then existing state/answer
  tests, runtime contracts and affected Quick components for shared validation
  behavior. Reuse unchanged reviewer-interface contracts rather than repeat them.
- Fresh A01 low/high and adjacent A12 low use original inputs, original
  assertions, actual files/tools and frozen snapshots. Preserve every failure;
  inspect whether remaining meanings survive and whether questions stay useful.
- No runtime domain-specific rule, ordinary trigger, mandatory review agent,
  new user confirmation or publication. Verify source/release mirror parity.

Results are recorded in the external report. A deterministic rejection alone
does not establish improved conversations or release acceptance.

## Verified Results And Limits

The old hash-bound parent/patch saves the lossy state on the frozen baseline;
the candidate rejects both unaccounted removals without creating a snapshot.
Authored corrected replays retain the unanswered facet in Q or explicitly
transfer it into a pending D. They pass the updater and parent check, but are
not model-generated behavior evidence.

Final state-update contracts pass 448 assertions on each of PowerShell 7 and
5.1. Existing answer-mapping contracts pass 77 assertions; runtime contracts
pass 172. Structure, invariant ownership, generic policy, route budget and
official Skill validation pass. Standard's official validator required the
existing Python environment's UTF-8 mode on Windows; no dependency was added.

Fresh low-effort A01 and A12 dialogues retain unanswered siblings, allow an
expression-mode change without restarting intake, and preserve an explicit
combined correction/history answer. Both still receive grounded Fail reviews
for visible internal mechanics. The additional sole-gap interpretation remains
debatable in context; preserve that disagreement rather than rewrite results.

Manual A01-low state inspection found a confirmed D retaining remaining_facets,
despite having answer receipts. The actual frontier validator also accepts
that state. This retained-array consistency problem is outside the new
removed-facet check and remains open. Literal quotations can still accompany
over-broad interpretations; their presence does not certify approval. The
high-effort dialogue also recommended a convenient answer to a factual question.
These require generic lifecycle/semantic review, not product-specific rules or
additional user approval ceremonies.

The external audit reports final high-effort results, preserved interrupted
attempts, source/mirror hashes, baseline integrity and unchanged HEAD. This is
a bounded retained fix, not complete interview or release acceptance.

Final A01 high completed three turns and received Grounded / Fail (5 of 8
assertions met). Its review alleged invented user quotes even though those
exact strings occur in the actual harness-supplied turn prompt. Preserve the
source-context disagreement and distinguish harness constraints from product
requirements; do not certify that accusation merely because citations resolve.
Decision-axis refinement versus a new linked child also needs semantic review.
The independently observed internal-process narration still supports Fail.
