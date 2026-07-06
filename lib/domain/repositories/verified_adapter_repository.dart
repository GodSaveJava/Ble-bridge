import '../entities/verified_adapter_record.dart';

abstract class VerifiedAdapterRepository {
  Stream<List<VerifiedAdapterRecord>> watchAll();
  Future<void> save(VerifiedAdapterRecord record);
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  });
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  });
}
