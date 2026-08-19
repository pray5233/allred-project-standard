---
name: allred-project-standard
description: Use when the user says "allred新项目", "新项目", "启动新项目", "开始项目", "项目开发标准流程", "项目推进标准流程", "allred长期任务", "长期任务启动", "开始长期任务", "继续长期任务", "长期任务复盘", "长期任务调试", "长期任务资料分析", "长期任务验证", "长期任务优化", "长期任务", "继续项目", "项目调试", "功能调试", "新增功能", "加功能", "界面优化", "本轮验收", "Skill优化", "技能优化", "优化技能", or wants to start, continue, debug, extend, polish, validate, hand off, review, or standardize a Codex-assisted project, Skill, workflow, or long-running technical task. Use beginner mode only when a project request explicitly says "allred新手新项目", "allred新手项目", "新手项目", "新手模式", or an active project is already recorded as beginner mode; do not infer beginner mode from incidental mentions of "新手". Use long-term task mode when the request explicitly says "allred长期任务", "长期任务启动", "开始长期任务", "继续长期任务", "长期任务复盘", "长期任务调试", "长期任务资料分析", "长期任务验证", "长期任务优化", or when an active project is already recorded as a long-term task; if "长期任务" is ambiguous, ask whether to start, continue, review, or only discuss. This skill applies the Allred project standard: route the project stage, capture the user's rough requirement first, request and analyze project materials, confirm level and strategy, confirm development basis or benchmark gate, confirm runtime environment and delivery mode when relevant, choose requirement sorting depth, inspect existing capabilities, refine requirements with numbered choices, separate total project scope from current-round scope when needed, restate and confirm current-scope requirements before implementation or task execution, decompose tasks, define metrics, evidence levels, write boundaries, current-scope acceptance, review, checkpoints, and handoff. Do not use for trivial text edits, simple Q&A, or one-command fixes.
---

# Allred Project Standard

Use this skill before starting a non-trivial project with Codex.

The goal is not to slow the user down. The goal is to prevent the common failure pattern:

```text
需求没问清 -> Codex 直接开发 -> 范围扩大 -> 结果不可验证 -> 后续无法交接
```

For an ongoing project, the goal is to prevent another common failure pattern:

```text
调试、新增、优化混在一起 -> 改动范围失控 -> 旧功能回归 -> 没有证据能说明已经变好
```

This Skill is not limited to app or software-tool development. For long-running technical work, device troubleshooting, data analysis, documentation, knowledge-base building, Skill/process improvement, or staged process improvement, treat:

- `本轮功能` as `本轮任务目标` or `本轮验证目标`
- `交付形态` as `本轮成果形态`, such as an analysis conclusion, test record, validation report, data archive, documentation index, stage plan, or runnable tool
- `开发` as `小步执行`, which may mean coding, analysis, file organization, testing, review, documentation, or handoff

## Trigger Meaning

When the user says:

```text
allred新项目
新项目
启动新项目
开始一个项目
按项目开发标准流程
按项目推进标准流程
```

treat it as a request to start the project standard workflow.

When the user says:

```text
allred长期任务
长期任务启动
开始长期任务
继续长期任务
长期任务复盘
长期任务调试
长期任务资料分析
长期任务验证
长期任务优化
```

use long-term task mode and read `references/长期任务模式.md`.

Treat `长期任务` alone as a long-term task signal only when it is clearly the user's intended mode or the active project is already recorded as a long-term task. If it may be a topic, file title, training content, or general discussion, ask:

```text
这里的“长期任务”是希望进入 Allred 长期任务模式，还是只是在讨论长期任务？
1. 进入长期任务模式，并建立或继续本轮推进（推荐）。
2. 只是讨论长期任务方法，不进入流程。
3. 先做长期任务复盘，再决定下一轮。
```

When the user says:

```text
allred新手新项目
allred新手项目
新手项目
新手模式
```

in a project context, use beginner mode.

Do not trigger beginner mode from incidental wording such as:

- `新手培训`
- `新手员工`
- `给新手使用`
- `新手教程`
- a document title or file content that contains `新手`

If `新手` could mean the target audience rather than the user's desired interaction mode, ask a short clarification instead of switching modes:

```text
这里的“新手”是指使用者是新手，还是希望我用新手模式推进？
1. 使用者是新手，但我仍按标准模式推进（推荐）。
2. 请用新手模式推进。
3. 两者都是。
```

If the user only asks a small factual question or a narrow edit, do not expand it into this full workflow.

