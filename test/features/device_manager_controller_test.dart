import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/services/adapter_registry.dart';
import 'package:toylink_ai/application/services/adapter_validator.dart';
import 'package:toylink_ai/application/use_cases/manage_adapter_use_case.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/domain/services/adapter_export_service.dart';
import 'package:toylink_ai/domain/services/adapter_import_service.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/device_manager_controller.dart';
import 'package:toylink_ai/infrastructure/mock/mock_toy_device.dart';

void main() {
  test(
    'precheckJsonText returns warning when ems max above soft limit',
    () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.precheckJsonText(_manifestJsonText(emsMax: 12));

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      expect(state.successMessage, contains('警告'));
      expect(state.errorMessage, isNull);
    },
  );

  test('importJsonText sets importedAdapterId on success', () async {
    final ProviderContainer container = _buildContainer();
    addTearDown(container.dispose);

    final DeviceManagerController notifier = container.read(
      deviceManagerControllerProvider.notifier,
    );
    await notifier.importJsonText(_manifestJsonText());

    final DeviceManagerState state = container.read(
      deviceManagerControllerProvider,
    );
    expect(state.importedAdapterId, 'generic.triple_channel.v1');
    expect(state.errorMessage, isNull);
  });

  test(
    'exportAdapterJson exposes manifest text for selected adapter',
    () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);
      await _importDefaultManifest(container);

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.exportAdapterJson('generic.triple_channel.v1');

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      expect(
        state.exportedJsonText,
        contains('"adapterId": "generic.triple_channel.v1"'),
      );
      expect(state.successMessage, contains('导出'));
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'saveAdapterJsonFile exposes saved file path for selected adapter',
    () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);
      await _importDefaultManifest(container);

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.saveAdapterJsonFile('generic.triple_channel.v1');

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      expect(
        state.exportedFilePath,
        'C:/exports/generic.triple_channel.v1.json',
      );
      expect(state.successMessage, contains('保存'));
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'deleteAdapter removes imported manifest and surfaces success',
    () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);
      await _importDefaultManifest(container);

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.deleteAdapter('generic.triple_channel.v1');

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      expect(state.adapters, isEmpty);
      expect(state.successMessage, contains('删除'));
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'pickJsonFile stores selected json text for review before import',
    () async {
      final ProviderContainer container = _buildContainer(
        importService: const _FakeAdapterImportService(
          jsonText: '{"adapterId":"picked.adapter"}',
        ),
      );
      addTearDown(container.dispose);

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.pickJsonFile();

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      expect(state.pickedJsonText, contains('picked.adapter'));
      expect(state.successMessage, contains('本地'));
      expect(state.errorMessage, isNull);
    },
  );

  test('pickJsonFile keeps state clean when user cancels selection', () async {
    final ProviderContainer container = _buildContainer(
      importService: const _FakeAdapterImportService(jsonText: null),
    );
    addTearDown(container.dispose);

    final DeviceManagerController notifier = container.read(
      deviceManagerControllerProvider.notifier,
    );
    await notifier.pickJsonFile();

    final DeviceManagerState state = container.read(
      deviceManagerControllerProvider,
    );
    expect(state.pickedJsonText, isNull);
    expect(state.successMessage, contains('取消'));
    expect(state.errorMessage, isNull);
  });

  test(
    'revokeAdapterVerification marks current device record as revoked',
    () async {
      final _InMemoryVerifiedRepository verifiedRepository =
          _InMemoryVerifiedRepository();
      final ProviderContainer container = _buildContainer(
        verifiedRepository: verifiedRepository,
      );
      addTearDown(container.dispose);
      await _importDefaultManifest(container);

      final ManageAdapterUseCase useCase = container.read(
        manageAdapterUseCaseProvider,
      );
      await useCase.markVerificationPassed(
        const AdapterVerificationInput(
          adapterId: 'generic.triple_channel.v1',
          deviceFingerprint: 'device-a',
          gattFingerprint: 'gatt-a',
          appVersion: '1.0.0',
          stepResults: <VerificationStepResult>[
            VerificationStepResult(stepKey: 'set_suck', passed: true),
            VerificationStepResult(stepKey: 'stop_all', passed: true),
          ],
        ),
      );

      final DeviceManagerController notifier = container.read(
        deviceManagerControllerProvider.notifier,
      );
      await notifier.revokeAdapterVerification(
        adapterId: 'generic.triple_channel.v1',
        deviceFingerprint: 'device-a',
      );

      final DeviceManagerState state = container.read(
        deviceManagerControllerProvider,
      );
      final VerifiedAdapterRecord? record = await verifiedRepository.find(
        adapterId: 'generic.triple_channel.v1',
        deviceFingerprint: 'device-a',
      );
      expect(record?.status, AdapterVerificationStatus.revoked);
      expect(state.successMessage, contains('撤销'));
      expect(state.errorMessage, isNull);
    },
  );
  test('bindAdapterForCurrentDevice stores active device binding', () async {
    final _InMemoryActiveBindingRepository activeBindingRepository =
        _InMemoryActiveBindingRepository();
    final ProviderContainer container = _buildContainer(
      activeBindingRepository: activeBindingRepository,
    );
    addTearDown(container.dispose);
    await _importDefaultManifest(container);

    final DeviceManagerController notifier = container.read(
      deviceManagerControllerProvider.notifier,
    );
    await notifier.bindAdapterForCurrentDevice(
      adapterId: 'generic.triple_channel.v1',
      deviceFingerprint: 'device-a',
    );

    final DeviceManagerState state = container.read(
      deviceManagerControllerProvider,
    );
    final ActiveAdapterBinding? binding = await activeBindingRepository
        .findByDeviceFingerprint('device-a');
    expect(binding, isNotNull);
    expect(binding!.adapterId, 'generic.triple_channel.v1');
    expect(state.successMessage, contains('切换'));
    expect(state.errorMessage, isNull);
  });
  test(
    'buildAdapterRecommendations sorts current verified matching template first',
    () {
      final List<AdapterManifest> manifests = <AdapterManifest>[
        _manifestFromJsonText(_manifestJsonText()),
        _manifestFromJsonText(
          _manifestJsonTextWithValues(
            adapterId: 'generic.other.v1',
            displayName: 'Other Template',
            blePrefix: 'OTHER',
            priority: 10,
            emsMax: 20,
          ),
        ),
      ];

      final List<AdapterRecommendation> recommendations =
          buildAdapterRecommendations(
            manifests: manifests,
            activeDeviceId: 'device-a',
            activeDeviceName: 'Mock SOSEXY Device',
            activeBleNamePrefix: 'SOSEXY',
            bindings: <ActiveAdapterBinding>[
              ActiveAdapterBinding(
                deviceFingerprint: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                boundAt: DateTime(2026, 1, 1),
              ),
            ],
            records: <VerifiedAdapterRecord>[
              _verifiedRecord(
                adapterId: 'generic.triple_channel.v1',
                deviceFingerprint: 'device-a',
                status: AdapterVerificationStatus.verified,
              ),
            ],
          );

      expect(
        recommendations.first.manifest.adapterId,
        'generic.triple_channel.v1',
      );
      expect(recommendations.first.reasons, contains('当前设备已经绑定这份适配器'));
      expect(recommendations.first.reasons, contains('设备前缀与模板匹配：SOSEXY'));
      expect(recommendations.first.reasons, contains('这份适配器已经在当前设备上验证通过'));
    },
  );
}

