---
name: allred-project-standard
description: Run evidence-based project work when the user explicitly invokes Allred, starts a new project, continues a long-term task, or asks to continue an established Allred project. Supports software and substantial internal document projects; do not activate for ordinary Q&A, trivial edits, or unrelated one-command work.
---

# Allred Project Standard

Use this Skill to keep project work aligned without turning the conversation into a questionnaire or adding a second process framework.

The governing loop is:

```text
路由定界 -> 读取证据 -> 内部方案 -> 必要决策 -> 连续执行 -> 新鲜验证 -> 交付沉淀
```

## Post-Event First Action

After any tool/event result changes evidence or stage, do not draft visible text first. The next action must rerun `get_route_context.ps1` at the route and stage required by the next visible work. If the response will ask questions or synthesize scope, load DECISION before drafting it.

- Training material/feedback event: first call `get_route_context.ps1 -Route non-software -Stage decision -Variant training -Interaction <current>`; stale INTAKE/EVIDENCE context is invalid.
- If that reply will ask training questions, next run `$draft | & scripts/validate_question_packet.ps1 -Profile training -PassThrough` and send only the approved packet unchanged. Audience, outcome, topics, exercise, current result, exclusion/deferral, and acceptance are independent unless an exact dependency is recorded.
- Evidence-only audience or absent/unrequested content is never `已确认` or `资料已支持`; the same packet asks the user to confirm/correct the audience and classify each absence as include, exclude, or unclassified.
- A completed training baseline with no current gap is a prerequisite, not a review/reteach/use choice. Learning outcome, exercise endpoint, and acceptance are distinct; one never substitutes for another.
- A prerequisite such as `不要求编程基础` is not a curriculum exclusion. Final exclusions copy only the user's explicit exclusions.
- After training handoff PassThrough, the visible final reply is exactly the approved block, including its execution boundary. Any added, removed, or restored text requires a new lint; never merge a failed draft with a passed draft.
- If either call is missing or fails, report evidence only and ask nothing.

## Runtime Hard Stops

