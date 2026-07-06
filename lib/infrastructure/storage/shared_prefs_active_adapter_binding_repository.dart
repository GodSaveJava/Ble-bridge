import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/active_adapter_binding.dart';
import '../../domain/repositories/active_adapter_binding_repository.dart';

class SharedPrefsActiveAdapterBindingRepository
    implements ActiveAdapterBindingRepository {
  SharedPrefsActiveAdapterBindingRepository();

  static const String _storageKey = 'active_adapter_bindings_v1';

  final StreamController<List<ActiveAdapterBinding>> _controller =
      StreamController<List<ActiveAdapterBinding>>.broadcast();

  List<ActiveAdapterBinding>? _cache;

  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield await _loadAll();
    yield* _controller.stream;
  }

  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async {
    final List<ActiveAdapterBinding> bindings = await _loadAll();
    for (final ActiveAdapterBinding binding in bindings) {
      if (binding.deviceFingerprint == deviceFingerprint) {
        return binding;
      }
    }
    return null;
  }

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {
    final List<ActiveAdapterBinding> bindings = await _loadAll();
    bindings.removeWhere(
      (ActiveAdapterBinding binding) =>
          binding.deviceFingerprint == deviceFingerprint,
    );
    await _saveAll(bindings);
  }

  @override
  Future<void> save(ActiveAdapterBinding binding) async {
    final List<ActiveAdapterBinding> bindings = await _loadAll();
    final int index = bindings.indexWhere(
      (ActiveAdapterBinding existing) =>
          existing.deviceFingerprint == binding.deviceFingerprint,
    );
    if (index >= 0) {
      bindings[index] = binding;
    } else {
      bindings.add(binding);
    }
    await _saveAll(bindings);
  }

  Future<List<ActiveAdapterBinding>> _loadAll() async {
    if (_cache != null) {
      return List<ActiveAdapterBinding>.from(_cache!);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <ActiveAdapterBinding>[];
      return <ActiveAdapterBinding>[];
    }
    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    final List<ActiveAdapterBinding> bindings = decoded
        .cast<Map<String, Object?>>()
        .map(ActiveAdapterBinding.fromJson)
        .toList();
    _cache = bindings;
    return List<ActiveAdapterBinding>.from(bindings);
  }

  Future<void> _saveAll(List<ActiveAdapterBinding> bindings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      bindings.map((ActiveAdapterBinding binding) => binding.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
    _cache = List<ActiveAdapterBinding>.from(bindings);
    _controller.add(List<ActiveAdapterBinding>.from(bindings));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