ProviderContainer _buildContainer({
  AdapterImportService importService = const _FakeAdapterImportService(),
  _InMemoryManifestRepository? manifestRepository,
  _InMemoryVerifiedRepository? verifiedRepository,
  _InMemoryActiveBindingRepository? activeBindingRepository,
  HardwareRepository? hardwareRepository,
}) {
  final _InMemoryManifestRepository resolvedManifestRepository =
      manifestRepository ?? _InMemoryManifestRepository();
  final _InMemoryVerifiedRepository resolvedVerifiedRepository =
      verifiedRepository ?? _InMemoryVerifiedRepository();
  final _InMemoryActiveBindingRepository resolvedActiveBindingRepository =
      activeBindingRepository ?? _InMemoryActiveBindingRepository();
  final AdapterRegistry registry = AdapterRegistry(
    adapterManifestRepository: resolvedManifestRepository,
    verifiedAdapterRepository: resolvedVerifiedRepository,
    activeAdapterBindingRepository: resolvedActiveBindingRepository,
  );
  final AdapterValidator validator = AdapterValidator(
    verifiedAdapterRepository: resolvedVerifiedRepository,
  );
  final ManageAdapterUseCase useCase = ManageAdapterUseCase(
    adapterRegistry: registry,
    adapterValidator: validator,
    adapterExportService: const _FakeAdapterExportService(),
  );

  return ProviderContainer(
    overrides: [
      manageAdapterUseCaseProvider.overrideWithValue(useCase),
      adapterImportServiceProvider.overrideWithValue(importService),
      hardwareRepositoryProvider.overrideWithValue(
        hardwareRepository ?? _FakeHardwareRepository(),
      ),
      activeDeviceStatusStreamProvider.overrideWith(
        (_) => Stream<DeviceStatus>.value(
          DeviceStatus(
            deviceId: 'device-a',
            isConnected: true,
            suckIntensity: 0,
            vibeIntensity: 0,
            emsIntensity: 0,
            suckMode: 1,
            vibeMode: 1,
            emsMode: 1,
            lastUpdatedAt: DateTime(2026),
          ),
        ),
      ),
    ],
  );
}

