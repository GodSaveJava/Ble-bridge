import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adapter_manifest.dart';
import '../../domain/repositories/adapter_manifest_repository.dart';

class SharedPrefsAdapterManifestRepository
    implements AdapterManifestRepository {
  SharedPrefsAdapterManifestRepository();

  static const String _storageKey = 'adapter_manifests_v1';

  final StreamController<List<AdapterManifest>> _controller =
      StreamController<List<AdapterManifest>>.broadcast();

  List<AdapterManifest>? _cache;

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield await _loadAll();
    yield* _controller.stream;
  }

  @override
  Future<AdapterManifest?> findById(String adapterId) async {
    final List<AdapterManifest> manifests = await _loadAll();
    for (final AdapterManifest manifest in manifests) {
      if (manifest.adapterId == adapterId) {
        return manifest;
      }
    }
    return null;
  }

  @override
  Future<void> remove(String adapterId) async {
    final List<AdapterManifest> manifests = await _loadAll();
    manifests.removeWhere((AdapterManifest e) => e.adapterId == adapterId);
    await _saveAll(manifests);
  }

  @override
  Future<void> save(AdapterManifest manifest) async {
    final List<AdapterManifest> manifests = await _loadAll();
    final int existingIndex = manifests.indexWhere(
      (AdapterManifest e) => e.adapterId == manifest.adapterId,
    );
    if (existingIndex >= 0) {
      manifests[existingIndex] = manifest;
    } else {
      manifests.add(manifest);
    }
    await _saveAll(manifests);
  }

  Future<List<AdapterManifest>> _loadAll() async {
    if (_cache != null) {
      return List<AdapterManifest>.from(_cache!);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <AdapterManifest>[];
      return <AdapterManifest>[];
    }
    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    final List<AdapterManifest> manifests = decoded
        .cast<Map<String, Object?>>()
        .map(AdapterManifest.fromJson)
        .toList();
    _cache = manifests;
    return List<AdapterManifest>.from(manifests);
  }

  Future<void> _saveAll(List<AdapterManifest> manifests) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      manifests.map((AdapterManifest e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
    _cache = List<AdapterManifest>.from(manifests);
    _controller.add(List<AdapterManifest>.from(manifests));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
