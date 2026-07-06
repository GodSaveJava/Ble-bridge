# Phase 0 / Phase 1 Evidence Manifest Template

> Copy this file into `docs/evidence/YYYY-MM-DD-phase-0-1-evidence.md` for each verification run.
> Use `PASS`, `FAIL`, or `BLOCKED`. Do not mark a gate as passed from old evidence.

## Run Metadata

| Field | Value |
|---|---|
| Date |  |
| Operator |  |
| Workspace |  |
| Git repository |  |
| Branch |  |
| Commit |  |
| Dirty working tree |  |
| OS |  |
| Flutter version |  |
| Dart version |  |
| Android device model |  |
| Android version |  |
| App build |  |
| Hardware mode | `mock BLE` / `real BLE` |
| Bridge mode | `disabled` / `loopback` / `internal HTTP` / `HTTPS` |

## Toolchain Checks

| Command | Working Directory | Start | End | Exit Code | Result | Evidence |
|---|---|---|---|---|---|---|
| `where.exe flutter` | repo root |  |  |  |  |  |
| `where.exe dart` | repo root |  |  |  |  |  |
| `flutter doctor -v` | repo root |  |  |  |  |  |

## Automated Verification

| Gate | Command | Working Directory | Exit Code | Result | Evidence |
|---|---|---|---|---|---|
| Flutter analyze | `flutter analyze` | repo root |  |  |  |
| Flutter tests | `flutter test` | repo root |  |  |  |
| Bridge server tests | `dart test` | `bridge_server` |  |  |  |

## Safety V0 Functional Evidence

| Gate | Result | Evidence Path | Notes |
|---|---|---|---|
| App visibly shows mock/real BLE mode |  |  |  |
| Real BLE scan |  |  |  |
| Real BLE connect |  |  |  |
| Adapter binding |  |  |  |
| Low-intensity adapter verification |  |  |  |
| Global `stop_all` visible |  |  |  |
| `stop_all` preempts normal commands |  |  |  |
| Bridge session advertises only `get_status,stop_all` |  |  |  |
| Bridge `get_status` call |  |  |  |
| Bridge `stop_all` call |  |  |  |
| Background keepalive 10 minutes |  |  |  |
| Background keepalive 30 minutes |  |  |  |
| Background keepalive 60 minutes |  |  |  |

## Security Gate Evidence

| Gate | Result | Evidence Path | Notes |
|---|---|---|---|
| No default public HTTP Bridge |  |  |  |
| Non-loopback HTTP rejected for formal config |  |  |  |
| Shared token required for public Bridge |  |  |  |
| `/debug/enqueue` returns 404 when disabled |  |  |  |
| `/debug/enqueue` returns 401 without debug token |  |  |  |
| Remote `set_*` rejected |  |  |  |
| AppLock rejects control tools when locked |  |  |  |
| `get_status` remote result is de-identified |  |  |  |

## Blockers

| Blocker | Evidence | Owner | Next Action |
|---|---|---|---|
|  |  |  |  |

## Final Decision

| Decision | Value |
|---|---|
| Phase 0 status | `PASS` / `FAIL` / `BLOCKED` |
| Safety V0 status | `PASS` / `FAIL` / `BLOCKED` |
| Release allowed | `yes` / `no` |
| Reviewer |  |
| Review time |  |