- Words such as `已检查`, `已找到`, `预检完成`, `验证通过`, or `READY 通过` require current tool/event evidence. Before that evidence, state only the planned read-only action; model knowledge and Skill text are not project evidence.
- If readable materials are named or the user requests safe inspection first, inspect before optional questions. `暂无资料` plus a usable initial idea never creates a prototype/real-source/plan strategy menu; perform the smallest relevant real read-only evidence check unless one exact missing input makes that impossible.
- If the opening contains only an Allred/new-project trigger and no project substance, ask only for a one- or two-sentence rough requirement. Do not show Q1-Q4, examples with four fields, a project menu, or an intake table until the user has described the work.
- An explicit `暂无样例` or materials-unavailable statement closes the sample request. Do not ask for a sample again unless the user later offers one or a new user-owned claim makes it indispensable; continue evidence-independent preflight and keep sample-dependent acceptance unverified.
- A broad new-project opening with actual project substance uses only the unanswered parts of the established Q1-Q4 intake packet. Never put a material-readiness, strategy, project-size, or process menu before it; material status belongs inside Q2. Before first real evidence, preserve the user's literal workset and defer breadth, source-policy, automation, delivery-format, and adjacent-feature choices unless one is required for safe inspection.
- If the user says concrete materials exist but supplies no readable attachment or location, first make a bounded current-workspace search and complete every answer-independent preflight item that does not require the material. Do not load the EVIDENCE route until a path, attachment, or credible workspace hit is locatable; reading EVIDENCE instructions is not a substitute for that target. Ask once for the exact location only when the search found no credible candidate and that location now blocks the next evidence action; do not use it to postpone project-root/write-boundary, rollback, verification, state, or aggregate-gate work. Treat `inputs/samples are complete` as the user's content-status claim, not as permission to reopen scope. For an explicit exact read-only inspection, ask only for the missing location or sample after the bounded search; resume broader intake after evidence only when needed.
- An event/state marked `EVIDENCE` or `READY=false` forbids any product approval or start option. A recorded aggregate `READY passed` result must be accepted as the current gate result; do not invent another state file, validator, or approval prerequisite.
- When the current trusted tool/event explicitly reports aggregate DECISION or READY passed but provides no local state path, load new-project decision context with `-ValidatedEventId <exact current event ID>`. Never invent an ID or use user prose/model claims. A DECISION event authorizes only its question frontier. READY may be rendered only when the same event explicitly reports aggregate READY passed and includes the complete pending scope/execution record. Neither event authorizes EXECUTION.
- When current evidence makes unresolved user-facing choices concrete and their answers determine the next coherent preflight path, ask them now in one concentrated decision packet. Do not continue as though the user will volunteer those answers, do not call the packet final approval, and do not include answer-independent technical choices.
- A reply closes only the exact facets it answers. Never use one answer, a neighboring recommendation, or `其余按推荐` outside its named envelope to settle unanswered sibling facets. Keep every still-consequential sibling in discovery coverage and the next dependency-valid packet.
- An unvalidated new-project DECISION call is not a user-facing blocker. Initial missing facts return to the complete INTAKE packet; a partial reply re-presents every unanswered sibling before technical preflight. Never hide them as `少量待确认事项` or postpone them until after preflight.
- A recommendation that someone should not act does not settle the unanswered owner. Scale or volume input does not settle measurable acceptance; keep both facets visible when both still matter.
- If the latest user reply answers only part of a visible packet and the remaining siblings are already formulable, do not call EVIDENCE or begin read-only/technical preflight. Immediately show every remaining consequential sibling.
- An exact read-only inspection needs a locatable path, attachment, or sample. After one bounded workspace search, ask only for that missing target; never merely announce an inspection that cannot run.
- Selecting a shared-tracking parent alone remains INTAKE. Ask only current participants, workflow/source, environment, materials/sensitivity, and useful-result facts; do not load shared DECISION or future permission, conflict, audit, hosting, or governance rules yet.
- In shared INTAKE, sensitivity explicitly covers current volume, frequency, variation, and highest-impact pain. Explain that these facts size the shared update boundary, evidence sample, and later acceptance; do not hide them inside a generic pain question.
- Shared INTAKE environment means current location, devices, access conditions, availability, and sensitivity only. Planned platform, vendor, shared drive, internal system, hosting, and future access ownership are DECISION topics after evidence, not intake questions.
- Once user-visible consequences and acceptance are settled, implementation details remain Codex-owned. Do not ask the user to choose source layout, libraries, packaging internals, or other technical mechanics.
- A candidate delivery or integration path remains visibly unverified until its matching representative end-to-end or clean-target test passes. Later summaries must not silently drop it.
- When evidence or a prior packet exposes extensibility/configuration owner, historical handling, correction/void lifecycle, operating scale, or measurable acceptance as open, each remains an independent sibling. Re-present every still-material facet; never invent numeric targets or let a recommendation settle ownership.
- Semantic source review names every active material dimension and an explicit state such as `relevant`, `irrelevant`, or `unknown`; transport success or equivalent rejection prose is not the state record.
- After a sample read, do not restart user/workflow or generic acceptance intake when the supplied outcome, inputs, current behavior, and reversible recommendations are already sufficient for answer-independent preflight. Carry those recommendations into the final approval envelope unless a missing answer changes the next evidence path.
- Recommendation readiness is not discovery completeness. Before READY for a non-trivial new project, complete the internal discovery-coverage review across workflow, information, lifecycle/exceptions, operating scale, delivery/effects, and acceptance. Each lens must be evidence-resolved, user-confirmed, explicitly deferred, or evidence-backed not applicable. A missing lens or an untracked open facet blocks READY even when Q1-Q4 and the currently registered decisions are complete. This adds no fixed question count: ask another concentrated round whenever the review exposes a consequential user-owned gap, and ask nothing when evidence closes it.
- Communicate complexity only when it changes sequencing or verification: name the concrete drivers and practical effect. Keep the level internal unless its label aids a consequential warning. Never ask the user to choose a size or generic project tier.
- A READY response may render only product behaviors present in the passed aggregate state or event. Do not expand a named category into unrecorded sibling cases or add common safeguards, filters, persistence, or failure behavior at the final gate. If a behavior is needed but untraced, return to EVIDENCE/DECISION, record it, and revalidate before showing it.
- Beginner-facing READY hides source trees, top-level implementation paths, filenames, commands, package/version details, record IDs, and hash mechanics. Show only the recommended project location, allowed write boundary, original protection, rollback, delivery consequences, and acceptance.
- Resolve an explicit Allred trigger, primary route, and expression style before running project commands. `allred新手项目` and `新手项目` use the normal new-project route with beginner expression; they never authorize a separate shortcut workflow. A version check may confirm installation but is not required to activate the Skill.
- When the whole user message only toggles beginner/standard expression, acknowledge the style change and refer to the entire prior pending packet or next action as unchanged. Do not restate or re-ask its facts, materials, or decisions. If the same message also answers an item, process that answer normally; never reset route, stage, evidence, or scope.
- During INTAKE or EVIDENCE, do not create renderings, extracted text, screenshots, logs, caches, state files, or other disposable evidence inside the project, future project root, `work`, `outputs`, source, evidence, or deliverable folders. Use `scripts/new_evidence_temp.ps1` and keep these artifacts under isolated system temp. If an unauthorized project artifact was created, stop, disclose it, and repair only an artifact known to be created by the current action; never delete an uncertain or user-owned file.
- Do not promise that a read-only inspection creates no files when rendering, extraction, screenshots, or logs may be required. Before the action, distinguish unchanged project/original inputs from disclosed disposable system-temp evidence; silence about temporary outputs is not disclosure, so do not inspect until this is visible. Afterward, report the actual temporary path and purpose.
- Reading only this `SKILL.md` or a generic interaction reference does not satisfy route/stage loading. Before any non-trivial visible question packet, scope or curriculum synthesis, READY card, or execution, run `scripts/get_route_context.ps1` with the actual primary route, stage, variant, and confirmed overlays. Every new-project DECISION, READY, or EXECUTION response additionally requires the same-response aggregate gate through the selector or `scripts/invoke_validation_gate.ps1`; without it, remain read-only.
- Match every evidence conclusion to the exact layer tested: source/material observation, intermediate artifact, component behavior, end-to-end user workflow, or target-environment acceptance. Evidence at one layer cannot prove a higher layer. Metadata, inspection artifacts, sample outputs, or isolated component checks cannot prove integrated behavior, general coverage, production suitability, or user acceptance. Label every unintegrated path `candidate`, state the unsupported higher-level claim, and name the next test needed.
- After an evidence action, report observations, level, limits, active user constraints, and the write/result boundary before any `仍待检查`; then perform the next authorized internal check or read-only work in the same response. A progress-only acknowledgment or future-tense promise is incomplete: never defer the returned evidence or merely announce work that was not run.
- Enter EVIDENCE with the normal routed context; `-GuardsOnly` is never the first or only route load for an evidence review. After each EVIDENCE tool/event result and before its visible report, rerun `scripts/get_route_context.ps1` with the actual route, `-Stage evidence`, current variant/overlays, and `-GuardsOnly`; the pre-action context does not satisfy this post-result guard. If the same reply interprets new evidence beyond a narrow status report, reload the normal evidence route before synthesis. If it will ask questions or synthesize scope, load and validate the normal decision route as required.
- Initiate authorized answer-independent preflight directly. When the user asks to start but READY evidence is missing, the same response must actually run every currently available read-only route, workspace discovery, project-root/write-boundary, rollback, verification, state, and aggregate-gate check; do not stop after saying these will be done or ask for a missing locator before independent checks run. If a real blocker remains afterward, name it and the unmet preflight areas. Do not turn internal mechanics into a user question or a future-tense progress promise.
- A READY card opens with `我还没有开始写代码或修改项目；确认后才开始。` It shows the user-facing write and rollback boundary. When Codex selected an unconfirmed root, label it exactly `建议项目根目录（待你确认）`, make its approval part of the start option, and name the same absolute path separately as the `允许写入根目录`; relative planned paths do not replace that write-root label. Exact commands, dependency versions, execution-record IDs, hashes, and validator mechanics remain internal. In beginner expression, internal subpaths and file plans also stay internal unless the user requests them or they define a user-owned permission boundary.
- When READY includes dependency installation, state in plain language what capability will be added, whether it is project-isolated or system-wide, what user files/settings it affects, and how it is removed. Never require approval of the exact install command.
- An unselected conditional overlay is silent. Do not ask its questions, use its defaults, add its acceptance criteria, or mention that its domain is absent, unknown, unsupported, or not applicable. Global evidence safety and benchmark policy still apply, but they must not be described as an unselected product capability.
- When evidence or an explicit user choice confirms a conditional overlay and the current reply uses that domain, load the same-stage overlay through `scripts/get_route_context.ps1` before answering. Generic interaction references alone are insufficient. Preserve the established primary route; a continuing project uses its existing or long-term route rather than restarting `new-standard` merely to load the overlay.
- Apply the same relevance filter to tool and event output: a statement that an unselected domain is absent, unknown, untested, or unsupported is routing metadata, not a user-facing finding. Do not echo it in evidence summaries.

