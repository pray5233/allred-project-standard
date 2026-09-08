# Goal Inheritance Review Calibration

## Problem And Benchmark

In the original native A02 dialogue, a self-study request led to asking whether
reading comprehension could replace an already required practical result. Two
earlier reviews accepted the dialogue. Exact quotes did not prove the proposed
alternatives preserved the source meaning. A separate risk is overreacting to
one omitted question by demanding every pending choice in every turn.

Inspected 2026-09-08: installed official skill-creator's intent preservation,
proportional specificity and independent tests; local Reviewer Ownership
Calibration, C01/C03/C09 controls, original-event evidence, frozen judgments and
Counterevidence review. These are the same Windows CLI semantic-review path.
Reuse the existing runner, assertions, schema and citation validator. No new
dependency, user trigger, runtime state or approval is required.

## Isolated Method

`-ReviewMethod SourceComparison` exists only in the external experiment's
candidate-lab and candidate-lab-r2 copies. It was not promoted. The installed
Lab retains Standard and Counterevidence unchanged; only new calibration cases
and this evidence record were accepted. No runtime interview was changed.

Within the existing review, AI compares original requirements and authorized
changes with the later concrete alternatives. It distinguishes the desired
result, how success is demonstrated and how work is delivered. Findings cite
both the source and the proposed difference. The existing reason fields carry
the explanation; there is no new output schema or separate AI process.

Judge an unresolved detail, equivalent implementation and actual scope change
differently. A user can explicitly revise a goal or ask to reconsider it. A
clearly marked pending scope-change suggestion is different from treating the
change as equivalent compliance. For alleged loss, identify an actual deletion,
replacement, closure or false completeness claim; omission from one question
slice alone does not establish loss. Missing evidence stays uncertain.

Runtime question quality and actual settled authority remain distinct. An
inaccurate question need not imply that the change was implemented or accepted.
Do not turn that distinction into mandatory approvals for ordinary details.

## Checks And Usage

```powershell
& ./scripts/run_review_calibration.ps1 -OutputRoot <new-directory> `
  -ControlIds @('C17','C18','C19','C20','C21','C22','C23','C24','C25','C26') `
  -ReviewMethod Counterevidence -Model gpt-5.6-sol `
  -ReasoningEffort low -UseUserConfig
& <isolated-candidate>/scripts/run_ordered_review.ps1 -OutputRoot <new-review> `
  -ReplayRoot <unchanged-dialogue> -SuitePath <original-suite> -CaseIds A02 `
  -ReviewMethod SourceComparison -UseUserConfig
```

The array syntax belongs in a PowerShell script or interactive call; an external
PowerShell -File invocation does not split comma-separated strings into IDs.
New controls C17-C26 pair retained/revised goals, verification versus guarantees,
pending versus settled scope changes and presentation versus completeness.
They live only in maintenance tests, not in runtime scenario-specific rules.

The isolated candidate's check_runtime_review_pipeline.ps1 exercised nine mocked
paths, including method selection reaching the prompt/manifest, Legacy behavior
and strict citation-only repair. Those code edits were not promoted. Installed
Quick and its existing checks remain unchanged. PS7/PS5.1 compatibility and exact
old method text were checked independently from semantic performance.

## Evidence And Limits

Evidence root:
F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-goal-inheritance-review

The first source-comparison method detected the target problem but also alleged
lost scope solely because a pending question was not repeated. That version is
retained separately. The second method requires an observed change or an actual
contradicted completeness claim. Original A02 turns, materials, tools and
assertions remained unchanged; these are review-only experiments.

Second-method low/high A02 reviews identified the learning-goal defect. The low
review needed one citation-only repair; its results and reasons were frozen,
and the original invalid report remains. The high review was directly grounded.
The high review distinguished the bad question from an unauthorized settled
choice. The low review's authority classification and the high review's further
sole-gap finding are not independently accepted in full. An accurate aggregate
Fail does not certify every explanation or prove superiority over the old method.

Both first-method low control arms met all eight common expected outcomes. Simple
controls therefore did not reveal the original full-context failure. The second
method matched 12/12 low and 12/12 high controls, including ordinary supporting
detail, changed proof, explicit goal revision, pending scope changes and the
existing bounded-packet/completeness pair. A06 still identified active disruption
inside read-only advice; it needed one frozen-judgment citation repair. Across
both revisions and the old method, all 44 control observations matched expected
outcomes. These are not 44 unique scenarios or independent users.

All four invalid full-dialogue reports received the same one-attempt citation
repair, preserving their Fail judgments and every reason. Original invalid
reports remain; no repair was used to change the verdict. Expected results are
hidden from reviewers. No rubric was relaxed, source reply rewritten or runtime
candidate promoted. No time or conversation-round quality score applies.

The candidate was held because valid negative findings still came with
misclassification of a pending question as a settled decision and a disputed
sole-gap finding. Aggregate correctness cannot excuse a materially wrong reason.
Next compare the evidence needed for each assertion before adding more reviewer
instructions; retain source fidelity, actual authority and completeness as
separate judgments. This record does not certify the project interview or make
the experimental reviewer a release authority.
