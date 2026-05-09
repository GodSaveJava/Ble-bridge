import '../../core/error/failure.dart';

enum AdapterKind { codecBacked }

class IntRange {
  const IntRange({required this.min, required this.max});

  final int min;
  final int max;

  Map<String, Object?> toJson() => <String, Object?>{'min': min, 'max': max};

  static IntRange fromJson(Map<String, Object?> json) {
    final Object? minValue = json['min'];
    final Object? maxValue = json['max'];
    if (minValue is! int || maxValue is! int) {
      throw const Failure.adapterSchemaInvalid(
        message: 'Range requires integer min and max.',
      );
    }
    if (minValue > maxValue) {
      throw const Failure.adapterSchemaInvalid(
        message: 'Range min cannot be greater than max.',
      );
    }
    return IntRange(min: minValue, max: maxValue);
  }
}

class AdapterMatching {
  const AdapterMatching({
    required this.serviceUuids,
    required this.priority,
    this.manufacturerDataPattern,
  });

  final List<String> serviceUuids;
  final String? manufacturerDataPattern;
  final int priority;

  Map<String, Object?> toJson() => <String, Object?>{
    'serviceUuids': serviceUuids,
    'manufacturerDataPattern': manufacturerDataPattern,
    'priority': priority,
  };

  static AdapterMatching fromJson(Map<String, Object?> json) {
    final List<String> serviceUuids = _readStringList(
      json: json,
      key: 'serviceUuids',
      required: true,
    );
    final Object? priorityValue = json['priority'];
    if (priorityValue is! int) {
      throw const Failure.adapterSchemaInvalid(
        message: 'matching.priority must be an integer.',
      );
    }
    final Object? patternValue = json['manufacturerDataPattern'];
    if (patternValue != null && patternValue is! String) {
      throw const Failure.adapterSchemaInvalid(
        message: 'matching.manufacturerDataPattern must be a string or null.',
      );
    }

    return AdapterMatching(
      serviceUuids: serviceUuids,
      manufacturerDataPattern: patternValue as String?,
      priority: priorityValue,
    );
  }
}

class AdapterGattProfile {
  const AdapterGattProfile({
    required this.serviceUuid,
    required this.writeCharacteristicUuid,
    required this.notifyCharacteristicUuid,
    required this.writeWithoutResponse,
  });

  final String serviceUuid;
  final String writeCharacteristicUuid;
  final String? notifyCharacteristicUuid;
  final bool writeWithoutResponse;

  Map<String, Object?> toJson() => <String, Object?>{
    'serviceUuid': serviceUuid,
    'writeCharacteristicUuid': writeCharacteristicUuid,
    'notifyCharacteristicUuid': notifyCharacteristicUuid,
    'writeWithoutResponse': writeWithoutResponse,
  };

  static AdapterGattProfile fromJson(Map<String, Object?> json) {
    final String serviceUuid = _readRequiredString(
      json: json,
      key: 'serviceUuid',
    );
    final String writeUuid = _readRequiredString(
      json: json,
      key: 'writeCharacteristicUuid',
    );
    final Object? notifyValue = json['notifyCharacteristicUuid'];
    if (notifyValue != null && notifyValue is! String) {
      throw const Failure.adapterSchemaInvalid(
        message:
            'gatt.notifyCharacteristicUuid must be a string or null value.',
      );
    }
    final Object? writeTypeValue = json['writeWithoutResponse'];
    if (writeTypeValue is! bool) {
      throw const Failure.adapterSchemaInvalid(
        message: 'gatt.writeWithoutResponse must be a boolean.',
      );
    }
    return AdapterGattProfile(
      serviceUuid: serviceUuid,
      writeCharacteristicUuid: writeUuid,
      notifyCharacteristicUuid: notifyValue as String?,
      writeWithoutResponse: writeTypeValue,
    );
  }
}

class AdapterConnectionHints {
  const AdapterConnectionHints({
    required this.requiresBonding,
    required this.requestMtu,
    required this.notifyRequired,
  });

