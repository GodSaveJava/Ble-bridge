import '../../domain/entities/remote_bridge_task_result.dart';

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
    return <String, Object?>{
      clientIdField: clientId,
    };
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
      resultField: result.result,
      errorCodeField: result.errorCode,
      errorMessageField: result.errorMessage,
    };
  }
}