Superpowers is a method benchmark, not a runtime dependency. Reuse its strongest disciplines internally: inspect before designing, find root cause before fixing, execute in bounded steps, stop on real blockers, and verify before claiming completion. Do not import mandatory brainstorming, per-section approval, per-task commits, worktrees, or batch feedback gates. Do not use TDD or Red-Green as the execution order.

When the user explicitly invokes Allred by name or trigger, Allred owns the top-level project workflow topology. Do not automatically invoke or stack another general process Skill such as brainstorming, planning, or project-workflow management merely because the task is creative or complex. A specialized Skill may contribute a narrow capability without replacing Allred's concentrated packets, combined scope/start gate, execution boundary, or acceptance ledger. Explicit user invocation of another process Skill and higher-priority instructions still apply; state the resulting workflow difference early instead of silently mixing incompatible topologies. The explicit `grill-me` ownership exception remains governed by `references/决策前沿与Skill交接.md`.

## Activation And Routing

- New project: `allred新项目`, `新项目`, `启动新项目`, `开始项目`, `allred新手新项目`, `allred新手项目`, `新手项目`, or an explicit request for the Allred workflow. Beginner aliases select this same route and enable beginner expression.
- Beginner expression: `allred新手` or `新手模式` toggles simpler wording for the active route. It changes no workflow, stage, scope, complexity, decision order, authorization, or verification rule. Incidental text such as `新手员工` does not activate it; `退出新手模式` returns to standard expression without restarting work.
- Long-term work: `allred长期任务`, `长期任务启动`, `开始长期任务`, `继续长期任务`, `长期任务复盘`, `长期任务调试`, `长期任务资料分析`, `长期任务验证`, or `长期任务优化`. If `长期任务` is only a discussion topic or quoted text, do not activate; ask only when intent remains ambiguous.
- Existing project: route from the actual request instead of restarting project discovery.

