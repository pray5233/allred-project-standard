# Skill 流程优化模式

Use this reference when the long-term task is to improve a Skill, project standard, prompt workflow, training workflow, README, release package, or reusable working method.

This is a subtype of long-term task mode. It keeps the same evidence discipline, but the product being improved is the workflow itself.

## Core Rule

Treat the Skill or workflow as the product:

- confirmed conclusion: observed behavior, test result, user feedback, accepted rule, or verified source
- unverified assumption: expected behavior that has not been tested
- current-round objective: the smallest instruction, reference, template, README, script, or test change that improves behavior
- future task: useful but unnecessary changes for later versions

Do not turn one user preference or one failed prompt into a universal rule unless the failure is repeatable or the rule protects safety, scope, validation, or handoff.

## Required Materials

Before editing, inspect only the materials that affect the current change:

1. current `SKILL.md`
2. references directly related to the mode being changed
3. `skill-creator` when available
4. test and acceptance references such as `references/Skill测试验收.md`
5. README, release package, install script, or distribution files when the Skill is shared

If a file can answer the factual question, inspect the file instead of asking the user.

## Development Basis

Choose and record the basis before editing:

```text
本轮 Skill/流程优化先按什么依据推进？
1. skill-creator / 官方 Skill 编写原则（推荐）：控制入口长度、渐进披露、只写会改变行为的规则。
2. 现有测试失败或用户反馈：针对一个可复现问题做最小修正。
3. 成熟本地 Skill 对标：复用它的触发、分流、校验或验收方式。
4. 当前 Allred 既有规则：不引入新结构，只修补现有模式。
5. AI 初稿假设：先提出方案，不直接修改，等验证后再落地。

请回复数字，也可以直接写自定义依据。
```

## Change Type

Classify the current-round change before editing:

| Type | Use when | Preferred place |
| --- | --- | --- |
| trigger/routing | words or stage detection must change | `SKILL.md` |
| shared stop rule | must block unsafe or drifting behavior across modes | `SKILL.md` |
| mode workflow | only one mode needs deeper behavior | `references/<mode>.md` |
| template/output | repeated output structure is needed | `templates/` |
| validation | a repeatable check is needed | `references/Skill测试验收.md` or `scripts/` |
| distribution | installed/shared package must change | README, release package, install script |

Prefer editing a mode reference over expanding `SKILL.md` when the rule is not needed at entry.

## Current-Round Flow

Use this order:

```text
1. 回顾上轮已确认行为、失败点、未验证假设
-> 2. 读取当前 Skill / reference / 测试 / 发布资料
-> 3. 明确本轮开发依据或对标
-> 4. 判断改动类型
-> 5. 限定本轮最小改动
-> 6. 明确不改什么
-> 7. 修改文件
-> 8. 运行结构检查和行为用例
-> 9. 同步 README / 发布包 / GitHub（如需要）
-> 10. 记录验收证据和下一轮建议
```

## Current-Round Restatement

Before editing a Skill or workflow, restate:

```text
执行前我先复述本轮 Skill/流程优化任务：
1. 要优化的对象：
2. 已确认问题或改进目标：
3. 本轮开发依据/对标：
4. 本轮要改：
5. 本轮不改：
6. 需要读取的文件：
7. 写入边界：
8. 验证方式：
9. 是否同步发布包或 README：

请确认是否有改动或遗漏：
1. 没有改动，按以上内容开始修改（推荐）。
2. 有遗漏，需要新增一个本轮必须修改点。
3. 有多余，需要删减或后移某些修改点。
4. 表述不准确，我直接修改说明。
```

If the user has already said to continue after approving a proposed direction, treat that as confirmation for the scoped current round.

## Validation

Use behavior-first validation:

- frontmatter exists and has `name` and `description`
- references, templates, and scripts linked from `SKILL.md` exist
- trigger terms route to the intended mode
- incidental wording does not over-trigger special modes
- changed mode has at least one realistic prompt in `references/Skill测试验收.md`
- no new rule forces every task into heavy process
- no new rule bypasses current-scope confirmation
- release package and README are synchronized when distributed

Run `scripts/check_skill_structure.ps1` when available. If a stronger validator such as `quick_validate.py` is blocked by missing dependencies, record that gap instead of claiming it passed.

## Output

For Skill or workflow optimization, output:

```text
长期任务状态：
回顾类型：
优化对象：
已确认问题：
未验证假设：
本轮开发依据/对标：
改动类型：
本轮修改：
本轮不改：
写入边界：
验证方式：
验收证据：
发布/同步状态：
下一轮建议：
```
