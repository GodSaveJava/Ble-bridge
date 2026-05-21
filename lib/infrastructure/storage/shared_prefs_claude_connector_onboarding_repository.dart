import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/claude_connector_onboarding_record.dart';
import '../../domain/repositories/claude_connector_onboarding_repository.dart';

class SharedPrefsClaudeConnectorOnboardingRepository
    implements ClaudeConnectorOnboardingRepository {
  static const String _storageKey = 'claude_connector_onboarding_v1';

  ClaudeConnectorOnboardingRecord? _cache;

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async {
    if (_cache != null) {
      return _cache;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Map<String, Object?> decoded =
        (jsonDecode(raw) as Map).cast<String, Object?>();
    _cache = ClaudeConnectorOnboardingRecord.fromJson(decoded);
    return _cache;
  }

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord record) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(record.toJson()));
    _cache = record;
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cache = null;
  }
}
