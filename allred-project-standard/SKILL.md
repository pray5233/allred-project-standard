---
name: allred-project-standard
description: Start or continue non-trivial Codex-assisted software and document-heavy internal projects with evidence-based scope, low-interruption decisions, controlled execution, fresh verification, and handoff. Use for new or long-term work, debugging/features/UI, training, policies, knowledge bases, bids, contracts, inspection records, acceptance, and Skill improvement. Do not use for simple Q&A, trivial text edits, or one-command fixes.
---

# Allred Project Standard

Use this Skill to keep project work aligned without turning the conversation into a questionnaire or adding a second process framework.

The governing loop is:

```text
路由定界 -> 读取证据 -> 内部方案 -> 必要决策 -> 连续执行 -> 新鲜验证 -> 交付沉淀
```

## Runtime Hard Stops

- Words such as `已检查`, `已找到`, `预检完成`, `验证通过`, or `READY 通过` require current tool/event evidence. Before that evidence, state only the planned read-only action; model knowledge and Skill text are not project evidence.
- If readable materials are named or the user requests safe inspection first, inspect before optional questions. `暂无资料` plus a usable initial idea never creates a prototype/real-source/plan strategy menu; perform the smallest relevant real read-only evidence check unless one exact missing input makes that impossible.
- A broad new-project opening uses only the unanswered parts of the established Q1-Q4 intake packet. Never put a material-readiness, strategy, project-size, or process menu before it; material status belongs inside Q2. Before first real evidence, preserve the user's literal workset and defer breadth, source-policy, automation, delivery-format, and adjacent-feature choices unless one is required for safe inspection.
- If the user mentions existing materials but supplies no readable attachment or location, do not end with an inspection announcement. Ask for the location as Q2 together with the other unanswered, co-answerable Q1/Q3/Q4 facets in the same intake packet.
- An event/state marked `EVIDENCE` or `READY=false` forbids any product approval or start option. A recorded aggregate `READY passed` result must be accepted as the current gate result; do not invent another state file, validator, or approval prerequisite.
- When current evidence makes unresolved user-facing choices concrete and their answers determine the next coherent preflight path, ask them now in one concentrated decision packet. Do not continue as though the user will volunteer those answers, do not call the packet final approval, and do not include answer-independent technical choices.
- Before the final READY envelope, state the provisional full-project complexity and current-round strategy once in plain language when they affect sequencing or verification. Use `当前建议按小型/中等/复杂项目控制` rather than `标准复杂度`, name the evidence-backed reason and practical effect, and say whether this changes validation only or also narrows the current round. Do not ask the user to choose a size label or use the classification to expand scope.
- A READY response may render only product behaviors present in the passed aggregate state or event. Do not expand a named category into unrecorded sibling cases or add common safeguards, filters, persistence, or failure behavior at the final gate. If a behavior is needed but untraced, return to EVIDENCE/DECISION, record it, and revalidate before showing it.
- A READY card opens with `我还没有开始写代码或修改项目；确认后才开始。` It shows the user-facing write and rollback boundary, but exact commands, dependency versions, execution-record IDs, hashes, and validator mechanics remain internal.
- When READY includes dependency installation, state in plain language what capability will be added, whether it is project-isolated or system-wide, what user files/settings it affects, and how it is removed. Never require approval of the exact install command.

Superpowers is a method benchmark, not a runtime dependency. Reuse its strongest disciplines internally: inspect before designing, find root cause before fixing, execute in bounded steps, stop on real blockers, and verify before claiming completion. Do not import mandatory brainstorming, per-section approval, per-task commits, worktrees, or batch feedback gates. Do not use TDD or Red-Green as the execution order.

When the user explicitly invokes Allred by name or trigger, Allred owns the top-level project workflow topology. Do not automatically invoke or stack another general process Skill such as brainstorming, planning, or project-workflow management merely because the task is creative or complex. A specialized Skill may contribute a narrow capability without replacing Allred's concentrated packets, combined scope/start gate, execution boundary, or acceptance ledger. Explicit user invocation of another process Skill and higher-priority instructions still apply; state the resulting workflow difference early instead of silently mixing incompatible topologies. The explicit `grill-me` ownership exception remains governed by `references/决策前沿与Skill交接.md`.

## Activation And Routing

- New project: `allred新项目`, `新项目`, `启动新项目`, `开始项目`, or an explicit request for the Allred workflow.
- Beginner interaction: `allred新手`, `allred新手新项目`, `allred新手项目`, `新手项目`, `新手模式`, or a project already recorded in beginner mode. Incidental text such as `新手员工` does not activate it.
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

