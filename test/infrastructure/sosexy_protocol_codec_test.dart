import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/infrastructure/devices/sosexy/sosexy_protocol_codec.dart';

void main() {
  group('SosexyProtocolCodec', () {
    const codec = SosexyProtocolCodec();

    test('buildSuckCommand encodes the tutorial packet shape', () {
      final bytes = codec.buildSuckCommand(30, 2);
      expect(
        bytes,
        <int>[
          0x00,
          0x01,
          0x00,
          0x02,
          0x00,
          0x07,
          0x11,
          30,
          0x00,
          0x08,
          0x11,
          2,
        ],
      );
    });

    test('buildVibeCommand encodes the tutorial packet shape', () {
      final bytes = codec.buildVibeCommand(45, 1);
      expect(
        bytes,
        <int>[
          0x00,
          0x01,
          0x00,
          0x02,
          0x00,
          0x01,
          0x11,
          45,
          0x00,
          0x02,
          0x11,
          1,
        ],
      );
    });

    test('buildEmsCommand encodes the tutorial packet shape', () {
      final bytes = codec.buildEmsCommand(8, 4);
      expect(
        bytes,
        <int>[
          0x00,
          0x01,
          0x00,
          0x02,
          0x00,
          0x03,
          0x11,
          8,
          0x00,
          0x04,
          0x11,
          4,
        ],
      );
    });

    test('rejects invalid mode', () {
      expect(() => codec.buildSuckCommand(10, 0), throwsA(isA<Failure>()));
    });

    test('rejects invalid ems intensity', () {
      expect(() => codec.buildEmsCommand(99, 1), throwsA(isA<Failure>()));
    });

    test('buildStopAllCommand returns tutorial stop packet', () {
      final bytes = codec.buildStopAllCommand();
      expect(
        bytes,
        <int>[
          0x00,
          0x01,
          0x00,
          0x03,
          0x00,
          0x01,
          0x11,
          0,
          0x00,
          0x03,
          0x11,
          0,
          0x00,
          0x07,
          0x11,
          0,
        ],
      );
    });

    test('buildSetAllCommand returns a single combined packet', () {
      final packets = codec.buildSetAllCommand(
        suck: 10,
        vibe: 20,
        ems: 3,
        suckMode: 1,
        vibeMode: 2,
        emsMode: 4,
      );

      expect(packets, hasLength(1));
      expect(
        packets.single,
        <int>[
          0x00,
          0x01,
          0x00,
          0x06,
          0x00,
          0x01,
          0x11,
          20,
          0x00,
          0x02,
          0x11,
          2,
          0x00,
          0x03,
          0x11,
          3,
          0x00,
          0x04,
          0x11,
          4,
          0x00,
          0x07,
          0x11,
          10,
          0x00,
          0x08,
          0x11,
          1,
        ],
      );
    });
  });
}