Future<void> _importDefaultManifest(ProviderContainer container) async {
  await container
      .read(manageAdapterUseCaseProvider)
      .importManifestJson(
        jsonDecode(_manifestJsonText()) as Map<String, Object?>,
      );
}

class _FakeAdapterExportService implements AdapterExportService {
  const _FakeAdapterExportService();

  @override
  Future<String> saveJson({
    required String suggestedFileName,
    required String jsonText,
  }) async {
    return 'C:/exports/$suggestedFileName';
  }
}

class _FakeAdapterImportService implements AdapterImportService {
  const _FakeAdapterImportService({this.jsonText = '{"adapterId":"sample"}'});

  final String? jsonText;

  @override
  Future<String?> pickJsonText() async => jsonText;
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

String _manifestJsonText({int emsMax = 20}) {
  return _manifestJsonTextWithValues(
    adapterId: 'generic.triple_channel.v1',
    displayName: 'Generic Triple Channel',
    blePrefix: 'SOSEXY',
    priority: 100,
    emsMax: emsMax,
  );
}

String _manifestJsonTextWithValues({
  required String adapterId,
  required String displayName,
  required String blePrefix,
  required int priority,
  required int emsMax,
}) {
  return '''
{
  "schemaVersion": 1,
  "adapterId": "$adapterId",
  "displayName": "$displayName",
  "protocolKey": "generic_triple_channel",
  "version": "1.0.0",
  "minAppVersion": "1.0.0",
  "adapterKind": "codecBacked",
  "codecKey": "generic_triple_channel_v1",
  "bleNamePrefixes": ["$blePrefix"],
  "matching": {
    "serviceUuids": ["0000fff0-0000-1000-8000-00805f9b34fb"],
    "manufacturerDataPattern": null,
    "priority": $priority
  },
  "gatt": {
    "serviceUuid": "0000fff0-0000-1000-8000-00805f9b34fb",
    "writeCharacteristicUuid": "0000fff3-0000-1000-8000-00805f9b34fb",
    "notifyCharacteristicUuid": "0000fff4-0000-1000-8000-00805f9b34fb",
    "writeWithoutResponse": true
  },
  "connection": {
    "requiresBonding": false,
    "requestMtu": 185,
    "notifyRequired": false
  },
  "capabilities": {
    "supportsSuck": true,
    "supportsVibe": true,
    "supportsEms": true,
    "supportsSetAll": true,
    "supportsStopAll": true
  },
  "ranges": {
    "suckIntensity": {"min": 0, "max": 100},
    "vibeIntensity": {"min": 0, "max": 100},
    "emsIntensity": {"min": 0, "max": $emsMax},
    "mode": {"min": 1, "max": 4}
  }
}
''';
}

AdapterManifest _manifestFromJsonText(String jsonText) {
  return AdapterManifest.fromJson(jsonDecode(jsonText) as Map<String, Object?>);
}

VerifiedAdapterRecord _verifiedRecord({
  required String adapterId,
  required String deviceFingerprint,
  required AdapterVerificationStatus status,
}) {
  return VerifiedAdapterRecord(
    adapterId: adapterId,
    manifestHash: 'hash-$adapterId',
    adapterVersion: '1.0.0',
    status: status,
    updatedAt: DateTime(2026, 1, 1),
    verifiedByAppVersion: '1.0.0',
    target: VerifiedTarget(
      deviceFingerprint: deviceFingerprint,
      gattFingerprint: 'gatt-$deviceFingerprint',
    ),
    stepResults: const <VerificationStepResult>[
      VerificationStepResult(stepKey: 'set_suck', passed: true),
      VerificationStepResult(stepKey: 'stop_all', passed: true),
    ],
  );
}

class _FakeHardwareRepository implements HardwareRepository {
  _FakeHardwareRepository({ToyDevice? activeDevice})
    : _activeDevice =
          activeDevice ??
          MockToyDevice(id: 'device-a', name: 'Mock SOSEXY Device');

  final ToyDevice _activeDevice;

  @override
  Future<void> connectActiveDevice(ToyDeviceInfo info) async {}

  @override
  Future<void> disconnectActiveDevice() async {}

  @override
  ToyDevice getActiveDevice() => _activeDevice;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Stream<DeviceStatus> watchActiveStatus() {
    return Stream<DeviceStatus>.value(
      DeviceStatus(
        deviceId: 'device-a',
        isConnected: true,
        suckIntensity: 0,
        vibeIntensity: 0,
        emsIntensity: 0,
        suckMode: 1,
        vibeMode: 1,
        emsMode: 1,
        lastUpdatedAt: DateTime(2026),
      ),
    );
  }

  @override
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      const Stream<List<ToyDeviceInfo>>.empty();
}