| Signal | Route |
| --- | --- |
| error, wrong result, failed test, `项目调试`, `功能调试` | 功能调试 |
| `新增功能`, `加功能`, a new capability | 新增功能 |
| `界面优化`, `UI 优化`, usability/layout problem | 界面优化 |
| `本轮验收`, `项目复盘`, delivery review | 本轮验收/复盘 |
| substantial training, policy, knowledge-base, bid/tender, contract, inspection, or quality-record work | 非软件项目 |
| continued multi-round work or evidence accumulation | 长期任务 |

If `继续项目` is unclear and project evidence cannot resolve the route, ask a compact routing question. Beginner expression changes explanation style, not complexity, scope, or engineering rigor.

## Required Reading

Keep progressive disclosure measurable. When scripts are available, run `scripts/get_route_context.ps1 -Route <route> -Stage <stage> -Interaction standard|beginner` and use its excerpts from the canonical references. Available stages are `intake`, `evidence`, `decision`, `external-read`, `execution`, and `verification`. Load a later stage only when work reaches it; do not then reread the same unchanged source file in full. If the selector cannot run, read `references/核心执行流程.md` and only the additional references needed by the route:

Choose one primary route for the current stage. A new training, policy, knowledge, bid, contract, or inspection project uses `non-software` with its variant; do not also load `new-standard` merely because it is new. Load another route only after a named mixed requirement genuinely needs that branch.

| Situation | Read |
| --- | --- |
| user decision, authorization, uncertainty, or explicit grilling | `references/决策前沿与Skill交接.md`, then `references/交互与确认规则.md` for visible card semantics |
| new project | `references/新项目启动模式.md`; read `references/动态项目契约.md` when product behavior, evidence, delivery, or acceptance is not already stable |
| beginner expression | `references/新手表达层.md` after selecting the actual route; it changes rendering only |
| existing/mixed request | `references/项目阶段分流.md` |
| debugging | `references/功能调试.md` |
| new feature | `references/新增功能.md` |
| UI optimization | `references/界面优化.md` |
| acceptance/review | `references/本轮验收与复盘.md` |
| long-term task | `references/长期任务模式.md` |
| non-trivial design/capability choice | `references/开发依据与能力复用.md` |
| complexity or delivery is genuinely unclear | `references/项目级别问法.md`, `references/运行环境与交付形态.md` |
| substantial training/policy/knowledge/bid/contract/inspection work | `references/非软件项目模式.md`; route the actual artifact to the installed document/spreadsheet/presentation/PDF capability |
| external URL, web/API/RSS, redirect, or download | `references/外部内容安全.md` before the external read |
| non-trivial new-project stage change, decision packet, or final scope | `references/阶段状态硬校验.md`; maintain the state package under a session temporary directory and run its validators |
| Standard/Deep work immediately before mutation | `templates/Codex执行记录.md`; run `scripts/invoke_validation_gate.ps1` for the target stage; it owns record, decision, scope, and transition validation |

