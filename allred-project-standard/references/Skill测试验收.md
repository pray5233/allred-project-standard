# Skill 测试验收

Use this reference when testing whether `allred-project-standard` behaves correctly after changes.

Testing a Skill has two parts:

- static structure check: files, references, trigger terms, and obsolete wording
- behavioral check: realistic prompts in a fresh conversation

## Static Structure Check

Run the official validator when dependencies are available:

```bash
python %USERPROFILE%\.codex\skills\.system\skill-creator\scripts\quick_validate.py %USERPROFILE%\.codex\skills\allred-project-standard
```

If `yaml` is unavailable, do a manual check:

```text
1. SKILL.md has valid frontmatter with name and description.
2. All references listed in SKILL.md exist.
3. All templates listed in SKILL.md exist.
4. No obsolete wording remains: old clarification-mode labels, old English question-mode wording, or the old post-grill pending-confirmation field.
5. Trigger terms exist for new project, beginner mode, ongoing project, debugging, new feature, UI optimization, and acceptance.
6. Stop Rules cover direct coding, missing scope, missing validation, wrong stage routing, and expert Skill over-invocation.
7. Stop Rules cover functional requirement restatement before app/tool implementation.
8. Stop Rules cover requirement-sorting / `grill-me` exit trigger words.
9. Beginner mode has explicit trigger guards and exit trigger words.
```

## Behavioral Test Method

Use a new conversation for trigger tests. Old context can mask whether the Skill naturally activates.

For each test:

1. Paste the test prompt.
2. Record the first Codex response.
3. Check only observable behavior, not exact wording.
4. Mark Pass / Partial / Fail.
5. If failed, write the smallest Skill change needed.

## Acceptance Levels

| Level | Meaning | Required response |
| --- | --- | --- |
| P0 | Must pass | Wrong behavior makes the Skill unsafe or misleading |
| P1 | Should pass | Workflow quality issue; fix soon |
| P2 | Nice to improve | Wording or training clarity issue |

Overall pass:

- all P0 tests pass
- no more than two P1 tests fail
- every failure has a clear next edit

## P0 Tests

### T1 New project has no description

```text
allred新项目
```

Pass:

- asks the user to describe the rough requirement first
- does not invent a project
- does not output a full startup card
- does not write code
- says that after the rough requirement, relevant materials/files should be added or described before requirement sorting

### T2 Beginner mode stays lightweight

```text
allred新手项目
我想做一个 Excel 清单整理工具。
```

Pass:

- enters beginner mode
- asks one question only
- uses numbered choices with option `1` recommended
- does not ask about Python, Node, database, framework, server, or deployment first
- does not invoke a full expert Skill by default

### T3 Ongoing bug routes to debugging

```text
继续项目
客户问题跟踪工具现在能打开，但导入后有几行没有识别。
```

Pass:

- routes to ongoing project / function debugging
- does not restart new-project workflow
- asks for reproduction steps, sample input/output, or evidence
- says it will not mix new features into the bug fix

### T4 New feature does not start coding

```text
新增功能
现在能生成 Excel 了，再加一个按负责人筛选。
```

Pass:

- classifies as new feature
- asks whether it enters current scope or roadmap
- defines acceptance criteria before implementation
- includes regression check for existing Excel generation

### T5 UI optimization requires target flow

```text
界面优化
这个工具页面不好用，按钮太乱。
```

Pass:

- routes to UI optimization
- asks for target user flow or recommends focusing on the main operation
- diagnoses before rewriting
- asks for or plans rendered evidence when applicable

### T6 Expert Skill explicit request is respected

```text
allred功能调试
请调用 systematic-debugging，按钮点了没反应。
```

Pass:

- recognizes explicit expert Skill request
- says expert Skill will handle the professional debugging part
- keeps Allred scope, write boundary, and acceptance control
- still starts with reproduction/evidence

### T7 Expert Skill not over-invoked for small tasks

```text
allred新项目
我想做一个文件重命名工具，规则已经明确，只要预览后确认再执行。
```

Pass:

- treats as small project candidate
- does not invoke full expert Skills by default
- requests sample filenames, rule examples, or file-location information before detailed requirement sorting, or records that no materials are available
- asks only must-decide questions
- confirms input, output, write boundary, and validation

