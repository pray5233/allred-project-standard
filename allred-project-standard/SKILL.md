---
name: allred-project-standard
description: Use when the user says "allred新项目", "新项目", "启动新项目", "开始项目", "项目开发标准流程", "项目推进标准流程", "allred长期任务", "长期任务启动", "开始长期任务", "继续长期任务", "长期任务复盘", "长期任务调试", "长期任务资料分析", "长期任务验证", "长期任务", "继续项目", "项目调试", "功能调试", "新增功能", "加功能", "界面优化", "本轮验收", or wants to start, continue, debug, extend, polish, validate, hand off, review, or standardize a Codex-assisted project or long-running technical task. Use beginner mode only when a project request explicitly says "allred新手新项目", "allred新手项目", "新手项目", "新手模式", or an active project is already recorded as beginner mode; do not infer beginner mode from incidental mentions of "新手". Use long-term task mode when the request explicitly says "allred长期任务", "长期任务启动", "开始长期任务", "继续长期任务", "长期任务复盘", "长期任务调试", "长期任务资料分析", "长期任务验证", or when an active project is already recorded as a long-term task; if "长期任务" is ambiguous, ask whether to start, continue, review, or only discuss. This skill applies the Allred project standard: route the project stage, capture the user's rough requirement first, request and analyze project materials, confirm level and strategy, confirm runtime environment and delivery mode when relevant, confirm development basis, choose requirement sorting depth, inspect existing capabilities, refine requirements with numbered choices, separate total project scope from current-round scope when needed, restate and confirm current-scope requirements before implementation or task execution, decompose tasks, define metrics, evidence levels, write boundaries, current-scope acceptance, review, checkpoints, and handoff. Do not use for trivial text edits, simple Q&A, or one-command fixes.
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

This Skill is not limited to app or software-tool development. For long-running technical work, device troubleshooting, data analysis, documentation, knowledge-base building, or staged process improvement, treat:

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
| 新项目启动 | `allred新项目`, `新项目`, `启动新项目`, `开始项目` | use Required Workflow below |
| 功能调试 | `项目调试`, `功能调试`, `修 Bug`, `报错`, `结果不对`, `按钮没反应` | `references/功能调试.md` |
| 新增功能 | `新增功能`, `加功能`, `再加一个`, `能不能支持` | `references/新增功能.md` |
| 界面优化 | `界面优化`, `UI 优化`, `页面不好看`, `不顺手`, `布局问题` | `references/界面优化.md` |
| 本轮验收/复盘 | `本轮验收`, `项目复盘`, `做完了`, `下一步怎么做` | `references/本轮验收与复盘.md` |
| 长期任务推进 | `allred长期任务`, `继续长期任务`, `长期任务复盘`, `长期任务调试`, `长期任务资料分析`, `长期任务验证` | `references/长期任务模式.md` |

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

### 1. Capture The User's Initial Requirement

Start from the user's own description. Do not use `grill-me` questioning to invent the product or define features before the user has described the rough need.

If the user already gave a rough need, briefly restate the shared understanding before asking structured questions:

- what they seem to want to build
- who will use it
- likely input
- likely output
- the first unclear decision

If the user only says a trigger word such as `allred新项目` or `新项目` without describing the project, ask for a short free-form description first:

```text
先请你用一两句话描述一下想做什么，不需要说技术方案。

可以按这个格式写：
我想做一个____工具/任务，主要给____使用，输入或资料是____，希望输出____。
```

Only after a rough requirement exists, continue to material collection and analysis. Then continue to project level, delivery mode, development basis, and requirement sorting.

### 2. Collect And Analyze Project Materials

For non-trivial new projects, ask the user to add relevant local materials to the workspace or describe where they are before entering structured requirement sorting or `grill-me` style questioning.

Use `references/资料收集与分析.md` for detailed handling.

Ask:

```text
为了避免只凭口头描述开发，请尽量把相关资料加入当前工程，或说明资料所在位置。
1. 样例文件/历史表格/原始数据（推荐）
2. 现有流程说明、制度文件、截图或手工操作记录
3. 参考工具、历史项目或现有模板
4. 暂时没有资料：先按现有描述整理假设，并缩小本轮范围

请回复数字，也可以直接说明资料位置。
```

If materials are provided or already exist in the workspace:

- inspect them before asking factual questions
- distinguish facts found in files from assumptions
- summarize the material analysis result
- ask the user to confirm which inferred requirements are correct, uncertain, or out of scope
- only then continue to project level, delivery mode, development basis, requirement sorting, and possible `grill-me` questioning

If the user has no materials:

- record `暂无资料`
- label assumptions as unverified
- keep the current scope smaller
- require stricter validation with sample data, later-supplied files, or user confirmation

### 3. Confirm Project Level

Classify the project:

| Level | Meaning | Required Process |
| --- | --- | --- |
| Small | One tool/task, one workflow, one clear output | lightweight startup card + direct implementation or execution of all clear work |
| Medium | Multiple files/modules/steps, repeatable use | choose strategy + startup card + metrics + task breakdown |
| Complex | Long-running, multiple owners, devices/systems, evidence chain | first version or current-round objective first + full standard + handoff + checkpoints |

If the level is unclear, ask:

```text
这个项目按哪个级别启动？
1. 小项目（推荐）：一个工具/任务、一个流程、一个明确输出，本轮可直接做完明确功能或明确行动。
2. 中型项目：多个文件/模块，后续会反复使用，需要任务分解和关键指标。
3. 复杂项目：涉及多人、设备、系统、真实业务流程或较强证据链，需要完整计划、交接和检查点。

请回复数字，也可以直接写自定义判断。
```

Do not use the same depth for every project.

Use level-specific depth:

| Level | Question Depth | Required Output |
| --- | --- | --- |
| Small | ask only must-decide questions | compact startup card + current-scope confirmation |
| Medium | standard questions and task breakdown | startup card + strategy choice + metrics + task table + validation plan |
| Complex | full questions, risk, owner, evidence, checkpoints | first-version/current-round plan + full standard + handoff card + checkpoint plan |

For detailed question sets, read `references/项目级别问法.md` when the level is unclear or when drafting the startup conversation.

Set development strategy by level:

| Level | Default Strategy |
| --- | --- |
| Small | directly implement or execute all clear, low-risk work in the current scope |
| Medium | ask the user to choose direct full implementation, first-version iteration, or plan-only |
| Complex | require a first version before expanding into the full scope |

For medium projects or ambiguous scope, ask:

```text
本项目采用哪种开发策略？
1. 直接实现全部明确功能/行动（推荐用于小项目或低风险中型项目）：本轮范围就是已确认的完整需求。
2. 先做第一版/本轮验证，再逐步迭代（推荐用于复杂项目或需求不确定时）：先跑通最小闭环，再做后续功能或任务。
3. 先整理完整方案，暂不开发：适合需求还没定、需要先评审的项目。

请回复数字，也可以直接写自定义策略。
```

### 4. Define The Problem

Ask for or extract:

- user or department
- exact problem
- input materials
- expected output
- constraints
- success criteria
- what not to do

If local files, existing docs, scripts, repo rules, or README files can answer a factual question, inspect them instead of asking the user.

If the project type is recognizable, use `references/项目类型问题库.md` to ask more specific questions without increasing the process level unnecessarily.

### 5. Confirm Runtime Environment And Delivery Mode

Before choosing app, web, script, or automation, distinguish the development environment from the user's runtime environment.

Codex may be able to build in the workspace, but the employee's computer may only have ordinary office tools. Do not assume Python, Node.js, Git, admin permission, package managers, or a local server exist on the user's machine.

Use `references/运行环境与交付形态.md` when delivery mode is unclear, the user is a beginner, or the tool must run on another employee's computer.