If `继续项目` is unclear and project evidence cannot resolve the route, ask a compact routing question. Beginner mode changes explanation style, not complexity, scope, or engineering rigor.

## Required Reading

Keep progressive disclosure measurable. When scripts are available, run `scripts/get_route_context.ps1 -Route <route> -Stage <stage>` and use its excerpts from the canonical references. Available stages are `intake`, `evidence`, `decision`, `external-read`, `execution`, and `verification`. Load a later stage only when work reaches it; do not then reread the same unchanged source file in full. If the selector cannot run, read `references/核心执行流程.md` and only the additional references needed by the route:

Choose one primary route for the current stage. A new training, policy, knowledge, bid, contract, or inspection project uses `non-software` with its variant; do not also load `new-standard` merely because it is new. Load another route only after a named mixed requirement genuinely needs that branch.

| Situation | Read |
| --- | --- |
| user decision, authorization, uncertainty, or explicit grilling | `references/决策前沿与Skill交接.md`, then `references/交互与确认规则.md` for visible card semantics |
| new project | `references/新项目启动模式.md`; read `references/动态项目契约.md` when product behavior, evidence, delivery, or acceptance is not already stable |
| beginner interaction | `references/新手模式.md`, then the routed stage |
| existing/mixed request | `references/项目阶段分流.md` |
| debugging | `references/功能调试.md` |
| new feature | `references/新增功能.md` |
| UI optimization | `references/界面优化.md` |
| acceptance/review | `references/本轮验收与复盘.md` |
| long-term task | `references/长期任务模式.md` |
| Skill/workflow improvement | `references/Skill流程优化模式.md`, `references/Skill测试验收.md` |
| non-trivial design/capability choice | `references/开发依据与能力复用.md` |
| complexity or delivery is genuinely unclear | `references/项目级别问法.md`, `references/运行环境与交付形态.md` |
| public-source monitoring | `references/公开信息监测项目.md` |
| substantial training/policy/knowledge/bid/contract/inspection work | `references/非软件项目模式.md`; route the actual artifact to the installed document/spreadsheet/presentation/PDF capability |
| external URL, web/API/RSS, redirect, or download | `references/外部内容安全.md` before the external read |
| non-trivial new-project stage change, decision packet, or final scope | `references/阶段状态硬校验.md`; maintain the state package under a session temporary directory and run its validators |
| Standard/Deep work immediately before mutation | `templates/Codex执行记录.md`; run `scripts/invoke_validation_gate.ps1` for the target stage; it owns record, decision, scope, and transition validation |

Selector routes are `new-standard`, `new-beginner`, `new-public`, `new-beginner-public`, `existing-debug`, `existing-feature`, `existing-ui`, `non-software`, `long-term`, and `skill-improvement`. For `non-software`, pass `-Variant training|policy|knowledge|bid|contract|inspection` when known. Read a full reference only when the emitted sections leave a named current decision unresolved; record that extra read in the context-read ledger.

Use `references/资料收集与分析.md` when real files/process evidence may exist. Use `references/项目类型问题库.md` and `references/首次触发示例.md` only when a routed response needs them.

## Shared Invariants

1. Start from the user's rough requirement, initial idea, project files, and current state. Do not invent a competing product before inspecting them.
2. Build an evidence-backed dynamic project contract before a non-trivial design decision. Treat its slots as internal structure, not a fixed questionnaire.
3. Search the local known-good path first, then official maintained references, then strong external examples only when a real gap remains.
4. Inspect installed Skills, plugins, MCP servers, scripts, libraries, and project patterns before adding capabilities. Use `find-skills` only for a real gap.
5. Classify interaction style, project complexity, and current-round strategy separately. Codex owns provisional classification; the user does not choose from vague size labels.
6. Separate total scope from current scope only when uncertainty, size, risk, or long-term work requires it. A bounded clear project may implement all agreed functions.
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

## Conversation Topology

Lifecycle stages are internal reasoning stages, not required conversation turns.

