# 2026-07-06 Phase 0 Baseline Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-06 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Git repository | Restored and tracking `origin/main` |
| Remote | `https://github.com/GodSaveJava/Ble-bridge.git` |
| Branch | `main` |
| Commit before this evidence update | `0cbef29` |
| Dirty working tree | Yes, this evidence/CI/toolchain update is in progress |
| OS | Windows 10 Pro 22H2 |
| Flutter version | `3.44.4` |
| Dart version | `3.12.2` |
| Hardware mode | App exposes `Mock BLE` / `Real BLE`; this run did not use real hardware |
| Bridge mode | Default app behavior is disabled/offline unless explicitly configured |

## Toolchain Checks

| Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|
| Reload Machine/User PATH then `where.exe flutter; where.exe dart` | repo root | 0 | PASS | Found `C:\Users\NPC\dev\flutter\bin\flutter(.bat)` and `dart(.bat)`. Current Codex process still needs explicit PATH/absolute path until restarted. |
| `C:\Users\NPC\dev\flutter\bin\flutter.bat --version` | repo root | 0 | PASS | Flutter `3.44.4`, channel stable; Dart `3.12.2`. |
| `C:\Users\NPC\dev\flutter\bin\dart.bat --version` | repo root | 0 | PASS | Dart SDK `3.12.2` on `windows_x64`. |
| `C:\Users\NPC\dev\flutter\bin\flutter.bat doctor -v` | repo root | 0 | WARN | Flutter usable. Remaining environment gaps: Flutter/Dart not inherited by current process PATH, Android cmdline-tools missing, Visual Studio missing for Windows desktop builds. |
| `C:\Users\NPC\dev\flutter\bin\flutter.bat pub get` | repo root | 0 | PASS | Dependencies resolved; lockfile updated for current stable SDK transitive test packages. |
| `C:\Users\NPC\dev\flutter\bin\dart.bat pub get` | `bridge_server` | 0 | PASS | Bridge server dependencies resolved. |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| Flutter analyze | `C:\Users\NPC\dev\flutter\bin\flutter.bat analyze` | repo root | 0 | PASS | `No issues found!` |
| Flutter tests | `C:\Users\NPC\dev\flutter\bin\flutter.bat test` | repo root | 0 | PASS | `185` tests passed. |
| Bridge server tests | `C:\Users\NPC\dev\flutter\bin\dart.bat test` | `bridge_server` | 0 | PASS | `5` tests passed. |

## CI Baseline

| Gate | Result | Evidence |
|---|---|---|
| Minimal GitHub Actions workflow | PASS | Added `.github/workflows/ci.yml` with Flutter `pub get/analyze/test` and bridge server `dart pub get/test`. |
| Android build CI | NOT INCLUDED | Android cmdline-tools are missing locally; Android build/real-device validation remains a later gate. |

## Phase 0 Changes Covered By This Evidence

| Change | Result |
|---|---|
| App-visible hardware runtime mode | Covered by existing Flutter tests and manual source inspection. |
| Default public HTTP Bridge removed from implicit fallback | Covered by config/provider tests and bridge source tests. |
| Android foreground service manifest baseline | Source change present; Android build not verified in this run. |
| Flutter SDK compatibility | Fixed explicit `package:flutter/cupertino.dart` import for `CupertinoPageTransitionsBuilder`. |
| Provider lint cleanup | Removed unused `remote_bridge_config.dart` import. |
| Minimal CI baseline | Added GitHub Actions workflow. |

## Remaining Blockers / Risks

| Blocker | Evidence | Owner | Next Action |
|---|---|---|---|
| Android cmdline-tools missing | `flutter doctor -v` reports missing cmdline-tools | DevOps / local environment | Install Android Studio cmdline-tools or configure `ANDROID_HOME`. |
| No real BLE evidence yet | This run did not connect hardware | Mobile / QA | Run real-device scan/connect/adapter verification in Phase 1 evidence. |
| Formal remote bridge still needs Safety V0 | Roadmap requires HTTPS/token/allowlist/AppLock/result de-identification | Security / backend / mobile | Start Phase 1 Safety V0 implementation. |
| Windows desktop builds not supported locally | `flutter doctor -v` reports Visual Studio missing | DevOps | Install Visual Studio C++ workload only if Windows desktop build becomes a target. |

## Final Decision

| Decision | Value |
|---|---|
| Phase 0 status | PASS for repository/toolchain/test/CI baseline; Android real-device environment remains WARN |
| Safety V0 status | BLOCKED / not complete |
| Release allowed | no |
| Next phase | Phase 1: Safety V0 |