If the first response style is unclear, use `references/首次触发示例.md` as the opening pattern.

## Beginner Mode

If beginner mode is triggered, read `references/新手模式.md` and use it before the standard workflow.

Beginner mode is an interaction layer, not only a project-starting stage. If a project is started or recorded as beginner mode, keep the beginner interaction style for later debugging, new features, UI optimization, and acceptance unless the user exits beginner mode.

Exit beginner mode when the user says:

- `退出新手模式`
- `切换标准模式`
- `不用新手模式`
- `按标准流程`
- `按标准模式`
- `我已经熟悉了`
- `用专业模式`

When the user exits beginner mode, acknowledge the switch and continue with the same project stage under the standard workflow. Do not restart the project.

Beginner mode keeps the same project standard but reduces the visible process:

- use plain language instead of development terms
- ask one question at a time
- use numbered choices with option `1` as the recommended default
- assume a normal office computer unless the user says otherwise
- prefer no-install or low-install delivery
- default small projects to direct implementation of all clear functions
- escalate to the standard medium or complex workflow only when risk, multi-user use, devices, shared systems, sensitive data, or long-term maintenance appears
- for ongoing stages, preserve the same safety and validation standards while using simpler questions, fewer terms, and clearer next actions

## Project Stage Routing

Before starting the full startup workflow, classify the project stage.

| Stage | Typical trigger | Reference to read |
| --- | --- | --- |
| 新项目启动 | `allred新项目`, `新项目`, `启动新项目`, `开始项目` | `references/新项目启动模式.md` |
| 功能调试 | `项目调试`, `功能调试`, `修 Bug`, `报错`, `结果不对`, `按钮没反应` | `references/功能调试.md` |
| 新增功能 | `新增功能`, `加功能`, `再加一个`, `能不能支持` | `references/新增功能.md` |
| 界面优化 | `界面优化`, `UI 优化`, `页面不好看`, `不顺手`, `布局问题` | `references/界面优化.md` |
| 本轮验收/复盘 | `本轮验收`, `项目复盘`, `做完了`, `下一步怎么做` | `references/本轮验收与复盘.md` |
| 长期任务推进 | `allred长期任务`, `继续长期任务`, `长期任务复盘`, `长期任务调试`, `长期任务资料分析`, `长期任务验证`, `长期任务优化` | `references/长期任务模式.md` |

If the user says `继续项目` or the stage is unclear, ask:

```text
当前项目处于哪个阶段？
1. 功能调试（推荐）：已有功能出错、结果不对、按钮没反应，先复现和找根因。
2. 新增功能：已有项目上增加能力，先判断是否进入本轮范围。
3. 界面优化：功能基本可用，主要改善页面、操作流程或视觉体验。
4. 本轮验收/复盘：检查本轮是否完成，并决定下一步。
5. 长期任务推进：已有长期项目或分阶段任务，需要先回顾再确定本轮目标。
6. 新项目启动：还没有明确范围，需要重新启动项目流程。

请回复数字，也可以直接写自定义阶段。
```

Do not force ongoing-project requests back into the new-project startup workflow.

If beginner mode is active, still route the project stage first. Then apply the beginner interaction layer to the chosen stage rather than restarting a new project.

## Long-Term Task Mode

Use `references/长期任务模式.md` when a project is explicitly long-running, spans multiple rounds, involves devices/systems/evidence chains, or when the user triggers a long-term task keyword.

Long-term task mode is a project type and review discipline, not a separate app-building workflow. It can route into data analysis, debugging, validation, documentation, planning, acceptance, or handoff.

When the long-term task is improving a Skill, project standard, prompt workflow, or training workflow, treat the Skill or workflow itself as the product being improved. Read `references/Skill流程优化模式.md`; use `skill-creator` when available, read the current `SKILL.md` and relevant references before editing, and validate with `references/Skill测试验收.md` or an equivalent behavior-test checklist.

Before each long-term task round, do a review gate:

- lightweight review for normal continuation
- full review when the context is missing, a new conversation starts, new materials appear, conclusions conflict, ownership changes, or the next step may affect a final conclusion, shared tracker, device, or system

Do not start a new long-term task round until the user confirms the current-round objective, evidence basis, write boundary, result form, and validation method.

## Skill Reuse And Benchmarks

For each stage, reuse excellent same-type Skills as benchmarks when available. Reuse the method, checklist, and validation discipline. Read `references/专家Skill调用策略.md` when deciding whether to invoke the full expert Skill or only reuse its method.

