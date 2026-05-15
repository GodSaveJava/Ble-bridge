abstract class AdapterExportService {
  Future<String> saveJson({
    required String suggestedFileName,
    required String jsonText,
  });
}
