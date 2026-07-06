import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/services/adapter_export_service.dart';

typedef ExportDirectoryResolver = Future<Directory> Function();

class LocalAdapterExportService implements AdapterExportService {
  const LocalAdapterExportService({ExportDirectoryResolver? directoryResolver})
    : _directoryResolver =
          directoryResolver ?? getApplicationDocumentsDirectory;

  final ExportDirectoryResolver _directoryResolver;

  @override
  Future<String> saveJson({
    required String suggestedFileName,
    required String jsonText,
  }) async {
    final Directory documentsDirectory = await _directoryResolver();
    final Directory exportDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}adapter_exports',
    );
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final String safeFileName = suggestedFileName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final File file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$safeFileName',
    );
    await file.writeAsString(jsonText);
    return file.path;
  }
}
