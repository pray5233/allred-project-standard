# ADR: Allred Runtime And Maintenance Ownership

- Status: accepted for `0.8.0-rc10`
- Date: 2026-08-29
- Baseline: `0.8.0-rc9`, Git commit `eeb2f04`

## Problem And Success Criteria

The runtime Skill accumulated source-monitoring, shared-collaboration, office-delivery, and Skill-maintenance rules in one context. Unrelated projects therefore loaded domain rules, descriptions attracted ordinary work, and exact-sentence static checks made safe wording changes expensive.

Success means:

- one ordinary user entry: `allred-project-standard`
- no shared-collaboration, external-source, or company-office detail in unrelated route context
- one-time external lookup does not inherit monitoring persistence/scheduling behavior
- Skill maintenance does not appear as a user project route
- deterministic checks validate ownership and coverage without prescribing generated prose
- software, training, external data, shared collaboration, debugging, and long-term behavior pass at low and high reasoning effort

## Benchmarks

| Source | Version/date | Comparable path | Reused principle |
| --- | --- | --- | --- |
| local accepted Allred baseline | `0.8.0-rc9`, 2026-08-29 | mature requirement collection and stage gates | preserve behavior before modularizing |
| OpenAI `skill-creator` | installed local reference, checked 2026-08-29 | Codex Skill structure and invocation policy | concise discovery, progressive disclosure, explicit-only maintenance Skill, behavior over prose matching |
| Anthropic Skills repository | `main`, reviewed 2026-08-29 | narrow capabilities with supporting references | keep conditional detail behind routed resources |
| GitHub Spec Kit | `main`, reviewed 2026-08-29 | core workflow plus optional quality/extension commands | separate stable runtime flow from optional maintenance capabilities |
| OpenSpec | `main`, reviewed 2026-08-29 | baseline plus explicit change artifacts | treat Skill refactors as bounded changes against an immutable baseline |
| Anthropic Skill Creator | `main`, reviewed 2026-08-30 | Skill eval execution, grader, blind comparator, iteration reports | baseline-versus-candidate runs, independent evidence grading, fixed artifacts, HTML review |
| Agent Skills evaluation guide | `main`, reviewed 2026-08-30 | eval-driven Skill iteration | isolated runs, objective assertions, timing/cost deltas, human review after automation |
| OpenAI Skills evaluation fixtures | `main`, reviewed 2026-08-30 | realistic cross-model Skill scenarios | store prompts, expected behavior, and measurable success criteria as versioned JSON |
| Promptfoo | repository state reviewed 2026-08-30 | general LLM matrix and CI evaluation | retained as a future adapter option; no dependency added while the Codex runner covers current needs |

The repositories were used as architecture benchmarks, not runtime dependencies. No package, Node.js tool, or external process framework is required.

## Automated Candidate Validation Addendum

Repeated manual conversation testing is too slow and makes it difficult to distinguish a real regression from model variance. The Lab therefore owns one local-first candidate pipeline:

1. derive impacted cases from Git changes, invariant ownership, explicit adjacency, and changed JSON case bodies
2. replay immutable known-good and known-bad records through an independent reviewer
3. run only affected behavior cases during iteration
4. add the cross-domain release matrix and low/high reasoning variants for a candidate
5. compare the candidate with an accepted Git snapshot without revealing version identity to the comparator
6. retain transcripts, reviewer output, logs, configuration, and a static HTML report

Deliberate differences from the benchmarks:

- retain the existing Codex CLI runner, hidden Oracle, and PowerShell tooling instead of adding Claude-specific execution or Promptfoo
- use deterministic scripts for structure, ownership, mutation, install, and parity; use model review only for semantic behavior
- do not automatically rewrite the Skill after a failure; the Lab reports the first divergence and the maintainer changes the smallest owner
- do not require every edit to run the full matrix; `Quick`, `Changed`, and `Candidate` scale cost with release risk

Acceptance metrics:

- one command produces a reviewable PASS/FAIL/INCONCLUSIVE report
- a changed owner selects its invariant cases and declared adjacent regressions
- unknown Standard changes fail safe to the release matrix
- known-good and known-bad fixed records are classified as expected
- a material baseline win blocks candidate promotion
- authentication, network, model, timeout, and validator failures remain inconclusive
- automation changes do not add ordinary user triggers or runtime project rules

## Decision

1. `allred-project-standard` owns activation, project routing, requirement collection, stage gates, execution, verification, and three conditional overlays.
2. `shared-collaboration`, `external-source`, and `company-office-delivery` are references loaded only from evidence-backed overlay selection. They add no user trigger words.
3. `allred-project-lab` is explicit-only and owns Skill refactoring, invariant maintenance, evaluations, and release review.
4. `allred-project-memory` and `allred-obsidian-notes` remain independent exact-trigger handoffs after project work. They do not collect requirements.
5. The target Skill keeps its own validators and behavior fixtures because they version the runtime contract; the Lab invokes and reviews them.

## Deliberate Differences

- Keep one integrated project workflow rather than splitting every runtime stage into a separately invoked Skill. Users should not compose process modules manually.
- Do not require external spec tooling, mandatory TDD, worktrees, per-step commits, or repeated approval gates.
- Preserve the mature Allred requirement intake and stage validators; modularization changes context ownership, not conversation topology.

## Acceptance Metrics

