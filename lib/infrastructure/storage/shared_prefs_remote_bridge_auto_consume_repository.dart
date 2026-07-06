import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/remote_bridge_auto_consume_repository.dart';

class SharedPrefsRemoteBridgeAutoConsumeRepository
    implements RemoteBridgeAutoConsumeRepository {
  static const String _storageKey = 'remote_bridge_auto_consume_enabled_v1';

  bool? _cache;

  @override
  Future<bool> loadEnabled() async {
    if (_cache != null) {
      return _cache!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _cache = prefs.getBool(_storageKey) ?? false;
    return _cache!;
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cache = null;
  }

  @override
  Future<void> saveEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, enabled);
    _cache = enabled;
  }
}