| Stage | Best local benchmark | Reuse as |
| --- | --- | --- |
| 需求梳理 | `grilling` | one decision at a time, facts inspected by Codex, decisions confirmed by user |
| 功能调试 | `systematic-debugging` | reproduce, find root cause, test one hypothesis, fix only after evidence |
| 新增功能 | `test-driven-development` and `prd-generator` | acceptance criteria before code, feature scope and success metrics |
| 界面优化 | `frontend-testing-debugging` and `redesign-existing-projects` | target flow, screenshot/interaction evidence, focused UI diagnosis |
| 验收收尾 | `finishing-a-development-branch` and local acceptance card | verify first, then present structured next-step options |

Record the chosen benchmark or reused Skill in the task note, startup card, or acceptance summary:

- benchmark Skill or source
- why it matches this stage
- what to reuse
- what to adapt for company employees
- validation evidence

Default rule:

- beginner mode and small projects: use Allred lightweight flow unless the user explicitly requests the expert Skill
- medium projects: ask before invoking the full expert Skill
- complex projects, repeated failures, strict testing, rendered UI validation, or formal handoff: recommend invoking the expert Skill, then wait for confirmation unless the user already explicitly requested it

## Required Workflow

Keep SKILL.md as the lightweight entry and routing layer. Load detailed mode references only when the current request needs them.

For a new project startup, read and follow `references/新项目启动模式.md`.

Use this compact entry sequence before loading deeper references:

```text
粗略需求
-> 资料收集
-> 资料分析
-> 项目级别判断
-> 开发依据/对标确认
-> 交付/成果形态判断
-> find-skills/已有能力检查
-> 需求梳理
-> 总功能/总目标和本轮范围拆分
-> 执行前功能/任务复述
-> 用户确认
-> 小步执行
-> 验证
-> 验收复盘
```

Mandatory entry gates:

- start from the user's rough requirement before `grill-me` or requirement sorting
- request and analyze relevant materials before detailed questions when the project is non-trivial
- confirm project level and development basis before delivery form, design, or implementation
- inspect existing Skills, plugins, MCP servers, scripts, libraries, templates, and prior files before adding capabilities
- separate total scope from current scope when the project is medium, complex, uncertain, or long-running
- restate current-scope requirements and wait for user confirmation before implementation or task execution
- use the smallest mode-specific reference that fits the routed stage

For Skill, workflow, prompt-standard, or training-flow optimization, read `references/Skill流程优化模式.md` after the long-term task review gate.

## Self-Correction

If the workflow starts drifting, say so explicitly and offer a numbered correction.

Use these correction patterns:

```text
我可能把这个小项目问得过重了。建议先回到本轮明确功能和最小验收。
1. 回到小项目轻量流程（推荐）。
2. 保持当前完整流程。
3. 重新判断项目级别。
```

```text
这个需求已经超出本轮范围，建议放入后续路线图。
1. 放入后续路线图（推荐）。
2. 加入本轮开发，但同步调整验收范围。
3. 从总功能中移除。
```

```text
当前结果还缺少验证证据，不建议直接交付。
1. 先补本轮验收（推荐）。
2. 只整理当前进度，不声明完成。
3. 用户人工确认后继续。
```

## Output Format

For a new project, output these sections:

For small projects, keep the output compact:

```text
项目级别：
开发策略：
使用者电脑环境：
交付形态：
目标：
输入：
输出：
资料/本地文件：
开发依据/对标：
本轮范围：
本轮暂不开发但总功能保留：
关键验收指标：
写入边界：
执行前功能/任务复述：
本轮范围确认问题：
建议下一步：
```

For medium and complex projects, output the full sections:

```text
项目级别：
开发策略：
使用者电脑环境：
交付形态：
目标：
用户：
需求梳理方式：
资料/本地文件：
资料分析结果：
开发依据/对标：
已有能力：
梳理后仍需确认：
功能分层展示：
总功能范围：
本轮范围：
本轮暂不开发但总功能保留：
后续开发路线图：
任务分解：
关键指标：
证据等级：
写入边界：
本轮最小闭环：
验证方式：
执行前功能/任务复述：
检查点和交接：
建议下一步：
```

For complex projects, also include:

```text
owner：
风险清单：
证据链：
回退方案：
交接卡：
阶段检查点：
```

For current-scope acceptance or review, output:

