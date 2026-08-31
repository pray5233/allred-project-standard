# Company Office Delivery Overlay

Load this overlay only when project evidence confirms a company office runtime whose installation, packaging, permissions, maintenance, or ordinary-computer constraints affect delivery. Beginner expression by itself does not activate it.

## Activation Boundary

Relevant evidence includes ordinary managed Windows computers, no developer tools, restricted installation/admin rights, Office-centered workflows, company network constraints, or a requirement that non-technical employees open the result directly.

Do not infer a platform from `内部使用`, `员工使用`, or `App`. First use the generic axes in `运行环境与交付形态.md`; this overlay adds organization-specific defaults only after the office context is real.

## Office Defaults

Prefer the least operational burden that still satisfies the approved workflow:

- spreadsheet-oriented cleanup/reporting: Excel/CSV input and output or a packaged tool that produces those files
- simple one-person import/export: local HTML only when browser file limits are acceptable
- repeated buttons and local files: packaged desktop application when installation and update responsibility are acceptable
- shared live state: hosted or intranet application only when hosting, identity, permissions, backup, network, and owner are confirmed

Do not require Python, Node.js, Git, package managers, a terminal, or a development server as the normal employee workflow. A development proof may use them, but it must not be presented as delivered employee software.

After representative-environment evidence is available, compare only employee-facing routes that the evidence supports, state the current recommendation and tradeoff at its actual evidence level, and exclude or label routes blocked by unknown policy. Do not postpone the whole route comparison merely because detailed business rules or sample coverage are still pending; identify which later evidence could change the recommendation.

## Office Acceptance

Before formal delivery:

- test the actual packaged/opening workflow on a clean or representative office computer
- verify sample inputs and outputs through the employee-facing interaction
- record installation, antivirus/signing, permissions, data folders, update method, rollback, and owner where applicable
- provide only the minimum user-facing operating guidance needed for the approved workflow

If a clean target is unavailable, label the result as a development proof or target-like test and keep employee delivery unverified.