- unrelated route output contains zero conditional overlay sources
- each overlay can be selected independently and reports its source in route metrics
- every P0 invariant has one canonical owner and at least one behavior case
- exact prose checks are reduced to structural markers and deterministic script contracts
- six scenario groups pass on low and high reasoning effort without new ordinary trigger words
- source/release parity and official Skill validation pass

## Acceptance Evidence

Final candidate evidence on 2026-08-30:

- invariant ownership passed: 14 invariants, 3 conditional overlays, 6 release scenario groups
- route budget, route isolation, 140-case behavior manifest, and 124 P0-case coverage checks passed
- `V134-V137` and `V139-V141` passed together at low and high reasoning effort on the final main-Skill snapshot
- `V138` passed separately at low and high reasoning effort after its fixture supplied the aggregate DECISION/frontier gate required by the runtime contract
- maintainer case `L01` passed and did not route Skill maintenance through ordinary project intake
- source/release parity passed for the runtime Skill and Lab; official `quick_validate.py` passed for both source and release copies

Earlier `V138` partial/fail runs were retained as test-design evidence: the fixture originally expected a product decision packet without supplying the mandatory stage-transition state. The corrected fixture now validates collaboration behavior without rewarding a runtime-gate violation.

## Candidate Hardening Addendum: Materials, Shared Work, And Evaluation UX

- Date: 2026-08-30
- Status: candidate validation in progress
- Known-good benchmark: `0.8.0-rc9`, Git commit `eeb2f04`

The accepted baseline is comparable because its material-first intake, concentrated user decisions, and single final start gate already produced the preferred interaction shape. The rc10 modular architecture is retained, but conflicting or low-salience rules must not make the candidate heavier than that baseline.

Implementation path reused from the benchmark:

- promised materials and the user's first-version idea precede optional intake
- sample findings become visible recommendations or unresolved items, never silent defaults
- shared work separates current intake facts from future authority decisions
- the user sees concise evidence conclusions while exact sample identities remain reproducible in the evidence record
- one final approval includes any Codex-selected project-root recommendation

Deliberate differences:

- conditional shared, external-source, and monitoring rules remain routed overlays rather than returning to one monolithic runtime context
- compact pre-send completeness checks replace long prose reminders
- low and xhigh behavior runs judge user experience semantically; fixed labels or copying every evidence ID into the visible reply are not required
- blanket shortcuts are rejected when a recommendation is conditional or intentionally neutral

Acceptance metrics for this change:

- `V02` passes material-first intake and one combined final gate
- `V61` preserves semantic evidence and rejects transport-only success without forcing a verbose visible evidence dump
- `V79` preserves the shared parent choice, then either asks current facts or waits for promised material before future shared decisions
- `V81` concentrates shared decisions without a `D1-D15` catalog or unsafe blanket acceptance
- `V119` labels an unconfirmed Codex-selected root as a recommendation
- `V120` does not replace a training request with a Codex-selected curriculum tier
- `V137` preserves schedule, history, source-change, failure, and ownership consequences for monitoring
- the targeted edge group passes at both low and xhigh reasoning effort before full candidate promotion

## Candidate Hardening Addendum: Routed Overlays And Fail-Fast Evals

- Date: 2026-08-30
- Status: targeted validation passed; full candidate pending
- Known-good benchmark: `0.8.0-rc9`, Git commit `eeb2f04`

Observed failures showed two architecture defects rather than a need for more domain prose. First, a model could read generic interaction references and answer a confirmed shared-collaboration problem without invoking the route selector, so the overlay's compact decision contract never entered context. Second, the candidate pipeline propagated batch exit codes but continued to later batches, and a behavior batch continued after its first P0 divergence.

Decision and implementation path:

- an evidence-confirmed overlay must be loaded through `get_route_context.ps1` at the current stage before its domain behavior is rendered
- any non-trivial question packet, scope/curriculum synthesis, READY card, or execution also loads the actual primary route, stage, and variant instead of relying on `SKILL.md` alone
- a continuing project preserves its existing or long-term route instead of restarting new-project intake to obtain an overlay
- the shared DECISION guard owns the five-group rendering; the reference owns authority, conflict, audit, recovery, operation, and acceptance semantics
- independently answerable facets keep stable suffix IDs, while one block-level basis and one natural-language example keep the user surface readable
- candidate batches stop after replay, Lab, low, or high behavior failure; behavior runs stop at the first non-passing P0 while still writing their summary
- behavior transcripts retain executed command names plus bounded exit status and output evidence, so the independent reviewer can verify route loading and validator results without manual event-log inspection

Acceptance metrics:

- event evidence shows the selector was invoked with the confirmed overlay
- `V79` preserves intake facts and defers future governance; `V81` renders five concentrated, naturally answerable groups
- `V79` and `V81` pass at low reasoning effort, and `V81` passes at xhigh
- `V121` preserves beginner-facing delivery consequences without exposing implementation mechanics
- `V99` loads the training route and never converts unrequested curriculum components into confirmed deferrals or exclusions
- P0 `Fail`, `Partial`, reviewer-invalid, or infrastructure outcomes stop later cases and later candidate behavior batches
- route budgets, source/release parity, and full candidate validation remain passing

## Candidate Hardening Addendum: State-Preserving Interaction And Evidence Reporting

