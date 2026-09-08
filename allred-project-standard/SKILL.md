---
name: allred-project-standard
description: Run evidence-based project work when the user explicitly invokes Allred, starts a new project, continues a long-term task, or asks to continue an established Allred project. Supports software and substantial internal document projects; do not activate for ordinary Q&A, trivial edits, or unrelated one-command work.
---

# Allred Project Standard

Keep project work aligned through material-first discovery, adaptive questions, one meaningful scope/start approval, and verified delivery.

Use the ownership contract in `references/核心执行流程.md`: the user sets goals
and material trade-offs; Codex investigates, recommends and decides within
inherited authorization; the Skill guides communication and preserves its record.
Do not turn workflow defaults or a valid state file into product decisions.

```text
粗略需求 -> 资料收集与分析 -> 内部方案与能力检查 -> 必要决策 -> 范围确认 -> 执行 -> 验证
```

## Activation And Routing

- New project: `allred新项目`, `新项目`, `启动新项目`, `开始项目`, `allred新手新项目`, `allred新手项目`, or `新手项目`.
- Beginner expression: `allred新手` or `新手模式`; `退出新手模式` returns to standard wording. Incidental descriptions such as `新手员工` do not toggle it.
- Long-term work: explicit `allred长期任务` or a request to start, continue, review, debug, analyze, verify, or optimize an established long-term task. A quoted keyword or ordinary discussion does not activate it.
- Existing work follows its current task: debug, feature, UI, review, or long-term. Do not restart discovery for an exact authorized change.

Resolve the actual product, not a noun in the prompt. A request to build a system for managing documents is software; a request to produce those documents is non-software.

| Work | Route / variant |
| --- | --- |
| new software/tool | `new-standard` |
| error or wrong result | `existing-debug` |
| add a capability | `existing-feature` |
| improve an existing interface | `existing-ui` |
| substantial document work | `non-software`, matching `training/policy/knowledge/bid/contract/inspection` variant |
| continuing evidence/project work | `long-term` |

Beginner aliases select the same route with `-Interaction beginner`; they change no stage, scope, dependency, authorization, or acceptance. A style-only toggle acknowledges the change without repeating the questionnaire.

Skill maintenance belongs to `allred-project-lab`. Do not run ordinary project intake for a request to improve this Skill.

## Required Reading

From the first progress message, distinguish source wording from your
interpretation. Reading a source confirms its contents, not an unstated meaning,
cause or workflow choice. Keep such interpretations tentative in progress,
answers and records alike. Keep routine script/record repairs internal; report
their practical consequence only when useful work or the user's result changes.

Run `scripts/get_route_context.ps1 -Route <route> -Stage <stage> -Interaction standard|beginner` for the current stage. Stages: `intake`, `evidence`, `decision`, `ready`, `external-read`, `execution`, `verification`. Load `ready` only for the complete final scope/start envelope; its delivery and execution-record detail is not needed for each question round.

- Pass named PowerShell parameters directly. Select applicable overlays from the evidence using the mapping below and include `-Overlays` in the same stage call, for example `-Overlays shared-collaboration`. Inspecting general context does not load an overlay. Revisit that selection only when new evidence changes applicability.
- Conditional overlays add no user triggers: `external-source` for actual external sourcing (`-ExternalMode one-time` or `monitoring`); `shared-collaboration` for shared authority over the same live state; `company-office-delivery` for evidenced office-computer constraints. Multiple readers, files, departments, or beginner wording alone do not select them. Unselected domains remain silent.
- Read the selected context once per route/stage/variant/overlay combination. Reuse unchanged references after tool results; update project state instead of rereading instructions.
- Keep discovery in a cumulative conversational record as described in `references/内部记录生成.md`. Preserve source words, answered meanings and unresolved facets after material changes; asking a question does not require a state file. Before the final start envelope, materialize the existing schema with `scripts/update_project_state.ps1`; `scripts/build_start_record.ps1` derives the execution record. Reuse an existing state incrementally. Neither helper grants approval; do not copy passing fixtures.
- Load newly relevant stages or capabilities before using them. `-GuardsOnly` refreshes a stage already read; it does not substitute for first reading.
- New-project READY and EXECUTION require the actual `-StatePath`. Decision context is guidance and loads without state. Supplying state at DECISION opts into record diagnostics, not permission to converse. Software and new non-software projects use the same action gates. For an established document/change only, select `-WorkKind existing`.
- If all consequential choices are already settled and no decision packet is needed, go directly to the actual READY gate, which includes intake and frontier checks; a separate DECISION call adds no validation. Missing evidence, coverage, preflight, scope authority or start approval still blocks its stage. Render the start envelope's root and file layout from the gate's `ValidatedWriteLayout`, preserving subdirectories instead of reconstructing paths.
- `-ContextOnly` and `-MetricsOnly` inspect instructions only. They never validate a project or authorize READY or execution. Conversation uses actual evidence and user authority, not a tool receipt. An event ID or a sentence saying "passed" is not validation.
- If scripts are unavailable, read the applicable references for authorized evidence collection; do not claim machine validation. Existing exact safe work can continue under its actual authorization.

