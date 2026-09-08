# Question Result Consumption

## Problem And Benchmark

Users should receive meaningful next questions, not a repair diary of internal
checks. The 2026-09-08 A12 run completes a question command with readable output
at event line 14, then claims at line 15 that no readable output returned and
repeats the command. The CLI event log proves process output and order, but the
ephemeral run does not preserve the original model-facing tool response. Do not
claim that these events alone prove why the model failed to consume the result.

The current validator mixes status text, a separate gate result, a scope caveat
and a delimited packet. Its caveat says packet lint is not DECISION validation,
even when the adjacent line reports a completed DECISION aggregate. This is an
interface ambiguity, not proof of the historical failure's sole cause.

Local benchmark: `prepare_answer_update.ps1` already emits a single JSON object;
the aggregate validator preserves independent subprocess exit results. Reuse
those patterns with the existing question guards. The installed `skill-creator`
guidance favors small deterministic helpers and outcome tests. No new library,
tool, external process skill, user confirmation or user trigger is required.

Baseline: live `0.8.0-rc15` tree on 2026-09-08 at HEAD
`2ade4dc988a6b6b75f3672019c83b2e2b60ce253`, including inherited local changes.
Frozen under
`F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-result-consumption/before`.

## Candidate

Add `-AsJson` to the existing question validator. Emit one result with status,
the actual decision-guard status/scope, exact input binding, errors, next action,
and the question text only on success. Explicitly leave execution unauthorized.
Keep the existing text mode for callers and regression evidence; clarify its
scope sentence without weakening any gate. JSON does not cache a pass or replace
READY/EXECUTION checks. A malformed/missing tool result remains unverified.

Initially route ordinary model use to this output mode through the entrypoint
and frontier owner as an experiment. Withdraw that routing if unchanged-case
behavior does not improve; the optional interface can remain independently
verified. Preserve the full intake and answer-state behavior.

## Tool Collection Follow-Up

The JSON-routing experiment did not resolve repeated diagnostics. It was
withdrawn before the next candidate. Entry/frontier wording returned to the
pre-experiment form, except for one command-result collection instruction in
SKILL.md. The optional JSON interface is not the claimed behavioral remedy.

On 2026-09-08, the native pending-marker probe launched one read-only command.
The first return had session_id=63553, output="" and no exit_code. Collecting
the same session returned exit_code=0 and ALLRED_PENDING_PROBE. Emitting only
result.output would hide the handle. This follows the installed exec_command /
write_stdin tool contract, the exact local benchmark for asynchronous collection;
no package or new runtime helper is needed. The traced A12 context command also
completed after the model-facing blank output (native lines 65/67/69), which is
consistent with lost pending metadata, although that original full return was
not emitted and cannot be reconstructed as direct evidence.

Have the existing entrypoint retain the whole awaited return via text(result),
then collect an actual session_id with write_stdin before interpreting completion.
No increased command timeout, question cap, workflow gate or user approval.
Acceptance: unchanged A12 and adjacent A01 dialogues must preserve user meaning
and authorization; inspect full return handling, actual completion and repeated
commands. A small probe proves collection behavior only, not stable usability.

## Acceptance

- JSON parses as one object on pass and logical rejection, retaining exact text
  only on pass. Failed guards never return a sendable packet.
- Unbound readability, new-project DECISION and existing-work frontier are
  distinguished. No output mode grants development approval.
- Bound hashes/IDs correspond to the checked inputs. Malformed input remains
  nonzero; no synthetic success fallback is introduced.
- Text/JSON agree on acceptance across positive/negative existing guard cases;
  PS7 and PS5.1 compatibility, source preservation and legacy output survive.
- Fresh A12 baseline/candidate runs use unchanged inputs and assertions. Review
  full progress messages, exact tool output, repeated calls and stored decisions.
  Adjacent ambiguity behavior is assessed if needed. A candidate failure or
  lack of improvement remains a valid result, not a reason to rewrite assertions.
- Record diagnostics independently from semantic judgments. No time or interview
  round-count acceptance threshold, no automatic stable release claim.

## Results

Evidence root:
`F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-result-consumption`.

- Optional JSON contract: PS7 full suite 172/172; focused PS7 and PS5.1 each
  144/144 after the compatibility correction. An introduced PS5.1 defect made
  Get-Content filesystem metadata expand recursively during JSON serialization.
  Using the underlying plain string via ToString() fixed it. Keep the initial
  interrupted run; it was not a passing compatibility test or a quality timeout.
- The initial mandatory-JSON candidate exceeded the existing training-context
  budget. Shortening restored the unchanged budget; that routing was subsequently
  withdrawn for lack of demonstrated behavioral benefit. No limit was raised.
- Frozen baseline A12, prototype A12, adjacent prototype A01, revised JSON A12
  and native-traced A12 all received Fail judgments. Their raw judgments remain.
  The later collection candidate preserves the original user turns/assertions.
- Collection A12 completed both turns without repeating a successful packet
  check or claiming missing output. It preserved the complete edit/history rule
  and the independent unanswered choice. Default review said Pass but failed
  citation validation, so its recorded status is ReviewerOutputInvalid. A
  separate ordered review of the unchanged dialogue passed all six assertions.
- Collection A01 completed three turns. The final response preserved earlier
  unanswered facets, opened the new inventory choice and honored the beginner
  exit. Its raw review said Pass but citation validation also failed, leaving
  ReviewerOutputInvalid. A separate ordered review of the unchanged dialogue
  passed all seven assertions. Maintainer review still flags technical progress wording as
  a usability gap, even where the case rubric accepts the final question packet.

The native-output audit corrected an earlier inspection mistake: casting a
multipart payload.output array to string made nonempty replies look blank.
Enumerating each text part reveals the original content. Three projected
responses in the traced A12 still were blank; the pending-marker probe demonstrates
how dropping a session handle can cause this, not a universal model/tool defect.
Both successful markers used actual tool return objects; .output is a valid
property but does not preserve completion state by itself.

An ordered reviewer also inferred model-visible availability from a completed
CLI event. The native trace shows why those are separate facts. Another reviewer
treated a current two-question slice as unsupported global completion despite
open coverage. These causal/extent judgments need human review; do not change
old reports, weaken consent rules, or certify semantic truth from locatable
quotes alone. Their independent diagnostic-narration findings still apply.

Retain the optional interface, clarified legacy scope sentence, plain-string
compatibility fix, contract tests and the short full-return collection guidance.
The frontier and intake are otherwise unchanged from this turn's frozen tree;
the prior source-linked blocker fix remains. No trigger, user approval, runtime
dependency, version bump, Git commit, publication or original-project write.
One low-effort sample per route is limited evidence. No high-effort matrix,
full project delivery or stable release acceptance is claimed. See the external
report and audit for complete dialogues, checks, hashes and residual findings.