- Date: 2026-08-31
- Status: full Candidate passed; ready for one user-operated pilot
- Known-good benchmark: `0.8.0-rc9`, Git commit `eeb2f04`

The late candidate sweep exposed several cross-route defects that were easy to miss in exact prompt examples. They are fixed as reusable invariants rather than domain-specific response text:

- a training intake requests the material location and all independent audience, work-scenario, practice-outcome, and success inputs in one packet; material inspection still precedes evidence-dependent recommendations
- each new-project intake question group states in plain language what its answer changes without expanding into a decision card
- switching standard/beginner expression preserves the complete pending ledger; an incomplete summary is a scope change
- an evidence event is reported before another inspection update, including observed facts, evidence level, limits, active constraints, and write/result boundary
- after each evidence result, the runtime reloads only the current routed stage guard through `get_route_context.ps1 -GuardsOnly`; this avoids both stale pre-action context and a full-reference reread
- render/extraction inspection discloses unchanged originals/project and isolated system-temporary evidence before acting
- event text about an unselected conditional overlay is ignored rather than echoed as an absent or unsupported domain
- a Codex-selected READY root remains visibly pending and separately names the same absolute allowed write root

Test-oracle corrections remain separate from runtime behavior:

- simulated cases cannot require host-project read commands when the harness forbids host inspection; the injected event is the evidence source
- an event-disclosed disposable report under isolated system temp is read-only evidence, not project or original-input mutation
- loading the main Standard Skill or a base route without overlays is not conditional-domain discovery
- the same rule applies to the base long-term route: an observed selector call without `-Overlays` is positive isolation evidence; the reviewer must not require an extra user-facing denial of internal overlays
- global read-only, original-preservation, and isolated-system-temp disclosure is evidence safety across routes; it is not shared-state audit or office-delivery leakage when a non-software training selector call omits `-Overlays`
- loading the Standard knowledge route does not invoke project-memory or Obsidian Skills

Acceptance evidence on the final source snapshot:

- `V22`, `V61`, `V71`, `V99`, `V119`, `V120-V141` each passed at low reasoning effort after fail-fast correction loops
- `V124` preserved the existing training baseline and concentrated independent training inputs
- `V127` explained intake consequences without increasing question count
- `V128` changed expression only and preserved pending scope
- `V129` reported returned evidence before continuing inspection
- `V129` and `V132` passed at low and xhigh with an observed post-event `-GuardsOnly` route call before the evidence report
- the complete candidate run exposed that the existing-debug EVIDENCE route omitted `Hypothesis Discipline`; generic evidence guidance produced a broad follow-up instead of one causal experiment. The route now loads the debug contract at EVIDENCE and requires one bounded experiment with explicit support/weaken outcomes; `V133` passed at low and xhigh after correction
- `V79` first passed at low and xhigh after the shared-intake ledger preserved all current-fact clusters across a sample-first deferral
- the complete candidate run then exposed a second `V79` failure: INTAKE still loaded evidence/ownership language that prompted low-effort models to ask future permission, conflict, audit, source-of-truth, backup, recovery, and acceptance questions immediately after the shared parent choice; the runtime now loads a dedicated `Intake Handoff` section, reuses the preceding packet, and keeps future collaboration governance unavailable until DECISION; the corrected path passed `V79` again at low and xhigh
- a later complete candidate run exposed stochastic `V81` incompleteness: five concentrated groups were rendered correctly, but a shared why/effect line did not cover every independently answerable suffix. The decision guard now runs a compact hidden facet-to-effect coverage lint while preserving one explanation per group rather than expanding into per-question ceremony
- the corrected `V81` path passed twice at low reasoning effort and once at xhigh before the next complete candidate run
- the next complete candidate run exposed `V122` beginner evidence wording that echoed an internal English artifact label. The evidence route now has a compact plain-Chinese rendering guard; this changes expression only and preserves the same route, evidence boundary, and exit behavior
- the corrected `V122` path passed twice at low and once at xhigh; after compacting duplicate evidence-guard prose to remain within route budgets, adjacent `V129` and `V133` passed at low and xhigh
- the following complete candidate run exposed stochastic `V127` intake wording that used one packet-wide consequence sentence instead of explaining each visible group. The intake guard now runs a generic user/workflow, materials, scope, and useful-result effect map without adding questions or rounds
- the corrected `V127` path passed twice at low and once at xhigh before the next complete candidate run
- a complete 32-case xhigh preflight showed the hidden group-level `V81` coverage lint could still omit one facet. The rendering contract now gives each suffix one short parenthetical practical effect while keeping basis, recommendation, and reply guidance once per group; this favors explicit user-readable coverage over brittle implicit aggregation without returning to per-question ceremony
- the first inline-effect xhigh rerun covered every consequence but its illustrative reply sentences still omitted answer syntax for several suffixes. Each group now ends with an optional compact reply skeleton whose ID set must exactly equal the shown question ID set; natural-paragraph replies remain accepted
- the first skeleton rerun exposed a real heading defect (`Q1` used as a topic label) plus reviewer pressure to repeat every facet in group-level why/basis prose. Runtime now forbids IDs on group headings; the Oracle now accepts the intended compact contract: per-facet short effect, group-level basis covering the named domain, and an exact-ID reply skeleton
- the next rerun had complete skeletons but mentioned natural-language replies only in the first block. The contract now requires one packet-wide natural-reply statement rather than repeating it under every group
- the final shared-decision rendering passed two consecutive xhigh `V81` reruns with per-facet effects, exact reply skeletons, ID-free group headings, and one packet-wide natural-reply statement
- the next xhigh preflight exposed a stochastic `V129` regression: after correctly reloading `-GuardsOnly`, the model deferred returned evidence behind another inspection update. The evidence guard now requires the next visible action to report exact-layer observations, limits, constraints, and write/result boundary before further work
- a low rerun then exposed incomplete pre-action disclosure that said only the originals were unchanged. The guard now requires both unchanged originals/project and possible disposable evidence under isolated system temp; corrected `V129` passed at low and xhigh
- `V135` separated two findings: internal stage-validation mechanics are not shared-collaboration leakage, but source search is not a stage transition. The training path now executes the actual DECISION route instead of ending with a future-tense consistency-check promise
- a subsequent `V135` rerun exposed a non-blocking future document-format question. Training delivery now means the current requested result; when the user explicitly requests no files and format does not affect curriculum or acceptance, speculative future document packages stay out of the visible packet. Corrected `V135` passed at low and xhigh
- the post-fix xhigh tail `V136-V141` passed without conditional-overlay, traceability, baseline, or route-isolation regressions
- a later full Candidate exposed `V99` treating evidence-derived training gaps as the complete must-teach list. Training evidence now supplies candidate minimums and always leaves an explicit confirm/correct/add path; speculative future file format remains outside the packet when it does not affect current curriculum or acceptance. `V99` passed at low and xhigh, and adjacent `V124`, `V125`, and `V135` passed at low
- the adjacent xhigh `V124` review incorrectly inferred that existing handouts meant employees had completed those courses. The Oracle now preserves the named material baseline while allowing the consequential question of prerequisite completion or course reuse; it still forbids reopening existence or assuming basic content must be retaught
- after that Oracle correction, adjacent training cases `V124`, `V125`, and `V135` passed together at xhigh as well as low
- the next full Candidate reached `V134` after 24 low passes, where the reviewer mislabeled required main-Skill and base `new-standard` evidence calls as conditional overlay leakage even though neither call included `-Overlays` and the visible reply stayed local-only. The case Oracle now states that base route plus `GuardsOnly` is positive isolation evidence; actual overlay loading or visible domain leakage remains a hard failure
- the following Candidate exposed a real stochastic `V124` defect: the opening said existing App, plugin, and Git handouts would not be repeated before learner completion or curriculum reuse was confirmed. Training baseline semantics now distinguish material availability from learner completion and require explicit authority or inspected evidence before any no-repeat, exclusion, or deferral wording
- two low reruns passed, but xhigh reproduced the same omission. Inspection of the rendered route context found the actual root cause: PowerShell interpreted the leading backtick in `` `existing`` as an ESC control character, corrupting the guard text. The guard now avoids that escape form, and route-budget validation rejects unexpected control characters so silent policy corruption cannot recur
- after the escape fix, `V124`, `V99`, and `V125` passed at both low and xhigh, while xhigh `V135` exposed a second route-order issue: the post-event evidence refresh contained the decision requirement too late and the model rendered questions after only `-GuardsOnly`. The training transition is now the first hard stop in the evidence refresh and requires the actual same-response non-software training decision call before any packet or curriculum synthesis
- the hard-stop correction passed `V135` at low and xhigh; the post-escape training set now has explicit passing evidence for `V99`, `V124`, `V125`, and `V135` at both configured reasoning levels
- full Candidate `r73` then exposed a route-level conflict at xhigh `V124`: `non-software` INTAKE rendered the generic existing-work guard ahead of the training alignment rule, so the model requested only the handout path and postponed independent audience, work-scenario, outcome, and success questions. The local benchmark is the established new-project INTAKE ledger and concentrated-packet behavior, adapted to formal non-software deliverables without importing software scope. `non-software` now has its own INTAKE guard, material location cannot serialize independent baseline questions, and structure validation prevents the generic existing-work guard from returning
- after that route correction, `V124` passed at low and xhigh; adjacent `V99`, `V125`, and `V135` also passed together at low and xhigh before the next full Candidate
- full Candidate `r74` then exposed a separate cross-route EVIDENCE gap at low `V131`: an exact read-only inspection had no target path, but the model loaded EVIDENCE and promised inspection without first obtaining a locatable artifact. The local benchmark is the existing new-project INTAKE exception and beginner inspection rule: missing target asks only for location/sample, while a supplied target proceeds without a broad questionnaire. This condition is now a shared evidence-stage hard stop, with `V131` and the positive supplied-path `V132` used as paired regression cases
- paired low `V131/V132` passed after the location correction; xhigh `V131` passed while `V132` exposed aggregate-to-subgroup inflation by changing a property of the combined sample into a claim about every sheet, and it failed to label the isolated report as disposable evidence. The shared evidence guard now preserves population, sample, subgroup, count, and uncertainty exactly and classifies isolated-temp outputs as disposable read-only evidence across document, table, log, and source inspections
- Candidate `r75` correctly stopped before behavior evaluation because the expanded EVIDENCE guard exceeded two route-context character budgets. The rule was compressed rather than raising the budget, preserving the same hard stops while keeping conditional route contexts within the established context envelope
- the first compressed xhigh rerun then showed that brevity had removed necessary salience: a descriptive fixture label was accepted as a locatable target and one explicitly untested capability was omitted. The guard now states that a name/label is not a path, attachment, or workspace hit and preserves every material negative capability named by evidence. The heaviest office-EVIDENCE cap increased from 28,500 to 28,800 characters (about 1%) rather than compressing a P0 boundary into ambiguity; all other caps remain unchanged
- Candidate `r76` reached low `V122` and exposed a separate interaction regression: an expression-only exit preserved the pending material location but repeated the request verbatim. The entrypoint and beginner adapter now treat a pure expression toggle as a style acknowledgment only, referring to the complete prior pending packet/action without restating or re-asking it; a toggle message that also contains an answer still processes that answer normally
- low `V122/V128` then passed. The xhigh `V122` reply correctly preserved project, stage, scope, and pending action without re-asking, but the reviewer demanded explicit preservation of inspected evidence and settled decisions even though the scenario had produced none. The Oracle now preserves only state that actually exists and forbids inventing prior evidence or decisions to satisfy a literal checklist
- after the Oracle correction, `V122` and adjacent expression-preservation case `V128` passed together at xhigh as well as low
- Candidate `r77` reached low `V130` and correctly refused READY, but only promised future internal preflight after reading the entrypoint. The runtime hard stop now requires the same response to execute every currently available answer-independent route, project/write, rollback, verification, state, and aggregate-gate check; only an exact blocker may stop it, and future-tense intent is not preflight evidence
- the first targeted low rerun still asked immediately for material paths because an older locator rule conflicted with the new preflight obligation. Locator handling now searches the current workspace first and cannot postpone independent project/write, rollback, verification, state, or aggregate checks; a user statement that samples are complete remains a content-status claim rather than a scope gap
- after resolving that conflict, `V130` passed at low and xhigh with observed answer-independent preflight work and no premature READY or mutation
- Candidate `r78` then exposed an authority-source conflict in `V02`: a trusted event supplied aggregate READY plus the complete execution/pending-recommendation record, while the selector required a local `StatePath`; the failed selector call caused the model to reject valid event evidence and lose pending recommendations. The selector now accepts an exact current `ValidatedEventId` for DECISION/READY context only. It cannot authorize EXECUTION, cannot be combined with `StatePath`, and cannot be inferred from user/model prose. Sample evidence that already supports reversible preflight also no longer restarts generic baseline intake
- the first post-`r78` xhigh rerun exposed one remaining material-state defect: when the user explicitly said promised samples had not yet been supplied, the model searched the workspace instead of requesting their location and the missing first-version idea. INTAKE now distinguishes explicitly unsupplied material from available-but-uninspected material; it does not search for the former or open a wider baseline packet before the material arrives or the user chooses a no-material path
- corrected `V02` passed at low and xhigh. The local CLI proxy then became unavailable and exposed a separate evaluation-infrastructure weakness: provider selection was implicit. Candidate, behavior, replay, blind-comparison, and entry-guard runners now accept an explicit model-provider name and environment-key name; the secret remains in the process environment and is never written to reports. Default behavior is unchanged when these parameters are omitted
- release behavior cases are independent across case IDs but ordered within each case. Candidate validation now runs three case workers per batch, preserves each case's sequential turns and isolated transcript, and applies P0 fail-fast between batches. Direct batch invocation remains serial by default. A three-case low-reasoning smoke (`V01`, `V04`, `V22`) passed concurrently before restarting the full candidate
- `V71` passed at low and xhigh after non-software evidence routes prohibited pre-evidence structure, taxonomy, field, package, and acceptance proposals
- `V134` kept unselected overlays silent
- `V140` stayed on the base debugging route and used the evidence-backed minimal fix
- route budgets remained within limits after every high-salience guard change
- full Candidate `r81` completed all static, replay, low/high candidate, baseline-transcript, entry-guard, parity, PowerShell 5.1, official-validation, and isolated-install stages, but its independent blind comparison found four material baseline wins: `V128/V139` serialized intake behind a sample request, while `V141/V22` allowed a post-result `-GuardsOnly` refresh to stand in for full routed evidence review
- the local benchmark for intake remains the accepted mature Q1-Q4 sufficiency model: missing material blocks evidence-dependent recommendations only, while workflow, first-version boundaries, and a recognizable useful result stay co-answerable in the same compact packet. The exact-inspection exception remains narrow
- the local benchmark for evidence review remains the accepted full base route plus the post-result safety refresh. `-GuardsOnly` is now explicitly post-result only; it cannot be the first or only route load, and synthesis beyond a status report reloads normal evidence context
- the two runtime corrections and one Oracle clarification kept every route under its existing context budget. Targeted `r82` then passed `V128`, `V139`, `V141`, and `V22` at low and xhigh; a fresh blind comparison preferred the candidate in all four cases with no candidate-side material regression
- the first full rerun stopped at `V02` because its Oracle still required the superseded sample-only intake. The runtime response correctly asked the missing independent workflow, first-version, and useful-result facts together; the Oracle now rejects serializing those facts behind sample arrival while still forbidding evidence-dependent product choices before inspection
- corrected `V02` passed at low and xhigh. Full `r84` then passed all 32 release cases at both low and xhigh with two case workers per reasoning lane (four total workers), no rate limit, infrastructure failure, output collision, or cross-case context leak
- blind comparison now uses the same bounded case-level parallelism. Candidate validation may reuse immutable baseline transcripts only after exact case coverage, frozen baseline Skill hash, visible test hash, model/provider/reasoning/config checks; current blind review, not the reused historical Oracle verdict, decides regression
- full Candidate `r88` passed against `eeb2f04`: candidate low 32/32, candidate xhigh 32/32, baseline transcripts 32/32 complete, blind comparison 32/32 with zero material candidate regressions (`25` candidate wins, `1` equivalent, `6` non-material baseline preferences), entry write guard 3/3, source/release parity, PowerShell 5.1, official validation, and isolated install. The reused-result Candidate stage completed in 845,621 ms; report: `C:\Users\Administrator\AppData\Local\Temp\allred-candidate-r88-20260831-131818\report.html`

The automated promotion gate is satisfied. Publication remains a separate user-authorized action; run one representative experiment-machine pilot before promoting the candidate to a stable release.

## RC11 Generality And Progressive-Disclosure Addendum

- Date: 2026-08-31
- Baseline: `0.8.0-rc10`, Git commit `8e2cf6e`
- Status: exact post-fix Candidate gate passed; ready for user-operated pilot

### Problem And Success Criteria

The modular runtime still contained two overly specific contracts: external-source review required the same four semantic axes for every project, and training handoff required fixed empty sections even when the user had made no exclusion or deferral decision. Both rules came from valid regression scenarios but had become broader than their evidence justified.

Success means:

- semantic source review derives its required dimensions from the active project contract and exact claim under test
- a material dimension cannot be omitted, while an irrelevant generic dimension is not forced into the user response
- training keeps a complete internal coverage ledger without exposing a fixed six-question or six-section form
- empty deferred/excluded sections are omitted and current no-file instructions remain execution boundaries
- scenario fixtures and product names cannot enter active runtime policy owners
- existing intake, stage gates, overlays, user triggers, and concentrated-decision behavior remain unchanged

### Benchmarks

| Source | Version/date | Why comparable | Reused path |
| --- | --- | --- | --- |
| local accepted Allred baseline | `0.8.0-rc10`, commit `8e2cf6e`, 2026-08-31 | mature requirement collection and candidate validation | preserve conversation topology and change only the owners of the two over-specific rules |
| OpenAI `skill-creator` | installed local reference, checked 2026-08-31 | current Skill authoring contract | keep the entrypoint concise, move conditional detail to routed references, and fix demonstrated failures narrowly |
| Matt Pocock `skills` | commit `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`, 2026-08-24 | small composable Skills with progressive disclosure | retain one user entry, use context pointers and reusable disciplines, and avoid re-interviewing already supplied intent |
| Superpowers | `v6.3.0`, commit `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`, 2026-08-12 | staged agent workflow with explicit efficiency trade-offs | scale ceremony to task risk, keep one review owner per task, and avoid nested or shared-state parallel implementation |
| OpenAI Codex Skills and subagents documentation | checked 2026-08-31 | official runtime and delegation guidance | keep Skills focused; reserve subagents for independent read-heavy work because they add context and token cost |
| Codex CLI | `0.150.0`, local `exec --help`, checked 2026-08-31 | authoritative behavior-test runtime available on the target host | use ephemeral isolated turns and explicit transcript replay when personal hooks or state persistence would contaminate scenario results |

The external repositories remain architecture benchmarks only. No dependency, plugin, subagent runtime, Node.js package, or new user keyword is added.

### Decision And Deliberate Differences

1. Replace fixed source axes with project-contract-derived required semantic dimensions. Subject, category, language, region, time, entity identity, and source class are examples, not a universal form.
2. Preserve the training completeness ledger internally, but render only nonempty user-relevant sections. This borrows progressive disclosure without splitting training into another Skill.
3. Add deterministic runtime-generality lint. Regression fixtures remain in tests/example-only files; active runtime policy may not contain their product-specific subjects or deprecated fixed contracts.
4. Add a conditional deterministic training-handoff lint, benchmarked on the existing Allred stage validators. It receives the draft by pipeline, creates no project artifact, and rejects a current no-file instruction when it is classified as curriculum deferral/exclusion instead of a separate execution boundary. Evidence-only absent topics remain candidate exclusions until the user confirms them.
5. Keep `allred-project-standard` as the only ordinary user entry. Do not add a Matt-style command family, a Superpowers-style mandatory workflow stack, or a new trigger.
6. Do not add runtime multi-agent dispatch in this release. Current evidence supports bounded parallel evaluation in the Lab, not parallel implementation against shared project state.
7. Preserve bounded command-result evidence in behavior transcripts. A validator claim is reviewable only when its command, exit code, status, and bounded output are present.
8. Candidate behavior evaluation defaults to stateless turn replay. Each turn receives the exact prior user, assistant, tool-event, and command-result transcript, then reruns the current route or gate. This keeps scenario behavior sequential while isolating personal notification hooks, MCP shutdown failures, and persistent thread-state coupling.
9. Normalize JSON arrays and absolute paths before PowerShell 5.1 background jobs. Parallel aggregation must produce exactly one result for every requested case; missing or duplicate results are infrastructure failures, never an empty successful summary.
10. Shared-decision packets use a conditional deterministic question lint. Every independently answerable question block needs adjacent impact and reply guidance; group-level why-now prose cannot substitute. The exact passing draft is the user-visible draft.
11. Reusable behavior evidence hashes the complete runtime surface (`SKILL.md`, version, agents, references, templates, and scripts), suite, Oracle, model, reasoning effort, provider, user config, plugin isolation, and stateless mode. Candidate mode keeps its broad default set, while an explicit exact-case switch supports narrow post-fix promotion without pretending unrelated cases reran.

### Acceptance Metrics

- runtime-generality lint passes in source and release copies
- route budgets and control-character checks remain within the rc10 envelope
- external evidence cases retain exact fixture-required axes but do not turn them into global requirements
- training cases preserve all consequential dimensions without printing empty placeholders or inventing omissions
- training-handoff lint accepts a separate execution boundary, rejects no-file-as-curriculum-deferral, and V99 observes a successful lint before the final handoff
- software, training, external-data, debugging, and route-isolation regressions pass at low and high reasoning effort before candidate promotion
- source/release parity, PowerShell 5.1 structure, and official Skill validation pass
- stateless `V99` passes at low and xhigh with the exact final handoff lint result visible to the reviewer
- adjacent `V124`, `V125`, and `V135` pass at low and xhigh without reopening completed baselines or inventing training exclusions
- a three-case aggregation smoke returns exactly three ordered results, and real parallel evaluation cannot report success with an empty summary
- `V81` rejects a draft whose standalone questions have only group-level rationale, then passes at low and xhigh after every visible question has adjacent impact and reply guidance
- reusable evidence is rejected when any runtime reference or validation script changes, even when `SKILL.md` is unchanged

### Targeted Acceptance Evidence

- `V99` low: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-v99-r15-low-20260831-230248`
- `V99` xhigh: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-v99-r16-xhigh-20260831-230907`
- adjacent low individual reports: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-training-adjacent-low-r3-20260831-233052\.parallel-parts`
- adjacent xhigh aggregate: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-training-adjacent-xhigh-20260831-233853`
- exact-result aggregation smoke: `C:\Users\Administrator\AppData\Local\Temp\allred-batch-aggregation-smoke-r2-20260831-233818`
- first broad Candidate: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-candidate-20260831-235346` (`14/14` low, `13/14` xhigh; `V81` partial exposed the missing adjacent effect)
- corrected `V81` low: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-v81-lint-low-20260901-010935`
- corrected `V81` xhigh: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-v81-lint-xhigh-20260901-011349`

