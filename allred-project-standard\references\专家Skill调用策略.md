# 专家 Skill 调用策略

Use this reference when Allred has routed the project stage and must decide whether to call a full expert Skill or only reuse its method.

The goal is to avoid two failures:

- not using an expert workflow when the project is risky or complex
- overloading a small or beginner task with a heavy expert workflow

## Priority Rules

1. If the user explicitly names an expert Skill, use that Skill when available and allowed. Allred still controls scope, write boundaries, and acceptance.
2. If the user uses an Allred trigger, Allred is the project entrypoint. Route the stage first, then decide whether an expert Skill is needed.
3. Beginner mode and small projects default to the Allred lightweight flow.
4. Medium projects ask before invoking a full expert Skill.
5. Complex projects, repeated failures, strict testing, rendered UI validation, or formal handoff should recommend an expert Skill and ask for confirmation unless the user already requested it.
6. Do not invoke a Skill that is unavailable, blocked by current instructions, or irrelevant to the delivery environment.

## Invocation Choices

When the choice matters, ask:

```text
是否调用完整专家 Skill？
1. 使用 Allred 内置轻量流程（推荐）：复用对标方法，但不额外加载完整专家流程。
2. 调用完整专家 Skill：适合复杂调试、严格测试、前端界面验证或正式收尾。
3. 暂不调用，只记录对标来源。

请回复数字，也可以直接写自定义要求。
```

If the user already explicitly requested the expert Skill, do not ask this generic question. Instead say:

```text
你已指定使用 `{expert_skill}`。我会用它处理专业部分，同时用 Allred 控制本次范围、写入边界和验收。
```

## Stage Defaults

| Allred stage | Default expert handling | Call full expert Skill when |
| --- | --- | --- |
| 需求梳理 | reuse `grilling` method | user asks for `grill-me` / `/grilling` / complete questioning |
| 功能调试 | reuse `systematic-debugging` method | root cause is unclear, bug is risky, repeated fixes failed, or user asks |
| 新增功能 | reuse `test-driven-development` / `prd-generator` method | behavior is critical, tests exist, feature changes data model/workflow, or user asks |
| 界面优化 | reuse `frontend-testing-debugging` / `redesign-existing-projects` method | a rendered app must be inspected, screenshots are needed, responsive bugs exist, or user asks |
| 本轮验收/收尾 | reuse acceptance card / `finishing-a-development-branch` method | tests pass and user wants merge, PR, cleanup, or formal branch completion |

## Conflict Handling

If multiple Skills could trigger:

```text
这条请求同时匹配 Allred 和专业 Skill。我先按 Allred 做项目范围控制，再决定是否调用专业 Skill。

建议处理：
1. Allred 轻量处理（推荐）：先分流、定范围、明确验收。
2. 调用专业 Skill：适合复杂或高风险问题。
3. 用户指定优先：按你明确点名的 Skill 处理。

请回复数字，也可以直接写自定义选择。
```

Do not show this when the user already clearly specified the priority.

## What To Record

Record expert Skill decisions in the startup card, ongoing-project card, or final summary:

```text
专家 Skill 调用：
对标 Skill：
调用方式：未调用/轻量复用/完整调用
原因：
适配点：
验证方式：
```

## Stop Rules

Stop and ask before invoking the full expert Skill when:

- the user is in beginner mode
- the project is small and low-risk
- the expert Skill would require browser, plugin, server, test framework, GitHub, or external service access
- invoking it would change the agreed current scope
- there is a conflict between the expert Skill and Allred's current-stage rules

## Acceptance

The expert Skill strategy passes when:

- explicit user requests are respected
- Allred triggers route through Allred first
- beginner and small projects stay lightweight by default
- complex or repeated-failure cases recommend an expert Skill
- every full invocation has a reason and validation method
