# 2026-07-08 Phase 2 External Platform Preflight Kit Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-08 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Branch | `main` |
| Hardware mode | Mock BLE only in this run |
| Connector scope | Safety V0: `get_status`, `stop_all` |
| Release allowed | no |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| ADB device detection | `adb devices -l` | repo root | 0 | BLOCKED | No Android devices were listed. |
| Preflight tool help | `dart run tool\external_platform_preflight.dart --help` | repo root | 0 | PASS | Tool prints usage for card-based and direct URL/token checks. |
| Preflight tool dry-run | `dart run tool\external_platform_preflight.dart --connector-url https://bridge.toylink.local/mcp/claude --token toy_bridge_token_ready --platform "ChatGPT GPT Actions" --dry-run` | repo root | 0 | PASS | Tool validates Safety V0 tools and derives `https://bridge.toylink.local/mobile-bridge/tool-call` without network calls. |
| Platform template regression | `flutter test test\features\connector_platform_template_test.dart` | repo root | 0 | PASS | `3` tests passed; Webhook URL is exactly `https://bridge.toylink.local/mobile-bridge/tool-call`. |
| Flutter analyze | `flutter analyze` | repo root | 0 | PASS | `No issues found!` |
| Full Flutter tests | `flutter test` | repo root | 0 | PASS | `203` tests passed. |
| Bridge server tests | `dart test` | `bridge_server` | 0 | PASS | `10` tests passed. |
| Android debug APK build | `flutter build apk --debug` | repo root | 0 | PASS | Built `build\app\outputs\flutter-apk\app-debug.apk`; command still emitted Kotlin Gradle Plugin future-compatibility warnings. |
| Whitespace check | `git diff --check` | repo root | 0 | PASS | No whitespace errors reported. |

## What Was Proven

| Claim | Result | Evidence |
|---|---|---|
| External platform checks have a repeatable preflight tool | PASS | `tool/external_platform_preflight.dart` can validate connector details and produce evidence text. |
| Preflight enforces Safety V0 tool scope | PASS | Tool fails if tools do not include `get_status,stop_all` or include tools outside Safety V0. |
| Manual evidence requirements are documented | PASS | `docs/23-external-platform-manual-evidence.md` defines PASS/PENDING/BLOCKED/FAIL rules. |
| Tool-call URL is clean for copy/paste | PASS | Webhook templates and preflight output no longer include a trailing empty query marker. |

## What Was Not Proven

| Gap | Status | Next Action |
|---|---|---|
| Live external platform evidence | PENDING | Run the guide against at least one real user-owned AI environment such as ChatGPT / GPT Actions, Claude, or another tool-calling client. |
| Real BLE hardware behavior | BLOCKED | Requires Android hardware with BLE device connected. |
| Android background stability | BLOCKED | Requires Android hardware background run evidence. |

## Final Decision

| Decision | Value |
|---|---|
| External platform preflight kit | PASS |
| Phase 2 full platform evidence | PENDING until external platform evidence is collected |
| Phase 1 full Safety V0 | BLOCKED until real-device BLE and Android foreground/background evidence are complete |
| Release allowed | no |
