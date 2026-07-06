import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/infrastructure/devices/sosexy/sosexy_device.dart';
import 'package:toylink_ai/infrastructure/devices/sosexy/sosexy_protocol_codec.dart';

void main() {
  group('SosexyDevice', () {
    test(
      'stopAll fails superseded pending commands instead of hanging',
      () async {
        final writes = <List<int>>[];
        final firstWriteStarted = Completer<void>();
        final firstWrite = Completer<void>();

        final device = SosexyDevice.test(
          id: 'sosexy-test',
          writer:
              (
                List<int> payload, {
                required bool withoutResponse,
                required int timeout,
              }) async {
                writes.add(List<int>.from(payload));
                if (writes.length == 1) {
                  firstWriteStarted.complete();
                  await firstWrite.future;
                }
              },
        );

        final suckFuture = device.setSuck(10);
        await firstWriteStarted.future.timeout(
          const Duration(milliseconds: 100),
        );

        final vibeFuture = device.setVibe(20);
        await Future<void>.delayed(Duration.zero);

        final vibeExpectation = expectLater(
          vibeFuture.timeout(const Duration(milliseconds: 100)),
          throwsA(
            isA<Failure>()
                .having(
                  (failure) => failure.code,
                  'code',
                  FailureCode.deviceWrite,
                )
                .having(
                  (failure) => failure.message,
                  'message',
                  contains('superseded'),
                ),
          ),
        );
        final stopFuture = device.stopAll();
        await Future<void>.delayed(Duration.zero);

        firstWrite.complete();

        await suckFuture.timeout(const Duration(milliseconds: 100));
        await stopFuture.timeout(const Duration(milliseconds: 100));
        await vibeExpectation;

        expect(writes, <List<int>>[
          const SosexyProtocolCodec().buildSuckCommand(10, 1),
          const SosexyProtocolCodec().buildStopAllCommand(),
        ]);
        final status = await device.getStatus();
        expect(status.suckIntensity, 0);
        expect(status.vibeIntensity, 0);
        expect(status.emsIntensity, 0);
      },
    );
  });
}