  final bool requiresBonding;
  final int requestMtu;
  final bool notifyRequired;

  Map<String, Object?> toJson() => <String, Object?>{
    'requiresBonding': requiresBonding,
    'requestMtu': requestMtu,
    'notifyRequired': notifyRequired,
  };

  static AdapterConnectionHints fromJson(Map<String, Object?> json) {
    final Object? requiresBondingValue = json['requiresBonding'];
    final Object? requestMtuValue = json['requestMtu'];
    final Object? notifyRequiredValue = json['notifyRequired'];
    if (requiresBondingValue is! bool ||
        requestMtuValue is! int ||
        notifyRequiredValue is! bool) {
      throw const Failure.adapterSchemaInvalid(
        message: 'connection fields are invalid.',
      );
    }
    return AdapterConnectionHints(
      requiresBonding: requiresBondingValue,
      requestMtu: requestMtuValue,
      notifyRequired: notifyRequiredValue,
    );
  }
}

class AdapterCapabilities {
  const AdapterCapabilities({
    required this.supportsSuck,
    required this.supportsVibe,
    required this.supportsEms,
    required this.supportsSetAll,
    required this.supportsStopAll,
  });

  final bool supportsSuck;
  final bool supportsVibe;
  final bool supportsEms;
  final bool supportsSetAll;
  final bool supportsStopAll;

  Map<String, Object?> toJson() => <String, Object?>{
    'supportsSuck': supportsSuck,
    'supportsVibe': supportsVibe,
    'supportsEms': supportsEms,
    'supportsSetAll': supportsSetAll,
    'supportsStopAll': supportsStopAll,
  };

  static AdapterCapabilities fromJson(Map<String, Object?> json) {
    bool readBool(String key) {
      final Object? value = json[key];
      if (value is! bool) {
        throw Failure.adapterSchemaInvalid(
          message: 'capabilities.$key must be a boolean.',
        );
      }
      return value;
    }

    return AdapterCapabilities(
      supportsSuck: readBool('supportsSuck'),
      supportsVibe: readBool('supportsVibe'),
      supportsEms: readBool('supportsEms'),
      supportsSetAll: readBool('supportsSetAll'),
      supportsStopAll: readBool('supportsStopAll'),
    );
  }
}

class AdapterRanges {
  const AdapterRanges({
    required this.suckIntensity,
    required this.vibeIntensity,
    required this.emsIntensity,
    required this.mode,
  });

  final IntRange suckIntensity;
  final IntRange vibeIntensity;
  final IntRange emsIntensity;
  final IntRange mode;

  Map<String, Object?> toJson() => <String, Object?>{
    'suckIntensity': suckIntensity.toJson(),
    'vibeIntensity': vibeIntensity.toJson(),
    'emsIntensity': emsIntensity.toJson(),
    'mode': mode.toJson(),
  };

  static AdapterRanges fromJson(Map<String, Object?> json) {
    return AdapterRanges(
      suckIntensity: IntRange.fromJson(
        _readObject(json: json, key: 'suckIntensity'),
      ),
      vibeIntensity: IntRange.fromJson(
        _readObject(json: json, key: 'vibeIntensity'),
      ),
      emsIntensity: IntRange.fromJson(
        _readObject(json: json, key: 'emsIntensity'),
      ),
      mode: IntRange.fromJson(_readObject(json: json, key: 'mode')),
    );
  }
}

class AdapterManifest {
  const AdapterManifest({
    required this.schemaVersion,
    required this.adapterId,
    required this.displayName,
    required this.protocolKey,
    required this.version,
    required this.minAppVersion,
    required this.adapterKind,
    required this.codecKey,
    required this.bleNamePrefixes,
    required this.matching,
    required this.gatt,
    required this.connection,
    required this.capabilities,
    required this.ranges,
    this.notes,
  });

