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
| Standard/Deep work immediately before mutation | `templates/Codex执行记录.md`; validate the record and every active `U/D` decision with `scripts/validate_execution_record.ps1` and `scripts/validate_decision_coverage.ps1` |

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
22. A request for a final confirmation card does not itself establish READY. Do not show a `start development` option until read-only technical preflight and the internal execution record are complete. A response that initiates or awaits that preflight cannot also be the final start envelope.

## Conversation Topology

Lifecycle stages are internal reasoning stages, not required conversation turns.

- There is no fixed question or turn budget. Clear authorized work proceeds without ceremony; ambiguity uses concentrated packets and real dependency depth.
- `继续` and `按推荐` advance only the immediately visible named envelope. They authorize new-project mutation only when the envelope is the complete READY scope and explicitly states that approval starts execution.
- A multi-module request receives an early plain-language complexity warning and outcome choice inside the first concentrated packet, not a separate ceremony or an automatic full-system route.
- Do not spend a user turn asking whether to enable a visualization, planning helper, or process aid before a current decision genuinely needs it. Do not ask the user to choose a framework or toolchain when Codex can select it from evidence; ask only about user-facing consequences such as delivery experience, cost, maintenance, data transfer, or installation.
- Use the decision tree/frontier and ownership router in `references/决策前沿与Skill交接.md`. Explicit `grill-me`/`grilling` owns visible interviewing; Allred does not duplicate it or automatically fall back in the same response. Without explicit invocation, Allred uses the same frontier method internally as a fallback.
- For a broad new project, the INTAKE packet contains only unanswered factual/open rows needed for recommendation readiness: `Q1 intended user/current workflow + pain`, `Q2 available materials/inputs + where to read them`, `Q3 the user's initial first-version idea + must-haves + known non-goals`, and `Q4 a recognizable useful/acceptable result`. Omit answered rows and do not turn them into model-created product options. Detailed privacy, delivery, operating-environment, ownership, workset, and acceptance decisions wait until evidence makes their consequences concrete, unless one is required to inspect safely.
- Preserve user-supplied unresolved alternatives exactly as `D1`; its decision dependency is always `None`. Baseline `Q` IDs may defer a recommendation but never make D1 itself dependent. Do not add a third route beyond custom input. Do not add first-packet future permission, update, state, history, continuity, tool, or rollout decisions; those wait until their parent exists.
- A child waits only when its parent determines whether it exists or makes its options meaningful. Once the route exists, batch co-answerable factual `Q` and neutral `D` items; use `recommendation deferred pending <Q IDs>` rather than serializing for recommendation evidence.
- If the user names decision topics to revisit after evidence, keep every topic on the decision frontier. Once evidence makes their options and consequences explainable, include them in the same next concentrated packet. A dependent item may appear with an exact parent-option dependency instead of being postponed; defer it only when the parent answer is genuinely required to formulate the child options.
- After shared or multi-owner work is selected, state `confirmed <D ID>=<shared choice>` immediately before the named shared packet; newly created child rows inherit that exact parent, while unique dependencies remain row-level. Carried independent decisions such as first-packet workset or acceptance keep `dependency: None` and stay outside the inherited child group or are explicitly labeled carried/independent. Compile: `Q actual roles/current owners`, `D update authority`, `D conflict behavior`, `D history/audit evidence`, `Q current source + D future authority`, `Q existing sensitive data + D record-visibility scope + D field masking`, `Q actual environment + D future continuity`, `Q acceptance owner + D acceptance conditions`. These are co-answerable: unresolved facts defer recommendations, not questions. Keep record visibility separate from field masking, conflict from audit, current facts from future rules, and owner from criteria.
- Use `Q` only for current facts and `D` only for future product/business meaning; split mixed facts and choices. Each important item states why it is needed now. Render concentrated packets as compact rows or tables, not unlabeled question lists. Every `Q` row has `ID | question | why now/answer impact | reply`. Every `D` row has `ID | dependency/why now | recommendation basis when one option is recommended | each option: material impact | custom reply | deferrable yes/no`. Neutral options with no recommended marker mean no recommendation; order and silence never create a default. A named group may state a genuinely identical dependency/why-now/basis once; each row owns unique impacts and reply. End with exact deferrable IDs and consequence.
- Track a multi-part `Q` by its factual facets. A partial reply fills only the facets actually answered; when the `Q` is shown again, preserve every still-material unanswered facet instead of shortening it away. Merge or remove a facet only when later evidence answers it or makes it irrelevant.
- Before sending a multi-`D` packet, run option compatibility lint: every `D` has `None` or exact dependencies; no option silently requires another `D` value; bind a required value exactly or remove that promise; split ambiguous `or` permissions into distinct choices. Shared update authority distinguishes submit/create, edit, close, and delete; never combine `view or submit`. `Not applicable` binds the exact option that removes the behavior. Any offline entry, temporary table, later replay, reconciliation, or sync path binds exact conflict and audit options. During discovery-only work every shared rule may defer; it becomes blocking only before affected implementation or acceptance. Copy these canonical audit labels without shortening: `actor`, `time`, `action`, `result`, `before/after`, `source/submission chain`, `failed actions`, `denied actions`, `recovery evidence`. `None` excludes all labels; `basic` includes actor/time/action/result and excludes all others; `complete` includes all labels. Audit evidence never proves restore capability; recovery behavior needs its own exact option/decision. Siblings promise audit evidence only by exact audit-option reference.
- When many optional areas remain, build a gray-area map and let the user choose discussion scope; this never approves scope. Preserve the user's exact set and count: `跨部门`, `多个文件`, or `若干使用者` does not authorize invented members, counts, or roles.
- Use assumption-first alignment: prefer evidence-backed assumptions and user correction over silent defaults. Combine stable final scope and start authorization when possible; never repeat unchanged confirmation.
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
