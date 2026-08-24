---
name: allred-project-standard
description: Start or continue non-trivial Codex-assisted projects with evidence-based scope, low-interruption decisions, staged execution, root-cause debugging, fresh verification, and handoff. Use for new projects, beginner mode, existing-project features/debugging/UI, acceptance, long-term tasks, and Skill improvement. Do not use for simple Q&A, trivial text edits, or one-command fixes.
---

# Allred Project Standard

Use this Skill to keep project work aligned without turning the conversation into a questionnaire or adding a second process framework.

The governing loop is:

```text
路由定界 -> 读取证据 -> 内部方案 -> 必要决策 -> 连续执行 -> 新鲜验证 -> 交付沉淀
```

Superpowers is a method benchmark, not a runtime dependency. Reuse its strongest disciplines internally: inspect before designing, find root cause before fixing, execute in bounded steps, stop on real blockers, and verify before claiming completion. Do not import mandatory brainstorming, per-section approval, per-task commits, worktrees, or batch feedback gates. Do not use TDD or Red-Green as the execution order.

## Activation And Routing

- New project: `allred新项目`, `新项目`, `启动新项目`, `开始项目`, or an explicit request for the Allred workflow.
- Beginner interaction: `allred新手新项目`, `allred新手项目`, `新手项目`, `新手模式`, or a project already recorded in beginner mode. Incidental text such as `新手员工` does not activate it.
- Long-term work: `allred长期任务`, `长期任务启动`, `开始长期任务`, `继续长期任务`, `长期任务复盘`, `长期任务调试`, `长期任务资料分析`, `长期任务验证`, or `长期任务优化`. If `长期任务` is only a discussion topic or quoted text, do not activate; ask only when intent remains ambiguous.
- Existing project: route from the actual request instead of restarting project discovery.

| Signal | Route |
| --- | --- |
| error, wrong result, failed test, `项目调试`, `功能调试` | 功能调试 |
| `新增功能`, `加功能`, a new capability | 新增功能 |
| `界面优化`, `UI 优化`, usability/layout problem | 界面优化 |
| `本轮验收`, `项目复盘`, delivery review | 本轮验收/复盘 |
| continued multi-round work or evidence accumulation | 长期任务 |

If `继续项目` is unclear and project evidence cannot resolve the route, ask one compact routing question. Beginner mode changes explanation style, not complexity, scope, or engineering rigor.

## Required Reading

Always read `references/核心执行流程.md` for an activated workflow. Read only the additional references needed by the route:

| Situation | Read |
| --- | --- |
| user decision, authorization, or uncertainty | `references/交互与确认规则.md` |
| new project | `references/新项目启动模式.md` |
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

Use `references/资料收集与分析.md` when real files/process evidence may exist. Use `references/项目类型问题库.md` and `references/首次触发示例.md` only when a routed response needs them.

## Shared Invariants

1. Start from the user's rough requirement, initial idea, project files, and current state. Do not invent a competing product before inspecting them.
2. Define the problem, users, constraints, non-goals, and measurable success before a non-trivial design decision.
3. Search the local known-good path first, then official maintained references, then strong external examples only when a real gap remains.
4. Inspect installed Skills, plugins, MCP servers, scripts, libraries, and project patterns before adding capabilities. Use `find-skills` only for a real gap.
5. Classify interaction style, project complexity, and current-round strategy separately. Codex owns provisional classification; the user does not choose from vague size labels.
6. Separate total scope from current scope only when uncertainty, size, risk, or long-term work requires it. A bounded clear project may implement all agreed functions.
7. Keep confirmed facts, hypotheses, proposals, rejected directions, current work, and future work distinct.
8. Protect original data and shared systems. Approval is narrow and never silently expands to installation, upload, Git, deployment, credentials, device action, or unrelated writes.
9. Execute the exact authorized scope in small verifiable steps. Progress communication is not a new approval gate.
10. Claim completion only from fresh verification evidence for the agreed outcome and environment. State remaining gaps and evidence level.

## Conversation Topology

Lifecycle stages are internal reasoning stages, not required conversation turns.

- Clear small or existing-project task: normally `0` decision questions; inspect, execute, verify, report.
- Non-trivial new project: normally exactly `1` combined scope/start gate after all read-only preflight. If a named scope with concrete boundary has already been approved and start was explicitly authorized, do not ask again.
- Exact safe local modification in an existing project: normally `0` gates.
- Complex or consequential task: normally `1` consolidated scope gate; add another gate only for new evidence, a true conflict, or external/irreversible authorization.
- A visible card contains `1-4` user-owned decisions. Method selection, benchmark search, capability inspection, file discovery, technical planning, and routine verification stay Codex-owned.

Codex owns the default work of searching and selecting a comparable benchmark, checking capabilities, preparing a technical path, and choosing narrow verification. Do not ask whether Codex should perform those steps.

If the user already authorized the exact displayed scope with `继续`, `按照建议修改`, `开始开发`, or equivalent wording, do not ask again. Combine scope approval and start authorization when nothing material changes during preflight.

## Execution And Debugging

Use the lane and phase rules in `references/核心执行流程.md`.

For debugging:

```text
稳定复现 -> 收集证据 -> 定位边界 -> 单一根因假设 -> 最小实验/修复 -> 回归验证
```

Do not guess a cause or bundle unrelated refactors. Do not use TDD or Red-Green as the execution order. Analyze and locate the root cause first, implement the smallest fix, then add or run targeted verification and regression checks according to risk. After three failed root-cause hypotheses, stop patching and review the architecture, assumptions, and evidence boundary.

## Verification And Closure

Completion means the promised behavior was verified, not merely that code ran, a package existed, or an agent reported success.

- Run the narrowest relevant verification first; broaden for shared logic, releases, or high-risk changes.
- Compare with the selected benchmark's measurable qualities when a benchmark shaped the design.
- Report `已验证`, `仍未验证`, residual risk, and the exact next action.
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

When changing this Skill, use `skill-creator`, keep shared rules in one owner, record architecture decisions in `references/调试与优化建议.md`, run `scripts/check_skill_structure.ps1` and `scripts/check_behavior_suite.ps1`, validate with realistic cases from `references/Skill测试验收.md`, and synchronize an established release mirror before claiming distribution readiness.