```text
本轮验收结论：
已通过：
未通过：
Bug：
优化：
新功能：
移除：
后续路线图更新：
建议下一步：
```

For requirement-sorting or `grill-me` exit, output:

```text
需求梳理退出总结：
退出触发词：
已确认：
仍然基于假设：
本轮功能/任务：
本轮暂不做但后续保留：
明确不做：
主要风险：
验收方式：
建议下一步：
```

For ongoing-project work, output:

```text
项目阶段：
新手模式：
当前请求分类：
对标/复用方法：
专家 Skill 调用：
本轮开发依据/对标：
当前承诺范围：
本次处理范围：
暂不处理：
需要的证据：
验证方式：
建议下一步：
```

For long-term task mode, output:

```text
长期任务状态：
回顾类型：
已确认结论：
未验证假设：
新增资料/证据：
本轮开发依据/对标：
已有能力/find-skills：
当前最大问题：
本轮目标：
本轮不做：
成果形态：
验证方式：
写入边界：
验收证据：
建议下一步：
```

## Templates

Use templates from `templates/` when useful:

- `项目启动卡.md`
- `项目中途推进卡.md`
- `长期任务回顾卡.md`
- `任务分解表.md`
- `关键指标表.md`
- `本轮验收卡.md`
- `交接卡.md`
- `Skill测试验收记录.md`

Use scripts from `scripts/` when useful:

- `scripts/check_skill_structure.ps1` for dependency-free structure checks when updating or distributing this Skill.

Use references from `references/` when explaining:

- `首次触发示例.md`
- `新手模式.md`
- `新项目启动模式.md`
- `资料收集与分析.md`
- `项目阶段分流.md`
- `专家Skill调用策略.md`
- `项目级别问法.md`
- `项目类型问题库.md`
- `运行环境与交付形态.md`
- `长期任务模式.md`
- `Skill流程优化模式.md`
- `功能调试.md`
- `新增功能.md`
- `界面优化.md`
- `本轮验收与复盘.md`
- `Skill测试验收.md`
- `证据等级说明.md`
- `写入边界说明.md`
- `调试与优化建议.md`

## Stop Rules

Stop and ask for confirmation when:

- target is unclear
- development basis or benchmark mode is missing before delivery/result form, requirement sorting, planning, implementation, or task execution in a non-trivial project
- user runtime environment or delivery mode is unclear and it affects implementation
- existing capability check has not been done
- write boundary is not defined
- validation method is missing
- current development/task scope has not been confirmed
- long-term task round starts without lightweight or full review, unless no previous context exists and the user confirms this is a fresh start
- long-term Skill/process optimization starts editing before reading the current Skill/workflow materials, relevant references, and `skill-creator` when available
- long-term task assumptions are presented as confirmed conclusions
- long-term task final conclusions, shared trackers, device/system actions, or handoff records would change without explicit confirmation
- implementation or task execution starts before restating the current-scope requirements and asking whether anything changed or was missed
- the user asks to stop, exit, pause, summarize, or proceed from current understanding during requirement sorting or `grill-me`
- non-trivial new project enters `grill-me`, implementation, or task execution before requesting and analyzing relevant project materials, unless the user confirms no materials are available
- chosen delivery mode requires tools, installation, server, or packaging that the user cannot run or has not approved
- total scope and current scope are mixed together in a way that conflicts with the chosen strategy
- small project flow is expanded into medium or complex depth without user confirmation
- beginner mode is triggered but the response uses the full standard workflow without escalation
- beginner mode is triggered only because `新手` appeared as a target audience, file title, training topic, or other incidental text
- user asks to exit beginner mode but the response continues using beginner-mode assumptions
- ongoing-project request is forced into new-project startup flow without stage confirmation
- a full expert Skill is invoked in beginner mode or a small project without explicit user request
- an expert Skill is invoked without checking availability, user intent, and current environment constraints
- debugging starts before reproducing the issue or identifying evidence
- a new feature is implemented before classifying whether it is bug, optimization, or scope expansion
- UI polish is claimed complete without checking the target user flow or rendered evidence when applicable
- complex project attempts to implement the full product scope without a first version
- current-scope completion is claimed without an acceptance card or validation evidence
- a Skill update is claimed complete without structure checks and a relevant behavior-test walkthrough or documented test gap
- new features are mixed into bug fixing without user confirmation
- the user asks for device/system write operations
- the next step would modify shared project trackers or final conclusions

Do not start implementation or task execution until the user confirms the current-scope requirement restatement and the plan.


