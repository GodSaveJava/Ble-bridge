abstract final class SafetyV0Tools {
  static const Set<String> names = <String>{getStatus, stopAll};

  static const String getStatus = 'get_status';
  static const String stopAll = 'stop_all';

  static bool contains(String toolName) => names.contains(toolName);
}
