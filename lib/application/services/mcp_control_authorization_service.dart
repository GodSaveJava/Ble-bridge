import '../../core/error/failure.dart';
import '../../domain/entities/active_adapter_binding.dart';
import '../../domain/entities/verified_adapter_record.dart';
import '../registry/active_device_registry.dart';
import 'adapter_registry.dart';

/// Centralizes the MCP-side permission check for hardware control tools.
///
/// MVP rule:
/// - read-only `get_status` is allowed without adapter verification
/// - emergency `stop_all` is always allowed
/// - all other control tools require at least one effective `verified` record
///   for the currently active device fingerprint
class McpControlAuthorizationService {
  const McpControlAuthorizationService({
    required ActiveDeviceRegistry activeDeviceRegistry,
    required AdapterRegistry adapterRegistry,
  }) : _activeDeviceRegistry = activeDeviceRegistry,
       _adapterRegistry = adapterRegistry;

  final ActiveDeviceRegistry _activeDeviceRegistry;
  final AdapterRegistry _adapterRegistry;

  Future<void> ensureToolAllowed(String toolName) async {
    if (_isAlwaysAllowed(toolName) || !_requiresVerifiedAdapter(toolName)) {
      return;
    }

    final String deviceFingerprint = _activeDeviceRegistry
        .requireActiveDevice()
        .id;
    final ActiveAdapterBinding? binding = await _adapterRegistry
        .getBindingForDevice(deviceFingerprint);
    if (binding != null) {
      final VerifiedAdapterRecord? record = await _adapterRegistry
          .getVerificationRecord(
            adapterId: binding.adapterId,
            deviceFingerprint: deviceFingerprint,
          );
      if (record != null) {
        _throwIfRecordBlocks(
          toolName: toolName,
          deviceFingerprint: deviceFingerprint,
          record: record,
        );
        if (record.status == AdapterVerificationStatus.verified) {
          return;
        }
      } else {
        throw Failure.adapterNotVerified(
          message: 'The bound adapter has not completed verification.',
          details: <String, Object?>{
            'tool': toolName,
            'deviceFingerprint': deviceFingerprint,
            'adapterId': binding.adapterId,
          },
        );
      }
    }

    final List<VerifiedAdapterRecord> deviceRecords = await _adapterRegistry
        .getVerificationRecordsForDevice(deviceFingerprint);

    if (deviceRecords.any(
      (VerifiedAdapterRecord record) =>
          record.status == AdapterVerificationStatus.verified,
    )) {
      return;
    }

    final VerifiedAdapterRecord? revokedRecord = _latestMatchingRecord(
      deviceRecords,
      statuses: const <AdapterVerificationStatus>[
        AdapterVerificationStatus.revoked,
      ],
    );
    if (revokedRecord != null) {
      _throwIfRecordBlocks(
        toolName: toolName,
        deviceFingerprint: deviceFingerprint,
        record: revokedRecord,
      );
    }

    final VerifiedAdapterRecord? failedRecord = _latestMatchingRecord(
      deviceRecords,
      statuses: const <AdapterVerificationStatus>[
        AdapterVerificationStatus.failed,
        AdapterVerificationStatus.needsReverify,
      ],
    );
    if (failedRecord != null) {
      _throwIfRecordBlocks(
        toolName: toolName,
        deviceFingerprint: deviceFingerprint,
        record: failedRecord,
      );
    }

    throw Failure.adapterNotVerified(
      message: 'The active device has not completed adapter verification.',
      details: <String, Object?>{
        'tool': toolName,
        'deviceFingerprint': deviceFingerprint,
      },
    );
  }

  bool _isAlwaysAllowed(String toolName) => toolName == 'stop_all';

  bool _requiresVerifiedAdapter(String toolName) {
    return switch (toolName) {
      'set_suck' || 'set_vibe' || 'set_ems' || 'set_all' => true,
      _ => false,
    };
  }

  void _throwIfRecordBlocks({
    required String toolName,
    required String deviceFingerprint,
    required VerifiedAdapterRecord record,
  }) {
    if (record.status == AdapterVerificationStatus.revoked) {
      throw Failure.adapterRevoked(
        message: 'The active device adapter verification was revoked.',
        details: _details(
          toolName: toolName,
          deviceFingerprint: deviceFingerprint,
          record: record,
        ),
      );
    }
    if (record.status == AdapterVerificationStatus.failed ||
        record.status == AdapterVerificationStatus.needsReverify) {
      throw Failure.adapterVerificationFailed(
        message:
            'The active device adapter must be verified again before AI control.',
        details: _details(
          toolName: toolName,
          deviceFingerprint: deviceFingerprint,
          record: record,
        ),
      );
    }
  }

  VerifiedAdapterRecord? _latestMatchingRecord(
    List<VerifiedAdapterRecord> records, {
    required List<AdapterVerificationStatus> statuses,
  }) {
    final Iterable<VerifiedAdapterRecord> candidates = records.where(
      (VerifiedAdapterRecord record) => statuses.contains(record.status),
    );
    if (candidates.isEmpty) {
      return null;
    }
    final List<VerifiedAdapterRecord> sorted = candidates.toList()
      ..sort(
        (VerifiedAdapterRecord a, VerifiedAdapterRecord b) =>
            b.updatedAt.compareTo(a.updatedAt),
      );
    return sorted.first;
  }

  Map<String, Object?> _details({
    required String toolName,
    required String deviceFingerprint,
    required VerifiedAdapterRecord record,
  }) {
    return <String, Object?>{
      'tool': toolName,
      'deviceFingerprint': deviceFingerprint,
      'adapterId': record.adapterId,
      'verificationStatus': record.status.name,
    };
  }
}
