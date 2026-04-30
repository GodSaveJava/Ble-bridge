import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLockState {
  const AppLockState({this.enabled = false, this.locked = false});

  final bool enabled;
  final bool locked;

  AppLockState copyWith({bool? enabled, bool? locked}) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
    );
  }
}

class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() => const AppLockState();

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value, locked: value ? true : false);
  }

  void lockNow() {
    if (!state.enabled) {
      return;
    }
    state = state.copyWith(locked: true);
  }

  bool unlockWithPin(String pin) {
    // MVP: local mock PIN validation. Replace with biometric/secure storage later.
    if (!state.enabled) {
      return true;
    }
    if (pin == '1234') {
      state = state.copyWith(locked: false);
      return true;
    }
    return false;
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
