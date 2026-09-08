# Per-Assertion Review Experiment

## Problem And Benchmark

Inspected 2026-09-08: the Lab's atomic scope-authority/evidence-truth assertions
in Get-AllredRuntimeReviewCase, ordered evidence IDs, frozen citation repair and
the installed official skill-creator's independent forward-testing guidance.
These match the existing Windows CLI evaluator and require no new dependency.

The prior source-comparison experiment found goal confusion but attached some
incorrect reasons. The bounded hypothesis was that separate assertion calls,
each seeing the same complete original evidence, could reduce cross-criterion
misclassification. Reuse the same schema, assertions, original environment and
review method. Aggregate validated coverage and results mechanically; do not
let a majority vote suppress a violated or missing assertion.

The first experiment preserved the original Counterevidence prompt, changing
only the assertion array. The joint form was checked against its frozen prompt.
PS7 and PS5.1 serialize JSON differently; parsed assertions and all surrounding
instructions/evidence must remain equivalent. The second experiment reused the
previous isolated SourceComparison text verbatim with separate calls. It added
no semantic rule. Both helpers remain in external test evidence, not this Lab.

## Findings And Disposition

A02 was reviewed on its original requirements, authority and truth assertions,
at low and xhigh effort. These are diagnostic subsets, not full-dialogue passes.
They used unchanged original turns and events. The remaining assertions and A06
were not rerun after the predefined stop condition was reached.

- Separate Counterevidence: the low requirements judgment inferred lost scope
  from an omitted question; the high judgment missed the goal distinction.
  Authority classification improved in A02, but the C18 control still attached
  an unauthorized-choice finding to an unselected question.
- Separate SourceComparison: low detected the goal distinction but again mixed
  it with alleged omission and settled-authority findings. High missed it in the
  requirements judgment and raised a different issue about the actor's initial
  independent-completion wording. Do not collapse different reasons because
  they share a Fail result.
- Completeness interpretations varied. New self-study requirements cannot be
  retroactive evidence of an earlier omission. A current question list alone
  does not establish deletion; an actual contradicted completion claim can.

Neither method met semantic acceptance. Do not promote either, expand the
runtime questionnaire, change the default reviewer or treat per-assertion
execution as inherently more reliable. It also requires more model calls.
Timing is diagnostic only; this experiment does not estimate reliability.

## Fixture Correction

The experimental bootstrap passed an absent optional assertions property as
null for C05/C06. The established calibration runner first normalizes it to an
empty array. This created an extra blank assertion; exclude both original case
aggregates from quality scoring, including the one whose aggregate matched.
Keep their six original calls. Reconstruct those two inputs in a separate
directory using the established normalization, reject blank assertions before
model execution, and re-evaluate their four valid assertions. No source reply,
expected answer, production test or runtime script was changed by this fix.

## Source Attribution Correction

A02's original brief says: "Success: complete a usable issue record and handoff
from an example." It does not explicitly require independent completion or
submission. "Independently" appeared in the actor's first paraphrase. Earlier
maintenance prose must not treat that addition as user-confirmed authority.

This does not automatically make the addition unauthorized: compare its actual
effect with the original outcome and bounded delegation. The practical-result
versus comprehension distinction still matters. Keep that distinction separate
from proof arrangements, routine teaching detail and actual settled changes.
An AI paraphrase is evidence of what the actor said, not automatically evidence
that the user approved every qualifier.

## Evidence And Next Use

Evidence root:
F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-assertion-isolation-review

See its Chinese report, original unit outputs, source-attribution correction,
fixture correction and audit. These are review-only experiments, not new project
behavior or release acceptance. The in-use main Skill and Lab scripts remain
unchanged; the previous 26 calibration cases remain intact.

Use AI review to surface source-backed candidate findings. Before using a finding
to change the Skill, verify the original requirement and the actual consequence
of the observed reply. Resolve materially disputed reasons separately; do not
automatically rewrite the workflow from an aggregate verdict. Preserve contrary
findings and test failures rather than continuing prompt variants until Pass.
