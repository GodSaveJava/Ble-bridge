class RemoteBridgeProbeResult {
  const RemoteBridgeProbeResult({
    required this.isSuccess,
    required this.summary,
    this.detail,
  });

  final bool isSuccess;
  final String summary;
  final String? detail;
}
