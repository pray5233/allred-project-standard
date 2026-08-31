# External Source Overlay

Load this overlay only when external or public information is an actual project input, evidence source, or product behavior. It is not a separate project route and adds no user trigger words.

Read `references/外部内容安全.md` before external requests. Load `references/开发依据与能力复用.md` or `references/运行环境与交付形态.md` only when the corresponding implementation or delivery question is unresolved.

## Boundary And Activation

External source work may be either a one-time query or continuous monitoring. Keep this distinction separate from delivery form and from whether the current action is read-only.

- one-time query: obtain a bounded current result for one request, analysis, comparison, or document
- continuous monitoring: preserve a subject/source definition and repeatedly detect, collect, compare, or notify about changes

Do not ask the user to choose this label when their requested behavior already makes it clear. If unclear and the difference changes persistence, scheduling, ownership, cost, or acceptance, expose that consequence in the normal decision packet.

## One-Time Query

For a one-time query, validate subject, evidence intent, source suitability, traceability, privacy, and the requested output. Do not add scheduling, history, deduplication across runs, alerting, background services, or long-term ownership unless explicitly requested.

The completion claim is limited to the tested query, date, source state, and output. It does not establish ongoing coverage.

## Continuous Monitoring

For continuous monitoring, separately establish trigger/schedule, source-change handling, cross-run deduplication, retained history, failure visibility/recovery, credentials/quota, maintenance owner, and acceptance period. Preserve user-stated frequency and history even when later evidence covers only technical gaps. Failure visibility tells the owner a run failed; recovery says what happens next.

After material monitoring evidence, render one compact five-cell status: schedule, retained history, source-change handling, failure visibility/recovery, and operating owner. Preserve known values and mark gaps. A manual replay never erases the operating schedule; scheduled work always needs visible failure state. Omit only dimensions genuinely unrelated to the requested monitoring behavior.


One successful fetch proves neither sustained access nor useful change detection. Verify multiple runs or a controlled replay before claiming monitoring behavior.

## Route Approval Boundary

Choosing `使用少量真实/公开来源验证` confirms only the validation route.

It does not approve:

- which industry, brand, product, technology, or event to monitor
- language, geography, or source categories
- preset topics or keywords invented by Codex
- favorites, filters, auto-refresh, export, AI summary, history, responsive UI, or other product features
- a particular API, crawler, framework, database, or delivery form
- credentials, paid services, login access, installation, deployment, or scheduled execution

Do not turn a route choice such as `1` into approval for those decisions.

## Minimum Validation Definition

Before lengthy source research or architecture selection, use `references/动态项目契约.md` to determine the smallest missing definition that makes research meaningful. Possible dimensions are:

- subject or working-set boundary: one topic, an imported list, a user-managed catalog, discovered candidates, or another explicit universe
- information intent: product records, news/events, seller/price clues, regulatory records, or another user-defined category
- evidence scope: language, region, source classes, traceability, and acceptable inference
- interaction/update meaning: browsing an organized catalog, manual refresh, import, scheduled collection, or another workflow
- proof and delivery boundary: what this round demonstrates and where it must actually work

These are not fixed questions. Extract answered dimensions from the user's initial idea, inspect what tools can establish, and expose only unresolved high-impact user decisions in one dynamic correction card.

The monitored subject and information intent have no AI default when the user's phrase is broad, such as `行业市场动态` or `某产品的市场信息`. A request to browse an organized set is not equivalent to user-entered keyword search. A request for an `App` does not approve a web delivery. Restate the resulting minimum definition before source benchmarking.

## Search Decisions Stay Separate

Keep these dimensions distinct even when they are presented in a concentrated card:

| Dimension | Examples |
| --- | --- |
| Search target/input | user keyword, imported list, approved preset brand list |
| Trigger | manual update, update when opened, background schedule |
| Schedule | daily, weekly, or another interval; applicable only when background execution is approved |
| Output | traceable result list, approved export, report |
| Evidence scope | language, region, source category |
| Delivery | developer proof, local employee tool, shared service |

Selecting an approved preset list does not approve scheduled execution. Selecting manual update does not erase the preset list. When the user asks for `自动搜索`, record automation as a total-scope goal and decide separately whether the first proof is manual or scheduled.

