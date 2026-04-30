# Android Permissions, Foreground Service, and Security Boundaries

## Purpose

This document defines the Android-first runtime boundaries for ToyLink AI MVP.

It covers:

- runtime permissions
- foreground service expectations
- BLE stability assumptions
- security and privacy boundaries

## Platform Priority

MVP priority:

- Android first

iOS should remain structurally compatible, but Android drives the first operational design.

## Required Android Permissions

The exact manifest set may vary by target SDK, but MVP planning should assume these Android capabilities are relevant:

- Bluetooth scan
- Bluetooth connect
- nearby devices
- foreground service
- foreground service subtype for connected device or data sync as required by target SDK behavior
- notifications for visible service state

## Runtime Permission Strategy

Permission requests should be staged, not dumped all at once.

Recommended sequence:

1. ask for Bluetooth-related permissions when user starts scan/connect flow
2. ask for notification permission when foreground service is needed
3. explain why the app needs background connection persistence before starting service

Rules:

- permission denial must produce actionable UI feedback
- app should not loop or spam permission dialogs
- feature access should degrade safely when permission is denied

## Bluetooth Environment Checks

Before scanning or connecting:

- verify Bluetooth is supported
- verify adapter is on
- verify required permissions are granted

Failure mapping:

- unsupported hardware -> `Failure.bluetoothUnavailable`
- Bluetooth off -> `Failure.bluetoothUnavailable`
- denied permission -> `Failure.permissionDenied`

## Foreground Service Design

Foreground service exists to improve BLE connection stability while the app is backgrounded.

Required behavior:

- service start is explicit
- visible notification is always present while service is active
- user has a clear way to stop it
- service lifecycle is observable in app state

Service must not be used to:

- conceal device activity
- bypass app lock or confirmation rules
- create unsafe autonomous background control

## Foreground Service State Model

States:

- `stopped`
- `starting`
- `running`
- `error`
- `stopping`

Rules:

- service can run without an active MCP session
- service may run with a connected device but idle outputs
- service stop should trigger cleanup review for active connection ownership

## Notification Requirements

The foreground service notification should communicate:

- app name
- BLE connection status
- MCP service status if relevant
- quick stop or open-app action if supported

Notification text must remain privacy-conscious and avoid intimate details.

## Security Boundaries

### App Lock

App lock should protect:

- control panel access
- settings that affect safety or privacy
- chat session access if it includes control history

App lock does not replace protocol-level safety checks.

### Local MCP Exposure

MCP MVP should assume:

- localhost-only exposure
- no public remote access
- no cloud relay by default

Threats to consider:

- local malware or untrusted apps on the device
- accidental unsafe invocation from local clients

Mitigation direction:

- keep transport local
- validate every tool call
- reject unsafe EMS requests

### Logging

Do not log:

- full BLE identifiers when avoidable
- raw protocol payloads in production logs
- chat transcript contents as operational logs
- persistent stimulation history by default

### Secure Storage

Use secure storage for:

- app lock or sensitive auth state
- future relay tokens

Do not place secrets in shared preferences.

## Auto-Reconnect and Recovery

MVP should be conservative.

Recommended rules:

- allow reconnect assistance only after explicit user opt-in
- do not auto-resume stimulation after reconnect
- restore connection state, not control output state

## Failure and Recovery UX

When the environment changes unexpectedly:

- Bluetooth off -> surface reconnect guidance
- permission revoked -> surface permission recovery path
- service killed -> surface visible warning and safe inactive state
- device disconnected -> keep MCP transport running but return typed errors

## Required Test Scenarios

- permission denied before scan
- Bluetooth off before connect
- service start success
- service start failure
- device disconnect while service is running
- app returns to foreground and lock is required
- MCP request while device is disconnected

## Open Decisions to Confirm During Implementation

1. Which foreground service subtype best matches final Android target SDK policy?
2. Should the service expose a notification action for emergency stop?
3. Should app lock be required on every foreground return or only after timeout?
4. Should the app allow scanning without starting the service?

## Default Implementation Direction

Until platform details are finalized:

- keep permission orchestration in application or presentation orchestration layers
- keep foreground service control behind an abstract service interface
- keep all safety validation independent from service lifecycle
