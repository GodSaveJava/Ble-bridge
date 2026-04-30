# Storage and Security Schema

## Purpose

This document defines what ToyLink AI stores locally, where it is stored, and why.

It exists to prevent three common problems:

- storing the right data in the wrong place
- leaking sensitive data through convenience shortcuts
- creating storage formats that are hard to migrate later

## Storage Principles

- keep sensitive data local-first
- store the minimum necessary data
- separate convenience settings from sensitive state
- prefer simple storage for MVP, but preserve upgrade paths
- never store intimate control history by default

## Storage Layers

ToyLink AI MVP uses three storage layers:

1. `shared_preferences`
2. `Hive`
3. `flutter_secure_storage`

## Why Three Different Stores

### shared_preferences

Use for:

- small primitive settings
- feature toggles
- last-used UI preferences

Reason:

- fast to implement
- simple key-value storage
- not suitable for secrets or structured device template data

### Hive

Use for:

- structured local app data
- device templates
- user-defined protocol configuration
- cached non-sensitive device records

Reason:

- lighter than SQLite for MVP
- easier to evolve quickly during early product work
- good fit for structured local records without complex queries

### flutter_secure_storage

Use for:

- secrets
- app lock related sensitive state
- future relay or provider credentials

Reason:

- values are backed by platform secure storage
- should be the only place for data that would be risky if read by another app

## Data Classification

### Safe Convenience Data

Examples:

- selected theme
- whether onboarding was completed
- last-opened screen

Store in:

- `shared_preferences`

### Structured Local Product Data

Examples:

- device templates
- user custom scan prefixes
- saved protocol metadata
- known device aliases

Store in:

- `Hive`

### Sensitive Data

Examples:

- app lock enabled state if tied to secure behavior
- future Claude relay token
- encryption or auth related state

Store in:

- `flutter_secure_storage`

### Data We Should Not Store By Default

Examples:

- full control action history
- raw BLE payload logs
- intimate session transcript history
- persistent stimulation history

Reason:

- high privacy risk
- low MVP value

## shared_preferences Schema

Recommended keys:

- `app.onboarding_completed` -> `bool`
- `app.last_opened_tab` -> `String`
- `ble.auto_disconnect_enabled` -> `bool`
- `ble.auto_disconnect_minutes` -> `int`
- `device.last_active_device_id` -> `String?`
- `mcp.last_known_port` -> `int`
- `security.lock_timeout_seconds` -> `int`

Rules:

- keep values primitive
- do not serialize complex JSON blobs into shared preferences unless there is a strong reason

## Hive Boxes and Records

Recommended boxes:

- `device_templates`
- `known_devices`
- `protocol_profiles`
- `app_settings_cache`

### device_templates

Purpose:

- built-in and user-created protocol templates

Suggested record shape:

- `templateId`
- `displayName`
- `protocolKey`
- `bleNamePrefixes`
- `supportsSuck`
- `supportsVibe`
- `supportsEms`
- `suckRangeMin`
- `suckRangeMax`
- `vibeRangeMin`
- `vibeRangeMax`
- `emsRangeMin`
- `emsRangeMax`
- `modeCount`
- `notes`
- `version`
- `isUserDefined`

### known_devices

Purpose:

- locally remembered devices chosen by the user

Suggested record shape:

- `deviceId`
- `displayAlias`
- `protocolKey`
- `lastSeenName`
- `lastConnectedAt`
- `isFavorite`
- `templateId?`

Rules:

- do not treat this as private long-term telemetry
- avoid storing unnecessary scan history

### protocol_profiles

Purpose:

- protocol-specific configuration snapshots

Suggested record shape:

- `profileId`
- `protocolKey`
- `serviceUuid`
- `writeCharacteristicUuid`
- `notifyCharacteristicUuid?`
- `writeWithoutResponse`
- `retryCount`
- `requestMtu`
- `metadata`
- `version`

### app_settings_cache

Purpose:

- structured non-sensitive settings that become awkward in shared preferences

Suggested record shape:

- `key`
- `value`
- `updatedAt`

Use carefully. Prefer explicit top-level boxes before dropping many unrelated objects here.

## Secure Storage Keys

Recommended secure keys:

- `security.app_lock_enabled`
- `security.last_unlock_method`
- `relay.claude_access_token`
- `relay.provider_base_url`

Notes:

- `provider_base_url` may move to non-secure storage if later judged non-sensitive
- tokens must never be stored outside secure storage

## App Lock Data Rules

Store only the minimum needed.

Recommended approach:

- secure storage for lock-enabled state and sensitive auth-related flags
- shared preferences for non-sensitive timeout duration if needed

Do not store:

- biometric raw data
- unlock attempt history unless there is a strong product need

## Migration Strategy

Even in MVP, define versioning early.

Recommended rules:

- every Hive record type includes `version`
- protocol profile records include explicit schema version
- changes that alter field meaning require migration logic, not silent reinterpretation

## Failure Mapping

Storage failures should map to typed failures:

- read failure -> `Failure.storage`
- write failure -> `Failure.storage`
- secure key unavailable -> `Failure.securityLock` or `Failure.storage` depending on context

## Testing Requirements

- read/write tests for each store abstraction
- migration tests for versioned records
- secure storage fallback behavior tests
- tests that verify sensitive data is not written to non-secure stores

## Default Implementation Decision

For MVP:

- simple scalar settings -> `shared_preferences`
- structured local app data -> `Hive`
- secrets and sensitive auth state -> `flutter_secure_storage`

This split is the default unless a future requirement clearly justifies SQLite or a different persistence model.
