# SOSEXY Protocol Specification Draft

## Purpose

This document captures the first implementation target for the SOSEXY BLE device protocol in a form that is safer and more maintainable than scattered notes.

This is a draft specification for ToyLink AI MVP. It is the source of truth for protocol implementation until replaced by a verified revision.

## Scope

This document defines:

- device identification assumptions
- GATT discovery expectations
- channel mapping
- command-building responsibilities
- open questions that must stay isolated in codec/spec code

This document does not define UI behavior, Riverpod state, or MCP transport behavior.

## Design Principles

- All SOSEXY protocol details must live under `infrastructure/devices/sosexy/`.
- Protocol byte encoding must be separated from BLE transport.
- Unknown or inferred rules must be marked clearly.
- No UI, MCP, or application code may construct raw SOSEXY command bytes.

## Files Expected From This Spec

- `sosexy_gatt_profile.dart`
- `sosexy_protocol_spec.dart`
- `sosexy_protocol_codec.dart`
- `sosexy_device.dart`

## Device Identity

### Name Filter

Initial scan matching rules:

- default BLE name prefix contains `SOSEXY`
- allow future user-configured prefixes through settings or device templates

### Device Template Key

- `protocolKey = sosexy`

### Notes

- Do not rely only on name matching for long-term identity
- Persist the selected device identifier separately from the protocol template key

## GATT Profile

The following fields must exist in `SosexyGattProfile`:

- `serviceUuid`
- `writeCharacteristicUuid`
- `notifyCharacteristicUuid?`
- `writeWithoutResponse`
- `connectTimeout`
- `writeTimeout`
- `retryCount`
- `requestMtu`

## Current Protocol Assumptions

The current planning baseline assumes the protocol notes mention three logical channels:

- `CH01` -> suck
- `CH03` -> vibe
- `CH07` -> ems

These mappings must be represented as constants in `SosexyProtocolSpec`.

## Capability Model

The SOSEXY implementation should expose the following capability assumptions:

- supports suck
- supports vibe
- supports ems
- supports combined update through `setAll`
- supports immediate stop through `stopAll`

## Intensity and Mode Ranges

Initial planning defaults:

- suck intensity: `0..100`
- vibe intensity: `0..100`
- ems intensity: `0..20`
- suck mode: `1..4`
- vibe mode: `1..4`
- ems mode: `1..4`

Safety rules are enforced above protocol level, but the codec should still validate raw ranges before encoding.

## Command Model

The codec should accept a domain-level request model, not naked argument lists.

Recommended request model fields:

- `channel`
- `intensity`
- `mode`
- `source`
- `timestamp`

## Required Codec Functions

`SosexyProtocolCodec` should expose these builders:

- `buildSuckCommand(int intensity, int mode)`
- `buildVibeCommand(int intensity, int mode)`
- `buildEmsCommand(int intensity, int mode)`
- `buildSetAllCommand(...)`
- `buildStopAllCommand()`

The actual implementation may additionally use a shared private builder for common packet structure.

## Packet Structure

The final packet format is not yet fully verified in the repository.

Implementation rule:

- packet layout assumptions must be centralized in `SosexyProtocolSpec`
- `SosexyProtocolCodec` may not embed unexplained magic numbers inline
- each byte or byte group must be documented with what it represents

Expected documented fields:

- header bytes
- channel byte
- mode byte
- intensity byte
- checksum or validation byte if present
- trailer byte if present

## Stop Behavior

`stopAll()` is a first-class protocol operation.

Required rules:

- it must have a dedicated codec path
- it must not depend on sending zero-intensity channel updates unless the protocol explicitly requires that
- command queue behavior must prioritize stop over regular writes

## BLE Write Rules

The SOSEXY transport layer should follow these rules:

- discover services after each fresh connection
- resolve and cache the target write characteristic
- use a serialized write queue
- support throttled slider-driven updates
- clear pending non-stop writes when `stopAll()` is issued

## Error Handling

Protocol and transport failures should map cleanly into app failures:

- missing service or characteristic -> `Failure.protocolUnsupported`
- invalid intensity or mode -> `Failure.validation`
- write timeout -> `Failure.deviceWrite`
- disconnected state -> `Failure.deviceDisconnected`

## Test Cases Required

The implementation must include protocol tests for:

- suck command encoding
- vibe command encoding
- ems command encoding
- stop command encoding
- invalid intensity rejection
- invalid mode rejection
- `setAll` packet strategy

## Open Questions

These questions remain unresolved and should be answered before final hardware integration:

1. What are the verified service and characteristic UUIDs?
2. Does the protocol require `writeWithoutResponse` or acknowledged writes?
3. Is there a checksum byte or fixed trailer?
4. Is `setAll` a native combined command or a sequence of per-channel commands?
5. What exact byte pattern performs a hard stop?
6. Are mode values `1..4` protocol-native or app-level abstractions?

## Default Implementation Decision

Until protocol notes are fully verified:

- keep protocol assumptions in a separate spec file
- annotate each assumption with `verified` or `inferred`
- avoid leaking uncertain details into domain or application layers
