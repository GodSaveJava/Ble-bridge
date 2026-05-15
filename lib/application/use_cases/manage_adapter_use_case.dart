import 'dart:convert';

import '../services/adapter_registry.dart';
import '../services/adapter_validator.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/adapter_manifest.dart';
import '../../domain/entities/verified_adapter_record.dart';
import '../../domain/services/adapter_export_service.dart';

class AdapterVerificationInput {
  const AdapterVerificationInput({
    required this.adapterId,
    required this.deviceFingerprint,
    required this.gattFingerprint,
    required this.appVersion,
    this.firmwareRevision,
    this.stepResults = const <VerificationStepResult>[],
  });

  final String adapterId;
  final String deviceFingerprint;
  final String gattFingerprint;
  final String appVersion;
  final String? firmwareRevision;
  final List<VerificationStepResult> stepResults;
}

class ManageAdapterUseCase {
  const ManageAdapterUseCase({
    required AdapterRegistry adapterRegistry,
    required AdapterValidator adapterValidator,
    required AdapterExportService adapterExportService,
  }) : _adapterRegistry = adapterRegistry,
       _adapterValidator = adapterValidator,
       _adapterExportService = adapterExportService;

  final AdapterRegistry _adapterRegistry;
  final AdapterValidator _adapterValidator;
  final AdapterExportService _adapterExportService;

  Stream<List<AdapterManifest>> watchAvailableAdapters() {
    return _adapterRegistry.watchAvailableManifests();
  }

  Future<void> importManifestJson(Map<String, Object?> json) async {
    final AdapterManifest manifest = AdapterManifest.fromJson(json);
    await _adapterRegistry.importManifestJson(json);
    await _adapterValidator.markNeedsReverifyForManifestChange(
      adapterId: manifest.adapterId,
      nextManifestHash: _manifestHash(manifest),
    );
  }

  Future<AdapterManifest> requireManifest(String adapterId) {
    return _adapterRegistry.requireManifest(adapterId);
  }

  Future<void> removeManifest(String adapterId) {
    return _adapterRegistry.removeManifest(adapterId);
  }

  Future<String> exportManifestJson(String adapterId) async {
    final AdapterManifest manifest = await _adapterRegistry.requireManifest(
      adapterId,
    );
    return const JsonEncoder.withIndent('  ').convert(manifest.toJson());
  }

  Future<String> saveManifestJsonFile(String adapterId) async {
    final String jsonText = await exportManifestJson(adapterId);
    return _adapterExportService.saveJson(
      suggestedFileName: '$adapterId.json',
      jsonText: jsonText,
    );
  }

  Future<void> revokeVerification({
    required String adapterId,
    required String deviceFingerprint,
  }) {
    return _adapterValidator.revoke(
      adapterId: adapterId,
      deviceFingerprint: deviceFingerprint,
    );
  }

  Future<VerifiedAdapterRecord> markVerificationPassed(
    AdapterVerificationInput input,
  ) async {
    final AdapterManifest manifest = await _adapterRegistry.requireManifest(
      input.adapterId,
    );
    final List<VerificationStepResult> steps = input.stepResults;
    if (steps.isEmpty) {
      throw const Failure.adapterVerificationFailed(
        message: 'Verification steps cannot be empty.',
      );
    }
    final bool hasStopStep = steps.any(
      (VerificationStepResult e) => e.stepKey == 'stop_all',
    );
    if (!hasStopStep) {
      throw const Failure.adapterVerificationFailed(
        message: 'Verification must include stop_all step.',
      );
    }

    return _adapterValidator.markVerified(
      manifest: manifest,
      manifestHash: _manifestHash(manifest),
      appVersion: input.appVersion,
      target: VerifiedTarget(
        deviceFingerprint: input.deviceFingerprint,
        gattFingerprint: input.gattFingerprint,
        firmwareRevision: input.firmwareRevision,
      ),
      stepResults: input.stepResults,
    );
  }

  Future<bool> isAdapterVerifiedForDevice({
    required String adapterId,
    required String deviceFingerprint,
  }) {
    return _adapterRegistry.isVerified(
      adapterId: adapterId,
      deviceFingerprint: deviceFingerprint,
    );
  }

  String _manifestHash(AdapterManifest manifest) {
    return base64Url.encode(utf8.encode(jsonEncode(manifest.toJson())));
  }
}