- There is no fixed question or turn budget. Clear authorized work proceeds without ceremony; ambiguity uses concentrated packets and real dependency depth.
- Keep visible orientation compact: show only the changed understanding, currently blocking decisions, explicitly non-blocking later items, and the exact next action; omit empty parts and never make this a second fixed template.
- When the user explicitly asks for safe read-only inspection first, continue that inspection under reversible assumptions and defer every question that does not change its safety or usefulness. Ask first only for the exact missing input that makes the inspection impossible or unsafe.
- Judge later rounds by causality, not count: each new packet must name new evidence or an exact parent decision that made its questions meaningful. Redundant, repeated, or later-invalidated questions are defects.
- If supplied project files can answer a visible question, inspect them first. Material inspection alone is not READY; continue all answer-independent capability, write-boundary, rollback, and verification preflight before opening a product or start gate.
- When a new-project request names readable samples/files and supplies an initial idea, the first response starts that read-only inspection with zero questions unless the path is ambiguous or inspection would be unsafe. After the material result, keep newly exposed business choices internal until answer-independent project preflight is complete, then combine them with the one final gate.
- Q/D IDs are internal stable references and optional shortcuts. Always accept a natural sentence or paragraph, map it back to the relevant IDs, and restate the operative meaning. Never require `Q1=... D1=...` syntax.
- `继续` and `按推荐` advance only the immediately visible named envelope. They authorize new-project mutation only when the envelope is the complete READY scope and explicitly states that approval starts execution.
- A multi-module request receives an early plain-language complexity warning and outcome choice inside the first concentrated packet, not a separate ceremony or an automatic full-system route.
- Do not spend a user turn asking whether to enable a visualization, planning helper, or process aid before a current decision genuinely needs it. Do not ask the user to choose a framework or toolchain when Codex can select it from evidence; ask only about user-facing consequences such as delivery experience, cost, maintenance, data transfer, or installation.
- Use the decision tree/frontier and ownership router in `references/决策前沿与Skill交接.md`. Explicit `grill-me`/`grilling` owns visible interviewing; Allred does not duplicate it or automatically fall back in the same response. Without explicit invocation, Allred uses the same frontier method internally as a fallback.
- For a broad new project, the INTAKE packet contains only unanswered factual/open rows needed for recommendation readiness: `Q1 intended user/current workflow + pain`, `Q2 available materials/inputs + where to read them`, `Q3 the user's initial first-version idea + must-haves + known non-goals`, and `Q4 a recognizable useful/acceptable result`. Omit answered rows and do not turn them into model-created product options. Detailed privacy, delivery, operating-environment, ownership, workset, and acceptance decisions wait until evidence makes their consequences concrete, unless one is required to inspect safely.
- Preserve user-supplied unresolved alternatives exactly as `D1`; its decision dependency is always `None`. Baseline `Q` IDs may defer a recommendation but never make D1 itself dependent. Do not add a third route beyond custom input. Do not add first-packet future permission, update, state, history, continuity, tool, or rollout decisions; those wait until their parent exists.
- Treat the user's literal named item set as the current workset. Do not ask whether to add adjacent categories, regions, workflows, or common features; leave unspecified breadth open unless it blocks the next safe evidence check or the requested outcome.
- A child waits only when its parent determines whether it exists or makes its options meaningful. Once the route exists, batch co-answerable factual `Q` and neutral `D` items; use `recommendation deferred pending <Q IDs>` rather than serializing for recommendation evidence.
- If the user names decision topics to revisit after evidence, keep every topic on the decision frontier. Once evidence makes their options and consequences explainable, include them in the same next concentrated packet. A dependent item may appear with an exact parent-option dependency instead of being postponed; defer it only when the parent answer is genuinely required to formulate the child options.
- After shared or multi-owner work is selected, state `confirmed <D ID>=<shared choice>` immediately before the named shared packet; newly created child rows inherit that exact parent, while unique dependencies remain row-level. Carried independent decisions such as first-packet workset or acceptance keep `dependency: None` and stay outside the inherited child group or are explicitly labeled carried/independent. Compile: `Q actual roles/current owners`, `D update authority`, `D conflict behavior`, `D history/audit evidence`, `Q current source + D future authority`, `Q existing sensitive data + D record-visibility scope + D field masking`, `Q actual environment + D future continuity`, `Q acceptance owner + D acceptance conditions`. These are co-answerable: unresolved facts defer recommendations, not questions. Keep record visibility separate from field masking, conflict from audit, current facts from future rules, and owner from criteria.
- Use `Q` only for current facts and `D` only for future product/business meaning; split mixed facts and choices. Each important item states why it is needed now. Render concentrated packets as compact rows or tables, not unlabeled question lists. Every `Q` row has `ID | question | why now/answer impact | reply`. Every `D` row has `ID | dependency/why now | recommendation basis when one option is recommended | each option: material impact | custom reply | deferrable yes/no`. Neutral options with no recommended marker mean no recommendation; order and silence never create a default. A named group may state a genuinely identical dependency/why-now/basis once; each row owns unique impacts and reply. End with exact deferrable IDs and consequence.
- Track a multi-part `Q` by its factual facets. A partial reply fills only the facets actually answered; when the `Q` is shown again, preserve every still-material unanswered facet instead of shortening it away. Merge or remove a facet only when later evidence answers it or makes it irrelevant.
- Before sending a multi-`D` packet, run option compatibility lint: every `D` has `None` or exact dependencies; no option silently requires another `D` value; bind a required value exactly or remove that promise; split ambiguous `or` permissions into distinct choices. Shared update authority distinguishes submit/create, edit, close, and delete; never combine `view or submit`. `Not applicable` binds the exact option that removes the behavior. Any offline entry, temporary table, later replay, reconciliation, or sync path binds exact conflict and audit options. During discovery-only work every shared rule may defer; it becomes blocking only before affected implementation or acceptance. Copy these canonical audit labels without shortening: `actor`, `time`, `action`, `result`, `before/after`, `source/submission chain`, `failed actions`, `denied actions`, `recovery evidence`. `None` excludes all labels; `basic` includes actor/time/action/result and excludes all others; `complete` includes all labels. Audit evidence never proves restore capability; recovery behavior needs its own exact option/decision. Siblings promise audit evidence only by exact audit-option reference.
- Before loading a new-project `decision` or `execution` stage, pass the session-temporary state path to `scripts/get_route_context.ps1` with `-StatePath <path>`. Run `scripts/invoke_validation_gate.ps1 -Path <path> -ToStage DECISION|READY|EXECUTION` for the target stage. After exact READY approval, update authorization and rerun the aggregate gate for EXECUTION before mutation.
- Every user-facing new-project product `D` packet or READY envelope requires the matching validator to pass in that response. If the temporary state cannot be written or validated, remain in EVIDENCE and name the internal blocker; never improvise the decision/final scope without the gate.
- When many optional areas remain, build a gray-area map and let the user choose discussion scope; this never approves scope. Preserve the user's exact set and count: `跨部门`, `多个文件`, or `若干使用者` does not authorize invented members, counts, or roles.
- Use assumption-first alignment: prefer evidence-backed assumptions and user correction over silent defaults. Combine stable final scope and start authorization when possible; never repeat unchanged confirmation.
- When preflight is complete and only named recommendations remain, make that packet the full READY envelope. A natural reply that resolves them and explicitly starts the traced scope authorizes execution; do not add a duplicate card or translate broad user words into extra visible behavior.
- A source/benchmark result or technical reference is not project preflight. Never print a start-development option unless actual evidence already names the project root, allowed write area, planned paths, rollback checkpoint, and verification path; otherwise the next action is read-only project preflight.
- After preflight, fold a reversible low-risk background assumption into the final envelope as a prominent recommendation when either answer leaves a coherent testable result; do not create a separate question round solely to perfect context.
- Every beginner new-project READY gate, and every user-requested existing-project change gate, ends with an explicit numbered option whose text says `批准以上范围并开始开发/改造`. Bare `1` starts work only when it selects that immediately visible option; otherwise it is not authorization.
- If beginner users cannot use development tools or a command line, the first response states both consequences: final delivery must open without those tools, and acceptance will include an actual opening/run check on a clean office computer. Do not choose the exact delivery form until the workflow is known.
- A later evidence packet may add or refine dependent choices, but it cannot erase an unanswered earlier independent choice. The final gate contains only exact `U/D` decisions plus clearly labeled unresolved items; it never converts omission into approval.