### Final Candidate Evidence

- exact post-fix Candidate: `C:\Users\Administrator\AppData\Local\Temp\allred-rc11-candidate-v81-final2-20260901-023635\report.html`
- selection was exactly Standard `V81`, Lab `L01`, and fixed replays `R01-R06`; unrelated Standard cases were not claimed as rerun
- candidate `V81` passed at low and xhigh; both candidate and frozen `rc10` baseline recorded `stateless_turns=true`
- blind comparison preferred the candidate with a material difference: current environment was retained, future authority facets stayed independently answerable, and unsupported defaults were withheld
- entry guard passed `3/3`: standard new project, beginner expression, and readable-material read-only inspection all kept zero workspace changes and a visible no-write/start boundary
- structure, invariant, runtime-generality, route-budget, Lab harness, source/release parity, PowerShell 5.1, official validation, and isolated installation stages all passed

Two failed pre-candidate runs were retained as harness evidence rather than hidden:

- blind comparison was incorrectly given the behavior-only `-StatelessTurns` switch; behavior and comparison option builders are now separate, and static checks bind each call to its exact code block
- the entry guard failed to recognize the natural phrase `没有修改文件` even though the response and workspace snapshot were correct; the boundary matcher now accepts equivalent no-write wording while rejecting positive write claims
- direct blind-batch invocation exposed relative-path dependence; the wrapper now normalizes runner, suite, Lab, candidate, and baseline paths, normalizes JSON arrays for PowerShell 5.1, and requires exactly one result per requested case

