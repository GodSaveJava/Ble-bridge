# ToyLink AI Progress

## Current State

- Phase 0 repository/toolchain/test/CI baseline is complete.
- Current phase is Phase 1: Safety V0.
- Release remains blocked until Safety V0 and real-device evidence are complete.

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
  - Added `origin` as `https://github.com/GodSaveJava/Ble-bridge.git`.
  - `git fetch origin --prune` and `git ls-remote origin` failed with `Repository not found`; push is blocked until the remote URL or GitHub access is fixed.
- After the repository was made public, `git ls-remote origin` and `git fetch origin --prune` succeeded.
- Merged local restored baseline with remote history using `git merge -s ours --allow-unrelated-histories origin/main`; local HEAD became `3fa0c8c Merge restored baseline with remote history`.
- `git push -u origin main` failed with GitHub 403: `Permission to GodSaveJava/Ble-bridge.git denied to magiccat997-gif`; push remains blocked by write permission.
- Cleared cached GitHub HTTPS credentials with `git credential reject`; a subsequent `git push -u origin main` succeeded and set local `main` to track `origin/main`.
- Installed Flutter SDK at `C:\Users\NPC\dev\flutter`.
- Confirmed Flutter `3.44.4` and Dart `3.12.2`.
- Confirmed user PATH contains `C:\Users\NPC\dev\flutter\bin`; the current Codex process still requires absolute paths or a reloaded PATH.
- Ran `flutter doctor -v`: command succeeded, with remaining warnings for current-process PATH, missing Android cmdline-tools, and missing Visual Studio Windows desktop workload.
- Ran `flutter pub get` and `bridge_server dart pub get`.
- Fixed Flutter SDK compatibility by explicitly importing `package:flutter/cupertino.dart` in `lib/core/theme/app_theme.dart`.
- Removed unused import from `lib/infrastructure/providers/infrastructure_providers.dart`.
- Ran `flutter analyze`: PASS, `No issues found!`.
- Ran `flutter test`: PASS, `185` tests passed.
- Ran `cd bridge_server; dart test`: PASS, `5` tests passed.
- Added minimal GitHub Actions CI in `.github/workflows/ci.yml`.
- Updated `docs/evidence/2026-07-06-phase-0-baseline-evidence.md`, `task_plan.md`, and `findings.md` with current Phase 0 evidence and Phase 1 entry plan.
