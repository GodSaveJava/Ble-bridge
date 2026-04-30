# Domain Interfaces and State Machines

## Purpose

This document defines the minimum domain and application contracts required before implementation begins.

It is intended to remove ambiguity around:

- public interfaces
- failure semantics
- active device ownership
- main state machines

## Design Goals

- keep domain types explicit
- isolate hardware behind `ToyDevice`
- unify manual control and MCP control paths
- make failure handling deterministic
- keep multi-device support possible without forcing MVP UI complexity

## Core Domain Interfaces

### ToyDevice

Responsibilities:

- connect and disconnect from one physical BLE device
- apply normalized control commands
- expose current status
- send raw commands only for infrastructure-level escape hatches

Required shape:

- `id`
- `name`
- `bleNamePrefix`
- `supportedFeatures`
- `intensityRangeByChannel`
- `safetyPolicy`
- `connectionState`
- `statusStream`
- `connect(...)`
- `disconnect()`
- `setSuck(...)`
- `setVibe(...)`
- `setEms(...)`
- `setAll(...)`
- `stopAll()`
- `getStatus()`
- `sendRawCommand(...)`

### HardwareRepository

Responsibilities:

- scan for candidate BLE devices
- manage active device connection lifecycle
- expose scan results and active device status

Required methods:

- `Stream<List<ToyDeviceInfo>> watchDiscoveredDevices()`
- `Future<void> startScan()`
- `Future<void> stopScan()`
- `Future<void> connectActiveDevice(ToyDeviceInfo info)`
- `Future<void> disconnectActiveDevice()`
- `ToyDevice? getActiveDevice()`
- `Stream<DeviceStatus> watchActiveStatus()`

### McpService

Responsibilities:

- start and stop local MCP transport
- register tools bound to the current active device flow
- publish endpoint state

Required methods:

- `Future<void> start()`
- `Future<void> stop()`
- `bool get isRunning`
- `McpEndpointInfo? get endpointInfo`
- `Future<void> registerToolsForActiveDevice()`

### ChatProvider

Responsibilities:

- maintain chat transcript flow
- expose tool invocation records
- remain replaceable for future domestic relay integration

Required methods:

- `Future<void> sendMessage(String text)`
- `Stream<List<ChatMessage>> watchMessages()`
- `Stream<ToolInvocationRecord> watchToolEvents()`

## Core Domain Types

### ToyDeviceInfo

Minimum fields:

- `id`
- `displayName`
- `bleNamePrefix`
- `protocolKey`
- `isKnownTemplate`
- `rssi?`

### DeviceStatus

Minimum fields:

- `deviceId`
- `isConnected`
- `suckIntensity`
- `vibeIntensity`
- `emsIntensity`
- `suckMode`
- `vibeMode`
- `emsMode`
- `batteryLevel?`
- `lastUpdatedAt`

### ControlCommand

Minimum fields:

- `channel`
- `intensity`
- `mode`
- `source`
- `requiresConfirmation`
- `requestedAt`

### SafetyPolicy

Minimum fields:

- `emsSoftLimit`
- `emsHardLimit`
- `requiresExplicitConfirmationAboveSoftLimit`

### Failure

Recommended top-level categories:

- `validation`
- `permissionDenied`
- `bluetoothUnavailable`
- `scanFailed`
- `deviceNotFound`
- `deviceConnection`
- `deviceDisconnected`
- `deviceWrite`
- `protocolUnsupported`
- `noActiveDevice`
- `mcpServer`
- `storage`
- `securityLock`
- `unknown`

## Active Device Model

MVP uses one active device for control routing.

Rules:

- multiple discovered devices may exist
- future background support may allow multiple retained device records
- UI and MCP control paths resolve exactly one active device at a time
- switching active device must invalidate previous control ownership

## State Machines

### Scan State Machine

States:

- `idle`
- `requestingPermissions`
- `readyToScan`
- `scanning`
- `scanResultsAvailable`
- `scanFailed`

Transitions:

- `idle -> requestingPermissions`
- `requestingPermissions -> readyToScan`
- `requestingPermissions -> scanFailed`
- `readyToScan -> scanning`
- `scanning -> scanResultsAvailable`
- `scanning -> scanFailed`
- `scanResultsAvailable -> scanning`
- `scanResultsAvailable -> idle`

### Connection State Machine

States:

- `disconnected`
- `connecting`
- `discoveringServices`
- `connected`
- `disconnecting`
- `connectionFailed`

Transitions:

- `disconnected -> connecting`
- `connecting -> discoveringServices`
- `connecting -> connectionFailed`
- `discoveringServices -> connected`
- `discoveringServices -> connectionFailed`
- `connected -> disconnecting`
- `connected -> disconnected`
- `disconnecting -> disconnected`

### Quick Start State Machine

States:

- `idle`
- `checkingEnvironment`
- `scanningOrResolvingDevice`
- `connectingDevice`
- `startingForegroundService`
- `startingMcpServer`
- `ready`
- `failed`

Failure in any intermediate state moves to `failed` with a typed `Failure`.

### Control State Machine

States:

- `unavailable`
- `ready`
- `applyingCommand`
- `awaitingSafetyConfirmation`
- `stopping`
- `error`

Rules:

- EMS over soft limit enters `awaitingSafetyConfirmation`
- `stopAll()` may interrupt `applyingCommand`
- stale slider updates must not outrun the command queue

### MCP Service State Machine

States:

- `stopped`
- `starting`
- `running`
- `error`
- `stopping`

Rules:

- running MCP does not imply a connected device
- device loss while MCP is running returns structured tool errors, not transport shutdown

### App Lock State Machine

States:

- `unlocked`
- `lockRequired`
- `authenticating`
- `lockedOut`

Rules:

- return to foreground may trigger `lockRequired`
- sensitive control screens must respect locked state

## Routing Rules

All command paths must converge through the same validation chain:

`UI or MCP -> Application Use Case -> SafetyGuard -> ActiveDeviceRegistry -> ToyDevice`

No alternate path may skip `SafetyGuard`.

## Acceptance Criteria

Before implementation starts, each interface above should be stable enough that:

- features can depend on signatures without guessing
- protocol code can be written without inventing new routing rules
- MCP handlers and UI handlers share the same command semantics
