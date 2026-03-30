import 'package:flutter_test/flutter_test.dart';

import 'package:trace/features/app_settings/biometric_lock/data/models/biometric_lock_settings.dart';
import 'package:trace/features/app_settings/biometric_lock/domain/biometric_lock_policy.dart';

void main() {
  const policy = BiometricLockPolicy();
  final now = DateTime(2026, 3, 30, 10);

  test('disabled biometric lock never prompts', () {
    final decision = policy.evaluate(
      settings: const BiometricLockSettings(),
      sessionUnlocked: false,
      trigger: BiometricLockTrigger.appOpened,
      now: now,
    );

    expect(decision.shouldPrompt, isFalse);
    expect(decision.reason, 'disabled');
  });

  test('next open prompts on a fresh session', () {
    final decision = policy.evaluate(
      settings: const BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.nextOpen,
      ),
      sessionUnlocked: false,
      trigger: BiometricLockTrigger.appOpened,
      now: now,
    );

    expect(decision.shouldPrompt, isTrue);
    expect(decision.reason, 'nextOpen');
  });

  test('next open does not prompt again within the same session', () {
    final decision = policy.evaluate(
      settings: const BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.nextOpen,
      ),
      sessionUnlocked: true,
      trigger: BiometricLockTrigger.appResumed,
      now: now,
    );

    expect(decision.shouldPrompt, isFalse);
    expect(decision.reason, 'sessionUnlocked');
  });

  test('fifteen minute interval expires after the threshold', () {
    final decision = policy.evaluate(
      settings: BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.fifteenMinutes,
        lastVerifiedAt: now.subtract(const Duration(minutes: 15)),
      ),
      sessionUnlocked: true,
      trigger: BiometricLockTrigger.appResumed,
      now: now,
    );

    expect(decision.shouldPrompt, isTrue);
    expect(decision.nextCheckAt, now);
    expect(decision.reason, 'intervalExpired');
  });

  test('fifteen minute interval stays unlocked before the threshold', () {
    final decision = policy.evaluate(
      settings: BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.fifteenMinutes,
        lastVerifiedAt: now.subtract(const Duration(minutes: 14)),
      ),
      sessionUnlocked: true,
      trigger: BiometricLockTrigger.appResumed,
      now: now,
    );

    expect(decision.shouldPrompt, isFalse);
    expect(decision.reason, 'withinInterval');
  });
}
