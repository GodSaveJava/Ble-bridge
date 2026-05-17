import '../../domain/entities/verified_adapter_record.dart';

enum ActiveDeviceAdapterReadinessState {
  noDevice,
  noBinding,
  bindingMissing,
  unverified,
  verified,
  revoked,
  needsReverify,
  verificationFailed,
}

class ActiveDeviceAdapterReadiness {
  const ActiveDeviceAdapterReadiness({
    required this.state,
    this.deviceId,
    this.adapterId,
    this.adapterDisplayName,
    this.verificationStatus,
  });

  final ActiveDeviceAdapterReadinessState state;
  final String? deviceId;
  final String? adapterId;
  final String? adapterDisplayName;
  final AdapterVerificationStatus? verificationStatus;

  bool get canControlViaMcp =>
      state == ActiveDeviceAdapterReadinessState.verified;
}
