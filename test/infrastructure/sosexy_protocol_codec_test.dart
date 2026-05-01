import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/infrastructure/devices/sosexy/sosexy_protocol_codec.dart';

void main() {
  group('SosexyProtocolCodec', () {
    const codec = SosexyProtocolCodec();

    test('buildSuckCommand encodes expected channel byte', () {
      final bytes = codec.buildSuckCommand(30, 2);
      expect(bytes[2], 0x01);
      expect(bytes[3], 2);
      expect(bytes[4], 30);
    });

    test('buildVibeCommand encodes expected channel byte', () {
      final bytes = codec.buildVibeCommand(45, 1);
      expect(bytes[2], 0x03);
      expect(bytes[4], 45);
    });

    test('buildEmsCommand encodes expected channel byte', () {
      final bytes = codec.buildEmsCommand(8, 4);
      expect(bytes[2], 0x07);
      expect(bytes[3], 4);
      expect(bytes[4], 8);
    });

    test('rejects invalid mode', () {
      expect(() => codec.buildSuckCommand(10, 0), throwsA(isA<Failure>()));
    });

    test('rejects invalid ems intensity', () {
      expect(() => codec.buildEmsCommand(99, 1), throwsA(isA<Failure>()));
    });

    test('buildStopAllCommand returns packet', () {
      final bytes = codec.buildStopAllCommand();
      expect(bytes.length, 6);
      expect(bytes[2], 0x00);
      expect(bytes[4], 0x00);
    });
  });
}
