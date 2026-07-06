# 2026-07-06 Phase 0 Baseline Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-06 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Git repository | Local repository restored with `git init`; `origin` configured but inaccessible |
| Branch | `main` |
| Commit | `15af36b` |
| Dirty working tree | Clean immediately after initial baseline commit; documentation updates followed |
| Hardware mode | App now exposes `Mock BLE` / `Real BLE`; current build not run in this shell |
| Bridge mode | Default app behavior changed to disabled/offline unless explicitly configured |

## Toolchain Checks

| Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|
| `git status --short --branch` | repo root | 1 | BLOCKED | `fatal: not a git repository (or any of the parent directories): .git` |
| `git init` | repo root | 0 | PASS | Initialized local repository in `.git/`. |
| `git commit -m "Initial restored ToyLink baseline"` | repo root | 0 | PASS | Created baseline commit `15af36b`. |
| `git remote add origin https://github.com/GodSaveJava/Ble-bridge.git` | repo root | 0 | PASS | Added `origin`. |
| `git fetch origin --prune` | repo root | 1 | BLOCKED | `remote: Repository not found.` |
| `git ls-remote origin` | repo root | 1 | BLOCKED | `remote: Repository not found.` |
| `where.exe flutter` | repo root | 1 | BLOCKED | `INFO: Could not find files for the given pattern(s).` |
| `where.exe dart` | repo root | 1 | BLOCKED | `INFO: Could not find files for the given pattern(s).` |
| `flutter analyze` | repo root | 1 | BLOCKED | `flutter : The term 'flutter' is not recognized...` |
| `dart test` | `bridge_server` | 1 | BLOCKED | `dart : The term 'dart' is not recognized...` |

## Automated Verification

| Gate | Result | Notes |
|---|---|---|
| Flutter analyze | BLOCKED | Flutter is not available in PATH. |
| Flutter tests | BLOCKED | Flutter is not available in PATH. |
| Bridge server tests | BLOCKED | Dart is not available in PATH. |

## Phase 0 Changes Made Before Verification

| Change | Result |
|---|---|
| App-visible hardware runtime mode | Implemented in Home and Settings. |
| Default public HTTP Bridge removed from implicit fallback | Implemented through disabled Remote Bridge service and disabled config defaults. |
| Android foreground service manifest baseline | Added `INTERNET` and `ForegroundService` declaration. |
| Evidence template | Added `docs/evidence/phase-0-1-evidence-manifest-template.md`. |
| Root README engineering entrypoint | Replaced default Flutter README with ToyLink AI setup and verification guidance. |

## Final Decision

| Decision | Value |
|---|---|
| Phase 0 status | BLOCKED |
| Safety V0 status | BLOCKED |
| Release allowed | no |
| Blocking reasons | Flutter/Dart unavailable; no current automated test evidence; no real-device evidence; remote access blocked by `Repository not found`. |