This gate promotes `0.8.0-rc11` to a user-pilot candidate only. Commit, publication, and stable-version promotion remain separate user-authorized actions.

## 2026-09-01 Discovery Coverage Gate (`0.8.0-rc12` Candidate)

### Problem And Users

The accepted `rc11` flow deliberately removed fixed turn limits and repetitive questionnaires, but its deterministic gates validated only the intake items and decisions already recorded. A model could therefore close Q1-Q4, register two plausible decisions, omit other material-exposed areas, and reach READY too early. The affected users are ordinary and beginner-expression project users, especially on non-simple software or internal-process projects with heterogeneous materials, relationships, lifecycle rules, scale, and delivery dependencies.

Success means:

- no minimum or maximum question/turn count
- no fixed user-visible domain questionnaire
- every non-trivial new-project READY state accounts for workflow, information, lifecycle, operating scale, delivery/effects, and acceptance
- all current evidence limitations participate in the latest review
- omitted decisions cannot disappear merely because they were never added to the frontier
- a bounded simple project still reaches one READY envelope without ceremonial questions

### Benchmark Check

| Source | Version/date | Why comparable | Reused path | Deliberate difference |
| --- | --- | --- | --- | --- |
| local accepted Allred baseline | `0.8.0-rc11`, 2026-09-01 | mature concentrated intake, frontier dependencies, and READY provenance | preserve the existing Q1-Q4 readiness and decision model | add completeness after evidence without changing user triggers or interview topology |
| local dynamic project contract | `rc11`, checked 2026-09-01 | already owns workflow, working set, output, boundaries, and acceptance slots | reuse its slots and provenance instead of adding a second framework | serialize six broad internal coverage lenses only for deterministic READY validation |
| OpenSpec baseline/change model | `main`, reviewed 2026-08-29 | separates accepted baseline from explicit unresolved change | require every final scope item and confirmed/deferred decision to remain linked | do not require OpenSpec installation, Node.js, or user-visible spec artifacts |
| OpenAI `skill-creator` local reference | installed reference, checked 2026-08-29 | favors progressive disclosure and behavior evaluation over long entry instructions | keep the full review in references and validators, with compact runtime guards | no new dependency or ordinary-user trigger |