Ask:

```text
使用者电脑环境大概是哪种？
1. 普通办公电脑（推荐）：有浏览器/Office，可能没有 Python、Node、Git 或管理员权限。
2. 开发电脑：可以运行 Python/Node/Git，也能按说明安装依赖。
3. 受限电脑：不能安装软件，只能打开浏览器、Office 或普通文件。
4. 不确定：先按普通办公电脑设计，尽量少依赖安装环境。

请回复数字，也可以直接写自定义环境。
```

Then ask when the delivery form affects implementation:

```text
本轮成果最终希望以什么形式交付？
1. 免安装文件工具/普通文件成果（推荐给新手/办公电脑）：例如单个 HTML、本地文件夹工具、Excel/模板、整理后的表格、报告或目录，尽量双击或用 Office/浏览器打开。
2. 桌面 App/可执行文件：适合频繁处理本地文件、离线使用或需要窗口界面，但需要打包和杀毒/权限验证。
3. 网页版工具：适合多人共享、统一更新、权限和数据同步，但需要服务器、部署、账号和维护。
4. 脚本/命令行工具：适合熟练用户或批处理，不适合完全新手直接使用。
5. 阶段性分析/验证成果：适合长期任务，交付分析结论、测试记录、日志归档、问题清单、阶段计划或验收报告。
6. 暂不确定：先按最少安装、最容易验收的方式做本轮。

请回复数字，也可以直接写自定义交付方式。
```

Default for beginners:

- prefer no-install or low-install delivery
- prefer outputs that open with browser, Office, or ordinary files
- avoid requiring terminal commands as the normal user workflow
- if a desktop app or web app is chosen, include packaging, deployment, and user-machine validation in the current scope

### 6. Choose Requirement Sorting Method

Use the user-facing name `需求梳理方式`. It means: based on the user's existing project description, Codex helps fill missing decisions about target, input, output, boundary, validation, delivery, and maintenance. It is not a request for Codex to invent the product for the user.

Do not ask this before the user has described a rough requirement. If the rough requirement is missing, first ask the user to describe what they want to build.

For small projects, use this format:

```text
本项目的需求梳理方式怎么选？
1. 轻量梳理（推荐）：只确认目标、输入、输出、边界和本轮验收。
2. 完整梳理：逐项确认软件设计需求、指标、风险、交接等内容。
3. 先出启动草案：根据现有描述整理草案，并标出待确认项。

请回复数字，也可以直接写自定义要求。
```

For medium or complex projects, use this format:

```text
本项目的需求梳理方式怎么选？
1. 完整梳理（推荐）：适合中型/复杂项目，会逐项确认软件设计需求、输入输出、边界、指标、验证和交接。
2. 轻量梳理：适合小项目，只确认必须由用户决策的内容。
3. 先出启动草案：根据现有描述整理草案，并标出待确认项。

请回复数字，也可以直接写自定义要求。
```

If the user chooses full or lightweight sorting, ask concrete software design questions on top of the user's rough requirement and material analysis before producing the current-scope plan.

If the user chooses a startup draft first, still identify assumptions and unresolved items in the startup card.

### 7. Choose Development Basis

Before design or implementation, confirm the project development basis.

This step is mandatory. An external benchmark is not mandatory.

Use this question:

```text
请选择本项目的开发依据：
1. 用户指定对标（推荐）：我提供一个现有软件、表格、流程、页面或历史项目作为参考。
2. Codex 帮我找对标：由 Codex 搜索本地资料、已有项目、插件/Skill、公开教程或优秀案例。
3. 按公司已有经验开发：参考公司现有表格、流程、岗位习惯、历史文件，不强求外部案例。
4. 先按 AI 方案生成初稿：适合探索型项目，但必须标注假设，并在本轮完成后重点验证。

请回复数字，也可以直接写自定义依据。
```

If the user specifies a benchmark, do not search externally unless the user asks or validation needs it.

