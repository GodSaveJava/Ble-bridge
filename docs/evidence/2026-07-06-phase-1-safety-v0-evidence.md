# 2026-07-06 Phase 1 Safety V0 Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-06 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Branch | `main` |
| Base commit | `8650a0b` |
| Hardware mode | Mock BLE only in this run |
| Bridge mode | Local loopback + bridge server tests |
| Android SDK | `C:\Users\NPC\AppData\Local\Android\Sdk` |
| Release allowed | no |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| Flutter analyze | `flutter analyze` | repo root | 0 | PASS | `No issues found!` |
| Safety V0 focused Flutter tests | `flutter test test\application\mcp_tool_router_test.dart test\application\remote_bridge_tool_dispatcher_test.dart test\application\remote_bridge_tool_call_handler_test.dart test\application\execute_remote_bridge_task_use_case_test.dart test\application\remote_bridge_config_controller_test.dart test\infrastructure\local_mcp_http_service_test.dart test\infrastructure\remote_bridge_protocol_test.dart test\infrastructure\http_remote_bridge_service_test.dart test\infrastructure\shared_prefs_remote_bridge_config_repository_test.dart` | repo root | 0 | PASS | `51` tests passed. |
| Local MCP / remote stop preemption test | `flutter test test\infrastructure\local_mcp_http_service_test.dart` | repo root | 0 | PASS | `9` tests passed, including `/mobile-bridge/tool-call` `stop_all` preemption. |
| Full Flutter tests | `flutter test` | repo root | 0 | PASS | `190` tests passed. |
| Bridge server tests | `dart test` | `bridge_server` | 0 | PASS | `10` tests passed. |
| Flutter doctor Android toolchain | `flutter doctor -v` | repo root | 0 | PASS for Android | Android toolchain reports SDK `36.0.0`, platform `android-36`, build-tools `36.0.0`, and all Android licenses accepted. |
| Android debug APK build | `flutter build apk --debug` | repo root | 0 | PASS | Built `build\app\outputs\flutter-apk\app-debug.apk`, size `160964000` bytes. |
| ADB device detection | `adb devices -l` | repo root | 0 | BLOCKED | No Android devices listed. |
| Android emulator availability | `flutter emulators` | repo root | 1 | BLOCKED | `Unable to find any emulator sources`; no Android AVD available. |

## Security Gate Evidence

| Gate | Result | Evidence |
|---|---|---|
| Bridge session advertises only `get_status,stop_all` even when unsafe tools are configured | PASS | `bridge_server/test/bridge_server_test.dart` verifies unsafe configured tools are filtered. |
| `/debug/enqueue` returns 404 when disabled | PASS | Existing bridge server test. |
| `/debug/enqueue` returns 401 without debug token | PASS | Existing bridge server test. |
| `/debug/enqueue` rejects non-allowlist tool | PASS | New bridge server test rejects `set_suck` and verifies no unsafe next task. |
| Public Bridge requires HTTPS outside loopback | PASS | Bridge server rejects non-loopback HTTP even with shared token. |
| Public/saved Remote Bridge config requires HTTPS + token outside loopback | PASS | Config controller and shared prefs repository tests reject/disable non-loopback HTTP. |
| Bridge session/token uses opaque CSPRNG IDs and TTL | PASS | Server implementation uses `Random.secure`; tests verify session expiry blocks task fetch. |
| Client/session binding | PASS | Bridge server test rejects refresh with mismatched `clientId`. |
| Local MCP requires auth token | PASS | Local MCP tests show `/mcp/tools` returns 401 without token and succeeds with bearer token. |
| Local MCP exposes only Safety V0 tools | PASS | Local MCP tests show only `stop_all,get_status`. |
| AppLock locked allows only `stop_all` | PASS | MCP router test rejects `get_status`/`set_suck` while locked and allows `stop_all`. |
| Remote/MCP `stop_all` preempts pending non-stop device writes | PASS | `test/infrastructure/local_mcp_http_service_test.dart` sends `stop_all` via `/mobile-bridge/tool-call`, verifies pending non-stop SOSEXY write is superseded, and verifies the next BLE packet is the stop packet. |
| Remote `get_status` result is de-identified | PASS | Dispatcher/tool-call/loopback tests verify `deviceId` is absent and status remains available. |
| Remote task result upload is de-identified | PASS | Protocol and HTTP bridge service tests verify `deviceId` is removed before upload. |
| User-facing BYO-AI Connector docs are Safety V0 scoped | PASS | `README.md`, `docs/03-mcp-tool-contract.md`, `docs/08-page-and-interaction-flow.md`, `docs/19-claude-remote-mcp-architecture.md`, `docs/20-claude-connector-onboarding-flow.md`, and `docs/22-byo-ai-hardware-connector-roadmap.md` state Phase 1 remote connector only exposes `get_status,stop_all`. |
| Android cmdline-tools and SDK baseline | PASS | `flutter doctor -v` now recognizes Android SDK at `C:\Users\NPC\AppData\Local\Android\Sdk`; licenses accepted. |
| Android debug build | PASS | `flutter build apk --debug` completed successfully. |

## Remaining Blockers

| Blocker | Result | Next Action |
|---|---|---|
| Real BLE scan/connect/adapter verification evidence | BLOCKED | Requires an Android device with USB debugging and BLE hardware connected. |
| Android foreground service real-device stability | BLOCKED | Run 10/30/60 minute background evidence on Android hardware. |

## Final Decision

| Decision | Value |
|---|---|
| Phase 1 software security baseline | PASS for implemented gates |
| Phase 1 full Safety V0 | BLOCKED until real-device BLE and Android foreground/background evidence are complete |
| Release allowed | no |
