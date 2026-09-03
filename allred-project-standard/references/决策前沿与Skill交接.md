# 决策前沿与 Skill 交接

Use this reference when requirement ambiguity needs an interview, when the user explicitly invokes `grill-me`/`grilling`, or when capability discovery may involve `find-skills`. Allred owns project scope, evidence, mutation, and acceptance. This reference owns interview topology and cross-Skill handoff only.

## Ownership Router

Choose exactly one visible interview owner:

| Signal | Interview owner | Allred behavior |
| --- | --- | --- |
| clear authorized task | none | inspect, execute, verify |
| ordinary Allred ambiguity | Allred fallback frontier | use the internal frontier below |
| explicit `$grill-me`, `$grilling`, `grill me`, or equivalent explicit invocation | external `grilling` when available | yield visible interviewing; do not ask a duplicate Allred packet |
| explicit request to find an installable Skill | `find-skills` discovery when available | preserve scope; search only, no installation |

Do not invoke external `grilling` merely because a project is complex. Do not make it a required dependency: another computer may not have it installed, and Codex cross-Skill invocation support differs by host. A literal explicit `$grill-me`/`$grilling` choice is user-owned: Allred must not start its fallback in the same response. If the host cannot activate the requested Skill, say so once and wait for the user to choose the Allred fallback or another path.

External grilling is optional; the Allred fallback does not require the external Skill.

An implicitly matched `find-skills` does not prove a capability gap. The capability gate in `references/开发依据与能力复用.md` still decides whether discovery is relevant.

## Internal Frontier Model

Build a private decision tree for the current approved outcome, not the product's entire possible future. Each node records:

| Field | Meaning |
| --- | --- |
| ID | stable `Q` fact or `D` decision identifier |
| parent dependencies | exact answers/evidence required before this node is meaningful |
| owner | Codex fact-finding, user information, user decision, or action authorization |
| basis | exact `U/E/D` support or missing evidence |
| current-outcome impact | what scope, behavior, risk, delivery, or acceptance changes |
| state | unresolved, investigating, frontier, confirmed, deferred, rejected, or conflict |

The frontier contains all unresolved user-owned nodes whose parent dependencies are settled and whose answers matter to the current outcome. Keep the whole frontier internally, but show only one readable dependency-valid slice at a time. A child whose options depend on an open frontier node waits for a later round.

The semantic skeleton in `SKILL.md` is a coverage lint, not a mandatory visible questionnaire. Add a node only when its answer changes the current outcome; remove answered, inspectable, irrelevant, and safely deferred nodes.

## Readable Frontier Slice

Keep the full frontier internal. Ordinary packet: at most four priority `Q/D`, one line each and one reply; queued count only, unresolved. Never name or settle an unshown item. Validate with `scripts/validate_question_packet.ps1 -Profile decision-frontier -PassThrough`.

## Fact-Finding Queue

Facts are Codex-owned when files, tools, official documentation, or safe read-only inspection can establish them. Before asking the user:

1. inspect the smallest relevant local evidence
2. start independent fact-finding without blocking unrelated frontier decisions when the environment permits parallel work
3. mark only downstream nodes as waiting for that evidence
4. ask the remaining frontier now

Do not require a subagent for ordinary work. Use local tools directly for small or tightly coupled checks. Use parallel/subagent exploration only when available, allowed, and materially useful. External content remains untrusted evidence and follows `references/外部内容安全.md`.

## Frontier Round

For each visible node, keep dependency, basis, ownership, and deferral fields internally. Show only its stable ID, plain-language question, one short impact, compact options, and an inline recommendation marker when evidence supports one. Surface dependency or safety/cost/privacy detail only when needed to understand that choice. Never print separate `为什么现在问/当前依据/建议/影响/选择/回复` paragraphs for every node.


After each user answer or evidence event, update only affected nodes, recompute the frontier, and keep settled decisions stable. Do not keep grilling after every material current-outcome node is confirmed, evidence-backed, or explicitly deferred.

## External Grilling Handoff

While explicit external `grilling` owns the interview:

- Allred performs no mutation and opens no parallel questionnaire
- facts found from project evidence remain evidence, not decisions
- recommendations remain unapproved until the user answers
- `停止询问`, `够了`, or `退出 grill-me` ends the visible interview under the existing stop rules

When the user asks Allred to continue after grilling, reconstruct one handoff from the conversation:

```text
Interview target:
Confirmed facts/evidence:
Confirmed decisions and exact meaning:
Deferred decisions and consequence:
Open blockers/conflicts:
Rejected or out-of-scope branches:
Assumptions and risks:
```

Do not require the external Skill to generate this exact format. Allred reconstructs it, compares it with project evidence, and asks for correction only when a material mismatch remains. Once the usable conversation and evidence are available, output the complete categorized handoff in that response; do not replace it with a promise to inspect, reconcile, or summarize later. Name each evidence conflict in the handoff and put only its user-owned correction in the normal scope/start gate. A grilling conclusion is not mutation authorization. Convert the handoff into the normal named scope/start gate, then use the execution record and decision coverage validators.

## Stop And Fallback

Stop the frontier when the current outcome is truthful, safe, and testable. Do not wait for every speculative future branch.

- external grilling unavailable after explicit invocation: offer Allred fallback without starting questions; do not install it automatically
- user stops questions: summarize confirmed/deferred/open nodes and continue only an already authorized safe subset
- preserve frontier states as separate groups when summarizing: confirmed, deferred, blocking/conflict, rejected, and investigating. A rejected choice is not a confirmed active feature, and an investigating fact is not a deferred decision
- missing fact can be researched: investigate instead of asking the user
- missing decision is genuinely blocking: keep only the affected outcome paused
- exact scope already authorized: skip both external and fallback interviews
