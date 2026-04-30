enum FailureCode {
  validation,
  permissionDenied,
  bluetoothUnavailable,
  scanFailed,
  deviceNotFound,
  deviceConnection,
  deviceDisconnected,
  deviceWrite,
  protocolUnsupported,
  noActiveDevice,
  mcpServer,
  storage,
  securityLock,
  unknown,
}

class Failure implements Exception {
  const Failure({
    required this.code,
    required this.message,
    this.debugMessage,
    this.recoverable = true,
    this.details,
  });

  final FailureCode code;
  final String message;
  final String? debugMessage;
  final bool recoverable;
  final Map<String, Object?>? details;

  const Failure.validation({
    required String message,
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.validation,
         message: message,
         debugMessage: debugMessage,
         details: details,
       );

  const Failure.noActiveDevice({
    String message = 'No active device is connected.',
    String? debugMessage,
  }) : this(
         code: FailureCode.noActiveDevice,
         message: message,
         debugMessage: debugMessage,
       );

  const Failure.unknown({
    String message = 'Unknown error occurred.',
    String? debugMessage,
  }) : this(
         code: FailureCode.unknown,
         message: message,
         debugMessage: debugMessage,
         recoverable: false,
       );
}
