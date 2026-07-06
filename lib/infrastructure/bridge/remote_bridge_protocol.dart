import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/entities/remote_bridge_task_assignment.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/entities/remote_bridge_payload_sanitizer.dart';

abstract final class RemoteBridgeProtocol {
  static const String sessionStartPath = '/mobile-bridge/session/start';

  static String sessionRefreshPath(String bridgeSessionId) {
    return '/mobile-bridge/session/$bridgeSessionId/refresh';
  }

  static String sessionNextTaskPath(String bridgeSessionId) {
    return '/mobile-bridge/session/$bridgeSessionId/next-task';
  }

  static String sessionTaskResultPath(String bridgeSessionId) {
    return '/mobile-bridge/session/$bridgeSessionId/task-result';
  }

  static String sessionStopPath(String bridgeSessionId) {
    return '/mobile-bridge/session/$bridgeSessionId/stop';
  }

  static const String clientIdField = 'clientId';
  static const String requestIdField = 'requestId';
  static const String toolField = 'tool';
  static const String inputField = 'input';
  static const String okField = 'ok';
  static const String resultField = 'result';
  static const String errorCodeField = 'errorCode';
  static const String errorMessageField = 'errorMessage';
  static const String bridgeSessionIdField = 'bridgeSessionId';
  static const String connectorUrlField = 'connectorUrl';
  static const String connectorTokenField = 'connectorToken';
  static const String toolNamesField = 'toolNames';
  static const String statusField = 'status';

  static Map<String, Object?> sessionRequestBody(String clientId) {
    return <String, Object?>{clientIdField: clientId};
  }

  static Map<String, Object?> taskResultRequestBody(
    String clientId,
    RemoteBridgeTaskResult result,
  ) {
    return <String, Object?>{
      clientIdField: clientId,
      requestIdField: result.requestId,
      toolField: result.tool,
      okField: result.ok,
      resultField: RemoteBridgePayloadSanitizer.sanitizeMap(result.result),
      errorCodeField: result.errorCode,
      errorMessageField: result.errorMessage,
    };
  }

  static RemoteBridgeSession parseSessionResponse(
    Map<String, dynamic> json, {
    required RemoteBridgeSession fallback,
  }) {
    final String bridgeSessionId =
        json[bridgeSessionIdField] as String? ?? fallback.bridgeSessionId ?? '';
    final String connectorUrl = json[connectorUrlField] as String? ?? '';
    final String connectorToken = json[connectorTokenField] as String? ?? '';
    final List<String> toolNames =
        (json[toolNamesField] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString())
            .toList();

    return RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.ready,
      bridgeSessionId: bridgeSessionId,
      connectorInfo: RemoteBridgeConnectorInfo(
        connectorUrl: connectorUrl,
        connectorToken: connectorToken,
        toolNames: toolNames,
      ),
      lastUpdatedAt: DateTime.now(),
    );
  }

  static RemoteBridgeTaskAssignment? parseTaskAssignmentResponse(
    Map<String, dynamic>? json,
  ) {
    if (json == null || json.isEmpty) {
      return null;
    }

    final Object? requestId = json[requestIdField];
    final Object? tool = json[toolField];
    final Object? input = json[inputField];
    if (requestId is! String || requestId.isEmpty) {
      return null;
    }
    if (tool is! String || tool.isEmpty) {
      return null;
    }
    if (input != null && input is! Map<String, dynamic>) {
      return null;
    }

    return RemoteBridgeTaskAssignment(
      requestId: requestId,
      tool: tool,
      input: (input as Map<String, dynamic>? ?? const <String, dynamic>{})
          .cast<String, Object?>(),
    );
  }
}
