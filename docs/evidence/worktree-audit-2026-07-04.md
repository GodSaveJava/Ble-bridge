# Worktree Audit - 2026-07-04

## Purpose

This audit records the current dirty workspace before any cleanup, move, or deletion.
The workspace contains product code changes, real-device evidence, UI dump files, and
local run logs. Nothing has been moved or removed as part of this audit.

## Baseline

- Branch: `main`
- Project: ToyLink AI Flutter app
- Product direction: Claude original conversation -> Remote MCP Bridge -> ToyLink App -> SafetyGuard -> ToyDevice -> BLE
- Safety constraint: control must keep flowing through application/domain boundaries; UI must not call BLE directly.
- Current safe Remote Bridge posture: keep remote dispatch conservative; do not enable remote stimulation controls until the safety demo loop is verified.

## Commands Used

- `git status --short --branch`
- `git status --short --ignored`
- `git diff --stat`
- `git diff --check`
- `git ls-files --others --exclude-standard`
- `rg` boundary checks for BLE/infrastructure/control calls in changed UI files

## Tracked Code Changes

| File | Current classification | Notes |
| --- | --- | --- |
| `lib/core/routing/app_shell.dart` | Safety slice | Global emergency stop now calls `controlDeviceUseCaseProvider.stopAll()` and reports success/failure through snackbars. This preserves the application/domain boundary. |
| `test/core/routing/app_shell_test.dart` | Safety slice | New widget test verifies the global emergency stop zeros suck/vibe/ems on a mock active device. |
| `lib/core/routing/app_router.dart` | Shell integration / needs ownership confirmation | Routes are wrapped in `ShellRoute` with `AppShell`, making the emergency stop globally visible. This was already dirty during handoff; keep it grouped with shell behavior if accepted. |
| `lib/features/ble_device/presentation/pages/scan_page.dart` | UI polish / real-device flow slice | Scan page layout was restyled. It still routes scan/connect through `scanControllerProvider`; no direct BLE dependency found in the changed file. |
| `lib/features/control/presentation/pages/control_page.dart` | UI polish / safety-visible manual control slice | Control UI was restyled and the local page stop button appears replaced by global shell stop spacing. Channel changes still go through `controlPanelControllerProvider`; no direct BLE dependency found. |
| `lib/features/home/presentation/pages/home_page.dart` | UI polish / bridge status entry slice | Home page was restyled and imports `PremiumBouncingWrapper`. No direct BLE dependency found. |
| `lib/shared/widgets/premium_bouncing_wrapper.dart` | UI helper slice | New animation wrapper. It should be reviewed for whether it is actually used enough to justify a shared widget. |
| `bridge_server/lib/bridge_server.dart` | Remote Bridge safety slice | Default advertised connector tools are now limited to `get_status` and `stop_all`; explicit `BRIDGE_TOOL_NAMES` override remains available for a future reviewed rollout. |
| `bridge_server/docker-compose.yml` | Remote Bridge safety slice | Docker Compose default `BRIDGE_TOOL_NAMES` now matches the conservative remote allowlist. |
| `lib/infrastructure/mock/mock_remote_bridge_service.dart` | Remote Bridge safety slice | Mock connector sessions now advertise only `get_status` and `stop_all`, keeping demo UI state aligned with production safety posture. |

## Verification Status

Already verified before this audit:

- `flutter test test\core\routing\app_shell_test.dart test\application\control_device_use_case_test.dart test\application\mcp_tool_router_test.dart` passed.
- `flutter test` passed with 181 tests.

Current quality gates after this audit/hygiene pass:

- `git diff --check` passes.
- `flutter analyze` passes with no issues.
- `dart test` passes in `bridge_server/`.
- `flutter test` passes with 185 tests.
- Latest safety-slice verification also passed after Remote Bridge tool list tightening:
  - `dart test` in `bridge_server/`: 3/3 passed.
  - `flutter analyze`: no issues.
  - `flutter test`: 185/185 passed.
- During verification, one full-suite run briefly failed in `HttpRemoteBridgeService startSession schedules keepalive refreshes automatically`; the same test passed in isolation, the full test file passed, and a later full-suite run passed. Treat this as a possible keepalive timing flake to watch.

## Code Risks Found During Audit

- Global shell coverage: `AppShell` now adds the emergency stop bar to every shell route. A focused widget test verifies the bar reserves layout space below bottom-aligned shell content.
- Stop preemption under in-flight writes: SOSEXY queue behavior now has a regression test verifying that `stopAll()` fails superseded pending non-stop commands instead of leaving their futures hanging.
- `PremiumBouncingWrapper` ownership: a widget test verifies wrapping an interactive child does not double-fire a tap.
- Direct BLE boundary check passed for the currently modified UI files: changed pages use controllers/providers/use cases, not `flutter_blue_plus`, raw BLE handles, or protocol bytes.

