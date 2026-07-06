class RemoteBridgeTaskResult {
  const RemoteBridgeTaskResult({
    required this.ok,
    this.requestId,
    this.tool,
    this.result,
    this.errorCode,
    this.errorMessage,
  });

  final bool ok;
  final String? requestId;
  final String? tool;
  final Map<String, dynamic>? result;
  final String? errorCode;
  final String? errorMessage;
}
