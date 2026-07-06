import 'mcp_tool_router.dart';
import 'safety_v0_tools.dart';
import '../../domain/entities/remote_bridge_payload_sanitizer.dart';

class RemoteBridgeToolDispatcher {
  RemoteBridgeToolDispatcher({required McpToolRouter mcpToolRouter})
    : _mcpToolRouter = mcpToolRouter;

  static const Set<String> enabledToolNames = SafetyV0Tools.names;

  final McpToolRouter _mcpToolRouter;

  Future<McpToolResult> dispatchTool(
    String toolName, {
    Map<String, Object?> arguments = const <String, Object?>{},
  }) async {
    if (!enabledToolNames.contains(toolName)) {
      return McpToolResult(
        ok: false,
        errorCode: 'tool_not_enabled_for_bridge',
        errorMessage: 'Remote bridge has not enabled this tool yet: $toolName',
        data: <String, Object?>{
          'toolName': toolName,
          'enabledToolNames': enabledToolNames.toList(),
        },
      );
    }

    final McpToolResult result = await _mcpToolRouter.callTool(
      toolName,
      arguments: arguments,
    );
    if (!result.ok) {
      return result;
    }
    return McpToolResult(
      ok: true,
      data: RemoteBridgePayloadSanitizer.sanitizeMap(result.data),
    );
  }
}