Local references were sufficient for this design. No plugin, Skill, MCP server, library, or external package was added.

### Decision

Add an internal `discovery_coverage` state with three methods: contract-slot review, evidence-gap review, and counterexample review. Six broad lenses are always accounted for internally but are never rendered as six mandatory questions. Each lens is resolved, evidence-backed not applicable, explicitly deferred, open, or investigating. READY/EXECUTION now run `validate_discovery_coverage.ps1` and reject unresolved lenses, stale evidence review, ungrounded deferral/not-applicable states, or final decisions/scope absent from coverage.

### Acceptance

- `V142`: a heterogeneous legacy-template project must continue discovery after two early decisions and preserve template boundary, history, lifecycle, scale, acceptance, and candidate-technology gaps
- `V143`: an exact bounded CSV project must close coverage internally and avoid another questionnaire
- valid READY fixture passes the new validator and aggregate seven-validator gate
- a fixture with an open lifecycle lens fails deterministically
- route-context budgets remain within existing limits
- source/release parity and low/high targeted behavior checks are required before publication

### Validation Evidence (2026-09-01)

- Quick candidate validation: 8/8 static steps passed; report at `allred-project-standard-validation/rc12/quick-final2-20260901/report.html`
- official `quick_validate.py`: Standard and Lab both valid under the isolated UTF-8/PyYAML environment
- `V142` heterogeneous-template coverage: low and xhigh passed on the final runtime rules
- `V143` bounded simple project: low and xhigh passed; no coverage questionnaire and the trusted READY event loaded decision context
- adjacent low cases `V127`, `V134`, `V135`, `V138`, and `V139` passed after the final routing fixes
- shared-collaboration `V138`: low and xhigh passed on the same final event metadata; no unsupported numeric target and discovery-only deferral remained visible
- source/release parity, PowerShell 5.1 structure, route budget, runtime generality, invariant ownership, and candidate harness passed
- isolated installation from the final release package installed `0.8.0-rc12`, wrote a receipt, and passed installed-structure validation at `allred-project-standard-validation/install-v080rc12-final2-20260901`

