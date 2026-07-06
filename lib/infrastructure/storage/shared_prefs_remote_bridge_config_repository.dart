import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/remote_bridge_config.dart';
import '../../domain/repositories/remote_bridge_config_repository.dart';

class SharedPrefsRemoteBridgeConfigRepository
    implements RemoteBridgeConfigRepository {
  SharedPrefsRemoteBridgeConfigRepository({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _storageKey = 'remote_bridge_config_v1';
  static const String _tokenStorageKey = 'remote_bridge_client_token_v1';

  final FlutterSecureStorage _secureStorage;

  RemoteBridgeConfig? _cache;

  @override
  Future<RemoteBridgeConfig> load() async {
    if (_cache != null) {
      return _cache!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    final String? token = await _secureStorage.read(key: _tokenStorageKey);
    if (raw == null || raw.isEmpty) {
      _cache = const RemoteBridgeConfig().normalized();
      return _cache!;
    }
    final Map<String, Object?> decoded =
        (jsonDecode(raw) as Map).cast<String, Object?>();
    final RemoteBridgeConfig loaded = RemoteBridgeConfig.fromJson(<String, Object?>{
      ...decoded,
      'clientToken': token ?? '',
    }).normalized();
    if (!_shouldUseLoadedConfig(loaded)) {
      _cache = const RemoteBridgeConfig().normalized();
      return _cache!;
    }
    _cache = loaded;
    return _cache!;
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await _secureStorage.delete(key: _tokenStorageKey);
    _cache = const RemoteBridgeConfig();
  }

  @override
  Future<void> save(RemoteBridgeConfig config) async {
    final RemoteBridgeConfig normalized = config.normalized();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(<String, Object?>{
        'enabled': normalized.enabled,
        'baseUrl': normalized.baseUrl,
        'clientId': normalized.clientId,
      }),
    );
    if (normalized.clientToken.isEmpty) {
      await _secureStorage.delete(key: _tokenStorageKey);
    } else {
      await _secureStorage.write(
        key: _tokenStorageKey,
        value: normalized.clientToken,
      );
    }
    _cache = normalized;
  }

  bool _shouldUseLoadedConfig(RemoteBridgeConfig config) {
    if (!config.enabled || config.normalizedBaseUrl.isEmpty) {
      return false;
    }
    return !config.normalizedBaseUrl.contains('bridge.toylink.local');
  }
}
