class VerifiedTarget {
  const VerifiedTarget({
    required this.deviceFingerprint,
    required this.gattFingerprint,
    this.firmwareRevision,
  });

  final String deviceFingerprint;
  final String gattFingerprint;
  final String? firmwareRevision;

  Map<String, Object?> toJson() => <String, Object?>{
    'deviceFingerprint': deviceFingerprint,
    'gattFingerprint': gattFingerprint,
    'firmwareRevision': firmwareRevision,
  };

  static VerifiedTarget fromJson(Map<String, Object?> json) {
    final Object? deviceFingerprintValue = json['deviceFingerprint'];
    final Object? gattFingerprintValue = json['gattFingerprint'];
    if (deviceFingerprintValue is! String || gattFingerprintValue is! String) {
      throw const FormatException('Invalid verified target payload.');
    }
    return VerifiedTarget(
      deviceFingerprint: deviceFingerprintValue,
      gattFingerprint: gattFingerprintValue,
      firmwareRevision: json['firmwareRevision'] as String?,
    );
  }
}

enum AdapterVerificationStatus {
  unverified,
  verified,
  failed,
  revoked,
  needsReverify,
}

class VerificationStepResult {
  const VerificationStepResult({
    required this.stepKey,
    required this.passed,
    this.skipped = false,
    this.message,
  });

  final String stepKey;
  final bool passed;
  final bool skipped;
  final String? message;

  Map<String, Object?> toJson() => <String, Object?>{
    'stepKey': stepKey,
    'passed': passed,
    'skipped': skipped,
    'message': message,
  };

  static VerificationStepResult fromJson(Map<String, Object?> json) {
    final Object? stepKeyValue = json['stepKey'];
    final Object? passedValue = json['passed'];
    final Object? skippedValue = json['skipped'];
    if (stepKeyValue is! String ||
        passedValue is! bool ||
        skippedValue is! bool) {
      throw const FormatException('Invalid verification step payload.');
    }
    return VerificationStepResult(
      stepKey: stepKeyValue,
      passed: passedValue,
      skipped: skippedValue,
      message: json['message'] as String?,
    );
  }
}

class VerifiedAdapterRecord {
  const VerifiedAdapterRecord({
    required this.manifestHash,
    required this.adapterId,
    required this.adapterVersion,
    required this.status,
    required this.updatedAt,
    required this.verifiedByAppVersion,
    required this.target,
    required this.stepResults,
    this.revokedReason,
  });

  final String manifestHash;
  final String adapterId;
  final String adapterVersion;
  final AdapterVerificationStatus status;
  final DateTime updatedAt;
  final String verifiedByAppVersion;
  final VerifiedTarget target;
  final List<VerificationStepResult> stepResults;
  final String? revokedReason;

  bool get isVerified => status == AdapterVerificationStatus.verified;

  VerifiedAdapterRecord markNeedsReverify({required String reason}) {
    return VerifiedAdapterRecord(
      manifestHash: manifestHash,
      adapterId: adapterId,
      adapterVersion: adapterVersion,
      status: AdapterVerificationStatus.needsReverify,
      updatedAt: DateTime.now(),
      verifiedByAppVersion: verifiedByAppVersion,
      target: target,
      stepResults: stepResults,
      revokedReason: reason,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'manifestHash': manifestHash,
    'adapterId': adapterId,
    'adapterVersion': adapterVersion,
    'status': status.name,
    'updatedAt': updatedAt.toIso8601String(),
    'verifiedByAppVersion': verifiedByAppVersion,
    'target': target.toJson(),
    'stepResults': stepResults.map((e) => e.toJson()).toList(),
    'revokedReason': revokedReason,
  };

  static VerifiedAdapterRecord fromJson(Map<String, Object?> json) {
    final Object? statusValue = json['status'];
    final Object? updatedAtValue = json['updatedAt'];
    final Object? targetValue = json['target'];
    final Object? stepResultsValue = json['stepResults'];
    if (statusValue is! String ||
        updatedAtValue is! String ||
        targetValue is! Map<String, Object?> ||
        stepResultsValue is! List<Object?>) {
      throw const FormatException('Invalid verified adapter record payload.');
    }
    final AdapterVerificationStatus status = AdapterVerificationStatus.values
        .firstWhere((e) => e.name == statusValue);
    return VerifiedAdapterRecord(
      manifestHash: json['manifestHash'] as String,
      adapterId: json['adapterId'] as String,
      adapterVersion: json['adapterVersion'] as String,
      status: status,
      updatedAt: DateTime.parse(updatedAtValue),
      verifiedByAppVersion: json['verifiedByAppVersion'] as String,
      target: VerifiedTarget.fromJson(targetValue),
      stepResults: stepResultsValue
          .cast<Map<String, Object?>>()
          .map(VerificationStepResult.fromJson)
          .toList(),
      revokedReason: json['revokedReason'] as String?,
    );
  }
}
