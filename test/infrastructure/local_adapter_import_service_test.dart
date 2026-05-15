import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/infrastructure/storage/local_adapter_import_service.dart';

void main() {
  test(
    'LocalAdapterImportService reads json text from selected file',
    () async {
      final LocalAdapterImportService service = LocalAdapterImportService(
        openFilePicker: (_) async {
          return XFile.fromData(
            Uint8List.fromList('{"adapterId":"picked.adapter"}'.codeUnits),
            mimeType: 'application/json',
            name: 'picked.adapter.json',
          );
        },
      );

      final String? jsonText = await service.pickJsonText();

      expect(jsonText, contains('picked.adapter'));
    },
  );

  test(
    'LocalAdapterImportService returns null when selection is cancelled',
    () async {
      final LocalAdapterImportService service = LocalAdapterImportService(
        openFilePicker: (_) async => null,
      );

      final String? jsonText = await service.pickJsonText();

      expect(jsonText, isNull);
    },
  );
}
