# rc15 Runtime Acceptance Follow-Up

## Benchmark And Boundary

- Date: 2026-09-07. Local candidate checkpoint: `2ade4dc`; previous baseline: `9e666a9`.
- Users: maintainers diagnosing incomplete evaluation, and ordinary users whose mature discovery flow must not regress.
- Problem: retained actual-file dialogues time out after substantial tool activity. Existing total duration cannot distinguish tool overhead from startup/model/network gaps. These are inconclusive, not product passes or failures.
- Benchmarks inspected: existing Lab `eval_runtime.ps1` and immutable rc15 event logs; installed OpenAI skill-creator guidance; local `codex exec --help`. Reuse the existing isolated CLI process, JSONL evidence and independent reviewer. No external dependency or configuration change.
- Implementation: timestamp observed stdout events in a sidecar; report first event/message and the union of active tool intervals. Preserve raw events and timeout policy. Unattributed time is not claimed as model compute or MCP startup time.
- Acceptance: partial JSON writes survive polling; concurrent tools are not double-counted; normal completion and process-tree timeouts retain evidence; all created sidecars are harness-owned, not product writes.
- Next: serial cold-start probe and A01 on the unchanged runtime snapshot, then fix only evidenced test or runtime defects. Migrate historical V143 semantics with explicit coverage, never erase original evidence or replace actual gates with simulated passes.
- Replay finding: the compact runner discarded prior tool observations and commentary, then told each fresh CLI process to apply the Skill again. This cannot test the Skill's instruction-reuse behavior fairly. ToolAware replay carries authentic prior command results and messages, with unchanged files reused but changed state revalidated; Compact remains available for paired diagnosis. Neither mode is a persistent-session latency benchmark.
- Release remains blocked until same-snapshot behavior, baseline comparison and isolated install are accepted. No publication is authorized by this maintenance run.

## Historical Oracle Migration

`tests/runtime-evidence-migrations.json` maps V143 to A07, preserving the original test and Oracle. A07 replaces injected gate claims with actual local specification/CSV files and requires an actual READY aggregate result plus independent review. Domain details live only in the fixture, never in runtime policy. The map alone is not acceptance: promotion must check the current runtime/suite hashes, completed dialogue, semantic Pass, protected files and actual gate evidence for each required effort. Missing, stale or failed evidence must block migration rather than count the skipped legacy case as passed.

Candidate retains repeated-evidence admission: at least two separate passing actual-file trials per effort (or a larger configured InitialTrials/MinimumAgreement value). A one-shot low/high pair does not migrate a release case. Subsequent trials are not launched after a prerequisite is incomplete or fails.

## Observed Results

Evidence root: `F:/AllredInspect/02_Test_Evidence/Future_Runs/2026-09-07_allred-rc15-followup`.

- No-tool CLI probe: 10.404s total; first event 2.700s. It proves that the configured CLI could answer, not that the network or every MCP server was healthy.
- Original compact A01 replay: turn 1 completed in 133.634s (7 tools); turn 2 timed out at 240.483s (14 tools, 46.029s observed tool activity). The trace includes invented parameter names, invalid enum values and state-schema repairs. Original evidence retained in `software-low-r1`.
- ToolAware A01 replay on the same unchanged Standard surface: all three turns completed, 181.529s / 88.209s / 136.238s, with 8 / 3 / 6 tools; independent review passed. Evidence in `software-low-toolaware-r1`. This is a single stochastic comparison, not a stable speed claim; first-turn latency did not improve, and the harness snapshot capture was added after this run began.
- A07 actual complete-evidence READY: timed out at 240.595s, 16 completed tools, 23.023s observed tool activity. No completed user reply or actual READY result exists. The model read the real materials, investigated Python command availability, then inspected multiple validator implementations to construct state/record fields. Unattributed time is not proof of a network cause. Evidence in `complete-ready-low-r1`.
- The actual migration checker rejected this incomplete A07 evidence. V143 has not been accepted or silently skipped. Its original cases and Oracle remain unchanged.
- Quick validation passed; the timing/replay contracts and migration admission contracts run without model calls on Windows PowerShell 5.1 and PowerShell 7. Synthetic fixture results certify the test harness only.

The same-snapshot cross-model matrix, full candidate pipeline, blind baseline comparison, isolated installation, and publication remain unaccepted. Do not expand model batches while the complete-evidence READY prerequisite is unresolved.

## Next Smallest Runtime Investigation

Investigate a machine-readable, stage-specific state/record construction interface against the existing validators and accepted fixture shapes. It must reduce schema guessing without pre-approving choices, fabricating sources, weakening gates, adding interview rounds or changing the mature discovery flow. First measure schema/parameter repair count and complete READY behavior on the same raw materials; do not merely raise the timeout or treat a hand-filled passing state as agent acceptance. This investigation is not implemented by the Lab-only changes above.
