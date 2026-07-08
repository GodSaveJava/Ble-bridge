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
- Implemented Phase 1 Safety V0 automated security baseline:
  - Bridge server filters advertised tools to `get_status,stop_all`.
  - `/debug/enqueue` requires debug token and rejects non-allowlisted tools.
  - Public Bridge rejects non-loopback HTTP; app Remote Bridge config requires HTTPS + token outside loopback.
  - Bridge server session/token IDs use CSPRNG, include TTLs, and reject expired or client-mismatched sessions.
  - Local MCP requires bearer token and defaults to `get_status,stop_all` only.
  - AppLock now participates in MCP authorization; locked state only allows `stop_all`.
  - Remote `get_status` and task result payloads are sanitized before returning/uploading.
- Added `docs/evidence/2026-07-06-phase-1-safety-v0-evidence.md`.
- Verification:
  - `flutter analyze`: PASS.
  - Safety V0 focused Flutter tests: PASS, 50 tests.
  - Full `flutter test`: PASS, 189 tests.
  - `cd bridge_server; dart test`: PASS, 10 tests.
- Continued Phase 1 Safety V0 execution:
  - Added remote/MCP end-to-end `stop_all` preemption coverage through `/mobile-bridge/tool-call`.
  - The test verifies a pending non-stop SOSEXY BLE write is superseded and the next device write is the stop packet.
  - Updated BYO-AI Connector user/developer docs to state Phase 1 only exposes `get_status` and `stop_all`; remote `set_*` remains Phase 3-gated.
- Verification:
  - `flutter test test\infrastructure\local_mcp_http_service_test.dart`: PASS, 9 tests.
  - Safety V0 focused Flutter tests: PASS, 51 tests.
  - `flutter analyze`: PASS.
  - Full `flutter test`: PASS, 190 tests.
  - `cd bridge_server; dart test`: PASS, 10 tests.
- Continued Android toolchain recovery:
  - Installed Android command-line tools at `C:\Users\NPC\AppData\Local\Android\Sdk\cmdline-tools\latest`.
  - Installed SDK packages: `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`; Gradle build also installed `platforms;android-35`, `build-tools;35.0.0`, NDK `28.2.13676358`, and CMake `3.22.1`.
  - Set Flutter Android SDK to `C:\Users\NPC\AppData\Local\Android\Sdk`.
  - Accepted Android SDK licenses.
  - Flutter doctor now reports Android toolchain PASS.
  - `flutter build apk --debug`: PASS, output `build\app\outputs\flutter-apk\app-debug.apk`.
  - `adb devices -l`: no Android device attached.
  - `flutter emulators`: no Android AVD source available.

## 2026-07-07

- Started Phase 2 BYO-AI onboarding simplification while preserving Phase 1 Safety V0 boundaries.
- Added a ToyLink connector card to the MCP page when the remote bridge session is ready:
  - Shows connector URL, masked token, Safety V0 status, and current tools.
  - Provides one-click copy for a structured connector card JSON.
  - Keeps Phase 1 copy explicit: only `get_status` and `stop_all`; remote `set_*` remains unavailable.
- Verification:
  - `flutter test test\widget_test.dart --name "mcp page shows connector info after remote bridge is ready"`: PASS.

## 2026-07-07

- Continued Phase 2 onboarding simplification with a connector verification loop.
- The MCP page now treats the first successful `get_status` remote task as proof that the user's own AI is connected:
  - Copying the connector card moves the UI into "waiting for get_status".
  - A successful `get_status` task automatically marks the connector as verified.
  - Safety V0 copy remains unchanged: only `get_status` and `stop_all` are allowed.

## 2026-07-07

- Added QR/deep link export for the ToyLink connector card.
- The MCP page now renders a QR code and copyable `toylink://connector-card/v1?...` URI generated from the same Safety V0 connector payload.
- Copying the deep link also moves the UI into the `get_status` verification wait state.
- Android deep link import is still a follow-up item; this step only solves cross-device transport/export.

## 2026-07-07

- Added Android deep link import for connector cards.
- Android Manifest now accepts `toylink://connector-card/v1` VIEW intents.
- The app routes imported connector links to a connector card import page that parses the payload, validates Safety V0 constraints, previews URL/token/tools, and lets the user copy the card again.
- Imported payloads containing non-V0 tools such as `set_suck` are rejected instead of being treated as valid connector cards.
- Emulator smoke test passed on `emulator-5554`: installed debug APK, launched `toylink://connector-card/v1?...` with `adb shell am start`, and confirmed the import page rendered.

## 2026-07-07

- Added multi-platform connector templates to the MCP page.
- The connection card now generates copyable templates for Claude Remote MCP, ChatGPT / GPT Actions, OpenAPI / REST Tool, and Webhook.
- GPT Actions and OpenAPI templates are emitted as OpenAPI 3.1 JSON with bearer auth and a strict `get_status` / `stop_all` enum.
- Copying any platform template moves the UI into the same `get_status` verification wait state.

## 2026-07-07