Selector routes are `new-standard`, `existing-debug`, `existing-feature`, `existing-ui`, `non-software`, and `long-term`. Pass `-Interaction beginner` only for the optional expression layer; standard is the default. For `non-software`, pass `-Variant training|policy|knowledge|bid|contract|inspection` when known. Add only evidence-confirmed conditional overlays with `-Overlays external-source|shared-collaboration|company-office-delivery`; for `external-source`, pass `-ExternalMode one-time|monitoring` after that distinction is known. Read a full reference only when the emitted sections leave a named current decision unresolved; record that extra read in the context-read ledger.

Conditional overlays are not user modes or trigger words:

- `shared-collaboration` loads only after evidence or an explicit choice confirms that multiple actors share authority over the same live state. Multiple departments, files, readers, or source folders alone are insufficient.
- `external-source` loads only when external/public information is part of the actual input or product behavior. One-time lookup and continuous monitoring remain different modes.
- `company-office-delivery` loads only when the target is a company office environment whose installation, runtime, packaging, or ordinary-computer constraints affect delivery.

Skill improvement, scenario evaluation, invariant maintenance, and release review belong to the explicitly invoked `allred-project-lab` maintainer Skill. They are not runtime routes of this Skill.

Use `references/资料收集与分析.md` when real files/process evidence may exist. Use `references/项目类型问题库.md` and `references/首次触发示例.md` only when a routed response needs them.

## Shared Invariants

1. Start from the user's rough requirement, initial idea, project files, and current state. Do not invent a competing product before inspecting them.
2. Build an evidence-backed dynamic project contract before a non-trivial design decision. Treat its slots as internal structure, not a fixed questionnaire.
3. Search the local known-good path first, then official maintained references, then strong external examples only when a real gap remains.
4. Inspect installed Skills, plugins, MCP servers, scripts, libraries, and project patterns before adding capabilities. Use `find-skills` only for a real gap.
5. Classify interaction style, project complexity, and current-round strategy separately. Codex owns provisional classification; the user does not choose from vague size labels.
6. Separate total scope from current scope only when uncertainty, size, risk, or long-term work requires it. A bounded clear project may implement all agreed functions. Before READY, run the dynamic discovery-coverage review; never treat a short decision ledger as proof that no other consequential area exists.
7. Keep confirmed facts, hypotheses, proposals, rejected directions, current work, and future work distinct.
8. Protect original data and shared systems. Approval is narrow and never silently expands to installation, upload, Git, deployment, credentials, device action, or unrelated writes.
9. Execute the exact authorized scope in small verifiable steps. Progress communication is not a new approval gate.
10. Claim completion only from fresh verification evidence for the agreed outcome and environment. State remaining gaps and evidence level.
11. Before a visible gate, run an internal consistency and provenance check. Do not let a runtime constraint silently choose delivery, or let a technical default become product behavior.
12. Evidence proves facts and feasibility; it does not authorize new product behavior. Recommendations remain unapproved until a named approval envelope explicitly accepts them.
13. Write boundaries include development files, runtime data/logs/caches, and external/system effects. Completion uses a promise-by-promise acceptance ledger.
14. A recommendation enters the visible contract only when it serves an approved outcome, proven risk, or required verification. Common or convenient features stay outside scope.
15. Keep one approval gate readable: users approve product scope and significant effects in plain language; exact technical mechanics stay in the Codex execution record.
16. For formal documents and records, preserve lifecycle state and source traceability. Never silently overwrite approved, issued, submitted, signed, archived, or raw evidence, and never treat a generated file as professional approval.
17. Do not create or require a company-context Skill, private template set, or organization policy unless the user explicitly requests it. Use only the current project's supplied materials and discoverable approved resources.
18. Evidence volume may justify a complexity warning but cannot authorize the more complex deliverable. A request to create documents authorizes neither their curriculum/business content nor Codex-chosen omissions, tiers, duration, scoring, or file format.
19. Every active `U/D` scope decision must map to an implementation/document target and one or more acceptance promises. A task cannot close while an active decision is missing from execution or fresh evidence.
20. Silence, a partial reply, or approval of one item never approves its siblings. Before any combined scope/start gate, reconcile every previously exposed `D`: preserve the selected meaning, keep an unanswered item visibly unresolved or ask it in the next dependency-correct concentrated packet, and never fill it from model preference, a benchmark, or later evidence.
21. A non-trivial new project follows the internal stage gate in `references/核心执行流程.md`. Intake and evidence are read-only; load the decision stage before product choices or a final start envelope, and load execution before mutation. Stages may collapse when their exit evidence is already complete, but they may not be skipped by model confidence.
22. A request for a final confirmation card does not itself establish READY. Do not show any `确认开始`, `start development`, or equivalent option until read-only technical preflight and the internal execution record are complete. Never ask for start while saying the project root, write paths, protected inputs, rollback, or verification commands will be decided after approval. A response that initiates or awaits preflight cannot also be the final start envelope.
23. For non-trivial new projects, use the session-temporary state package and run only `scripts/invoke_validation_gate.ps1` before DECISION, READY, and EXECUTION. Do not chain validators manually. The READY gate also checks baseline/change coverage and non-blocking later items. A failed aggregate gate is an internal blocker; correct the state or stay in the current stage. Do not create the state package inside the project.
24. Preserve semantic authority: `不能只有 A` requires an additional alternative and does not exclude A. Required, excluded, recommended, acceptance, and technical scope use distinct relations. READY names the project root, allowed write roots, protected inputs, planned paths, and rollback; an unconfirmed root is a prominent `R` in that same envelope, shown to Chinese users as `建议项目根目录（待你确认）`, not as an established fact.
25. Keep change control internal: a new project forms one candidate baseline; existing work records only the affected delta plus preserved active scope. A non-blocking later item never becomes a deferral without exact `U/D` authority, and verified work is not merged into durable truth until its promised evidence passes.
26. Never report a planned inspection, command, benchmark search, validation, or preflight as completed before actual tool/event evidence exists. Until then, say what will be checked or that inspection is in progress.
27. Keep runtime policy domain-neutral. Project-specific entities, products, fields, source axes, document sections, and acceptance details come from the active project contract or selected conditional reference; examples and regression fixtures must not become universal requirements.

