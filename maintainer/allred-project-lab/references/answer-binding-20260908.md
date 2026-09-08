# Literal Answer Binding

Status: structural prototype verified; required runtime integration withdrawn
after failed dialogue acceptance. No commit or publication.

## Diagnosis And Benchmark

The previous A01 failure was already present in the model-authored patch and a
progress message before update_project_state ran. The serializer preserved that
wrong interpretation; it did not transform a correct one. The prior isolated
context probes were different tasks, not earlier correct steps in that live run.

Users need ambiguous replies to leave alternatives unresolved while explicit
combined/custom replies advance once. Local benchmarks inspected 2026-09-08:
the three-case structured interpretation probe (full and focused contexts),
the existing stable-ID updater, exact source/hash binding and immutable snapshots.
Reuse those paths and installed official skill-creator's progressive disclosure.
PM Skills' broader comparison reference remains in core-simplification-20260907.md.
No new external Skill, plugin, package, user keyword or user approval is needed.

## Change

- A read-only preparer supplies the actual prior question draft, full reply,
  current decision rows and original source quotes. It asks for the bounded
  interpretation first, before record/architecture work.
- The existing updater accepts an optional answer_map in its normal patch. It
  binds that interpretation to the unchanged input files and state, stores the
  complete reply, and derives decision status/choice/approval_source without a
  second model-authored translation. Pending IDs must account for the remaining
  unresolved decisions. New facts/requirements can still enter ordinary upserts.
- Optional resolved rows retain existing explicit deferral, rejection and
  replacement semantics. Their resolution source is bound to the same literal
  reply, and the established lifecycle guard validates reasons/replacement IDs.
- Initial intake, existing exact work and non-answer updates keep their existing
  path. Explicit corrections of prior choices remain possible; the mechanism
  does not grant execution authority or require a new user confirmation.
- A valid map is structural traceability, not a semantic verdict. An incorrectly
  chosen option can still be faithfully written; actual conversation evaluation
  must detect it. The preparer cannot prove that supplied local text is the real
  conversation. Do not claim authenticated intent from a file hash.

## Acceptance

Freeze this candidate before actual tests. Verify exact mapping into state, full
literal quote preservation, untouched siblings, explicit corrections, stale
inputs, incomplete maps, contradictory overrides and no writes on rejection.
Run PS7/PS5.1, shared runtime contracts, official validation, and actual A01/A12
plus A02 when the first two justify expansion. Keep original cases and judges;
inspect command and state evidence as well as final replies. No total interview
round or elapsed-time quality target, no date/record-specific runtime rules.

## Maintainer-Only Experiment

Ordinary runtime references no longer require preparation or answer_map. The
three affected runtime documents have been restored to this round's frozen
baseline. Optional scripts and tests remain available for controlled maintenance
experiments; retaining them does not declare them a successful runtime design.

For an isolated experiment, preserve the actual visible question and complete
literal reply in its authorized evidence area, then call the Standard script:

```powershell
& scripts/prepare_answer_update.ps1 -StatePath <latest-state> -QuestionPath <previous-question> -ReplyPath <full-reply>
```

Use the returned binding in the existing updater's patch:

```text
{"answer_map": {"binding": <returned binding>,
                "confirmed": [{"id": "D-id", "choice": "settled meaning"}],
                "pending": ["every remaining unresolved D ID"],
                "resolved": [{"id": "D-id", "status": "deferred", "reason": "literal user reason"}]},
 "upsert": <optional ordinary new facts, requirements and questions>}
```

resolved is optional; superseded rows additionally need superseded_by IDs.
Already confirmed choices need no repeated entry unless explicitly corrected.
Use source_id for ordinary new facts; do not override generated mapped fields.
Every old unresolved ID appears exactly once. The full reply is preserved, and
no approval is generated. Local hashes do not authenticate conversational origin
or establish that the model's interpretation is true.

## Progress

- [x] Freeze current sources and trace the original failure to interpretation.
- [x] Implement preparation and exact answer-map application.
- [x] Run deterministic and compatibility checks.
- [x] Run and independently inspect fresh runtime dialogues.
- [x] Synchronize mirrors and report evidence and acceptance gaps.

## Observed Results And Integration Decision

Evidence: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-answer-binding`.
The unchanged A01/A12 cases ran through actual CLI tools with gpt-5.6-sol/low.
Both frozen model reviews returned Fail. A01 still narrowed an ambiguous reply;
its authority review accepted that inference, which the maintainer disputes.
A12 correctly applied the explicit combined answer but exposed validator
diagnostics in progress messages. Retain all original judgments and this
disagreement; neither a tidy final reply nor hash fidelity cures those defects.

Three observed mapped updates preserve the complete supplied reply, copy mapped
choices exactly and retain pending siblings. This verifies serialization, not
the interpretation. The prototype therefore did not meet behavioral acceptance.
Mandatory preparation was withdrawn from SKILL, frontier and record instructions;
those three files match the pre-experiment baseline. Optional API and Lab tests
remain for further controlled experiments. No ordinary trigger, dependency,
approval round or default preparation step was added.

Mechanical checks: 76 mapping assertions in each of PS7 and PS5.1; 266 older
updater assertions; 100 shared runtime assertions; structure, route budgets,
Lab/harness structure and official validation passed. Earlier failed harness
attempts are retained. The reader's PowerShell metadata serialization bug and
single-element array validation bug were fixed; the fixture also needed its
neutral execution_plan. A02 and high-effort expansion were not run because
the changed first cases already failed acceptance.

Next design work must first test the actual failed question/reply in a genuinely
separate interpretation context, then resume the same dialogue, against the
same-context path and an unchanged rubric. Prior isolated probes were different
tasks and cannot predict this result. Also determine whether missing-output
narration comes from model interpretation or tool-result handoff before changing
runtime guards. Do not add another general confirmation gate, scenario-specific
rule or mandatory model dependency without evidence of benefit.
