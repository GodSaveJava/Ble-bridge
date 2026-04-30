import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../application/mcp/mcp_tool_router.dart';
import '../../domain/services/mcp_service.dart';

/// Local MCP HTTP service for MVP.
///
/// Transport responsibilities:
/// - Expose a local POST endpoint for tool execution.
/// - Validate JSON payload shape.
/// - Map request/response as structured JSON.
///
/// Business responsibilities stay in [McpToolRouter], so protocol/safety
/// behavior is still governed by application/domain rules.
class LocalMcpHttpService implements McpService {
  LocalMcpHttpService({
    required McpToolRouter toolRouter,
    this.host = '127.0.0.1',
    this.port = 8765,
  }) : _toolRouter = toolRouter;

  final McpToolRouter _toolRouter;
  final String host;
  final int port;

  HttpServer? _server;
  McpEndpointInfo? _endpointInfo;

  @override
  bool get isRunning => _server != null;

  @override
  McpEndpointInfo? get endpointInfo => _endpointInfo;

  @override
  Future<void> start() async {
    if (isRunning) {
      return;
    }

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_handleRequest);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.tryParse(host) ?? InternetAddress.loopbackIPv4,
      port,
    );
    _endpointInfo = const McpEndpointInfo(
      host: '127.0.0.1',
      port: 8765,
      path: '/mcp/tool',
    );
  }

  @override
  Future<void> stop() async {
    final server = _server;
    if (server == null) {
      return;
    }
    await server.close(force: true);
    _server = null;
    _endpointInfo = null;
  }

  @override
  Future<void> registerToolsForActiveDevice() async {}

  Future<Response> _handleRequest(Request request) async {
    if (request.url.path == 'mcp/status' && request.method == 'GET') {
      return _jsonResponse(HttpStatus.ok, <String, Object?>{
        'ok': true,
        'service': 'toylink_local_mcp',
        'running': isRunning,
        'endpoint': endpointInfo == null
            ? null
            : <String, Object?>{
                'host': endpointInfo!.host,
                'port': endpointInfo!.port,
                'path': endpointInfo!.path,
              },
      });
    }

    if (request.url.path != 'mcp/tool' || request.method != 'POST') {
      return _jsonResponse(HttpStatus.notFound, <String, Object?>{
        'ok': false,
        'errorCode': 'route_not_found',
        'errorMessage': 'Unsupported MCP route.',
      });
    }

    try {
      final dynamic json = jsonDecode(await request.readAsString());
      if (json is! Map<String, dynamic>) {
        return _validationError('Request body must be a JSON object.');
      }

      final name = json['name'];
      final arguments = json['arguments'];
      if (name is! String || name.isEmpty) {
        return _validationError('Missing or invalid tool name.');
      }
      if (arguments != null && arguments is! Map<String, dynamic>) {
        return _validationError('Tool arguments must be a JSON object.');
      }

      final result = await _toolRouter.callTool(
        name,
        arguments: (arguments ?? <String, dynamic>{}).cast<String, Object?>(),
      );

      return _jsonResponse(
        result.ok ? HttpStatus.ok : HttpStatus.badRequest,
        <String, Object?>{
          'ok': result.ok,
          'data': result.data,
          'errorCode': result.errorCode,
          'errorMessage': result.errorMessage,
        },
      );
    } on FormatException {
      return _validationError('Invalid JSON payload.');
    } catch (_) {
      return _jsonResponse(HttpStatus.internalServerError, <String, Object?>{
        'ok': false,
        'errorCode': 'mcp_internal_error',
        'errorMessage': 'Unexpected server error.',
      });
    }
  }

  Response _validationError(String message) {
    return _jsonResponse(HttpStatus.badRequest, <String, Object?>{
      'ok': false,
      'errorCode': 'validation_error',
      'errorMessage': message,
    });
  }

  Response _jsonResponse(int statusCode, Map<String, Object?> body) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}