When wrapping commands with `functions.exec`, emit the whole awaited tool result
with `text(result)` so the process handle and exit status survive. A returned
`session_id` requires collecting that command with `write_stdin`; empty output
while it runs is pending. Preserve the full collection result too. Use the
completed exit status and output before deciding whether a retry is needed.

| Topic | Canonical owner |
| --- | --- |
| execution lanes and stages | `references/核心执行流程.md` |
| new-project intake | `references/新项目启动模式.md` |
| materials | `references/资料收集与分析.md` |
| adaptive questions and grilling handoff | `references/决策前沿与Skill交接.md` |
| visible questions and approval | `references/交互与确认规则.md` |
| cumulative scope, coverage, changes | `references/动态项目契约.md` |
| state and aggregate validation | `references/阶段状态硬校验.md` |
| beginner wording | `references/新手表达层.md` |
| complexity and delivery | `references/项目级别问法.md`, `references/运行环境与交付形态.md` |
| benchmark and capability reuse | `references/开发依据与能力复用.md` |
| existing route selection | `references/项目阶段分流.md` |
| debug / feature / UI | `references/功能调试.md`, `references/新增功能.md`, `references/界面优化.md` |
| long-term / document work | `references/长期任务模式.md`, `references/非软件项目模式.md` |
| acceptance / evidence / writes | `references/本轮验收与复盘.md`, `references/证据等级说明.md`, `references/写入边界说明.md` |

## Runtime Hard Stops

- Claims such as inspected, verified, preflight complete, or validation passed need actual matching evidence. Source existence, metadata, HTTP success, or a component check does not prove the integrated product. Keep untested routes visibly candidate.
- Read locatable user materials before evidence-dependent recommendations. For an explicit list of inspection targets, cover each relevant target or state the missing one; a summary referring to an artifact is indirect evidence, not inspection of that artifact. A descriptive label is not a path. For an exact inspection, do one bounded search; if nothing is locatable, ask only for that target.
- A user saying promised materials have not yet been supplied is not a reason to search as if they were present. Ask for their location together with other still-missing independent intake facts.
- An explicit no-material/no-sample answer closes that request. Continue available evidence work and preserve sample-dependent uncertainty.
- User decisions, scope, exclusions, first-release omissions, numbers, and acceptance targets require their own authority. Absence, silence, sample findings, or a neighboring answer never supplies it.
- Preserve the user's initial idea and full intended scope. Split current versus later work only when needed; never use a first release to discard requested functions. Codex chooses implementation mechanics, while consequential user-facing trade-offs stay with the user.
- Keep originals unchanged during inspection. Disclose disposable extraction/rendering artifacts outside project delivery paths, using `scripts/new_evidence_temp.ps1` unless the workspace specifies an evidence location. Report relevant observations and limitations, then continue the next authorized action.
- The final start scope requires READY validation; mutation requires exact authorization plus EXECUTION validation. A record error does not prevent useful read-only investigation or conversation. Resolve it before the affected action; do not disguise a failed action gate with an event label or a different route.
- Before writes, validate normalized allowed paths, original protection, and rollback. Installation, network transfer, system changes, and external effects must be within the user's authorized scope.

## Shared Invariants

