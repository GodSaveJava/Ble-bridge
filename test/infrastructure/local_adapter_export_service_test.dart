import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/infrastructure/storage/local_adapter_export_service.dart';

void main() {
  test(
    'LocalAdapterExportService writes json into adapter_exports directory',
    () async {
      final Directory tempRoot = await Directory.systemTemp.createTemp(
        'adapter-export-test',
      );
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final service = LocalAdapterExportService(
        directoryResolver: () async => tempRoot,
      );

      final String savedPath = await service.saveJson(
        suggestedFileName: 'generic.triple_channel.v1.json',
        jsonText: '{"adapterId":"generic.triple_channel.v1"}',
      );

      final File savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(
        await savedFile.readAsString(),
        contains('generic.triple_channel.v1'),
      );
      expect(savedFile.parent.path, endsWith('adapter_exports'));
    },
  );
}
