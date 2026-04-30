# MCP Tool Contract

## Purpose

This document defines the local MCP tool surface for ToyLink AI MVP.

It is the contract between:

- local MCP clients
- ToyLink AI application services
- active device control flow

## Transport

Initial transport target:

- Streamable HTTP over `localhost`

Default constraints:

- no public internet exposure in MVP
- no remote cloud dependency for device control
- MCP availability should not imply unsafe autonomous control

## Tool Routing

All tools route through:

`McpToolRouter -> SafetyGuard -> Application Use Case -> ActiveDeviceRegistry -> ToyDevice`

No tool may directly call BLE infrastructure.

## Shared Tool Rules

All tools must:

- return structured failure when no active device exists
- apply the same validation as manual UI controls
- provide human-readable text content
- provide structured status output when relevant

## Error Contract

Recommended error fields:

- `code`
- `message`
- `recoverable`
- `details?`

Recommended error codes:

- `no_active_device`
- `device_disconnected`
- `validation_failed`
- `ems_confirmation_required`
- `ems_limit_exceeded`
- `mcp_internal_error`

## Tool Definitions

### set_suck

Purpose:

- set suck intensity and mode on the active device

Input schema:

```json
{
  "type": "object",
  "required": ["intensity"],
  "properties": {
    "intensity": { "type": "integer", "minimum": 0, "maximum": 100 },
    "mode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 }
  },
  "additionalProperties": false
}
```

Success result:

- text summary
- structured device status

### set_vibe

Purpose:

- set vibe intensity and mode on the active device

Input schema:

```json
{
  "type": "object",
  "required": ["intensity"],
  "properties": {
    "intensity": { "type": "integer", "minimum": 0, "maximum": 100 },
    "mode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 }
  },
  "additionalProperties": false
}
```

Success result:

- text summary
- structured device status

### set_ems

Purpose:

- set ems intensity and mode on the active device

Input schema:

```json
{
  "type": "object",
  "required": ["intensity"],
  "properties": {
    "intensity": { "type": "integer", "minimum": 0, "maximum": 20 },
    "mode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 }
  },
  "additionalProperties": false
}
```

Safety behavior:

- `0..8` -> execute immediately
- `9..20` -> reject with `ems_confirmation_required`
- `>20` -> reject with `ems_limit_exceeded`

Design note:

MVP MCP does not perform an interactive confirmation handshake. It rejects above-soft-limit requests and leaves confirmation to the local app UI workflow.

### set_all

Purpose:

- apply multiple channel values in one logical command

Input schema:

```json
{
  "type": "object",
  "properties": {
    "suck": { "type": "integer", "minimum": 0, "maximum": 100, "default": 0 },
    "vibe": { "type": "integer", "minimum": 0, "maximum": 100, "default": 0 },
    "ems": { "type": "integer", "minimum": 0, "maximum": 20, "default": 0 },
    "suckMode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 },
    "vibeMode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 },
    "emsMode": { "type": "integer", "minimum": 1, "maximum": 4, "default": 1 }
  },
  "additionalProperties": false
}
```

Safety behavior:

- same EMS rules as `set_ems`
- if `ems > 8`, reject entire tool call

Default execution rule:

- treat `set_all` as one logical request
- if protocol lacks a native combined command, application layer may translate to an ordered sequence

### stop_all

Purpose:

- immediately stop all supported stimulation channels

Input schema:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false
}
```

Behavior:

- always allowed when device is connected
- should preempt queued non-stop commands
- should return latest known device status after stop

### get_status

Purpose:

- fetch current active device status

Input schema:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false
}
```

Success result fields:

- `deviceId`
- `isConnected`
- `suckIntensity`
- `vibeIntensity`
- `emsIntensity`
- `suckMode`
- `vibeMode`
- `emsMode`
- `batteryLevel`
- `lastUpdatedAt`

## Standard Success Shape

Recommended structured content:

```json
{
  "ok": true,
  "status": {
    "deviceId": "string",
    "isConnected": true,
    "suckIntensity": 0,
    "vibeIntensity": 0,
    "emsIntensity": 0,
    "suckMode": 1,
    "vibeMode": 1,
    "emsMode": 1,
    "batteryLevel": null,
    "lastUpdatedAt": "2026-04-30T00:00:00Z"
  }
}
```

## Standard Failure Shape

Recommended structured content:

```json
{
  "ok": false,
  "error": {
    "code": "no_active_device",
    "message": "No active toy device is connected.",
    "recoverable": true,
    "details": null
  }
}
```

## Tool Registration Rules

At MCP service startup:

- register all supported tools
- tool behavior should resolve against current active device at call time
- do not require server restart when active device changes

## Logging Rules

MCP tool logs must:

- avoid full raw BLE payload dumps
- avoid intimate long-term action history by default
- preserve only minimal operational diagnostics

## Required Tests

- schema validation for each tool
- `no_active_device` failure behavior
- EMS over-soft-limit rejection
- EMS over-hard-limit rejection
- `stop_all` queue-preemption behavior
- `get_status` success shape
