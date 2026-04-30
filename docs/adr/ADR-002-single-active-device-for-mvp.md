# ADR-002: Use a Single Active Device in MVP

## Status

Accepted

## Context

The long-term product should support multiple devices, but the MVP must remain understandable and safe.

Controlling multiple devices at once increases complexity in:

- routing
- UI state
- MCP targeting
- emergency stop behavior
- safety prompts

## Decision

For MVP:

- allow discovery of many devices
- allow future architecture to support many devices
- route manual UI and MCP control through one active device at a time

## Why This Decision

- simpler mental model for users
- simpler control routing for implementation
- safer EMS and stop behavior
- fewer ambiguous MCP tool outcomes

## Consequences

Positive:

- easier app state model
- lower chance of accidental cross-device control
- clearer error handling

Tradeoffs:

- does not deliver simultaneous control in MVP
- later multi-device orchestration will still require new work

## Rejected Alternatives

### Full multi-device control in MVP

Rejected because:

- too much UI and routing complexity for first release
- increases safety risk and implementation risk

### Hardcode a forever single-device architecture

Rejected because:

- would force painful refactors later

## Guidance for Junior Developers

Think of it this way:

- many devices can exist in the app
- one device owns the current control session

That current owner is the active device. MCP and UI should both talk to that same owner.