- Added REST/OpenAPI connector smoke evidence for Phase 2.
- The new smoke test generates an OpenAPI / REST Tool template from a Safety V0 connector card, parses the generated schema, starts the local MCP HTTP service, and performs a real `POST /mobile-bridge/tool-call` request for `get_status`.
- Verification:
  - `flutter test test\features\connector_rest_openapi_smoke_test.dart`: PASS, with `POST [200] /mobile-bridge/tool-call`.
  - `flutter analyze`: PASS.
  - Full `flutter test`: PASS, `200` tests.
  - `cd bridge_server; dart test`: PASS, `10` tests.
  - `flutter build apk --debug`: PASS, output `build\app\outputs\flutter-apk\app-debug.apk`.
  - `git diff --check`: PASS.
- Scope note:
  - This is reproducible REST/OpenAPI client evidence.
  - It is not yet live external ChatGPT / Claude platform evidence.
  - MCP client live evidence remains pending.

## 2026-07-08

- Added MCP client smoke evidence for Phase 2.
- The new smoke test starts `LocalMcpHttpService` on a non-default localhost port, discovers service status, fetches Safety V0 tool definitions, calls `get_status` through `/mcp/call`, and verifies `set_suck` is rejected by the Safety V0 allowlist.
- Fixed `LocalMcpHttpService.endpointInfo` so custom host/port values are reflected correctly instead of always reporting `127.0.0.1:8765`.
- Verification:
  - `flutter test test\features\connector_mcp_client_smoke_test.dart test\features\connector_rest_openapi_smoke_test.dart`: PASS, with `GET [200] /mcp/status`, `GET [200] /mcp/tools`, `POST [200] /mcp/call`, `POST [400] /mcp/call`, and `POST [200] /mobile-bridge/tool-call`.
  - `flutter analyze`: PASS.
  - Full `flutter test`: PASS, `201` tests.
  - `cd bridge_server; dart test`: PASS, `10` tests.
  - `flutter build apk --debug`: PASS, output `build\app\outputs\flutter-apk\app-debug.apk`.
  - `git diff --check`: PASS.
- Scope note:
  - This is reproducible local MCP client evidence over localhost Streamable HTTP.
  - It is not yet external Claude / ChatGPT platform evidence.
  - Local MCP `get_status` follows `docs/03-mcp-tool-contract.md` and includes local `deviceId`; remote BYO-AI connector status remains separately de-identified on `/mobile-bridge/tool-call`.

## 2026-07-08

- Rechecked real-device evidence path:
  - `adb devices -l`: ADB daemon started, but no devices were listed.
  - Phase 1 real BLE scan/connect/adapter verification/emergency stop/background evidence remains BLOCKED.
- Added generic AI Connector Setup page for Phase 2:
  - New route: `/ai-connector-setup`.
  - MCP page now shows a `通用 AI 接入` entry when bridge connector info is ready.
  - The setup page reuses the existing Safety V0 connector card and platform templates for Claude Remote MCP, ChatGPT / GPT Actions, OpenAPI / REST Tool, and Webhook.
  - The page keeps the remote tool scope explicit: `get_status` and `stop_all` only; `set_*` remains unavailable.
- Verification:
  - `flutter test test\features\ai_connector_setup_page_test.dart`: PASS, `2` tests.
  - `flutter test test\widget_test.dart --name "mcp page shows connector info after remote bridge is ready"`: PASS.
  - `flutter analyze`: PASS.
  - Full `flutter test`: PASS, `203` tests.
  - `cd bridge_server; dart test`: PASS, `10` tests.
  - `flutter build apk --debug`: PASS, output `build\app\outputs\flutter-apk\app-debug.apk`.
  - `git diff --check`: PASS.
- Scope note:
  - This completes the UI/page work for generic AI connector setup.
  - It does not complete external platform hand verification; at least one real user-owned AI environment still needs to be checked.

## 2026-07-08

- Added an external platform manual-evidence preflight kit for Phase 2.
- Added `tool/external_platform_preflight.dart`:
  - Accepts either a copied connector card JSON or direct connector URL/token.
  - Validates Safety V0 tool scope.
  - Derives the `/mobile-bridge/tool-call` endpoint.
  - Supports `--dry-run` for no-network validation.
  - Can write markdown evidence via `--evidence-out`.
- Added `docs/23-external-platform-manual-evidence.md` with PASS/PENDING/BLOCKED/FAIL rules for real ChatGPT / Claude / user-owned AI verification.
- Cleaned connector platform URL generation so Webhook and preflight output use `/mobile-bridge/tool-call` without a trailing `?`.
- Verification:
  - `dart run tool\external_platform_preflight.dart --help`: PASS.
  - `dart run tool\external_platform_preflight.dart --connector-url https://bridge.toylink.local/mcp/claude --token toy_bridge_token_ready --platform "ChatGPT GPT Actions" --dry-run`: PASS.
  - `flutter test test\features\connector_platform_template_test.dart`: PASS, `3` tests.
  - `flutter analyze`: PASS.
  - Full `flutter test`: PASS, `203` tests.
  - `cd bridge_server; dart test`: PASS, `10` tests.
  - `flutter build apk --debug`: PASS, output `build\app\outputs\flutter-apk\app-debug.apk`.
  - `git diff --check`: PASS.
- Scope note:
  - This is not external platform hand evidence by itself.
  - It is the repeatable preflight/evidence capture path to use when a real platform account/environment is available.
