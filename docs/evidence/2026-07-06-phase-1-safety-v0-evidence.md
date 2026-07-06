# 2026-07-06 Phase 1 Safety V0 Evidence

## Run Metadata

| Field | Value |
|---|---|
| Date | 2026-07-06 |
| Workspace | `C:\Users\NPC\Desktop\Ble-bridge-main` |
| Branch | `main` |
| Base commit | `5d32cd7` |
| Hardware mode | Mock BLE only in this run |
| Bridge mode | Local loopback + bridge server tests |
| Release allowed | no |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| Flutter analyze | `flutter analyze` | repo root | 0 | PASS | `No issues found!` |
| Safety V0 focused Flutter tests | `flutter test test\application\mcp_tool_router_test.dart test\application\remote_bridge_tool_dispatcher_test.dart test\application\remote_bridge_tool_call_handler_test.dart test\application\execute_remote_bridge_task_use_case_test.dart test\application\remote_bridge_config_controller_test.dart test\infrastructure\local_mcp_http_service_test.dart test\infrastructure\remote_bridge_protocol_test.dart test\infrastructure\http_remote_bridge_service_test.dart test\infrastructure\shared_prefs_remote_bridge_config_repository_test.dart` | repo root | 0 | PASS | `50` tests passed. |
| Full Flutter tests | `flutter test` | repo root | 0 | PASS | `189` tests passed. |
| Bridge server tests | `dart test` | `bridge_server` | 0 | PASS | `10` tests passed. |

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
| Remote `get_status` result is de-identified | PASS | Dispatcher/tool-call/loopback tests verify `deviceId` is absent and status remains available. |
| Remote task result upload is de-identified | PASS | Protocol and HTTP bridge service tests verify `deviceId` is removed before upload. |

## Remaining Blockers

| Blocker | Result | Next Action |
|---|---|---|
| Real BLE scan/connect/adapter verification evidence | BLOCKED | Requires Android cmdline-tools and hardware run. |
| `stop_all` remote/MCP preemption beyond existing pending-command unit test | BLOCKED | Add end-to-end preemption tests and, if needed, device command epoch guard. |
| Android foreground service real-device stability | BLOCKED | Run 10/30/60 minute background evidence on Android hardware. |
| User-facing connector docs updated for Safety V0 only | BLOCKED | Update onboarding/README docs to state Phase 1 only exposes `get_status,stop_all`. |

## Final Decision

| Decision | Value |
|---|---|
| Phase 1 automated security baseline | PASS for implemented gates |
| Phase 1 full Safety V0 | BLOCKED until real-device and `stop_all` preemption evidence are complete |
| Release allowed | no |