## Untracked Evidence Worth Keeping

These files are already under `docs/evidence/` and should be preserved or explicitly archived:

| File | Approx size | Classification |
| --- | ---: | --- |
| `docs/evidence/bugreport-JAD-AL00-HUAWEIJAD-AL00-2026-05-08-01-47-10.zip` | 17.3 MB | Real-device bugreport evidence |
| `docs/evidence/bugreport-JAD-AL00-HUAWEIJAD-AL00-2026-05-08-01-58-58.zip` | 17.4 MB | Real-device bugreport evidence |
| `docs/evidence/bugreport-JAD-AL00-HUAWEIJAD-AL00-2026-06-05-16-22-58.zip` | 17.1 MB | Real-device bugreport evidence |
| `docs/evidence/device-current-screen.png` | 375 KB | Real-device screen evidence |
| `docs/evidence/device-current-screen-valid.png` | 200 KB | Real-device screen evidence |

Recommendation: keep these in `docs/evidence/`, but decide whether large bugreport ZIPs belong in git or should be archived outside the repository with a manifest pointer.

## Root-Level UI / Device Evidence

These appear to be generated during real-device UI debugging and adapter binding verification:

- `device-after-bind.png`
- `device-after-bind2.png`
- `device-after-bind3.png`
- `device-after-prefer-template.png`
- `device-screen.png`
- `device-screen-2.png`
- `adapter_bind_after_tap.xml`
- `adapter_bind_check.xml`
- `after_bind_entry.xml`
- `after_connect_real.xml`
- `after_start_scan.xml`
- `after_wait_scan.xml`
- `back_home.xml`
- `current_ui.xml`
- `home_after_back.xml`
- `home_screen.xml`
- `home_scrolled.xml`
- `import_after.xml`
- `scan_page.xml`
- `scan_real.xml`
- `scan_try.xml`
- `ui_after_update.xml`
- `ui_now.xml`
- `window_dump.xml`
- `window_dump2.xml`
- `window_dump3.xml`

Recommendation: keep only selected screenshots/XML dumps that prove the final user flow, move those selected artifacts into `docs/evidence/real-device-ui-2026-06-05/`, and leave the rest untracked or delete after approval.

## Likely Temporary Text Artifacts

These look like comparison/check scripts outputs or local environment probes:

- `copy_verify.txt`
- `project_compare.txt`
- `recopy_verify.txt`
- `swb_path.txt`
- `tools_check.txt`
- `vmrun_test.txt`

Recommendation: do not commit unless a maintainer can explain why a specific file is needed.

## Ignored Local Runtime Artifacts

`git status --ignored` shows local/derived artifacts that should remain untracked:

- `.dart_tool/`
- `build/`
- `.idea/`
- Android/iOS generated files
- `flutter-real-ble*.log`
- `flutter-run-device*.log`
- `flutter_01.log`
- `swb_multi_launch.log`

Recommendation: do not commit. If a log contains important evidence, extract the relevant summary into a Markdown evidence note instead of committing the full log.

## Suggested Staging Groups

1. Safety demo slice:
   - `lib/core/routing/app_shell.dart`
   - `test/core/routing/app_shell_test.dart`
   - Possibly `lib/core/routing/app_router.dart` if the shell route integration is accepted as part of the same behavior.

2. UI polish slice:
   - `lib/features/ble_device/presentation/pages/scan_page.dart`
   - `lib/features/control/presentation/pages/control_page.dart`
   - `lib/features/home/presentation/pages/home_page.dart`
   - `lib/shared/widgets/premium_bouncing_wrapper.dart`
   - Before staging, remove trailing whitespace, address `withOpacity` deprecations, and run focused widget/manual layout checks.

3. Evidence archive slice:
   - Selected `docs/evidence/*`
   - A small manifest describing what each artifact proves.
   - Avoid committing every root-level dump unless it is tied to a named verification step.

## Next Recommended Actions

1. Add or update evidence notes so the final real-device flow is represented by a small, named artifact set rather than loose root files.
2. Run a visual/manual route sweep on real device or emulator for chat, settings, MCP, bridge settings, device manager, verification, and onboarding screens.
3. Keep Remote Bridge control allowlist conservative until the safety demo loop has a reproducible app-side proof and a documented rollback path.
