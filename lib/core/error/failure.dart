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
  adapterSchemaInvalid,
  adapterNotVerified,
  adapterConflict,
  adapterVerificationFailed,
  adapterRevoked,
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

  const Failure.adapterSchemaInvalid({
    String message = 'Adapter manifest schema is invalid.',
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.adapterSchemaInvalid,
         message: message,
         debugMessage: debugMessage,
         details: details,
       );

  const Failure.adapterNotVerified({
    String message = 'Adapter has not been verified on this device.',
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.adapterNotVerified,
         message: message,
         debugMessage: debugMessage,
         details: details,
       );

  const Failure.adapterConflict({
    String message = 'Adapter does not match the connected device.',
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.adapterConflict,
         message: message,
         debugMessage: debugMessage,
         details: details,
       );

  const Failure.adapterVerificationFailed({
    String message = 'Adapter verification failed.',
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.adapterVerificationFailed,
         message: message,
         debugMessage: debugMessage,
         details: details,
       );

  const Failure.adapterRevoked({
    String message = 'Adapter verification was revoked.',
    String? debugMessage,
    Map<String, Object?>? details,
  }) : this(
         code: FailureCode.adapterRevoked,
         message: message,
         debugMessage: debugMessage,
         details: details,
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