Residual scope: the complete 142-case low/xhigh dynamic matrix was not rerun. Publication, Git commit, and stable-version promotion remain separate user-authorized actions.

## 2026-09-01 GitHub Validation Automation

### Problem And Success Criteria

Manual testing catches realistic interaction defects but covers too few routes and model variants. The repository needs automatic breadth without putting credentials in a public repository or running expensive model evaluations on every push.

Success means:

- every push and pull request runs dependency-free Windows static checks with no model credentials
- static CI verifies structure, invariants, route isolation/budget, runtime generality, harness integrity, PowerShell 5.1, and isolated installation
- model behavior is manual-only and never runs on untrusted pull-request events
- dynamic evaluation reuses an authenticated self-hosted Windows experiment machine and stores complete test/check transcripts as artifacts
- maintainers can choose changed, release, full-low, or full-dual coverage without editing YAML
- all jobs use read-only repository permissions and bounded artifact retention

### Benchmarks

| Source | Version/date | Comparable path | Reused principle |
| --- | --- | --- | --- |
| GitHub Actions workflow syntax | official documentation, checked 2026-09-01 | push/PR static checks and manual `workflow_dispatch` | least-privilege permissions, concurrency, bounded jobs, artifacts |
| GitHub self-hosted runners | official documentation, checked 2026-09-01 | authenticated local Codex evaluation without repository secrets | label the dedicated Windows runner and use manual dispatch only |
| OpenAI Skill eval guidance | official Eval Skills article, checked 2026-09-01 | repeated realistic task trials and comparison against success criteria | keep deterministic checks separate from model behavior evidence |
| local `allred-project-lab` | `0.8.0-rc12`, 2026-09-01 | impact selection, parallel test/check groups, blind comparison, HTML reports | wrap existing validated runners instead of introducing another evaluator |

### Decision

Add two repository workflows:

1. `static-validation.yml` runs on push, pull request, and manual dispatch using GitHub-hosted `windows-latest`. It needs no Codex login or secret.
2. `behavior-evals.yml` runs only through `workflow_dispatch` on a self-hosted runner labeled `allred-eval`. The runner must already have Codex CLI authenticated. It uploads complete evidence and never runs on pull requests.

Add `run_ci_behavior.ps1` as the testable orchestration owner. `Changed` uses impact-selected low evaluation, `Release` runs the candidate gate, `FullLow` evaluates all behavior cases at low reasoning, and `FullDual` evaluates all cases at low then xhigh. The workflows do not install Skills, change the user's active Codex configuration, publish releases, or promote a candidate.