## Conversation Topology

Lifecycle stages are internal reasoning stages, not required conversation turns.

- There is no fixed question or turn budget. Clear authorized work proceeds without ceremony; ambiguity uses concentrated packets and real dependency depth.
- Keep visible orientation compact: show only the changed understanding, currently blocking decisions, explicitly non-blocking later items, and the exact next action; omit empty parts and never make this a second fixed template.
- When the user explicitly asks for safe read-only inspection first, continue that inspection under reversible assumptions and defer every question that does not change its safety or usefulness. Ask first only for the exact missing input that makes the inspection impossible or unsafe.
- Judge later rounds by causality, not count: each new packet must name new evidence or an exact parent decision that made its questions meaningful. Redundant, repeated, or later-invalidated questions are defects.
- After a narrow evidence action, report only the requested observations, the limitations that constrain the current conclusion, and the exact next safe action. Do not volunteer unrelated future delivery, collaboration, external-source, office, or product decisions merely because their slots remain unresolved.
- If supplied project files can answer a visible question, inspect them first. Material inspection alone is not READY; continue all answer-independent capability, write-boundary, rollback, and verification preflight before opening a product or start gate.
- When a new-project request names readable samples/files and supplies an initial idea, the first response starts that read-only inspection with zero questions unless the path is ambiguous or inspection would be unsafe. After the material result, keep newly exposed business choices internal until answer-independent project preflight is complete, then combine them with the one final gate.
- When the user explicitly says promised materials have not yet been supplied, do not search the workspace as if they were present. Ask in one compact reply for the exact location/upload plus every still-missing independent readiness facet the user can answer now: current user/workflow, first-version idea or must-haves/non-goals, and recognizable useful result. Ask only for the location/sample when the user requested one exact read-only inspection or all other readiness facets are already known. Material arrival may postpone evidence-dependent recommendations, never independent intake.
- Q/D IDs are internal stable references and optional shortcuts. Always accept a natural sentence or paragraph, map it back to the relevant IDs, and restate the operative meaning. Never require `Q1=... D1=...` syntax.
- `继续` and `按推荐` advance only the immediately visible named envelope. They authorize new-project mutation only when the envelope is the complete READY scope and explicitly states that approval starts execution.
- Open a substantial multi-module request by naming its concrete coordination burden and effect on evidence, boundaries, or acceptance. Offer only user-supplied or evidenced outcome choices; never invent generic document/review/system tiers.
- Do not spend a user turn asking whether to enable a visualization, planning helper, or process aid before a current decision genuinely needs it. Do not ask the user to choose a framework or toolchain when Codex can select it from evidence; ask only about user-facing consequences such as delivery experience, cost, maintenance, data transfer, or installation.
- Use the decision tree/frontier and ownership router in `references/决策前沿与Skill交接.md`. Explicit `grill-me`/`grilling` owns visible interviewing; Allred does not duplicate it or automatically fall back in the same response. Without explicit invocation, Allred uses the same frontier method internally as a fallback.
- For a broad new project, ask only unanswered facets needed for the next recommendation: `Q1 user/workflow/pain`, `Q2 materials/location`, `Q3 initial first-version idea/must-haves/non-goals`, and `Q4 recognizable acceptance`. They are readiness facets, not mandatory fields. When outcome, inputs, first-round behavior, and proof are sufficient, proceed under visible narrow assumptions instead of completing the form.
- Preserve user-supplied unresolved alternatives exactly as `D1`; its decision dependency is always `None`. Baseline `Q` IDs may defer a recommendation but never make D1 itself dependent. Do not add a third route beyond custom input. Do not add first-packet future permission, update, state, history, continuity, tool, or rollout decisions; those wait until their parent exists.
- Treat the user's literal named item set as the current workset. Do not ask whether to add adjacent categories, regions, workflows, or common features; leave unspecified breadth open unless it blocks the next safe evidence check or the requested outcome.
- A child waits only when its parent determines whether it exists or makes its options meaningful. Once the route exists, batch co-answerable factual `Q` and neutral `D` items; use `recommendation deferred pending <Q IDs>` rather than serializing for recommendation evidence.
- If the user names decision topics to revisit after evidence, keep every topic on the decision frontier. Once evidence makes their options and consequences explainable, include them in the same next concentrated packet. A dependent item may appear with an exact parent-option dependency instead of being postponed; defer it only when the parent answer is genuinely required to formulate the child options.
- After shared authority is confirmed, immediately load `shared-collaboration` and batch roles/permissions, update authority, truth source, conflict, audit/recovery, hosting/owner, and acceptance. Explain that sharing made them relevant, do not repeat answered items, and never combine `Q+D` in one row. Keep this overlay out of unrelated projects.
- Use `Q` for current facts and `D` for future meaning; never combine them. Each states why now and what changes. A `Q` has `ID | question | why/impact | reply` and no recommended answer. A `D` has `ID | dependency/why | evidence-backed recommendation if any | option impacts | custom reply | deferrable`. Without project evidence or a comparable benchmark, show neutral trade-offs. End with exact deferrable IDs and consequences.
- When the user authorizes only discovery, analysis, design, or scope clarification, every unresolved product `D` remains deferrable unless its answer is required for the next safe read-only action. The visible packet must state which IDs may be deferred and the exact later design, implementation, or acceptance work each deferral blocks. Never imply that the full packet must be answered now merely because the decisions interact.
- Track a multi-part `Q` by its factual facets. A partial reply fills only the facets actually answered; when the `Q` is shown again, preserve every still-material unanswered facet instead of shortening it away. Merge or remove a facet only when later evidence answers it or makes it irrelevant.
- Before sending a multi-`D` packet, run option compatibility lint: every `D` has `None` or exact dependencies; no option silently requires another `D` value; bind a required value exactly or remove that promise; split ambiguous `or` permissions into distinct choices. Domain-specific compatibility rules belong to their selected overlay, not this shared entrypoint.
- Before loading a new-project `decision` or `execution` stage, pass the session-temporary state path to `scripts/get_route_context.ps1` with `-StatePath <path>`. Run `scripts/invoke_validation_gate.ps1 -Path <path> -ToStage DECISION|READY|EXECUTION` for the target stage. After exact READY approval, update authorization and rerun the aggregate gate for EXECUTION before mutation.
- Every user-facing new-project product `D` packet or READY envelope requires the matching validator to pass in that response. If the temporary state cannot be written or validated, remain in EVIDENCE and name the internal blocker; never improvise the decision/final scope without the gate.
- When many optional areas remain, build a gray-area map and let the user choose discussion scope; this never approves scope. Preserve the user's exact set and count: `跨部门`, `多个文件`, or `若干使用者` does not authorize invented members, counts, or roles.
- Use assumption-first alignment: prefer evidence-backed assumptions and user correction over silent defaults. Combine stable final scope and start authorization when possible; never repeat unchanged confirmation.
- When preflight is complete and only named recommendations remain, make that packet the full READY envelope. A natural reply that resolves them and explicitly starts the traced scope authorizes execution; do not add a duplicate card or translate broad user words into extra visible behavior.
- A source/benchmark result or technical reference is not project preflight. Never print a start-development option unless actual evidence already names the project root, allowed write area, planned paths, rollback checkpoint, and verification path; otherwise the next action is read-only project preflight.
- After preflight, fold a reversible low-risk background assumption into the final envelope as a prominent recommendation when either answer leaves a coherent testable result; do not create a separate question round solely to perfect context.
- Every beginner new-project READY gate, and every user-requested existing-project change gate, ends with an explicit numbered option whose text says `批准以上范围并开始开发/改造`. Bare `1` starts work only when it selects that immediately visible option; otherwise it is not authorization.
- When evidence confirms a company office delivery constraint, load `company-office-delivery`. Beginner wording alone does not choose a platform or add company-computer assumptions.
- A later evidence packet may add or refine dependent choices, but it cannot erase an unanswered earlier independent choice. The final gate contains only exact `U/D` decisions plus clearly labeled unresolved items; it never converts omission into approval.

