---
name: allred-project-standard
description: Start or continue non-trivial Codex-assisted projects with evidence-based scope, benchmark selection, low-interruption decisions, staged execution, verification, and handoff. Use for new projects, beginner project mode, ongoing debugging/features/UI work, acceptance, long-term tasks, and Skill or workflow improvement. Do not use for simple Q&A, trivial text edits, or one-command fixes.
---

# Allred Project Standard

Use this Skill to keep a project aligned without turning the conversation into a questionnaire.

The governing loop is:

```text
限定方向 -> 确认本轮 -> 小步执行 -> 证据验证 -> 验收复盘
```

This Skill applies to apps, scripts, automation, data work, documentation, device-related investigation, knowledge organization, and reusable workflow or Skill improvement. In non-software work, interpret `开发` as `执行`, `功能` as `任务目标`, and `交付形态` as `成果形态`.

## Activation

Use standard new-project mode for `allred新项目`, `新项目`, `启动新项目`, `开始项目`, or an explicit request to use the Allred project workflow.

Use beginner interaction only for `allred新手新项目`, `allred新手项目`, `新手项目`, `新手模式`, or a project already recorded in beginner mode. Incidental phrases such as `新手员工`, `新手培训`, or document titles do not activate it.

Use long-term mode for `allred长期任务`, `长期任务启动`, `开始长期任务`, `继续长期任务`, `长期任务复盘`, `长期任务调试`, `长期任务资料分析`, `长期任务验证`, or `长期任务优化`. If `长期任务` is only a topic and the intent is unclear, ask whether to enter the mode or only discuss it.

Route an existing project by the actual request:

| Signal | Stage |
| --- | --- |
| `项目调试`, `功能调试`, errors, wrong results | 功能调试 |
| `新增功能`, `加功能`, new capability | 新增功能 |
| `界面优化`, `UI 优化`, layout/usability issue | 界面优化 |
| `本轮验收`, `项目复盘`, delivery review | 本轮验收/复盘 |
| `继续项目` with unclear intent | use the routing rules below |

Do not force an ongoing request back through new-project startup.

## Required Reading

Read only the references needed for the routed request:

| Situation | Read |
| --- | --- |
| Any activated workflow that may ask decisions or mutate files | `references/交互与确认规则.md` |
| New project | `references/新项目启动模式.md` |
| Beginner interaction | `references/新手模式.md`, then the routed stage |
| Existing project or mixed request | `references/项目阶段分流.md` |
| Function debugging | `references/功能调试.md` |
| New feature | `references/新增功能.md` |
| UI optimization | `references/界面优化.md` |
| Acceptance or review | `references/本轮验收与复盘.md` |
| Long-term task | `references/长期任务模式.md` |
| Skill/workflow improvement | `references/Skill流程优化模式.md` and `references/Skill测试验收.md` |
| Non-trivial design or capability choice | `references/开发依据与能力复用.md` |
| Project level or execution strategy is unclear | `references/项目级别问法.md` |
| Online search, market intelligence, or public-information monitoring | `references/公开信息监测项目.md` |

Use `references/首次触发示例.md` only when the opening response is unclear. Use `references/项目类型问题库.md` only after the project type is known and a domain-specific decision is actually needed.

## Shared Contract

Preserve these invariants across every mode:

1. Start from the user's rough requirement and existing idea; do not invent a competing product before understanding it.
2. Request and inspect relevant local materials before asking factual questions. Treat the user's first-version idea as project material.
3. Define the problem, users, constraints, and measurable success before choosing architecture, UI, workflow, protocol, data model, toolchain, dependency, or product behavior.
4. Classify interaction style, full-project complexity, and current-round strategy separately. Beginner mode does not make a project small.
5. Base classification on evidence and risk. Do not ask the user to choose a level from vague labels when Codex can assess it.
6. Select a development basis or benchmark before non-trivial design, then inspect existing Skills, plugins, MCP servers, scripts, libraries, templates, and project patterns before adding capabilities.
7. Separate total scope from current-round scope only when uncertainty, risk, size, or long-term work makes that useful. A bounded project may implement all clear functions in one round.
8. Keep user-owned product decisions visible. Low interruption means compressed decisions and useful progress updates, not silent autonomy.
9. Before a substantial new build, scope expansion, shared-data write, or long-term round, restate the current scope and obtain confirmation as defined in `references/交互与确认规则.md`.
10. Execute in small verifiable steps; protect original data; verify the intended delivery form; report evidence, gaps, and remaining risk.
11. Treat each approval narrowly. Confirming a route such as real-source validation does not approve topics, features, data providers, architecture, credentials, or delivery form that were not shown in that choice.
12. Claim only evidence actually observed through user-provided content or a completed tool/read/test event. A path, expected fixture, prior conversation, or hidden test answer is not proof that material was inspected.

## Conversation Topology

The lifecycle below is the order of reasoning and evidence work, not a list of questions to ask the user.

