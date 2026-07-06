# ToyLink AI Progress

## 2026-07-06

- Added governing roadmap document: `docs/22-byo-ai-hardware-connector-roadmap.md`.
- Added persistent planning files: `task_plan.md`, `findings.md`, `progress.md`.
- Current execution phase is Phase 0: engineering baseline recovery.
- Loaded the engineering workflow file and mapped it to the current execution style: product/architecture/security/QA/SRE gates must be visible before development and release.
- Spawned four read-only subagents for Phase 0/1 review: DevOps baseline, security, mobile, QA evidence.
- Confirmed local blockers: this directory is not a Git repository; `flutter` and `dart` are not available in PATH.
- Implemented Phase 0/1 baseline changes:
  - Added app-visible hardware runtime mode (`mock BLE` / `real BLE`) and surfaced it on Home and Settings.
  - Changed default Remote Bridge behavior to disabled/offline instead of silently using public HTTP defaults.
  - Updated Remote Bridge config reset/load tests to expect disabled defaults.
  - Added Android main Manifest `INTERNET` permission and `flutter_foreground_task` foreground service declaration.
  - Added `docs/evidence/phase-0-1-evidence-manifest-template.md`.
  - Replaced root `README.md` with project-specific setup, verification, runtime mode, and Bridge guidance.
  - Added `docs/evidence/2026-07-06-phase-0-baseline-evidence.md`.
- Verification attempted and remains BLOCKED:
  - `git status --short --branch` failed because this directory is not a Git repository.
  - `where.exe flutter` / `where.exe dart` found no executables.
  - `flutter analyze` failed with command-not-found.
  - `cd bridge_server; dart test` failed with command-not-found.
- Restored Git as a local repository:
  - Ran `git init`.
  - Created initial baseline commit `15af36b Initial restored ToyLink baseline`.
  - Confirmed `git status --short --branch` now reports branch `main`.
  - No remote is configured yet; formal remote URL was not present in the handoff docs.
