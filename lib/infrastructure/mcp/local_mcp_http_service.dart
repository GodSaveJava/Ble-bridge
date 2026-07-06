import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../application/mcp/mcp_tool_router.dart';
import '../../application/mcp/remote_bridge_tool_call_handler.dart';
import '../../application/mcp/safety_v0_tools.dart';
import '../../domain/entities/remote_bridge_payload_sanitizer.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/mcp_service.dart';

typedef RemoteBridgeTaskAssignmentCallback =
    Future<RemoteBridgeTaskResult> Function(Object? payload);

class LocalMcpHttpService implements McpService {
  LocalMcpHttpService({
    required McpToolRouter toolRouter,
    required RemoteBridgeToolCallHandler remoteBridgeToolCallHandler,
    RemoteBridgeTaskAssignmentCallback? remoteBridgeTaskAssignmentHandler,
    this.host = '127.0.0.1',
    this.port = 8765,
    this.authToken = 'toylink-local-mcp-dev-token',
    this.enabledToolNames = SafetyV0Tools.names,
  }) : _toolRouter = toolRouter,
       _remoteBridgeToolCallHandler = remoteBridgeToolCallHandler,
       _remoteBridgeTaskAssignmentHandler = remoteBridgeTaskAssignmentHandler;

  final McpToolRouter _toolRouter;
  final RemoteBridgeToolCallHandler _remoteBridgeToolCallHandler;
  final RemoteBridgeTaskAssignmentCallback? _remoteBridgeTaskAssignmentHandler;
  final String host;
  final int port;
  final String authToken;
  final Set<String> enabledToolNames;

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

    if (!_isAuthenticated(request)) {
      return _errorResponse(
        HttpStatus.unauthorized,
        code: 'unauthorized',
        message: 'Missing or invalid local MCP token.',
        recoverable: true,
      );
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

    if (request.url.path == 'mobile-bridge/tool-call' &&
        request.method == 'POST') {
      return _handleRemoteBridgeToolCall(request);
    }

    if (request.url.path == 'mobile-bridge/task-assignment' &&
        request.method == 'POST') {
      return _handleRemoteBridgeTaskAssignment(request);
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
      final Response? allowlistError = _rejectIfToolDisabled(name);
      if (allowlistError != null) {
        return allowlistError;
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
      final Response? allowlistError = _rejectIfToolDisabled(tool);
      if (allowlistError != null) {
        return allowlistError;
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

  Future<Response> _handleRemoteBridgeToolCall(Request request) async {
    try {
      final dynamic json = jsonDecode(await request.readAsString());
      final Map<String, Object?> response = await _remoteBridgeToolCallHandler
          .handle(json);
      return _jsonResponse(
        response['ok'] == true ? HttpStatus.ok : HttpStatus.badRequest,
        response,
      );
    } on FormatException {
      return _jsonResponse(
        HttpStatus.badRequest,
        await _remoteBridgeToolCallHandler.handle(null),
      );
    } catch (_) {
      return _errorResponse(
        HttpStatus.internalServerError,
        code: 'bridge_tool_call_failed',
        message: 'Unexpected remote bridge tool error.',
        recoverable: false,
      );
    }
  }

  Future<Response> _handleRemoteBridgeTaskAssignment(Request request) async {
    final RemoteBridgeTaskAssignmentCallback? handler =
        _remoteBridgeTaskAssignmentHandler;
    if (handler == null) {
      return _errorResponse(
        HttpStatus.serviceUnavailable,
        code: 'bridge_task_assignment_unavailable',
        message: 'Remote bridge task assignment is not configured.',
        recoverable: true,
      );
    }

    try {
      final dynamic json = jsonDecode(await request.readAsString());
      final RemoteBridgeTaskResult result = await handler(json);
      return _buildRemoteBridgeTaskResultResponse(result);
    } on FormatException {
      return _buildRemoteBridgeTaskResultResponse(await handler(null));
    } catch (_) {
      return _errorResponse(
        HttpStatus.internalServerError,
        code: 'bridge_task_assignment_failed',
        message: 'Unexpected remote bridge task assignment error.',
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

  Response? _rejectIfToolDisabled(String toolName) {
    if (enabledToolNames.contains(toolName)) {
      return null;
    }
    return _errorResponse(
      HttpStatus.badRequest,
      code: 'tool_not_enabled_for_mcp_safety_v0',
      message: 'Local MCP Safety V0 only allows get_status and stop_all.',
      recoverable: true,
      details: <String, Object?>{
        'toolName': toolName,
        'enabledToolNames': enabledToolNames.toList(growable: false),
      },
    );
  }

  bool _isAuthenticated(Request request) {
    if (authToken.trim().isEmpty) {
      return true;
    }
    final String token =
        request.headers[HttpHeaders.authorizationHeader] ??
        request.headers['x-mcp-token'] ??
        '';
    return token == 'Bearer $authToken' || token == authToken;
  }

  Response _buildRemoteBridgeTaskResultResponse(RemoteBridgeTaskResult result) {
    if (result.ok) {
      return _jsonResponse(HttpStatus.ok, <String, Object?>{
        'ok': true,
        'requestId': result.requestId,
        'tool': result.tool,
        'result': RemoteBridgePayloadSanitizer.sanitizeMap(result.result),
      });
    }

    return _jsonResponse(HttpStatus.badRequest, <String, Object?>{
      'ok': false,
      'requestId': result.requestId,
      'tool': result.tool,
      'error': <String, Object?>{
        'code': result.errorCode ?? 'bridge_task_assignment_failed',
        'message':
            result.errorMessage ?? 'Remote bridge task assignment failed.',
        'recoverable': true,
      },
    });
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
      if (enabledToolNames.contains(SafetyV0Tools.stopAll))
        <String, Object?>{
          'name': 'stop_all',
          'description': 'Stop all channels immediately.',
        },
      if (enabledToolNames.contains(SafetyV0Tools.getStatus))
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
