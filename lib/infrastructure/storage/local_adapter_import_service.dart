import 'package:file_selector/file_selector.dart';

import '../../domain/services/adapter_import_service.dart';

typedef AdapterJsonFilePicker =
    Future<XFile?> Function(List<XTypeGroup> acceptedTypeGroups);

class LocalAdapterImportService implements AdapterImportService {
  LocalAdapterImportService({AdapterJsonFilePicker? openFilePicker})
    : _openFilePicker = openFilePicker ?? _defaultOpenFilePicker;

  final AdapterJsonFilePicker _openFilePicker;

  static Future<XFile?> _defaultOpenFilePicker(
    List<XTypeGroup> acceptedTypeGroups,
  ) {
    return openFile(acceptedTypeGroups: acceptedTypeGroups);
  }

  @override
  Future<String?> pickJsonText() async {
    const XTypeGroup jsonTypeGroup = XTypeGroup(
      label: 'json',
      extensions: <String>['json'],
      mimeTypes: <String>['application/json', 'text/plain'],
    );
    final XFile? file = await _openFilePicker(const <XTypeGroup>[
      jsonTypeGroup,
    ]);
    if (file == null) {
      return null;
    }
    return file.readAsString();
  }
}
