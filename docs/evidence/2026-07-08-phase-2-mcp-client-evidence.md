# 2026-07-08 Phase 2 MCP Client Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-08 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Branch | `main` |
| Hardware mode | Mock BLE only in this run |
| MCP transport | Localhost Streamable HTTP |
| Connector scope | Safety V0: `get_status`, `stop_all` |
| Release allowed | no |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| MCP client smoke | `flutter test test\features\connector_mcp_client_smoke_test.dart test\features\connector_rest_openapi_smoke_test.dart` | repo root | 0 | PASS | Client received `GET [200] /mcp/status`, `GET [200] /mcp/tools`, `POST [200] /mcp/call` for `get_status`, `POST [400] /mcp/call` for `set_suck`, and REST/OpenAPI regression `POST [200] /mobile-bridge/tool-call`. |
| Flutter analyze | `flutter analyze` | repo root | 0 | PASS | `No issues found!` |
| Full Flutter tests | `flutter test` | repo root | 0 | PASS | `201` tests passed. |
| Bridge server tests | `dart test` | `bridge_server` | 0 | PASS | `10` tests passed. |
| Android debug APK build | `flutter build apk --debug` | repo root | 0 | PASS | Built `build\app\outputs\flutter-apk\app-debug.apk`; command still emitted Kotlin Gradle Plugin future-compatibility warnings. |
| Whitespace check | `git diff --check` | repo root | 0 | PASS | No whitespace errors reported. |

## What Was Proven

| Claim | Result | Evidence |
|---|---|---|
| MCP service status can be discovered by a client | PASS | Test calls `/mcp/status` without auth and verifies the reported endpoint port matches the actual service port. |
| MCP client can discover Safety V0 tools | PASS | Test calls `/mcp/tools` with bearer auth and receives exactly `stop_all,get_status`. |
| MCP client can call `get_status` | PASS | Test posts `{"tool":"get_status","input":{}}` to `/mcp/call` and receives HTTP 200 with connected mock status. |
| Unsafe remote-control tool remains blocked | PASS | Test posts `set_suck` to `/mcp/call` and receives HTTP 400 with `tool_not_enabled_for_mcp_safety_v0`. |
| Custom MCP host/port discovery is accurate | PASS | `LocalMcpHttpService.endpointInfo` now reports the configured host and port instead of hard-coded `127.0.0.1:8765`. |

## Boundary Notes

| Topic | Status | Note |
|---|---|---|
| Local MCP privacy shape | KNOWN | Local MCP `get_status` follows `docs/03-mcp-tool-contract.md` and includes local `deviceId`. |
| Remote BYO-AI connector privacy shape | PASS in prior evidence | `/mobile-bridge/tool-call` status remains de-identified and omits `deviceId`. |
| Live external platform evidence | PENDING | Still requires at least one user-owned AI environment such as ChatGPT / GPT Actions, Claude, or another tool-calling client. |
| Real BLE hardware behavior | BLOCKED | Requires Android hardware with BLE device connected. |

## Final Decision

| Decision | Value |
|---|---|
| MCP client live evidence | PASS for local Streamable HTTP smoke |
| REST/OpenAPI smoke evidence | Still PASS via regression command |
| Phase 2 full platform evidence | PENDING until external platform evidence is collected |
| Phase 1 full Safety V0 | BLOCKED until real-device BLE and Android foreground/background evidence are complete |
| Release allowed | no |
