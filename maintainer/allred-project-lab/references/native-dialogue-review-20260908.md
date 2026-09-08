# Native Dialogue And Contrary-Evidence Review

## Problem And Benchmark

Historical runtime tests opened a fresh ephemeral CLI process each turn and
injected prior messages and observed tools as text. That tests reconstruction,
not native continuation. A previous A06 reviewer also accepted a read-only plan
that included causing a service interruption because no configuration changed.
Users need trustworthy diagnostics before changing a mature interview workflow.

Inspected 2026-09-08: installed official codex-cli 0.153.4 exec/resume help and
the local Lab's original-event adapter, frozen source hashes, exact citations
and actor-environment recovery. Reuse the official continuation path and existing
review contract. No new package, user keyword or runtime approval is introduced.
The benchmark is comparable because it is the same CLI/tool path used by this
Windows evaluator. A CLI experiment does not establish desktop App equivalence.

## Bounded Implementation

- Default SessionMode remains Replay. Native persists the first exec and resumes
  only its returned UUID. Later input is the exact current user text, without
  re-injected history, Skill instructions or reviewer feedback. Each case starts
  fresh; never use --last. CLI owns normal session persistence; the mode is not
  ephemeral and therefore leaves its test sessions in local CLI history.
- Keep sandbox, root, model, effort and config settings across turns. Missing,
  ambiguous or changed session identity is an infrastructure failure, never a
  Skill-quality verdict. Record returned/requested IDs and identity validity.
- Review-only replay recovers the original environment from the first prompt.
  Matching first/current events, transcript identities and user-only later input
  are required. Refuse missing or conflicting context instead of guessing. Keep
  frozen sources, raw reviews and independently locatable evidence unchanged.
- ReviewMethod defaults to Standard. Optional Counterevidence asks the reviewer
  to resolve contrary source evidence before Met, distinguish performed actions
  from planned actions, and honor real delegated scope. It cannot add assertions,
  invent defects, grant consent or change citation/aggregate validation.
- Time and number of rounds remain diagnostic only. InstructionMode Native
  means the no-Skill control; SessionMode Native means session continuity. They
  are independent options. HistoryMode affects injected replay, not native
  continuation after the first turn.
- Read internal Markdown/JSON records as plain UTF-8 text. Windows PowerShell
  5.1 Get-Content attaches provider metadata which deep JSON can recursively
  expand. The existing snapshot adapter now uses ReadAllText; the pipeline
  checks exact content and absence of provider properties before serialization.

## Maintenance Commands

Use new output directories. Commands below run from the Lab directory; adjust
the frozen Skill, suite and evidence paths to the experiment. The array syntax
is for a PowerShell script or prompt; passing I,J through an external -File
invocation supplies one literal string, so invoke one case per process there.

```powershell
& ./scripts/check_native_sessions.ps1 -OutputRoot <new-directory> -SkillRoot <skill>
& ./scripts/run_runtime_dialogues.ps1 -OutputRoot <new-native> `
  -SkillRoot <frozen-skill> -SuitePath <frozen-outcome-suite> `
  -CaseIds @('A02','A14') -SessionMode Native -ReviewMethod Standard `
  -Model gpt-5.6-sol -ReasoningEffort low -UseUserConfig -TimeoutSeconds 1800
& ./scripts/run_runtime_dialogues.ps1 -OutputRoot <new-replay> `
  -SkillRoot <same-frozen-skill> -SuitePath <same-frozen-outcome-suite> `
  -CaseIds @('A02','A14') -SessionMode Replay -ReviewMethod Standard `
  -Model gpt-5.6-sol -ReasoningEffort low -UseUserConfig -TimeoutSeconds 1800
& ./scripts/run_ordered_review.ps1 -OutputRoot <new-review> `
  -ReplayRoot <existing-dialogue> -SuitePath <same-frozen-outcome-suite> `
  -CaseIds A02 -ReviewMethod Counterevidence -UseUserConfig
```

Quick includes the mocked native contract/pipeline check. Its passing result
proves argument construction, identity handling, context binding and evidence
replay only. Use live continuation and outcome review for behavioral evidence.
Re-review is a new judgment of unchanged behavior, not a new actor trial.

## Results And Limits

Evidence root:
F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-08_allred-native-dialogue-review

The same frozen r4 runtime candidate and outcome suite were used in both arms.
All 14 actor turns completed. Native retained one ID within each case and used
different IDs between cases. The live marker test recalled earlier content with
no reinjection or tools. This establishes functional CLI continuation only.

| Case | Replay automatic review | Native automatic review | Maintenance review |
| --- | --- | --- | --- |
| A02 training | Fail | Pass | Both reopen the established learning outcome as a weaker option; native Pass is not accepted. |
| A14 partial answers and pause | Pass | Fail | Both preserve cancellation, unresolved choices, unknown volume and the pause; recurring reference-loading narration remains a communication concern in both. |

The reviewer's additional A02 reporting/time-allocation criticism is not
independently accepted in full: routine teaching arrangements and material
changes need semantic distinction. Do not add a new approval for every detail.
First-use Skill disclosure alone is not a defect. Repeated procedural narration
in later progress is the separate usability concern.

Six Counterevidence controls (C01, C04, C13-C16) matched their expected outcomes,
including positive controls. Re-reviewing the unchanged prior A06 changed the
AI verdict from Pass to Fail and identified the active interruption in a
read-only plan. Native A02 re-review still returned Pass, despite its question
offering reading-only as an alternative to the established practical outcome.
The quote is valid but does not prove preserved meaning. Keep that disagreement.

These are single low-effort trials, not a reliability estimate. Native testing
does not cure requirement inheritance, and adding a contrary-evidence instruction
does not make a reviewer a final authority. Do not tune runtime prompts or relax
assertions merely to obtain a pass. Keep the main runtime candidate isolated;
promote only verified Lab tooling with both options remaining explicit.

Retain the initial PS5.1 contract assertion's array-enumeration failure, the
mock replay's literal I,J argument failure, and the PS5.1 provider-metadata
serialization failure separately. The first two were test invocation issues;
the third required a real plain-text extraction fix. None is a runtime Skill
quality verdict. Live dialogues predate that final extraction fix; final
record-preservation and contract checks cover it without relabeling old runs.

Next experiment: calibrate goal continuation versus explicitly authorized goal
change, and harmless implementation versus settled material alternatives, using
contrasting sources and full dialogues. Preserve the reference outcome while
testing how AI records and reviews the new requirement. Do not hard-code a
training, reservation or instrumentation scenario into the shared runtime.