If Codex searches for a benchmark, search in this order:

1. project known-good implementation or local reference
2. official documentation or maintained reference implementation
3. high-quality external product or open-source project when needed

If the user chooses company experience, inspect or ask for local files, current forms, manual workflows, historical projects, and role habits.

If the user chooses AI draft:

- clearly label it as an AI first draft, not a validated benchmark
- list key assumptions
- make the current scope smaller when assumptions are high
- set stricter validation metrics
- after current-scope validation, ask whether to supplement a benchmark or continue based on measured results

Record:

- development basis type
- source or assumption
- why comparable
- what to reuse
- what not to copy
- acceptance metrics

If no benchmark fits, record the search scope and why candidates were unsuitable before using a custom or AI-draft path.

### 8. Inspect Existing Capabilities

Before adding anything, inspect available:

- local Skills
- plugins
- MCP servers
- scripts
- libraries
- templates
- prior project files

If `find-skills` is available and the task may need a known Skill, use or recommend it. If not available, manually inspect local skills and tools.

Do not install new capabilities unless they are required, maintained, compatible, licensed appropriately, and narrowly validated.

### 9. Refine The Requirement

Use the `grill-me` style only after a rough requirement exists and relevant materials have been requested, analyzed, or explicitly marked as unavailable.

While in requirement sorting or `grill-me`, honor exit trigger words. Exit triggers include:

- `停止追问`
- `停止询问`
- `别再问了`
- `先别问了`
- `退出追问`
- `退出 grill-me`
- `结束 grill-me`
- `结束需求梳理`
- `够了`
- `先总结`
- `先整理`
- `进入计划`
- `按当前理解推进`
- `按当前理解先做`
- `暂停`
- `先停一下`

Treat the single word `停止` as a requirement-sorting exit trigger only when the user is clearly responding inside an active requirement-sorting or `grill-me` sequence. If `停止` is ambiguous, ask whether the user wants to stop questioning, pause the whole task, or cancel implementation.

When an exit trigger appears, stop asking new requirement questions. Do not start implementation or task execution. Instead, produce a requirement-sorting exit summary and ask for the next step.

Use this format:

```text
需求梳理退出总结：
已确认：
仍然基于假设：
本轮功能/任务：
本轮暂不做但后续保留：
明确不做：
主要风险：
验收方式：

下一步怎么处理？
1. 进入执行前功能/任务复述（推荐）：先复述功能或任务清单，确认无遗漏后再开发/执行。
2. 继续追问一个关键问题：只补最影响结果的一项。
3. 先出启动草案：暂不开发，只整理项目启动卡。
4. 暂停：先不继续推进。

请回复数字，也可以直接写自定义安排。
```

Also exit requirement sorting when:

- small projects already have target, input, output, boundary, and validation
- medium projects already have scope, delivery mode, key metrics, and major risks
- complex projects already have first-version scope, owner, evidence level, write boundary, and checkpoints
- continuing to ask would only add low-value detail and not reduce project risk
- the user chooses startup draft or plan-only mode

The goal is to improve and verify the user's requirement, not to replace the user's idea. Treat it as structured requirement clarification:

- ask hard questions about unclear target, input, output, boundaries, risks, owner, validation
- point out conflicts between the stated goal, current scope, delivery mode, and validation method
- ask one decision question at a time when interaction is needed
- every question must provide numbered choices such as `1 / 2 / 3`
- make option `1` the recommended default whenever a recommendation is possible
- allow the user to reply with only a number
- allow custom text when the listed choices do not fit
- state what the choice affects, such as scope, data, UI, validation, delivery, or maintenance
- do not start implementation or task execution until the user confirms the shared understanding

Question budget by level:

- Small: ask up to 3 must-decide questions before drafting the current scope
- Medium: ask enough to close scope, data, output, metrics, and write boundaries
- Complex: continue until owner, risk, evidence level, checkpoints, rollback, and handoff are clear