After source preflight reveals what is feasible, combine all then-known product decisions into one card. Do not ask separate turns for input mode, output, refresh frequency, office environment, and market region unless a later tool result genuinely creates a new blocker.

The dynamic alignment card is the consolidated direction card for a bounded proof. If the user approves it and source preflight does not change that direction, do not add both a standalone scope-approval card and a later start-development card. Use the combined final gate described below.

## First-Round Evidence Strategy

Do not force every monitoring project into a one-keyword prototype. Choose the smallest strategy that proves the user's confirmed core workflow. When the user explicitly prioritizes a rapid proof and has not defined a broader organized workflow, a candidate proof may contain:

- one user-confirmed subject or one narrow keyword family
- one to three candidate public sources appropriate to that subject
- manual search/refresh or controlled import
- title, source name, publish time when available, collection time, and original link
- a visible no-result, source-failure, and rate-limit response
- enough raw evidence for a person to verify the result

Keep these outside a rapid proof unless requested or required by the confirmed workflow:

- multiple AI-invented preset industries
- automatic interval refresh or background scheduling
- favorites and persistent history
- complex source/category/time filters
- AI-generated summaries
- Excel/Word/PDF export
- multi-user accounts, cloud deployment, reminders, or dashboards
- broad desktop/mobile polish beyond the one validation viewport

Move an item into the first round only when it supports the stated proof or the user explicitly confirms it. “尽快跑起来” means reduce scope, not silently add a complete small product.

## Source And Benchmark Selection

Separate three kinds of evidence:

| Evidence | What it proves | What it does not prove |
| --- | --- | --- |
| Product/workflow benchmark | useful interaction and information workflow | availability or legality of real data |
| Source-provider/API/RSS test | one source can return traceable data | adequate industry coverage or long-term monitoring |
| User/industry source list | business relevance and coverage target | technical feasibility until tested |

Selecting and checking these references is Codex-owned work after the subject and evidence route are confirmed. Do not ask whether Codex should find a reference. Ask only when using a candidate would require payment, credentials, login access, disputed scraping permission, or a material change in product direction.

A general news API is not automatically an adequate industry-market source. Match sources to the confirmed subject, language/region, update needs, access constraints, and evidence requirements.

For each candidate source record:

- source/provider and version or test date
- subject and geography coverage
- access method and CORS/browser behavior when relevant
- authentication/key requirement
- rate and retention limits
- commercial-use, attribution, redistribution, and scraping constraints
- fields available: title, time, source, excerpt, original link
- test result and known gaps

Use source states precisely:

| State | Required evidence |
| --- | --- |
| Candidate | a named URL/provider that appears relevant but has not been tested |
| Reachable | an actual request or browser check returned a response |
| Access blocked | the source responded but denied usable access, such as `403`, login, robots/policy restriction, or an unresolved permission wall |
| Parseable | the required fields were extracted from a dated sample |
| Suitable for proof | relevance, traceability, access terms, limits, and failure behavior were checked for the current validation scope |
| Production-ready | ongoing ownership, credentials, quota, terms, monitoring, and recovery are defined and verified |

## Semantic Relevance Gate

Transport and parsing success do not prove business usefulness. Before a search/query source becomes `Suitable for proof`, derive the required semantic dimensions from the active project contract and the exact claim being tested. Typical dimensions include:

- confirmed subject, entity names/aliases, product, or working set
- requested information category or intent
- language, region, time range, or source class when they change usefulness
- original-link traceability and whether the result is actually about the named subject
- duplication, generic noise, mistranslation, false matches, or another project-defined exclusion

A dimension is required only when a mismatch would change usefulness, scope, or acceptance. Do not force language, region, time, or another generic axis into a project where it is immaterial; do not omit a material axis merely because it is absent from this example list.

Record semantic state separately as `相关`, `混合`, `无关`, or `未知`, with actual sample titles/IDs. HTTP `200`, valid XML/JSON, expected fields, and a large result count can coexist with completely irrelevant results. Do not call that source usable.

Use a reproducible sample instead of selecting favorable items:

