import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/services/adapter_registry.dart';
import 'package:toylink_ai/application/services/adapter_validator.dart';
import 'package:toylink_ai/application/use_cases/manage_adapter_use_case.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/domain/services/adapter_export_service.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/adapter_verification_controller.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  test('submit fails when stop_all is unchecked', () async {
    final _InMemoryManifestRepository manifestRepository =
        _InMemoryManifestRepository();
    final _InMemoryVerifiedRepository verifiedRepository =
        _InMemoryVerifiedRepository();
    final _InMemoryActiveBindingRepository activeBindingRepository =
        _InMemoryActiveBindingRepository();
    final AdapterRegistry registry = AdapterRegistry(
      adapterManifestRepository: manifestRepository,
      verifiedAdapterRepository: verifiedRepository,
      activeAdapterBindingRepository: activeBindingRepository,
    );
    final AdapterValidator validator = AdapterValidator(
      verifiedAdapterRepository: verifiedRepository,
    );
    final ManageAdapterUseCase useCase = ManageAdapterUseCase(
      adapterRegistry: registry,
      adapterValidator: validator,
      adapterExportService: const _NoopAdapterExportService(),
    );
    await useCase.importManifestJson(_manifestJson());

    final ProviderContainer container = ProviderContainer(
      overrides: [manageAdapterUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);

    final AdapterVerificationController notifier = container.read(
      adapterVerificationControllerProvider.notifier,
    );

    notifier.setStepPassed(stepKey: 'set_suck', passed: true);
    notifier.setStepPassed(stepKey: 'set_vibe', passed: true);
    notifier.setStepPassed(stepKey: 'set_ems', passed: true);
    notifier.setStepPassed(stepKey: 'stop_all', passed: false);

    await notifier.submit(
      adapterId: 'generic.triple_channel.v1',
      deviceFingerprint: 'device-a',
    );

    final AdapterVerificationState state = container.read(
      adapterVerificationControllerProvider,
    );
    expect(state.errorMessage, isNotNull);
    expect(state.successMessage, isNull);
  });

  test('runStep set_suck marks step as passed when command succeeds', () async {
    final _InMemoryManifestRepository manifestRepository =
        _InMemoryManifestRepository();
    final _InMemoryVerifiedRepository verifiedRepository =
        _InMemoryVerifiedRepository();
    final _InMemoryActiveBindingRepository activeBindingRepository =
        _InMemoryActiveBindingRepository();
    final AdapterRegistry registry = AdapterRegistry(
      adapterManifestRepository: manifestRepository,
      verifiedAdapterRepository: verifiedRepository,
      activeAdapterBindingRepository: activeBindingRepository,
    );
    final AdapterValidator validator = AdapterValidator(
      verifiedAdapterRepository: verifiedRepository,
    );
    final ManageAdapterUseCase useCase = ManageAdapterUseCase(
      adapterRegistry: registry,
      adapterValidator: validator,
      adapterExportService: const _NoopAdapterExportService(),
    );
    await useCase.importManifestJson(_manifestJson());

    final MockHardwareRepository mockHardwareRepository =
        MockHardwareRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        manageAdapterUseCaseProvider.overrideWithValue(useCase),
        hardwareRepositoryProvider.overrideWithValue(mockHardwareRepository),
      ],
    );
    addTearDown(() async {
      await mockHardwareRepository.dispose();
      container.dispose();
    });

    final AdapterVerificationController notifier = container.read(
      adapterVerificationControllerProvider.notifier,
    );

    await notifier.runStep('set_suck');

    final AdapterVerificationState state = container.read(
      adapterVerificationControllerProvider,
    );
    final VerificationStepDraft suckStep = state.steps.firstWhere(
      (VerificationStepDraft step) => step.key == 'set_suck',
    );
    expect(suckStep.passed, isTrue);
    expect(state.errorMessage, isNull);
  });

  test('submit writes real gatt fingerprint from active device', () async {
    final _InMemoryManifestRepository manifestRepository =
        _InMemoryManifestRepository();
    final _InMemoryVerifiedRepository verifiedRepository =
        _InMemoryVerifiedRepository();
    final _InMemoryActiveBindingRepository activeBindingRepository =
        _InMemoryActiveBindingRepository();
    final AdapterRegistry registry = AdapterRegistry(
      adapterManifestRepository: manifestRepository,
      verifiedAdapterRepository: verifiedRepository,
      activeAdapterBindingRepository: activeBindingRepository,
    );
    final AdapterValidator validator = AdapterValidator(
      verifiedAdapterRepository: verifiedRepository,
    );
    final ManageAdapterUseCase useCase = ManageAdapterUseCase(
      adapterRegistry: registry,
      adapterValidator: validator,
      adapterExportService: const _NoopAdapterExportService(),
    );
    await useCase.importManifestJson(_manifestJson());

    final MockHardwareRepository mockHardwareRepository =
        MockHardwareRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        manageAdapterUseCaseProvider.overrideWithValue(useCase),
        hardwareRepositoryProvider.overrideWithValue(mockHardwareRepository),
      ],
    );
    addTearDown(() async {
      await mockHardwareRepository.dispose();
      container.dispose();
    });

    final AdapterVerificationController notifier = container.read(
      adapterVerificationControllerProvider.notifier,
    );
    notifier.setStepPassed(stepKey: 'set_suck', passed: true);
    notifier.setStepPassed(stepKey: 'set_vibe', passed: true);
    notifier.setStepPassed(stepKey: 'set_ems', passed: true);
    notifier.setStepPassed(stepKey: 'stop_all', passed: true);

    await notifier.submit(
      adapterId: 'generic.triple_channel.v1',
      deviceFingerprint: 'mock-sosexy-001',
    );

    final VerifiedAdapterRecord? record = await verifiedRepository.find(
      adapterId: 'generic.triple_channel.v1',
      deviceFingerprint: 'mock-sosexy-001',
    );
    expect(record, isNotNull);
    expect(record!.target.gattFingerprint, contains('mock-gatt'));

    final ActiveAdapterBinding? binding = await activeBindingRepository
        .findByDeviceFingerprint('mock-sosexy-001');
    expect(binding, isNotNull);
    expect(binding!.adapterId, 'generic.triple_channel.v1');
  });
}