Use this pattern:

```text
这个项目第一步更适合按哪种方式推进？
1. 先做最小可运行工具/本轮验证（推荐）：先跑通输入、处理、输出和验证。
2. 先整理完整功能/目标蓝图：适合需求还比较分散、涉及多人协作或长期任务的项目。
3. 先做技术和对标评估：适合不确定技术路线或数据来源的项目。

请回复数字，也可以直接写自定义要求。
```

### 10. Decompose Tasks

Break the project into tasks with:

- input
- output
- owner
- dependency
- allowed write scope
- validation method
- risk level

Mark which tasks can run in parallel and which must be serialized.

### 11. Define Key Metrics

Define metrics by level.

For small projects, at minimum define:

- input metric
- output metric
- success metric
- safety metric

For medium and complex projects, at minimum define:

- input metric
- output metric
- accuracy metric
- safety metric
- usability metric
- delivery metric

Each metric must have:

- target value
- validation method
- failure response

### 12. Define Evidence Level

Use these levels:

| Level | Meaning |
| --- | --- |
| guess | unverified assumption |
| static_analysis | code/docs/logs inspected |
| offline_validation | sample or historical data passed |
| live_validation | real system/device/workflow passed |
| product_closure | repeatable, documented, handed off |

Never treat packaging success as live validation. Never treat static analysis as product closure.

### 13. Define Write Boundaries

Specify:

- read-only files
- allowed edit paths
- forbidden edit paths
- systems/devices that must not be touched
- Git branch or worktree rules
- who owns shared trackers or final conclusions

Default rule:

```text
可以多人读，可以分模块写；
同一文件、同一设备、同一 tracker、同一最终结论只能一个 owner。
```

### 14. Separate Total Scope And Current Scope

Before producing the plan, separate scope according to the project strategy:

- total product scope: what the project may eventually include
- current development/task scope: what will be implemented, analyzed, validated, organized, or delivered in this round
- reserved future scope: features or tasks that remain part of the total goal but are not built or executed in this round
- removed scope: features the user confirms should not remain in the project

For small projects, the current development/task scope may equal the total product scope. Do not force a first-version split when all functions or actions are clear, low-risk, and can be validated in one pass.

For medium projects, use the user's strategy choice:

- direct full implementation: current scope may include all clear functions
- first-version iteration: current scope is the first version and future features go to the roadmap
- plan-only: current scope is the plan deliverable, not implementation

For complex projects, the current development/task scope must be a first version or current-round objective. Do not implement or execute the full product/project scope in one pass.

Do not use current-scope limits to permanently limit the whole project.

Explain the difference with a scope ladder:

| Layer | Meaning | User-facing wording |
| --- | --- | --- |
| 总功能/目标地图 | The full product or project direction and possible final capability | 以后这个工具/项目/长期任务可能完整做到什么程度 |
| 本轮范围 | The work to implement, execute, or deliver now | 这一次确认要做、要验收的内容；小项目可等于全部功能或全部明确行动 |
| 后续路线图 | Useful features or tasks reserved after the current round | 本轮先不做但没有放弃，等当前范围跑通后再排期 |
| 明确移除 | Features that should not be part of the project | 当前和后续都不作为默认目标 |

When showing future features, use a roadmap table:

| 后续功能/任务 | 为什么不放入本轮 | 触发开发条件 | 预计验证方式 |
| --- | --- | --- | --- |

When saying "本轮不做", write it as "本轮暂不开发/暂不执行，但是否保留为总功能或总目标" unless the user explicitly removes the feature.

Ask a numbered clarification when the boundary is ambiguous:

```text
这个功能如何处理？
1. 按当前开发策略处理（推荐）：小项目可放入本轮；复杂项目默认先放后续。
2. 放入本轮范围：本轮必须实现或执行，并进入验收范围。
3. 从项目中移除：后续也不作为默认目标。

请回复数字，也可以直接写自定义要求。
```

