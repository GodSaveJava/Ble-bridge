import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/core/security/app_lock_controller.dart';

void main() {
  group('AppLockController', () {
    test('enabling lock sets state to locked', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appLockControllerProvider.notifier);
      controller.setEnabled(true);

      final state = container.read(appLockControllerProvider);
      expect(state.enabled, isTrue);
      expect(state.locked, isTrue);
    });

    test('unlockWithPin accepts default PIN in MVP', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(appLockControllerProvider.notifier);
      controller.setEnabled(true);

      final ok = controller.unlockWithPin('1234');
      final state = container.read(appLockControllerProvider);

      expect(ok, isTrue);
      expect(state.locked, isFalse);
    });
  });
}
