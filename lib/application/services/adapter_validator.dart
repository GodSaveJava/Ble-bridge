import '../../core/error/failure.dart';
import '../../domain/entities/adapter_manifest.dart';
import '../../domain/entities/verified_adapter_record.dart';
import '../../domain/repositories/verified_adapter_repository.dart';

class AdapterValidator {
  AdapterValidator({
    required VerifiedAdapterRepository verifiedAdapterRepository,
  }) : _verifiedAdapterRepository = verifiedAdapterRepository;

  final VerifiedAdapterRepository _verifiedAdapterRepository;

  Future<VerifiedAdapterRecord> markVerified({
    required AdapterManifest manifest,
    required String manifestHash,
    required String appVersion,
    required VerifiedTarget target,
    required List<VerificationStepResult> stepResults,
  }) async {
    final bool hasFailingStep = stepResults.any(
      (VerificationStepResult step) => !step.passed && !step.skipped,
    );
    if (hasFailingStep) {
      throw const Failure.adapterVerificationFailed(
        message: 'Cannot mark adapter as verified with failed steps.',
      );
    }

    final VerifiedAdapterRecord record = VerifiedAdapterRecord(
      manifestHash: manifestHash,
      adapterId: manifest.adapterId,
      adapterVersion: manifest.version,
      status: AdapterVerificationStatus.verified,
      updatedAt: DateTime.now(),
      verifiedByAppVersion: appVersion,
      target: target,
      stepResults: stepResults,
    );
    await _verifiedAdapterRepository.save(record);
    return record;
  }

  Future<VerifiedAdapterRecord> markVerificationFailed({
    required AdapterManifest manifest,
    required String manifestHash,
    required String appVersion,
    required VerifiedTarget target,
    required List<VerificationStepResult> stepResults,
    required String reason,
  }) async {
    final VerifiedAdapterRecord record = VerifiedAdapterRecord(
      manifestHash: manifestHash,
      adapterId: manifest.adapterId,
      adapterVersion: manifest.version,
      status: AdapterVerificationStatus.failed,
      updatedAt: DateTime.now(),
      verifiedByAppVersion: appVersion,
      target: target,
      stepResults: stepResults,
      revokedReason: reason,
    );
    await _verifiedAdapterRepository.save(record);
    return record;
  }

  Future<void> revoke({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    final VerifiedAdapterRecord? current = await _verifiedAdapterRepository
        .find(adapterId: adapterId, deviceFingerprint: deviceFingerprint);
    if (current == null) {
      throw const Failure.adapterNotVerified(
        message: 'No local verified adapter record exists.',
      );
    }
    final VerifiedAdapterRecord revoked = VerifiedAdapterRecord(
      manifestHash: current.manifestHash,
      adapterId: current.adapterId,
      adapterVersion: current.adapterVersion,
      status: AdapterVerificationStatus.revoked,
      updatedAt: DateTime.now(),
      verifiedByAppVersion: current.verifiedByAppVersion,
      target: current.target,
      stepResults: current.stepResults,
      revokedReason: 'revoked_by_user',
    );
    await _verifiedAdapterRepository.save(revoked);
  }

  Future<void> markNeedsReverifyForManifestChange({
    required String adapterId,
    required String nextManifestHash,
  }) async {
    final List<VerifiedAdapterRecord> records = await _verifiedAdapterRepository
        .watchAll()
        .first;
    for (final record in records) {
      if (record.adapterId != adapterId) {
        continue;
      }
      if (record.status != AdapterVerificationStatus.verified) {
        continue;
      }
      if (record.manifestHash == nextManifestHash) {
        continue;
      }
      await _verifiedAdapterRepository.save(
        record.markNeedsReverify(reason: 'manifest_changed'),
      );
    }
  }
}