class _NoopAdapterExportService implements AdapterExportService {
  const _NoopAdapterExportService();

  @override
  Future<String> saveJson({
    required String suggestedFileName,
    required String jsonText,
  }) async {
    return suggestedFileName;
  }
}

class _InMemoryManifestRepository implements AdapterManifestRepository {
  final StreamController<List<AdapterManifest>> _controller =
      StreamController<List<AdapterManifest>>.broadcast();
  final List<AdapterManifest> _manifests = <AdapterManifest>[];

  @override
  Future<AdapterManifest?> findById(String adapterId) async {
    for (final AdapterManifest manifest in _manifests) {
      if (manifest.adapterId == adapterId) {
        return manifest;
      }
    }
    return null;
  }

  @override
  Future<void> remove(String adapterId) async {
    _manifests.removeWhere((AdapterManifest e) => e.adapterId == adapterId);
    _controller.add(List<AdapterManifest>.from(_manifests));
  }

  @override
  Future<void> save(AdapterManifest manifest) async {
    final int index = _manifests.indexWhere(
      (AdapterManifest e) => e.adapterId == manifest.adapterId,
    );
    if (index >= 0) {
      _manifests[index] = manifest;
    } else {
      _manifests.add(manifest);
    }
    _controller.add(List<AdapterManifest>.from(_manifests));
  }

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield List<AdapterManifest>.from(_manifests);
    yield* _controller.stream;
  }
}

class _InMemoryVerifiedRepository implements VerifiedAdapterRepository {
  final Map<String, VerifiedAdapterRecord> _records =
      <String, VerifiedAdapterRecord>{};
  final StreamController<List<VerifiedAdapterRecord>> _controller =
      StreamController<List<VerifiedAdapterRecord>>.broadcast();

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    return _records['$adapterId::$deviceFingerprint'];
  }

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    _records.remove('$adapterId::$deviceFingerprint');
    _controller.add(_records.values.toList());
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    _records['${record.adapterId}::${record.target.deviceFingerprint}'] =
        record;
    _controller.add(_records.values.toList());
  }

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield _records.values.toList();
    yield* _controller.stream;
  }
}

class _InMemoryActiveBindingRepository
    implements ActiveAdapterBindingRepository {
  final Map<String, ActiveAdapterBinding> _bindings =
      <String, ActiveAdapterBinding>{};
  final StreamController<List<ActiveAdapterBinding>> _controller =
      StreamController<List<ActiveAdapterBinding>>.broadcast();

  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async {
    return _bindings[deviceFingerprint];
  }

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {
    _bindings.remove(deviceFingerprint);
    _controller.add(_bindings.values.toList());
  }

  @override
  Future<void> save(ActiveAdapterBinding binding) async {
    _bindings[binding.deviceFingerprint] = binding;
    _controller.add(_bindings.values.toList());
  }

  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield _bindings.values.toList();
    yield* _controller.stream;
  }
}

Map<String, Object?> _manifestJson() {
  return <String, Object?>{
    'schemaVersion': 1,
    'adapterId': 'generic.triple_channel.v1',
    'displayName': 'Generic Triple Channel',
    'protocolKey': 'generic_triple_channel',
    'version': '1.0.0',
    'minAppVersion': '1.0.0',
    'adapterKind': 'codecBacked',
    'codecKey': 'generic_triple_channel_v1',
    'bleNamePrefixes': <String>['SOSEXY'],
    'matching': <String, Object?>{
      'serviceUuids': <String>['0000fff0-0000-1000-8000-00805f9b34fb'],
      'manufacturerDataPattern': null,
      'priority': 100,
    },
    'gatt': <String, Object?>{
      'serviceUuid': '0000fff0-0000-1000-8000-00805f9b34fb',
      'writeCharacteristicUuid': '0000fff3-0000-1000-8000-00805f9b34fb',
      'notifyCharacteristicUuid': '0000fff4-0000-1000-8000-00805f9b34fb',
      'writeWithoutResponse': true,
    },
    'connection': <String, Object?>{
      'requiresBonding': false,
      'requestMtu': 185,
      'notifyRequired': false,
    },
    'capabilities': <String, Object?>{
      'supportsSuck': true,
      'supportsVibe': true,
      'supportsEms': true,
      'supportsSetAll': true,
      'supportsStopAll': true,
    },
    'ranges': <String, Object?>{
      'suckIntensity': <String, Object?>{'min': 0, 'max': 100},
      'vibeIntensity': <String, Object?>{'min': 0, 'max': 100},
      'emsIntensity': <String, Object?>{'min': 0, 'max': 20},
      'mode': <String, Object?>{'min': 1, 'max': 4},
    },
  };
}
