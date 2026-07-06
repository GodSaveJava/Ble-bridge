import 'mcp_tool_router.dart';
import 'remote_bridge_tool_dispatcher.dart';

class RemoteBridgeToolCallHandler {
  RemoteBridgeToolCallHandler({
    required RemoteBridgeToolDispatcher dispatcher,
  }) : _dispatcher = dispatcher;

  final RemoteBridgeToolDispatcher _dispatcher;

  Future<Map<String, Object?>> handle(Object? payload) async {
    if (payload is! Map<String, dynamic>) {
      return _validationError('Request body must be a JSON object.');
    }

    final Object? requestId = payload['requestId'];
    final Object? tool = payload['tool'];
    final Object? input = payload['input'];

    if (tool is! String || tool.isEmpty) {
      return _errorEnvelope(
        requestId: requestId,
        code: 'validation_error',
        message: 'Missing or invalid tool field.',
        recoverable: true,
      );
    }

    if (input != null && input is! Map<String, dynamic>) {
      return _errorEnvelope(
        requestId: requestId,
        code: 'validation_error',
        message: 'Input must be a JSON object.',
        recoverable: true,
      );
    }

    final Map<String, dynamic> parsedInput = input is Map<String, dynamic>
        ? input
        : <String, dynamic>{};

    final McpToolResult result = await _dispatcher.dispatchTool(
      tool,
      arguments: parsedInput.cast<String, Object?>(),
    );

    if (result.ok) {
      return <String, Object?>{
        'ok': true,
        'requestId': requestId,
        'tool': tool,
        'result': result.data,
      };
    }

    return _errorEnvelope(
      requestId: requestId,
      code: result.errorCode ?? 'mcp_internal_error',
      message: result.errorMessage ?? 'Remote bridge tool call failed.',
      details: result.data,
      recoverable: true,
    );
  }

  Map<String, Object?> _validationError(String message) {
    return _errorEnvelope(
      code: 'validation_error',
      message: message,
      recoverable: true,
    );
  }

  Map<String, Object?> _errorEnvelope({
    Object? requestId,
    required String code,
    required String message,
    required bool recoverable,
    Map<String, Object?>? details,
  }) {
    return <String, Object?>{
      'ok': false,
      'requestId': requestId,
      'error': <String, Object?>{
        'code': code,
        'message': message,
        'recoverable': recoverable,
        'details': details,
      },
    };
  }
}
