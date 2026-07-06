# CODEX.md

This file defines the working rules for AI coding agents collaborating on **ToyLink AI**.

ToyLink AI is a **Flutter-first, Android-priority** application for connecting to and controlling BLE intimate hardware, exposing verified control capabilities to external AI clients through a safe MCP-compatible bridge.

This project is **hardware-sensitive** and **privacy-sensitive**. Safety, maintainability, and architectural discipline are higher priority than speed.

## Current Governing Roadmap

All future work must follow `docs/22-byo-ai-hardware-connector-roadmap.md`.

The current product definition is **BYO-AI Hardware Connector**: users keep chatting in their own AI web/app, while ToyLink safely connects that AI tool surface to local hardware.

The current execution target is **Safety V0**:

- Remote Bridge may expose only `get_status` and `stop_all`.
- Remote `set_suck`, `set_vibe`, `set_ems`, and `set_all` must remain disabled until the Phase 3 gates in `docs/22-byo-ai-hardware-connector-roadmap.md` are complete.
- Public Bridge deployments must use HTTPS and token authentication before they can be treated as release candidates.
- The existing HTTP public Bridge may only be treated as an internal test environment.

## Mission

Build and maintain ToyLink AI as a production-grade Flutter app that:

- connects to BLE toys with a simple user flow
- lets users pair devices locally and verify them safely inside the app
- abstracts device-specific protocols behind a stable domain model
- exposes safe MCP tools for AI-driven control
- exposes verified devices to external AI clients through a Claude-compatible remote bridge path
- supports future GPT / ChatGPT and self-hosted agent integrations through the same safety-first connector model
- preserves privacy by keeping sensitive control local-first
- remains easy to extend for future hardware brands and Buttplug-compatible integrations

## Core Principles

- Use **Clean Architecture** with strict dependency direction.
- Use **Feature-First** project structure.
- Keep **device protocol logic isolated** from UI and application orchestration.
- Prefer **small, explicit, testable units** over clever abstractions.
- Optimize for **safe extensibility**, not short-term convenience.
- Do not hardcode brand-specific behavior outside device implementation boundaries.
- Treat EMS and other sensitive stimulation features as **safety-critical**.

## Non-Negotiable Rules

### 1. Architecture

Always follow:

- `Presentation -> Application -> Domain <- Infrastructure`

Never allow:

- UI to call BLE APIs directly
- UI to construct raw BLE payloads
- MCP handlers to bypass application use cases
- feature widgets to depend on infrastructure classes directly

### 2. Structure

Use this project shape unless explicitly revised:

Project structure:

- `lib/core/`
- `lib/features/ble_device/`
- `lib/features/control/`
- `lib/features/mcp_server/`
- `lib/features/chat/`
- `lib/features/device_manager/`
- `lib/features/settings/`
- `lib/domain/`
- `lib/application/`
- `lib/infrastructure/`
- `lib/shared/`
- `lib/main.dart`

### 3. State Management

- Prefer **Riverpod**.
- Use `Notifier`, `AsyncNotifier`, and providers deliberately.
- Keep ephemeral widget state local.
- Keep business state in application-facing controllers/providers.
- Do not introduce another global state framework unless explicitly approved.

### 4. BLE Boundary

- BLE implementation belongs in `infrastructure/ble/`.
- Use `flutter_blue_plus`.
- Device connection, characteristic discovery, and writes must be wrapped behind repositories/services.
- UI must never know UUIDs, characteristic handles, or protocol byte layouts.

### 5. Hardware Abstraction

All device control must go through `ToyDevice`.

Target shape:

```dart
abstract class ToyDevice {
  String get id;
  String get name;
  String get bleNamePrefix;

  Future<bool> connect(BluetoothDevice device);
  Future<void> disconnect();

  Future<void> setSuck(int intensity, {int mode = 1});
  Future<void> setVibe(int intensity, {int mode = 1});
  Future<void> setEms(int intensity, {int mode = 1});
  Future<void> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
  });
  Future<void> stopAll();
  Future<DeviceStatus> getStatus();
  Future<void> sendRawCommand(List<int> bytes);
}
```

