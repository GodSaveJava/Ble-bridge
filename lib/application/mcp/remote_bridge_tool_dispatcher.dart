import 'mcp_tool_router.dart';

class RemoteBridgeToolDispatcher {
  RemoteBridgeToolDispatcher({required McpToolRouter mcpToolRouter})
    : _mcpToolRouter = mcpToolRouter;

  static const Set<String> enabledToolNames = <String>{
    'get_status',
    'stop_all',
  };

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

    return _mcpToolRouter.callTool(toolName, arguments: arguments);
  }
}