1. Record the exact query/input and every applicable provider option or filter, such as language/region, time range, sort order, page/cursor, request time, and returned count.
2. For an ordered response, inspect the first five distinct returned items in provider order, or every item when fewer than five are returned. Do not search deeper for better-looking examples first.
3. For an unordered batch, sort by a stable source ID or canonical URL and inspect the first five. Record the rule; do not use a manually chosen subset.
4. Record every inspected title/ID/link and its relevance reason. For multiple required coverage cells, sample each cell separately rather than pooling results.
5. Mark the sample `相关` only when every inspected item matches every required semantic dimension. Any mixture is `混合`; all mismatches are `无关`; a missing required dimension or unreadable content is `未知`.

Before reporting semantic relevance, run a compact completeness check: show the actual inspected title/ID/link, name the required dimensions selected from the active contract, and state the observed result for each. Report every required dimension separately even when another mismatch already rejects the sample; do not merge axes or imply them from a title. Missing identity or any required dimension means the review is incomplete, while an irrelevant generic dimension should be omitted rather than reported as an artificial unknown.

`混合` is not suitable for unattended display merely because some results are useful. A deterministic filter may be proposed, but it must be recorded, applied to a fresh response, and sampled again using the same rule. Keep the unfiltered and filtered observations so the filter cannot hide the original failure. One favorable result, a provider relevance score, or a marketing claim never substitutes for this sample.

If representative samples are irrelevant, wrong-language noise, or cannot be tied to the confirmed subject, reject the source for the current proof. Do not compensate by adding more features or lowering acceptance silently.

When no credible source remains for the core promised behavior, stop before development confirmation. In plain language offer only evidence-honest paths such as continued source research, a manually curated source directory, user-provided/approved sources, a labeled UI-only prototype, or plan-only work. Do not create an update button whose core retrieval path has not passed semantic relevance.

Report `已完成来源预检` only from the actual tool event or request result. A `200` proves reachability only; a `403`, login wall, empty result, or rate limit must remain visible evidence.

Before recommending implementation, show a compact source evidence table containing source, test date, current state, observed fields, access/terms/limits, and gap. If terms or access cannot be checked, label the source `待验证`; do not silently treat it as approved.

Use exact URLs/provider IDs and the actual query/input tested. Portal names, grouped labels such as `等公开来源`, and search-result snippets are not reproducible source evidence.

When the approved scope contains multiple dimensions whose combinations matter, derive a coverage matrix from the dynamic contract. Its axes may be subject x information category, source x field, region x source class, or another relevant shape. Each cell must distinguish `已验证`, `候选`, `缺口`, and `不适用`. Evidence in one cell does not prove another.

Assign exactly one current state to each cell. Put qualifications in notes, such as `候选；官方来源仍缺失`; do not use combined state labels such as `候选/缺口`.

The source evidence table and a derived coverage matrix are mandatory preconditions for the final scope/start gate when multiple material dimensions are in scope. Do not replace them with a prose summary. Use the exact tested URL/provider identifier and test date; labels alone are insufficient.

Use pass language at the same granularity as the evidence:

- `核心路线可行` means at least one approved category has a suitable-for-proof source and the missing coverage is visible.
- `部分覆盖可进入验证版` means implementation may proceed with an explicitly limited matrix and gap labels.
- `来源预检通过` without a qualifier is allowed only when every current-round required matrix cell is suitable for proof.

Do not upgrade `Reachable` or `Parseable` to `Suitable for proof` until access terms, limits, traceability, semantic relevance, and the current information intent have been checked. Name exact URLs or provider identifiers in the evidence record; a brand label alone is not a reproducible source.

Do not use a bare statement such as `公开资料调研完成` or `可以搜索全球公开网页`. Name the checked sources and states, then limit coverage claims to the observed samples. A language/region preference defines the target; it does not prove that global coverage exists.

Do not call multi-source monitoring validated when only one source works. Do not offer a source filter when the current scope has one source.

## Acceptance Metric Provenance

Do not invent a result-count threshold before source evidence exists. For a niche product, `至少 20 条` may reward irrelevant pages, duplicates, or reseller copies. Start with evidence-backed quality criteria:

- result relevance to the confirmed subject and information intent
- traceable original link and collection time
- accuracy of required fields against the source
- honest distinction among no result, blocked access, parse failure, and rate limit
- successful operation in the confirmed validation environment