Codex owns the default work of searching and selecting a comparable benchmark, checking capabilities, preparing a technical path, and choosing narrow verification. Do not ask whether Codex should perform those steps.

If the user already authorized the exact READY scope and its displayed option explicitly included starting execution, do not ask again. Earlier direction approval, recommendation approval, sample submission, `继续`, or `按推荐` without that READY meaning is not development authority.

## Execution And Debugging

Use the lane and phase rules in `references/核心执行流程.md`.

For debugging:

```text
稳定复现 -> 收集证据 -> 定位边界 -> 单一根因假设 -> 最小实验/修复 -> 回归验证
```

Do not guess a cause or bundle unrelated refactors. Choose the next diagnostic experiment for one highest-value causal fork and state which result would support or weaken the hypothesis; one experiment need not eliminate every remaining cause. Do not use TDD or Red-Green as the execution order. Analyze and locate the root cause first, implement the smallest fix, then add or run targeted verification and regression checks according to risk. After three failed root-cause hypotheses, stop patching and review the architecture, assumptions, and evidence boundary.

## Verification And Closure

Completion means the promised outcome was verified, not merely that code ran, a file/package existed, or an agent reported success.

- Run the narrowest relevant verification first; broaden for shared logic, releases, or high-risk changes.
- Compare with the selected benchmark's measurable qualities when a benchmark shaped the design.
- Report `已验证`, `仍未验证`, residual risk, and the exact next action.
- Preserve the verification method and material observation for each completion claim in the final `已验证` summary. When evidence contains SHA-256 comparison, named fields, sample values, explicit render defects checked, or target-environment observations, repeat the method and result; do not weaken them to `未改变`, `可读`, `已检查`, or `正常`.
- Git commit, push, merge, publication, installation, deployment, external write, and device/system action require explicit scope or authorization.

