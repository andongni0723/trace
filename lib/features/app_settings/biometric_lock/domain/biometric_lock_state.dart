import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/biometric_lock_settings.dart';

part 'biometric_lock_state.freezed.dart';

@freezed
abstract class BiometricLockState with _$BiometricLockState {
  const BiometricLockState._();

  const factory BiometricLockState({
    required BiometricLockSettings settings,
    @Default(false) bool sessionUnlocked,
    @Default(false) bool canAuthenticate,
    @Default(false) bool isAuthenticating,
    String? lastErrorMessage,
  }) = _BiometricLockState;

  bool get enabled => settings.enabled;

  bool get isLocked => enabled && !sessionUnlocked;

  DateTime? get nextVerificationAt {
    final interval = settings.reauthInterval.duration;
    final lastVerifiedAt = settings.lastVerifiedAt;

    if (interval == null || lastVerifiedAt == null) {
      return null;
    }

    return lastVerifiedAt.add(interval);
  }
}
