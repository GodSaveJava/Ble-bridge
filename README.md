# ToyLink AI

ToyLink AI is a BYO-AI Hardware Connector. Users keep using their existing AI chat web/app, while ToyLink connects supported tool-call environments to local BLE hardware through the ToyLink app safety chain.

The governing roadmap is [docs/22-byo-ai-hardware-connector-roadmap.md](docs/22-byo-ai-hardware-connector-roadmap.md). If older docs conflict with it, follow `docs/22`.

## Current Phase

Phase 0: engineering baseline recovery.

Do not claim Phase 0 or Safety V0 is complete until the evidence manifest for the same day contains fresh command output and real-device evidence.

## Required Local Tooling

- Git
- Flutter SDK
- Dart SDK
- Android toolchain for real-device verification

Current known blocker in this workspace: this directory is not a Git repository, and `flutter` / `dart` were not available in the current PowerShell PATH during the 2026-07-06 review.

## Verification Commands

Run these from a clean, tracked checkout:

```powershell
git status --short --branch
flutter doctor -v
flutter analyze
flutter test
cd bridge_server
dart test
```

Record results in a dated copy of [docs/evidence/phase-0-1-evidence-manifest-template.md](docs/evidence/phase-0-1-evidence-manifest-template.md).

## Runtime Modes

Mock BLE is the default:

```powershell
flutter run
```

Real BLE must be explicit:

```powershell
flutter run --dart-define=TOYLINK_USE_REAL_BLE=true
```

The app must visibly show whether it is running in `Mock BLE` or `Real BLE` mode. Mock BLE evidence is not a substitute for real-device Safety V0 evidence.

## Remote Bridge

The app must not silently default to the public HTTP Bridge. Remote Bridge should be disabled unless explicitly configured through saved settings or dart-define values.

For internal testing only:

```powershell
flutter run `
  --dart-define=TOYLINK_USE_REAL_REMOTE_BRIDGE=true `
  --dart-define=TOYLINK_REMOTE_BRIDGE_BASE_URL=https://bridge.example.com `
  --dart-define=TOYLINK_REMOTE_BRIDGE_CLIENT_TOKEN=<token>
```

Formal release requires HTTPS and token authentication. Safety V0 only exposes `get_status` and `stop_all`; remote `set_*` tools are blocked until Phase 3 gates are complete.

## Bridge Server

The Dart bridge server lives in `bridge_server/`.

```powershell
cd bridge_server
dart pub get
dart test
dart run bin/bridge_server.dart
```

Do not publish real tokens, raw BLE IDs, raw control logs, or private real-device evidence into public source control.
