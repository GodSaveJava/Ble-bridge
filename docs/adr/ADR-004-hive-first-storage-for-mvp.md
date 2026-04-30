# ADR-004: Use Hive First for Structured MVP Storage

## Status

Accepted

## Context

ToyLink AI needs storage for:

- device templates
- protocol metadata
- user-defined configuration
- lightweight local records

The team also needs development speed during MVP.

## Decision

For MVP:

- use `shared_preferences` for simple scalar settings
- use `Hive` for structured non-sensitive local data
- use `flutter_secure_storage` for secrets and sensitive auth state

Do not introduce SQLite unless future requirements justify it.

## Why This Decision

- Hive is easier to move fast with in MVP
- query needs are still simple
- repository boundaries let us upgrade later if needed
- secure storage remains reserved for genuinely sensitive values

## Consequences

Positive:

- faster implementation
- lower schema overhead during early iteration
- cleaner separation between ordinary settings and secrets

Tradeoffs:

- Hive is not as strong as SQLite for complex queries and migrations
- careless record design could still create upgrade pain later

## Rejected Alternatives

### SQLite from day one

Rejected because:

- more setup and migration overhead than MVP currently needs

### Put everything into shared_preferences

Rejected because:

- poor structure
- harder migrations
- too easy to abuse for semi-sensitive blobs

## Guidance for Junior Developers

A simple rule:

- tiny primitive setting -> shared preferences
- structured app data -> Hive
- secret or token -> secure storage