  final int schemaVersion;
  final String adapterId;
  final String displayName;
  final String protocolKey;
  final String version;
  final String minAppVersion;
  final AdapterKind adapterKind;
  final String codecKey;
  final List<String> bleNamePrefixes;
  final AdapterMatching matching;
  final AdapterGattProfile gatt;
  final AdapterConnectionHints connection;
  final AdapterCapabilities capabilities;
  final AdapterRanges ranges;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'adapterId': adapterId,
    'displayName': displayName,
    'protocolKey': protocolKey,
    'version': version,
    'minAppVersion': minAppVersion,
    'adapterKind': adapterKind.name,
    'codecKey': codecKey,
    'bleNamePrefixes': bleNamePrefixes,
    'matching': matching.toJson(),
    'gatt': gatt.toJson(),
    'connection': connection.toJson(),
    'capabilities': capabilities.toJson(),
    'ranges': ranges.toJson(),
    'notes': notes,
  };

  static AdapterManifest fromJson(Map<String, Object?> json) {
    final Object? schemaVersionValue = json['schemaVersion'];
    if (schemaVersionValue is! int) {
      throw const Failure.adapterSchemaInvalid(
        message: 'schemaVersion must be an integer.',
      );
    }
    final String adapterKindValue = _readRequiredString(
      json: json,
      key: 'adapterKind',
    );
    if (adapterKindValue != AdapterKind.codecBacked.name) {
      throw Failure.adapterSchemaInvalid(
        message:
            'Only adapterKind="${AdapterKind.codecBacked.name}" is supported.',
      );
    }

    final List<String> blePrefixes = _readStringList(
      json: json,
      key: 'bleNamePrefixes',
      required: true,
    );
    if (blePrefixes.isEmpty) {
      throw const Failure.adapterSchemaInvalid(
        message: 'bleNamePrefixes cannot be empty.',
      );
    }

    return AdapterManifest(
      schemaVersion: schemaVersionValue,
      adapterId: _readRequiredString(json: json, key: 'adapterId'),
      displayName: _readRequiredString(json: json, key: 'displayName'),
      protocolKey: _readRequiredString(json: json, key: 'protocolKey'),
      version: _readRequiredString(json: json, key: 'version'),
      minAppVersion: _readRequiredString(json: json, key: 'minAppVersion'),
      adapterKind: AdapterKind.codecBacked,
      codecKey: _readRequiredString(json: json, key: 'codecKey'),
      bleNamePrefixes: blePrefixes,
      matching: AdapterMatching.fromJson(
        _readObject(json: json, key: 'matching'),
      ),
      gatt: AdapterGattProfile.fromJson(_readObject(json: json, key: 'gatt')),
      connection: AdapterConnectionHints.fromJson(
        _readObject(json: json, key: 'connection'),
      ),
      capabilities: AdapterCapabilities.fromJson(
        _readObject(json: json, key: 'capabilities'),
      ),
      ranges: AdapterRanges.fromJson(_readObject(json: json, key: 'ranges')),
      notes: json['notes'] as String?,
    );
  }
}

Map<String, Object?> _readObject({
  required Map<String, Object?> json,
  required String key,
}) {
  final Object? value = json[key];
  if (value is! Map<String, Object?>) {
    throw Failure.adapterSchemaInvalid(message: '$key must be an object.');
  }
  return value;
}

String _readRequiredString({
  required Map<String, Object?> json,
  required String key,
}) {
  final Object? value = json[key];
  if (value is! String || value.isEmpty) {
    throw Failure.adapterSchemaInvalid(
      message: '$key must be a non-empty string.',
    );
  }
  return value;
}

List<String> _readStringList({
  required Map<String, Object?> json,
  required String key,
  required bool required,
}) {
  final Object? raw = json[key];
  if (raw == null && !required) {
    return const <String>[];
  }
  if (raw is! List<Object?>) {
    throw Failure.adapterSchemaInvalid(message: '$key must be a string list.');
  }
  final List<String> values = <String>[];
  for (final Object? item in raw) {
    if (item is! String || item.isEmpty) {
      throw Failure.adapterSchemaInvalid(
        message: '$key contains an invalid value.',
      );
    }
    values.add(item);
  }
  return values;
}