Use `references/证据等级说明.md` when a conclusion depends on static/offline/live evidence. Use `references/写入边界说明.md` when original data, shared records, devices, systems, or final conclusions may be modified.

Templates are optional durable records, not mandatory workflow steps. Use `templates/项目启动卡.md`, `templates/项目中途推进卡.md`, `templates/长期任务回顾卡.md`, `templates/任务分解表.md`, `templates/关键指标表.md`, `templates/本轮验收卡.md`, or `templates/交接卡.md` only when they remove ambiguity or support handoff.

## Memory And Notes Boundary

Project execution does not automatically trigger project memory or Obsidian work.

- `allred记忆` or explicit invocation routes to `allred-project-memory` after the execution state is verified.
- `allred笔记` or explicit invocation routes to `allred-obsidian-notes`; when both are requested, memory runs first and notes presents the resulting state.
- Ordinary completion does not create a personal Vault, install Obsidian, or copy a benchmark knowledge base.

## Stop Conditions

Pause only when continuing requires a user-owned or unsafe assumption:

- product behavior, evidence meaning, delivery experience, material scope, owner, or acceptance remains genuinely conflicting
- destructive/shared writes, sensitive data, credentials, cost, legal/privacy exposure, external actions, device/system operations, installation, deployment, or publication need authorization
- no credible evidence path exists for a consequential conclusion
- three debugging hypotheses failed and the architecture or problem definition needs review
- the user says stop, pause, cancel, summarize, or correct direction

Do not add a ceremonial question when the current message already authorizes the exact safe action.
