# ADR-001: Use Feature-First with Clean Architecture

## Status

Accepted

## Context

ToyLink AI is not a simple CRUD app.

It combines:

- Flutter presentation
- BLE hardware control
- local MCP server behavior
- safety-sensitive EMS rules
- future multi-device support

Without strict boundaries, device protocol logic would quickly leak into UI and become hard to maintain.

## Decision

Use:

- Feature-First project structure
- Clean Architecture dependency direction

Target dependency rule:

- `Presentation -> Application -> Domain <- Infrastructure`

## Why This Decision

- Feature-First keeps related UI and feature flows easy to navigate.
- Clean Architecture protects the hardware abstraction boundary.
- This combination makes future device support less invasive.
- MCP, BLE, and UI can evolve without tightly coupling everything together.

## Consequences

Positive:

- safer extension for new devices
- easier unit testing
- cleaner control path for MCP and manual UI

Tradeoffs:

- more files
- more abstraction than a quick MVP
- requires discipline from every contributor

## Rejected Alternatives

### Flat featureless Flutter structure

Rejected because:

- BLE and protocol logic would leak into screens quickly
- scaling to more hardware would become painful

### Layer-only structure without features

Rejected because:

- feature navigation becomes harder as the app grows
- presentation code gets fragmented across unrelated folders

## Guidance for Junior Developers

If you are unsure where code belongs, ask:

1. Is this UI rendering? Put it in `features/.../presentation` or `shared/`.
2. Is this app flow orchestration? Put it in `application/`.
3. Is this business meaning or interface contract? Put it in `domain/`.
4. Is this plugin, BLE, MCP, storage, or OS-specific code? Put it in `infrastructure/`.
