import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/verified_adapter_record.dart';
import '../../domain/repositories/verified_adapter_repository.dart';

class SharedPrefsVerifiedAdapterRepository
    implements VerifiedAdapterRepository {
  SharedPrefsVerifiedAdapterRepository();

  static const String _storageKey = 'verified_adapter_records_v1';

  final StreamController<List<VerifiedAdapterRecord>> _controller =
      StreamController<List<VerifiedAdapterRecord>>.broadcast();

  List<VerifiedAdapterRecord>? _cache;

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield await _loadAll();
    yield* _controller.stream;
  }

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    final List<VerifiedAdapterRecord> records = await _loadAll();
    for (final VerifiedAdapterRecord record in records) {
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
    final List<VerifiedAdapterRecord> records = await _loadAll();
    records.removeWhere(
      (VerifiedAdapterRecord e) =>
          e.adapterId == adapterId &&
          e.target.deviceFingerprint == deviceFingerprint,
    );
    await _saveAll(records);
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    final List<VerifiedAdapterRecord> records = await _loadAll();
    final int existingIndex = records.indexWhere(
      (VerifiedAdapterRecord e) =>
          e.adapterId == record.adapterId &&
          e.target.deviceFingerprint == record.target.deviceFingerprint,
    );
    if (existingIndex >= 0) {
      records[existingIndex] = record;
    } else {
      records.add(record);
    }
    await _saveAll(records);
  }

  Future<List<VerifiedAdapterRecord>> _loadAll() async {
    if (_cache != null) {
      return List<VerifiedAdapterRecord>.from(_cache!);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <VerifiedAdapterRecord>[];
      return <VerifiedAdapterRecord>[];
    }
    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    final List<VerifiedAdapterRecord> records = decoded
        .cast<Map<String, Object?>>()
        .map(VerifiedAdapterRecord.fromJson)
        .toList();
    _cache = records;
    return List<VerifiedAdapterRecord>.from(records);
  }

  Future<void> _saveAll(List<VerifiedAdapterRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      records.map((VerifiedAdapterRecord e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
    _cache = List<VerifiedAdapterRecord>.from(records);
    _controller.add(List<VerifiedAdapterRecord>.from(records));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