Codex owns the default work of searching and selecting a comparable benchmark, checking capabilities, preparing a technical path, and choosing narrow verification. Do not ask whether Codex should perform those steps.

If the user already authorized the exact READY scope and its displayed option explicitly included starting execution, do not ask again. Earlier direction approval, recommendation approval, sample submission, `继续`, or `按推荐` without that READY meaning is not development authority.

## Execution And Debugging

Use the lane and phase rules in `references/核心执行流程.md`.

For debugging:

```text
稳定复现 -> 收集证据 -> 定位边界 -> 单一根因假设 -> 最小实验/修复 -> 回归验证
```

Do not guess a cause or bundle unrelated refactors. Do not use TDD or Red-Green as the execution order. Analyze and locate the root cause first, implement the smallest fix, then add or run targeted verification and regression checks according to risk. After three failed root-cause hypotheses, stop patching and review the architecture, assumptions, and evidence boundary.

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

## Maintenance

When changing this Skill, use `skill-creator`, keep shared rules in one owner, record architecture decisions in `references/调试与优化建议.md`, run `scripts/check_skill_structure.ps1` and `scripts/check_behavior_manifest.ps1`, then use `scripts/run_behavior_eval.ps1` for realistic changed P0 cases. A manifest pass is not behavioral proof. Synchronize an established release mirror before claiming distribution readiness.
