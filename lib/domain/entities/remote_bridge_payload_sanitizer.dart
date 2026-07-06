abstract final class RemoteBridgePayloadSanitizer {
  static const Set<String> sensitiveKeys = <String>{
    'deviceId',
    'deviceFingerprint',
    'gattFingerprint',
    'rawBleId',
    'adapterId',
    'serviceUuid',
    'characteristicUuid',
    'writeCharacteristicUuid',
  };

  static Map<String, dynamic>? sanitizeMap(Map<String, dynamic>? value) {
    if (value == null) {
      return null;
    }
    return _sanitizeObject(value) as Map<String, dynamic>;
  }

  static Object? _sanitizeObject(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final MapEntry<dynamic, dynamic> entry in value.entries)
          if (!sensitiveKeys.contains(entry.key.toString()))
            entry.key.toString(): _sanitizeObject(entry.value),
      };
    }
    if (value is List) {
      return value.map(_sanitizeObject).toList(growable: false);
    }
    return value;
  }
}