Rules:

- New hardware support must come from new implementations, adapters, or protocol configs.
- Do not scatter `if (brand == ...)` across the app.
- Prefer capability-based design over brand-based branching.
- Keep protocol metadata configurable where practical.

### 6. Adapter System

ToyLink AI expands hardware support through a controlled adapter system.

Rules:

- First-stage adapters must be `manifest + built-in codecKey`, not executable plugins.
- Shared adapter files may be imported and exported, but local verification status must never be embedded in the shared file.
- Adapter verification state must be stored locally and tied to the current device or GATT fingerprint.
- Unverified adapters must not enter MCP control flow.
- Adapter declarations may narrow safety limits, but may never widen system safety limits.

## Safety Rules

### EMS Safety

EMS is safety-sensitive.

Mandatory defaults:

- default soft limit: `8`
- hard limit: `20`
- values above `8` require explicit user confirmation
- values above `20` must be rejected
- UI must display a clear warning for EMS usage
- MCP tool calls must pass through the same safety checks as manual UI actions

Never bypass EMS safety limits in debug or production paths without explicit user request and code review.

### Sensitive Operations

Treat these as sensitive:

- EMS intensity changes
- simultaneous multi-channel stimulation changes
- background/remote-triggered control
- auto-reconnect + auto-resume control flows

Sensitive operations should:

- require local validation
- be logged in a privacy-safe way
- fail safely
- preserve `stopAll()` as the fastest available recovery path

### Privacy

- Do not upload hardware telemetry by default.
- Do not send BLE identifiers, raw command payloads, or intimate usage logs to remote services unless explicitly designed and approved.
- Prefer local-first behavior for control and status.
- Redact logs.
- Avoid persistent storage of sensitive command history unless required and explicitly designed.

## MCP Rules

### MCP Design

The MCP server exists to expose a **safe local tool interface** for active-device control.

Supported tool family:

- `set_suck`
- `set_vibe`
- `set_ems`
- `set_all`
- `stop_all`
- `get_status`

Rules:

- MCP transport should be local-first, typically `localhost` Streamable HTTP.
- MCP handlers must resolve the **current active device** via application/domain abstractions.
- MCP handlers must not directly touch BLE infrastructure.
- MCP and UI controls must share the same validation and safety logic.

Preferred flow:

```text
Remote MCP Tool Call
-> McpToolRouter
-> SafetyGuard
-> Application Use Case
-> ActiveDeviceRegistry
-> ToyDevice
-> Infrastructure BLE write
```

### MCP Extensibility

Design MCP for future compatibility with:

- Claude Desktop style local integrations
- domestic relay/provider bridges
- future Buttplug-compatible backends

Do not couple MCP contracts to a single model vendor.

## Foreground Service and Background Behavior

For Android stability:

- prefer foreground service support for connection persistence
- keep background behavior explicit and reviewable
- do not hide long-running BLE behavior from the user
- always provide a visible way to stop service/control activity

Foreground service is for connection stability, not for bypassing safety prompts.

## Device Protocol Design

### SOSEXY

SOSEXY should be implemented as the first concrete device.

Recommended split:

- `sosexy_device.dart`
- `sosexy_protocol_codec.dart`
- `sosexy_gatt_profile.dart`

Rules:

- keep UUID definitions centralized
- keep channel mapping centralized
- document every byte-format assumption
- write tests for protocol encoding
- prefer protocol spec objects/config over “magic byte arrays” in random methods

If protocol knowledge comes from markdown notes or reverse engineering:

- preserve the source assumptions in comments
- isolate assumptions in codec/spec files
- avoid leaking uncertain protocol logic into higher layers

### Future Devices

Future devices may include:

- Lovense-like devices
- Generic Buttplug-compatible devices
- JSON-configured protocol templates

The architecture must assume multiple future devices from day one.

## Domain Modeling Rules

Favor explicit domain types.