### T8 New project requests and analyzes materials before grill-me

```text
allred新项目
我想做一个客户设备清单和问题反馈跟踪工具，相关 Excel 和截图已经放在工程里。
```

Pass:

- asks for or searches relevant local materials before structured `grill-me` questioning
- analyzes available files before asking factual questions
- summarizes material-backed facts and assumptions
- asks the user to confirm the analysis before finalizing requirement sorting
- does not start implementation before scope confirmation

### T9 Functional requirements are restated before app/tool development

```text
allred新项目
我想做一个离线 Windows 小工具，用 Excel 统计每个员工工时，规则已经说明清楚，可以开始做。
```

Pass:

- does not start creating app/tool files immediately
- restates the target user, input, functions, output, delivery form, validation, non-goals, and assumptions
- asks whether the functional requirements have changes or omissions
- provides numbered choices with option `1` as the recommended confirmation
- waits for user confirmation before implementation

### T10 Requirement sorting exits on stop trigger words

```text
allred新项目
我想做一个客户问题跟踪工具，先按中型项目梳理。
够了，先总结，按当前理解推进。
```

Pass:

- stops asking new `grill-me` / requirement-sorting questions
- outputs a requirement-sorting exit summary
- lists confirmed items, assumptions, current-scope functions, reserved future scope, non-goals, risk, and validation
- asks for the next step with numbered choices
- does not start implementation until the user confirms the functional requirement restatement and plan

### T11 Incidental beginner wording does not trigger beginner mode

```text
allred新项目
我想做一份新手员工培训资料目录工具。
```

Pass:

- does not automatically enter beginner mode only because `新手员工` appears
- asks whether `新手` means the target user or beginner interaction mode if needed
- can proceed in standard mode when `新手` only describes the tool audience
- does not use beginner-mode defaults unless user confirms beginner mode

### T12 Beginner mode can be exited

```text
allred新手项目
我想做一个 Excel 清单整理工具。
退出新手模式，按标准流程继续。
```

Pass:

- acknowledges switching to standard mode
- continues the same project stage instead of restarting the project
- stops applying beginner assumptions such as one-question-only visibility
- still keeps Allred confirmation, validation, and write-boundary rules

### T13 Beginner mode persists across ongoing stages

```text
allred新手项目
我想做一个 Excel 清单整理工具。
继续项目
导入后有几行没有识别。
```

Pass:

- routes to function debugging, not new-project startup
- keeps beginner interaction style
- asks for visible problem, operation path, screenshot, sample input, actual output, or expected output in plain language
- does not start with technical terms like stack trace, framework, database, or terminal commands

## P1 Tests

### T14 Mixed bug and new feature

```text
功能调试
按钮点了没反应，顺便帮我加一个导出 PDF。
```

Pass:

- button issue classified as Bug
- PDF export classified as New feature
- recommends fixing Bug first
- asks before expanding scope

### T15 Complex project recommends expert Skill

```text
继续项目
这个设备连接问题已经修了三次还不稳定，日志每次都不一样。
```

Pass:

- routes to function debugging
- identifies repeated failure / unclear root cause
- recommends full systematic debugging or deeper evidence gathering
- does not attempt another blind fix

### T16 Frontend validation when requested

```text
界面优化
这个页面移动端错位，请使用 frontend-testing-debugging 检查。
```

Pass:

- respects explicit expert Skill request if available
- defines target flow
- asks for or uses rendered evidence
- checks mobile layout when practical

## Test Record Template

```text
测试日期：
测试人：
Skill 版本/提交：
测试对话：

| ID | 提示词 | 期望 | 实际 | 结论 | 需要修改 |
| --- | --- | --- | --- | --- | --- |
| T1 |  |  |  | Pass/Partial/Fail |  |

P0 通过数：
P1 通过数：
是否通过本轮验收：
下一版优先修改：
```

## Final Acceptance Checklist

Before saying the Skill update is done:

- static structure check completed
- obsolete wording check completed
- required references and templates exist
- at least P0 tests are mentally or actually walked through
- user-facing trigger terms remain clear
- no new rule forces all projects into heavy process
- no new rule bypasses user confirmation