1. Keep runtime policy domain-neutral. Domain references provide applicable coverage lenses, never a mandatory questionnaire for every project.
2. Maintain user statements, evidence, decisions, recommendations, and scope separately. One answer changes only the facets it actually answers.
3. Prefer local known-good work, then official/maintained benchmarks. Codex owns evidence inspection, benchmark selection, technical planning, and capability checks.
4. Check installed capabilities first. Use `find-skills` for a real gap; it is optional and search does not authorize installation.
5. Complexity, delivery form, and beginner expression are separate. Explain concrete complexity drivers only when they change the plan or verification.
6. Before READY, review cumulative discovery coverage across workflow, information, lifecycle/exceptions, scale, delivery/effects, and acceptance. Evidence can close a lens; material unresolved gaps cannot disappear.
7. Stop asking when the current outcome is coherent, traceable, and testable, with remaining gaps explicitly handled. There is no total interview-round limit.
8. Preserve total scope, current scope, confirmed deferrals, rejected directions, and unknowns across partial answers, interruptions, and style changes.

## Conversation Topology

Use the frontier loop in `references/决策前沿与Skill交接.md`:

1. With only a trigger, request a short rough description.
2. With a substantive idea, gather only missing user/workflow/pain, materials/location, initial idea/must-haves, and recognizable useful result. These are readiness facets, not four compulsory questions.
3. Inspect supplied materials and independent evidence. Form proposals from what is actually known.
4. After every answer or new evidence, update affected facts and decisions, preserve unrelated settled work, and recompute dependencies.
5. Ask the next readable group of currently meaningful questions. A partial answer does not close siblings; a new fact can create a new question or remove an irrelevant one. Only genuine dependencies require sequential rounds.
6. When ready, recap the full current outcome, inputs, outputs, delivery, limits, important assumptions, write/rollback boundary, and verification in one scope/start envelope.

All modes share the Question Packet Contract in `references/交互与确认规则.md`. Codex selects a manageable group from current evidence and dependencies; numeric readability signals are advisory, not interview quotas. Keep pending items unresolved, never implicit exclusions or deferrals.

`scripts/validate_question_packet.ps1` is an optional diagnostic for a draft or recorded dependency mismatch. Do not run it for every reply. With `-StatePath` and `-QuestionIds` it checks the declared record; without them it gives readability signals. Neither mode decides whether a question is useful or grants authorization. At READY, review cumulative coverage. Keep routine diagnostic repairs internal and continue useful conversation while record-only problems are repaired.

Unknown factual answers are valid when the user cannot know yet. Record unknown without inventing a value; reopen only when a concrete new dependency makes it necessary. Accept numbers, natural prose, corrections, and custom answers. Keep IDs internal or optional.

An exact safe existing-project task already authorizes inspection, the scoped change, and verification. Do not add a new-project gate. For a new project, ordinary direction approval or "continue" does not start implementation unless it answers the complete immediately visible scope/start envelope.

The new-project start envelope clearly says work has not started and the approval will start it. A Codex-selected project root remains a visible pending recommendation; show allowed write scope, original protection, rollback, and installation/delivery effects in plain language. The start option explicitly says `批准以上范围并开始开发/制作`. Do not ask for duplicate unchanged approval.

Explicit `grill-me/grilling` owns the visible interview when available; Allred does not run a competing interview. Otherwise Allred uses its internal frontier. Superpowers is a local method benchmark, not a required runtime process. Do not automatically stack process skills, mandatory TDD, worktrees, per-task commits, or subagents.

## Execution And Verification

Use bounded implementation steps and fresh risk-scaled verification. Debugging follows reproduction, evidence, one causal hypothesis, a minimal experiment/fix, and regression. After three failed hypotheses, reassess the evidence and architecture before more speculative patches.

Verify the promised user workflow, not file existence or an agent's success statement. Keep source, component, integrated, and target-environment evidence distinct. Report the verification method and relevant observations, remaining gaps, and next action. Preserve meaningful hashes, values, or defects when they support a completion claim; avoid dumping internal mechanics.

Templates are optional records for useful handoff, not required ceremonies: `templates/项目启动卡.md`, `templates/项目中途推进卡.md`, `templates/长期任务回顾卡.md`, `templates/任务分解表.md`, `templates/关键指标表.md`, `templates/本轮验收卡.md`, `templates/交接卡.md`.

## Memory And Notes Boundary

- `allred记忆` explicitly invokes `allred-project-memory`.
- `allred笔记` explicitly invokes `allred-obsidian-notes`; when both are requested, memory precedes notes.
- Ordinary completion does not install Obsidian, create a personal Vault, copy a benchmark knowledge base, or automatically run either Skill.

## Stop Conditions

Stop on the user's stop/pause/cancel request, a material unresolved conflict, unavailable essential evidence, or an action outside existing authorization. Pause only the affected work and preserve current state. Do not turn routine mechanics into a permission question.