Expected core types include:

- `ToyDevice`
- `ToyDeviceInfo`
- `DeviceStatus`
- `ControlCommand`
- `SafetyPolicy`
- `Failure`

Rules:

- use enums/value objects where they improve clarity
- avoid weakly typed `Map<String, dynamic>` in domain logic
- keep `Failure` as the unified error abstraction
- map infrastructure exceptions into domain/application failures

## Error Handling Rules

- Use a consistent `Failure` hierarchy.
- Prefer predictable failures over thrown UI-facing exceptions.
- Translate platform/plugin errors into app-specific failures.
- Include recovery-oriented error messages where useful.
- Never swallow BLE write/connect failures silently.
- `stopAll()` failure paths should still preserve clear user feedback.

## Workflow: Plan Before Code

This project must follow **plan-first execution**.

Before implementing significant work:

1. understand the request
2. inspect the current codebase and constraints
3. identify ambiguities and risks
4. propose a concrete implementation plan
5. only then write code

A good plan should define:

- target behavior
- affected layers
- interfaces to add/change
- safety implications
- testing strategy
- assumptions and defaults

Do not jump straight into code for major features.

## AI Hallucination Guardrails

AI assistance is useful in this repository, but it is not a source of truth.

Rules:

- Do not assume a plugin API, BLE UUID, protocol byte layout, route shape, or provider contract without checking the repo or the source material first.
- Mark inferred behavior clearly when it is not verified.
- Prefer "I need to verify this" over inventing missing details.
- Never claim hardware behavior has been validated if it has not been tested or confirmed from protocol notes.
- Do not fabricate test coverage, execution results, device support, or implementation status.
- When a design or coding answer depends on uncertain details, stop and verify against:
  - repo documents
  - official package docs
  - verified protocol notes
  - current code
- If uncertainty remains, record it explicitly as an assumption or open question.

Default rule:

- Verified facts beat confident guesses.

## Context-First Development

Before designing or implementing uncertain behavior, gather trusted context first.

Rules:

- Prefer curated, versioned, inspectable documentation over memory or generic search results.
- For plugin APIs, protocols, transport behavior, and framework usage, fetch the smallest reliable source set first, then implement.
- When a task depends on external documentation, record exactly which source was used.
- If the source is incomplete, do not silently fill the gap with confident guesses.
- Capture missing knowledge as a local note, open question, or follow-up documentation update so the team does not rediscover the same gap later.
- When we learn a reliable workaround or constraint, promote it into repo documentation instead of leaving it only in chat history.

Preferred loop:

- search trusted source
- fetch focused documentation
- implement against verified context
- record gaps, assumptions, and corrections

## Implementation Strategy

Build incrementally.

Preferred delivery order:

1. `core + domain`
2. `application`
3. `infrastructure/ble + first device implementation`
4. `features/ble_device + control`
5. `infrastructure/mcp + features/mcp_server`
6. `features/claude_connector_tutorial` or equivalent guided onboarding slice
7. `features/settings + security`
8. `features/device_manager`

Do not dump the whole project in one pass unless explicitly asked.

## UI Rules

- Use Material 3.
- Keep the UI intentional, calm, and legible.
- Prioritize clarity over decorative complexity.
- Make safety warnings obvious but not theatrical.
- Reflect real device/service state clearly.
- Always provide a visible emergency stop path.

Core screens should include:

- device scan/connect
- manual control
- MCP / bridge status
- Claude connector tutorial
- device manager / adapter import
- settings/security

The in-app chat shell may exist later as a debug or experimental surface, but it is not the first-stage primary control entry.

## Chat Rules

The in-app chat is not the primary control boundary; it is a UX layer.

Rules:

- keep chat provider abstract
- allow stub/local implementations first
- separate chat transcript state from MCP tool execution state
- expose tool invocation records clearly in the UI
- do not tightly couple chat UX to one vendor API

## Product Shape Rules

For the current stage of the project:

