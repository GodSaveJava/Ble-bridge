import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../application/mcp/mcp_tool_router.dart';
import '../../domain/services/mcp_service.dart';

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

    if (request.url.path == 'mcp/tools' && request.method == 'GET') {
      return _jsonResponse(HttpStatus.ok, <String, Object?>{
        'ok': true,
        'tools': _toolDefinitions(),
      });
    }

    if (request.url.path == 'mcp/call' && request.method == 'POST') {
      return _handleCallStyleRequest(request);
    }

    if (request.url.path == 'mcp/tool' && request.method == 'POST') {
      return _handleLegacyToolRequest(request);
    }

    return _errorResponse(
      HttpStatus.notFound,
      code: 'route_not_found',
      message: 'Unsupported MCP route.',
      recoverable: false,
    );
  }

  Future<Response> _handleLegacyToolRequest(Request request) async {
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
      return _buildToolResultResponse(result);
    } on FormatException {
      return _validationError('Invalid JSON payload.');
    } catch (_) {
      return _errorResponse(
        HttpStatus.internalServerError,
        code: 'mcp_internal_error',
        message: 'Unexpected server error.',
        recoverable: false,
      );
    }
  }

  Future<Response> _handleCallStyleRequest(Request request) async {
    try {
      final dynamic json = jsonDecode(await request.readAsString());
      if (json is! Map<String, dynamic>) {
        return _validationError('Request body must be a JSON object.');
      }

      final tool = json['tool'];
      final input = json['input'];
      if (tool is! String || tool.isEmpty) {
        return _validationError('Missing or invalid tool field.');
      }
      if (input != null && input is! Map<String, dynamic>) {
        return _validationError('Input must be a JSON object.');
      }

      final result = await _toolRouter.callTool(
        tool,
        arguments: (input ?? <String, dynamic>{}).cast<String, Object?>(),
      );
      return _buildToolResultResponse(result);
    } on FormatException {
      return _validationError('Invalid JSON payload.');
    } catch (_) {
      return _errorResponse(
        HttpStatus.internalServerError,
        code: 'mcp_internal_error',
        message: 'Unexpected server error.',
        recoverable: false,
      );
    }
  }

  Response _buildToolResultResponse(McpToolResult result) {
    if (result.ok) {
      return _jsonResponse(HttpStatus.ok, <String, Object?>{
        'ok': true,
        'status': result.data,
      });
    }
    return _errorResponse(
      HttpStatus.badRequest,
      code: result.errorCode ?? 'mcp_internal_error',
      message: result.errorMessage ?? 'MCP tool call failed.',
      details: result.data,
      recoverable: true,
    );
  }

  Response _validationError(String message) {
    return _errorResponse(
      HttpStatus.badRequest,
      code: 'validation_error',
      message: message,
      recoverable: true,
    );
  }

  Response _errorResponse(
    int statusCode, {
    required String code,
    required String message,
    required bool recoverable,
    Map<String, Object?>? details,
  }) {
    return _jsonResponse(statusCode, <String, Object?>{
      'ok': false,
      'error': <String, Object?>{
        'code': code,
        'message': message,
        'recoverable': recoverable,
        'details': details,
      },
    });
  }

  List<Map<String, Object?>> _toolDefinitions() {
    return <Map<String, Object?>>[
      <String, Object?>{
        'name': 'set_suck',
        'description': 'Set suck intensity and mode.',
      },
      <String, Object?>{
        'name': 'set_vibe',
        'description': 'Set vibe intensity and mode.',
      },
      <String, Object?>{
        'name': 'set_ems',
        'description':
            'Set EMS intensity and mode (soft limit requires confirmation).',
      },
      <String, Object?>{
        'name': 'set_all',
        'description': 'Set all channels in one logical request.',
      },
      <String, Object?>{
        'name': 'stop_all',
        'description': 'Stop all channels immediately.',
      },
      <String, Object?>{
        'name': 'get_status',
        'description': 'Get active device status.',
      },
    ];
  }

  Response _jsonResponse(int statusCode, Map<String, Object?> body) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}
