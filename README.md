# Allred Project Standard Skill

Allred Project Standard is a Codex Skill for starting, continuing, debugging, extending, validating, and reviewing Codex-assisted small and medium projects.

## What It Does

- Routes project requests into new project, debugging, new feature, UI optimization, or acceptance/review modes.
- Uses a benchmark-first project standard before non-trivial design decisions.
- Requests and analyzes project materials before structured requirement questioning.
- Supports beginner mode without lowering validation standards.
- Restates functional requirements before implementation.
- Provides exit triggers for requirement questioning and `grill-me`.

## Install

Clone this repository, then run:

```powershell
.\install.ps1
```

Or copy the skill folder manually:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item -Recurse -Force ".\allred-project-standard" "$env:USERPROFILE\.codex\skills\allred-project-standard"
```

Restart or open a new Codex conversation after installation.

## Test Prompts

```text
allred新项目
我想做一个 Excel 清单整理工具。
```

```text
allred新手项目
我想做一个 Excel 清单整理工具。
```

```text
allred新项目
我想做一份新手员工培训资料目录工具。
```

## Versioning

Use Git tags such as `v0.1.0`, `v0.2.0` for stable test releases.
