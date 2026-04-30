# ADR-003: Use Localhost Streamable HTTP for MVP MCP Transport

## Status

Accepted

## Context

ToyLink AI needs a local MCP surface that:

- works well with app-local services
- avoids cloud dependency
- keeps privacy risk lower
- stays flexible for future client integrations

We considered multiple transport styles, including STDIO and broader remote exposure.

## Decision

For MVP:

- use Streamable HTTP
- bind to localhost
- do not expose public remote control by default

## Why This Decision

- good fit for a phone-hosted local service
- easier to inspect and debug than process-bound STDIO in this app shape
- supports future bridge layers without changing the internal tool model
- aligns with local-first privacy goals

## Consequences

Positive:

- simpler local integration model
- lower accidental exposure than network-facing remote designs
- good compatibility with structured tool calling workflows

Tradeoffs:

- still requires careful localhost threat modeling
- remote scenarios will need an explicit future bridge

## Rejected Alternatives

### STDIO-first MCP

Rejected because:

- it is a weaker fit for an app-hosted mobile runtime
- harder to treat as a stable local service boundary

### Remote public MCP endpoint in MVP

Rejected because:

- unnecessary privacy and safety risk
- more operational and auth complexity too early

## Guidance for Junior Developers

Remember:

- localhost is not the same as internet exposure
- but localhost is still not automatically safe

Every tool call still needs validation and safety checks.