### 15. Produce Current-Scope Plan

Before implementation or task execution, first produce a plain-language current-scope requirement restatement. This is mandatory before creating or modifying app, web, script, automation, tool files, analysis outputs, documentation, project records, or long-running task artifacts.

The restatement must include:

- target user
- input materials and data rules
- current-scope functions or task objectives
- output/result
- delivery/result form
- validation method
- functions or tasks not done in this round but reserved for later
- explicit non-goals
- assumptions that still need confirmation

Use this format before the plan:

```text
执行前我先复述本轮功能/任务需求：
1. 使用对象：
2. 输入资料/现有证据：
3. 本轮要做的功能/任务：
4. 输出结果：
5. 交付/成果形态：
6. 验收方式：
7. 本轮暂不做但后续保留：
8. 明确不做：
9. 仍然基于假设的内容：

请确认本轮功能/任务需求是否有改动或遗漏：
1. 没有改动，按以上内容开始开发/执行（推荐）。
2. 有遗漏，需要新增一个本轮必须功能或任务。
3. 有多余，需要删减或后移某些功能/任务。
4. 表述不准确，我直接修改说明。

请回复数字，也可以直接写需要修改的内容。
```

Then wait for user confirmation. If the user changes the functional requirements, update the current scope, validation method, and task plan before asking again.

After the functional requirement restatement is confirmed, produce:

- current development/task scope
- files to create or edit
- commands to run
- validation method
- handoff output
- rollback or checkpoint plan

After drafting the current-scope plan, ask the user to confirm whether the current scope is reasonable and whether anything must be added, removed, or moved.

Use this format:

```text
请确认本轮范围是否合理：
1. 合理，按这个本轮范围推进（推荐）。
2. 需要新增一个本轮必须功能或任务。
3. 需要删减或后移某些本轮功能/任务。
4. 需要重新选择策略或重新区分本轮和后续内容。

请回复数字，也可以直接写自定义调整。
```

Then wait for user confirmation.

### 16. Accept And Review Current Scope

When the current scope is delivered, tested, or the user asks what to do next, switch from startup mode to acceptance and review mode.

Use `templates/本轮验收卡.md` and `references/本轮验收与复盘.md`.

Classify feedback into:

- Bug: the current scope promised it but did not meet it
- Optimization: it works but is inconvenient, unclear, slow, or fragile
- New feature: it was not part of the current-scope commitment
- Remove: the user confirms it should not remain in future scope

Do not mix bug fixing and new feature expansion unless the user explicitly chooses to.

Ask:

```text
本轮复盘后，下一步怎么处理？
1. 先修复本轮 Bug（推荐）：先让已承诺功能稳定可用。
2. 做少量体验优化：本轮功能可用，但需要更顺手。
3. 规划下一轮功能：本轮已闭合，开始处理后续路线图。
4. 暂停开发，整理交接材料。

请回复数字，也可以直接写自定义安排。
```

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
当前最大问题：
本轮目标：
本轮不做：
成果形态：
验证方式：
写入边界：
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

Use references from `references/` when explaining:

- `首次触发示例.md`
- `新手模式.md`
- `资料收集与分析.md`
- `项目阶段分流.md`
- `专家Skill调用策略.md`
- `项目级别问法.md`
- `项目类型问题库.md`
- `运行环境与交付形态.md`
- `长期任务模式.md`
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
- development basis is missing and the task is non-trivial
- user runtime environment or delivery mode is unclear and it affects implementation
- existing capability check has not been done
- write boundary is not defined
- validation method is missing
- current development/task scope has not been confirmed
- long-term task round starts without lightweight or full review, unless no previous context exists and the user confirms this is a fresh start
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
- new features are mixed into bug fixing without user confirmation
- the user asks for device/system write operations
- the next step would modify shared project trackers or final conclusions

Do not start implementation or task execution until the user confirms the current-scope requirement restatement and the plan.
