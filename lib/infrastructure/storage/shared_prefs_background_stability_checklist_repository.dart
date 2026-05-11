import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/background_stability_checklist.dart';
import '../../domain/repositories/background_stability_checklist_repository.dart';

class SharedPrefsBackgroundStabilityChecklistRepository
    implements BackgroundStabilityChecklistRepository {
  static const String _storageKey = 'background_stability_checklist_v1';

  BackgroundStabilityChecklist? _cache;

  @override
  Future<BackgroundStabilityChecklist> load() async {
    if (_cache != null) {
      return _cache!;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = const BackgroundStabilityChecklist();
      return _cache!;
    }
    final Map<String, Object?> decoded =
        (jsonDecode(raw) as Map).cast<String, Object?>();
    _cache = BackgroundStabilityChecklist.fromJson(decoded);
    return _cache!;
  }

  @override
  Future<void> save(BackgroundStabilityChecklist checklist) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(checklist.toJson()));
    _cache = checklist;
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cache = const BackgroundStabilityChecklist();
  }
}
