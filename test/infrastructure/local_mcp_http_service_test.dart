import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('LocalMcpHttpService', () {
    test('executes set_suck via HTTP tool endpoint', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final bridgeHandler = container.read(remoteBridgeToolCallHandlerProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        remoteBridgeToolCallHandler: bridgeHandler,
        host: '127.0.0.1',
        port: 8871,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8871/mcp/tool'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object?>{
          'name': 'set_suck',
          'arguments': <String, Object?>{'intensity': 25, 'mode': 1},
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['status'] as Map<String, dynamic>)['suckIntensity'], 25);
    });

    test('returns validation error for malformed payload', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final bridgeHandler = container.read(remoteBridgeToolCallHandlerProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        remoteBridgeToolCallHandler: bridgeHandler,
        host: '127.0.0.1',
        port: 8872,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8872/mcp/tool'),
      );
      request.headers.contentType = ContentType.json;
      request.write('{ bad json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      expect(json['ok'], false);
      expect(
        (json['error'] as Map<String, dynamic>)['code'],
        'validation_error',
      );
    });

    test('returns tool definitions from /mcp/tools', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final bridgeHandler = container.read(remoteBridgeToolCallHandlerProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        remoteBridgeToolCallHandler: bridgeHandler,
        host: '127.0.0.1',
        port: 8873,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:8873/mcp/tools'),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['tools'] as List<dynamic>).length, 6);
    });

    test('supports call-style payload at /mcp/call', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final bridgeHandler = container.read(remoteBridgeToolCallHandlerProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        remoteBridgeToolCallHandler: bridgeHandler,
        host: '127.0.0.1',
        port: 8874,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8874/mcp/call'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object?>{
          'tool': 'set_vibe',
          'input': <String, Object?>{'intensity': 40, 'mode': 1},
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['status'] as Map<String, dynamic>)['vibeIntensity'], 40);
    });

    test(
      'returns adapter_not_verified for control tool without verification',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final bridgeHandler = container.read(
          remoteBridgeToolCallHandlerProvider,
        );
        final service = LocalMcpHttpService(
          toolRouter: router,
          remoteBridgeToolCallHandler: bridgeHandler,
          host: '127.0.0.1',
          port: 8875,
        );
        addTearDown(service.stop);

        await service.start();

        final client = HttpClient();
        addTearDown(client.close);

        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:8875/mcp/tool'),
        );
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode(<String, Object?>{
            'name': 'set_suck',
            'arguments': <String, Object?>{'intensity': 25, 'mode': 1},
          }),
        );
        final response = await request.close();
        final body = await utf8.decodeStream(response);
        final Map<String, dynamic> json =
            jsonDecode(body) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest);
        expect(json['ok'], false);
        expect(
          (json['error'] as Map<String, dynamic>)['code'],
          'adapter_not_verified',
        );
      },
    );

    test('supports remote bridge tool-call payload for get_status', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final bridgeHandler = container.read(remoteBridgeToolCallHandlerProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        remoteBridgeToolCallHandler: bridgeHandler,
        host: '127.0.0.1',
        port: 8876,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8876/mobile-bridge/tool-call'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object?>{
          'requestId': 'bridge-req-1',
          'tool': 'get_status',
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect(json['requestId'], 'bridge-req-1');
      expect((json['result'] as Map<String, dynamic>)['deviceId'], 'mock-sosexy-001');
    });

    test(
      'returns bridge whitelist error for disabled tool on remote bridge route',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final bridgeHandler = container.read(
          remoteBridgeToolCallHandlerProvider,
        );
        final service = LocalMcpHttpService(
          toolRouter: router,
          remoteBridgeToolCallHandler: bridgeHandler,
          host: '127.0.0.1',
          port: 8877,
        );
        addTearDown(service.stop);

        await service.start();

        final client = HttpClient();
        addTearDown(client.close);

        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:8877/mobile-bridge/tool-call'),
        );
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode(<String, Object?>{
            'requestId': 'bridge-req-2',
            'tool': 'set_suck',
            'input': <String, Object?>{'intensity': 10, 'mode': 1},
          }),
        );
        final response = await request.close();
        final body = await utf8.decodeStream(response);
        final Map<String, dynamic> json =
            jsonDecode(body) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest);
        expect(json['ok'], false);
        expect(json['requestId'], 'bridge-req-2');
        expect(
          (json['error'] as Map<String, dynamic>)['code'],
          'tool_not_enabled_for_bridge',
        );
      },
    );
  });
}

class _InMemoryVerifiedRepository implements VerifiedAdapterRepository {
  _InMemoryVerifiedRepository({
    List<VerifiedAdapterRecord> records = const <VerifiedAdapterRecord>[],
  }) : _records = List<VerifiedAdapterRecord>.from(records);

  final List<VerifiedAdapterRecord> _records;

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield List<VerifiedAdapterRecord>.from(_records);
  }

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    for (final VerifiedAdapterRecord record in _records) {
      if (record.adapterId == adapterId &&
          record.target.deviceFingerprint == deviceFingerprint) {
        return record;
      }
    }
    return null;
  }

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    _records.removeWhere(
      (VerifiedAdapterRecord record) =>
          record.adapterId == adapterId &&
          record.target.deviceFingerprint == deviceFingerprint,
    );
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    _records.removeWhere(
      (VerifiedAdapterRecord existing) =>
          existing.adapterId == record.adapterId &&
          existing.target.deviceFingerprint == record.target.deviceFingerprint,
    );
    _records.add(record);
  }
}

class _InMemoryManifestRepository implements AdapterManifestRepository {
  @override
  Future<AdapterManifest?> findById(String adapterId) async => null;

  @override
  Future<void> remove(String adapterId) async {}

  @override
  Future<void> save(AdapterManifest manifest) async {}

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield const <AdapterManifest>[];
  }
}

class _InMemoryActiveBindingRepository
    implements ActiveAdapterBindingRepository {
  _InMemoryActiveBindingRepository({
    List<ActiveAdapterBinding> bindings = const <ActiveAdapterBinding>[],
  }) : _bindings = <String, ActiveAdapterBinding>{
         for (final ActiveAdapterBinding binding in bindings)
           binding.deviceFingerprint: binding,
       };

  final Map<String, ActiveAdapterBinding> _bindings;

  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async {
    return _bindings[deviceFingerprint];
  }

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {
    _bindings.remove(deviceFingerprint);
  }

  @override
  Future<void> save(ActiveAdapterBinding binding) async {
    _bindings[binding.deviceFingerprint] = binding;
  }

  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield _bindings.values.toList();
  }
}

VerifiedAdapterRecord _record({required AdapterVerificationStatus status}) {
  return VerifiedAdapterRecord(
    manifestHash: 'hash-1',
    adapterId: 'adapter.sosexy.demo',
    adapterVersion: '1.0.0',
    status: status,
    updatedAt: DateTime(2026, 5, 18, 12),
    verifiedByAppVersion: '1.0.0',
    target: const VerifiedTarget(
      deviceFingerprint: 'mock-sosexy-001',
      gattFingerprint: 'gatt:demo',
    ),
    stepResults: const <VerificationStepResult>[
      VerificationStepResult(stepKey: 'stop_all', passed: true),
    ],
    revokedReason: status == AdapterVerificationStatus.revoked
        ? 'revoked for test'
        : null,
  );
}
