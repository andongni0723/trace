import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/biometric_lock_settings.dart';

part 'biometric_lock_policy.freezed.dart';

enum BiometricLockTrigger { appOpened, appResumed }

@freezed
abstract class BiometricLockDecision with _$BiometricLockDecision {
  const factory BiometricLockDecision({
    required BiometricLockTrigger trigger,
    required bool shouldPrompt,
    required String reason,
    DateTime? nextCheckAt,
  }) = _BiometricLockDecision;
}

@freezed
abstract class BiometricLockOutcome with _$BiometricLockOutcome {
  const factory BiometricLockOutcome({
    required BiometricLockDecision decision,
    required bool attemptedAuthentication,
    required bool authenticated,
    String? failureMessage,
  }) = _BiometricLockOutcome;
}

class BiometricLockPolicy {
  const BiometricLockPolicy();

  BiometricLockDecision evaluate({
    required BiometricLockSettings settings,
    required bool sessionUnlocked,
    required BiometricLockTrigger trigger,
    required DateTime now,
  }) {
    if (!settings.enabled) {
      return BiometricLockDecision(
        trigger: trigger,
        shouldPrompt: false,
        reason: 'disabled',
      );
    }

    if (sessionUnlocked &&
        settings.reauthInterval == BiometricReauthInterval.nextOpen) {
      return BiometricLockDecision(
        trigger: trigger,
        shouldPrompt: false,
        reason: 'sessionUnlocked',
      );
    }

    final duration = settings.reauthInterval.duration;
    final lastVerifiedAt = settings.lastVerifiedAt;

    if (duration == null) {
      return BiometricLockDecision(
        trigger: trigger,
        shouldPrompt: !sessionUnlocked,
        reason: sessionUnlocked ? 'sessionUnlocked' : 'nextOpen',
      );
    }

    if (lastVerifiedAt == null) {
      return BiometricLockDecision(
        trigger: trigger,
        shouldPrompt: true,
        reason: 'neverVerified',
      );
    }

    final nextCheckAt = lastVerifiedAt.add(duration);
    final shouldPrompt = !now.isBefore(nextCheckAt);

    return BiometricLockDecision(
      trigger: trigger,
      shouldPrompt: shouldPrompt,
      reason: shouldPrompt ? 'intervalExpired' : 'withinInterval',
      nextCheckAt: nextCheckAt,
    );
  }
}