These are quality dimensions, not approved product behavior. Related UI states or export fields enter this round only when requested, found in project evidence, or approved in the named scope.

Add a minimum result count only after an observed source sample or explicit user requirement supports it. Record whether the count means unique products, unique manufacturers, unique sources, or raw pages.

## Summary Provenance

Use precise labels:

- `原文摘要/接口摘要`: supplied by the source
- `规则提取`: generated from explicit deterministic rules
- `AI 摘要`: model-generated and must retain the source link and identify inference

If AI summary is outside the current round, do not list an unexplained “摘要” as if it were included.

## Credentials And Client Architecture

Any API key or token embedded in browser JavaScript is visible to the user and network tools.

- a provider-approved public/test key may be used only for a clearly labeled local feasibility test
- do not describe a client-exposed key as a production credential design
- formal delivery needs a user-owned key strategy, a backend/proxy, or a keyless public source as appropriate
- record quota, attribution, terms, and migration path before calling the result deliverable
- never commit real secrets or place them in screenshots, docs, sample data, or frontend bundles

Automatic refresh increases quota and failure risk. Do not add it to a rapid proof without a user requirement and a rate-limit plan.

## Classification

Classify only after the minimum definition and source/runtime evidence exist.

A fixed-source, manual-refresh proof may be medium. Scheduled updates, many sources, source credibility scoring, deduplication, AI conclusions, login-only sites, scraping constraints, multi-user reports, or long-term ownership may make the full project complex.

Do not classify a project as medium merely because the proposed feature list contains `联网搜索、整理、筛选和导出`. When source credibility, access method, coverage, or maintenance is still unknown, state that full-project complexity remains provisional and choose a narrow validated slice for the current round.

State classification as a provisional evidence-based assessment; do not present it as confirmed merely because the request contains “App” or “automatic search”.

## Acceptance

A first-round proof passes when:

- it searches the user-confirmed subject
- the selected source is relevant to that subject
- each result is traceable to its original source
- result fields and summary provenance are clear
- no-result, source failure, and rate limiting are distinguishable
- credentials and usage limits are documented
- the proof runs in the confirmed validation environment
- claims are limited to what the tested source coverage proves

“At least one preset topic returns something” is not sufficient. A random general-news result does not prove useful industry monitoring.

## Monitoring Scope Draft

Use the product decision/start gate from `references/交互与确认规则.md`. The monitoring draft may contain only features and choices traceable to:

- the user's current or previous explicit statement
- inspected project materials
- an explicitly approved decision card
- a clearly labeled implementation assumption that does not change product behavior

Do not use the start-development card to introduce new product requirements. Put unsupported optional ideas in `后续保留/待讨论`.

If the card authorizes dependency installation, include exact package names/versions, lock or environment changes, narrow verification, rollback, and actions still excluded. If those are unknown, continue read-only preflight instead of showing `npm install` as a generic authorization.

Before the final gate, keep a compact internal preflight record:

- selected local/official implementation basis and why it is comparable
- installed capability result and the exact gap, if any
- provisional current-round classification and why
- runtime/delivery meaning for this round

These are Codex-owned conclusions, not questions, and require corresponding inspection evidence.

After source preflight, keep exact output fields, source states, visible failures, trigger/output boundary, and coverage gaps in one named contract rather than scattered scope patches.

The user's approval applies only to the exact named draft. If the draft was not approved, source name, collection time, empty-result, blocked-source, parse-failure, retry, rate-limit, or other standard-looking behavior must not appear for the first time in the start card.

For an approved bounded direction, use one combined gate from `references/交互与确认规则.md` when implementation is not authorized. Restate behavior, data handling, source limits, effects, acceptance, and no-touch meaning plainly. Exact mechanics stay in the Codex execution record. If a product decision changed, replace the active scope while preserving unaffected decisions; do not append a partial patch.

Do not ask one turn to approve direction and another unchanged turn to start. If source evidence changes a user-owned product decision, show the changed decision and its plain-language evidence first; that is a justified extra round.

For a beginner, keep the visible card concise and free of framework files, commands, package details, caches, and internal state codes. The user-facing scope, runtime meaning, credential limitation, significant effects, and acceptance must be understandable; exact mechanics stay in the Codex execution record.
