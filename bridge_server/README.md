# ToyLink Bridge Server

Minimal Remote Bridge server for ToyLink AI.

## Local run

```bash
cd bridge_server
dart pub get
dart run bin/bridge_server.dart
```

Default listens on `0.0.0.0:8100`.

## Environment variables

- `BRIDGE_HOST`: bind host, default `0.0.0.0`
- `BRIDGE_PORT`: bind port, default `8100`
- `BRIDGE_PUBLIC_BASE_URL`: public base URL returned to clients, optional
- `BRIDGE_CONNECTOR_PATH`: connector path returned in `connectorUrl`, default `/mcp/claude`
- `BRIDGE_SHARED_TOKEN`: optional bearer token required by the mobile bridge client
- `BRIDGE_DEBUG_TOKEN`: optional token for `/debug/enqueue`
- `BRIDGE_TOOL_NAMES`: comma-separated tool list

## Docker

```bash
cd bridge_server
docker build -t toylink-bridge-server .
docker run --rm -p 8100:8100 \
  -e BRIDGE_PUBLIC_BASE_URL=http://47.95.242.29:8100 \
  toylink-bridge-server
```

If you put Nginx in front of it, point the upstream to the container's `8100` port.
