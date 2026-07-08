# External Platform Manual Evidence Guide

## Purpose

This guide is for Phase 2 external platform hand verification. It does not replace real ChatGPT / Claude / user-owned AI setup. It defines the exact evidence needed before we can mark external platform evidence as PASS.

## Required Evidence

For at least one real external AI environment:

1. The platform is configured with a ToyLink connector card or generated platform template.
2. The platform successfully calls `get_status`.
3. ToyLink marks connector verification as waiting or verified after the tool call.
4. The platform only sees Safety V0 tools: `get_status` and `stop_all`.
5. A `set_*` attempt is unavailable or rejected.
6. The evidence record includes date, platform name, connector source, command/output or screenshots, and final result.

## Preflight Command

Use the preflight tool before or during manual platform verification:

```powershell
& 'C:\Users\NPC\dev\flutter\bin\dart.bat' run tool\external_platform_preflight.dart `
  --card C:\path\to\connector-card.json `
  --platform "ChatGPT GPT Actions" `
  --evidence-out docs\evidence\manual-chatgpt-preflight.md
```

Dry-run without network calls:

```powershell
& 'C:\Users\NPC\dev\flutter\bin\dart.bat' run tool\external_platform_preflight.dart `
  --connector-url https://bridge.example.com/mcp/claude `
  --token toy_connector_token `
  --platform "Claude Remote MCP" `
  --dry-run
```

## Evidence Result Rules

- `PASS`: real external platform configured and successfully called `get_status`; unsafe tools unavailable or rejected.
- `PENDING`: preflight passed, but platform UI/configuration was not actually verified.
- `BLOCKED`: account access, platform feature access, connector reachability, Android hardware, or Bridge environment prevented verification.
- `FAIL`: platform was configured but could not call `get_status`, exposed unsafe tools, or allowed `set_*`.

## Safety Boundary

Phase 1 / Safety V0 remote connector must remain limited to `get_status` and `stop_all`.

Do not mark external platform evidence as complete from a local script alone. The script is supporting evidence; the acceptance gate requires a real user-owned AI environment.