For a normal new project, keep these as the default user-visible decision points:

1. one opening checkpoint for available materials and the user's initial idea, when they are not already provided
2. one consolidated decision card after the available read-only inspection and internal analysis
3. one prominent start-development or start-execution confirmation after concrete preflight

Research progress, evidence summaries, benchmark records, and implementation updates are communication, not new approval rounds. Add another decision card only when new evidence creates a user-owned blocker, an answer conflicts with an earlier decision, or a consequence could not reasonably have been known before. State which new evidence caused it.

For a bounded normal task, keep the consolidated card to 1-4 user-owned decisions. Put the complete proposed fields, states, rules, and acceptance behavior in a stable named draft such as `范围草案 V1`, and make one decision approve or change that draft. Text outside the approved card or named draft is not authorized. Lifecycle stages, technical checks, and every proposed business rule must not become separate questions.

Codex owns the default work of searching and selecting a comparable benchmark, inspecting installed capabilities, resolving implementation-path mismatches, drafting provisional complexity/current-round strategy, and preparing a technical plan. Do not ask whether Codex should perform those steps. Ask the user only when a choice changes product behavior, evidence meaning, delivery experience, cost, permissions, external actions, write boundaries, or acceptance.

## New-Project Lifecycle

```text
粗略需求
-> 用户资料和初版想法
-> 资料分析
-> 问题、约束和成功标准
-> 风险分级与本轮策略
-> 开发依据/对标
-> 已有能力检查
-> 交付环境（需要时）
-> 需求草案与关键决策
-> 总范围和本轮范围
-> 执行前确认
-> 小步实现
-> 验证
-> 验收复盘
```

Do not turn each lifecycle arrow into a conversation turn. Several internal stages may complete between the material checkpoint and the consolidated decision card.

The order matters: benchmark and tool choices come after the problem is defined, and implementation comes after the current-round meaning is confirmed.

## Existing And Long-Term Work

For an existing project, first classify Bug, optimization, new feature, UI issue, acceptance item, or long-term continuation. If several are mixed, recommend the order based on failed commitments and risk; normally fix current-scope Bugs before adding features.

Every long-term round begins with a lightweight review. Use a full review only when context is missing, evidence changed, conclusions conflict, ownership changed, or the next action affects a final conclusion, shared tracker, device, system, or handoff.

Keep confirmed conclusions, unverified assumptions, rejected directions, current-round goals, and future work distinct.

## Benchmark And Capability Gate

For non-trivial design, follow `references/开发依据与能力复用.md`:

- search local known-good work first, then official maintained sources, then strong external examples when needed
- record why the benchmark is comparable, what is reused, deliberate differences, and acceptance metrics
- check installed capabilities before adding tools or dependencies
- use `find-skills` when a real capability gap exists, not as ceremony
- do not invoke a heavy expert Skill merely because it is available; explicit user requests and higher-priority environment rules win

An external product benchmark is optional. A stated development basis is not.

## Execution And Evidence

Use `references/证据等级说明.md` when conclusions depend on evidence and `references/写入边界说明.md` when original data, devices, shared systems, trackers, or final conclusions may be modified.

Completion means the agreed outcome was verified, not merely that code ran or a package was created. Verify against the selected benchmark's relevant qualities when a benchmark was used.

## Templates

Use templates only when the result benefits from a durable project record:

- `templates/项目启动卡.md`: medium, complex, uncertain, or shared projects
- `templates/项目中途推进卡.md`: scoped work in an existing project
- `templates/长期任务回顾卡.md`: long-term review and round control
- `templates/任务分解表.md`: multiple dependent tasks
- `templates/关键指标表.md`: measurable acceptance needs
- `templates/本轮验收卡.md`: current-round closure
- `templates/交接卡.md`: ownership transfer or pause
- `templates/Skill测试验收记录.md`: Skill behavior testing

Do not fill every template for a small task.

## Global Stop Conditions

Pause and ask only when continuing would require a user-owned decision or unsafe assumption, including:

- real versus simulated capability, delivery form, validation meaning, data-source credibility, or a material scope change
- destructive or shared writes, device/system actions, sensitive data, credentials, legal/privacy exposure, or irreversible work
- no evidence path for a conclusion that affects delivery, quality, safety, or customer commitments
- a complex project being treated as one unbounded implementation step
- a long-term round changing confirmed conclusions or shared records without review
- the user says stop, pause, cancel, summarize, or correct direction

Do not add a ceremonial question when the user's current message already clearly authorizes the exact scoped action. Do not interpret broad approval as permission for unrelated external actions, installs, commits, pushes, deployments, or device/system writes.

## Maintenance

When changing this Skill, use `skill-creator` when available, record architecture decisions in `references/调试与优化建议.md`, run `scripts/check_skill_structure.ps1`, and walk through the relevant behavior cases in `references/Skill测试验收.md`.