- Treat ToyLink AI as a hardware bridge first, not a chat replacement.
- The first supported user journey is BYO-AI connector setup: the user keeps their existing AI chat web/app and connects it to ToyLink through a supported tool surface.
- Claude Remote MCP remains the first concrete connector path, but the product must not be hardcoded to Claude as the only supported AI environment.
- GPT / ChatGPT support belongs in the connector matrix and must share the same local safety chain.
- Safety V0 only promises remote status and emergency stop. Remote stimulation control is a later gated phase.
- Do not expand the product into a full in-app chat platform before the pairing, verification, connector setup, and remote control loop is stable.
- Favor template selection, device verification, Claude connector setup, and safety visibility over conversational polish.

## Storage Rules

Prefer:

- `shared_preferences` for lightweight settings
- `Hive` for device templates/configuration in MVP
- `flutter_secure_storage` for sensitive settings/tokens
- SQLite only when query complexity or migrations justify it

Do not over-engineer persistence early, but do preserve repository boundaries so storage can evolve later.

## Security Review Checklist

Before finishing any feature, verify:

- does it preserve clean dependency direction?
- does it route all device control through `ToyDevice`?
- does it centralize BLE/protocol details in infrastructure?
- does it apply EMS safety limits?
- does it avoid privacy leaks?
- does it keep `stopAll()` immediately available?
- is the behavior testable without real hardware where possible?

## Testing Rules

Every important behavior should have the right test level.

### Unit Tests

Prioritize tests for:

- protocol codec generation
- EMS safety guard logic
- MCP tool routing
- active-device registry behavior
- failure mapping
- control command validation

### Widget Tests

Prioritize tests for:

- control panel interactions
- EMS warning/confirmation UI
- MCP status display
- lock screen behavior
- scan/connect state rendering

### Integration Tests

Use mocks/fakes where needed for:

- scan -> connect -> control flow
- MCP tool -> use case -> device control flow
- one-click startup orchestration

Do not rely only on manual hardware testing.

## Code Style Rules

- Follow `very_good_analysis`.
- Prefer small files with clear responsibilities.
- Add comments where protocol or hardware behavior is non-obvious.
- Do not add noise comments.
- Avoid dead abstractions.
- Avoid speculative genericity unless it directly supports planned device expansion.
- Prefer readability and traceability over terseness.

## Documentation Rules

When adding or changing behavior:

- update architecture docs if boundaries change
- document new device capabilities and limits
- document MCP tool contract changes
- document protocol assumptions
- document safety implications

If a protocol decision is inferred rather than verified, say so clearly.

## What to Avoid

Do not:

- hardcode device protocol rules in widgets
- duplicate validation across UI and MCP layers
- expose unsafe raw control paths casually
- persist intimate usage data by default
- introduce cloud dependencies without a clear privacy model
- bypass planning for significant features
- optimize architecture by collapsing layers “just for MVP”

## Default Decision Heuristics

When multiple valid choices exist, prefer:

- safer over clever
- explicit over implicit
- testable over magical
- local-first over cloud-first
- extensible abstraction over brand-specific shortcuts
- repository/service boundaries over plugin leakage
- incremental delivery over broad unfinished scaffolding

## Definition of Done

A feature is not done unless:

- architecture boundaries are respected
- safety checks are implemented
- errors map cleanly to `Failure`
- tests cover critical logic
- docs/comments are sufficient for future maintenance
- no device-specific logic leaked into unrelated layers

## Preferred Stack

Use these by default unless there is a strong project-specific reason not to:

- Flutter
- Riverpod
- go_router
- flutter_blue_plus
- shelf
- mcp_server
- flutter_foreground_task
- permission_handler
- shared_preferences
- hive
- flutter_secure_storage
- local_auth

## Final Reminder

ToyLink AI is not a generic CRUD app.

It controls real hardware, includes safety-sensitive stimulation modes, and exposes AI-callable local control surfaces. Treat every architecture and implementation decision as if it must still be understandable, safe, and extensible six months from now when new devices, new MCP clients, and new compliance expectations arrive.
