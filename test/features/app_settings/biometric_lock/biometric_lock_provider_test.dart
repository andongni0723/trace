import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trace/features/app_settings/biometric_lock/data/auth/biometric_auth_client.dart';
import 'package:trace/features/app_settings/biometric_lock/data/models/biometric_lock_settings.dart';
import 'package:trace/features/app_settings/biometric_lock/domain/biometric_lock_policy.dart';
import 'package:trace/features/app_settings/biometric_lock/domain/biometric_lock_service.dart';
import 'package:trace/features/app_settings/biometric_lock/providers/biometric_lock_provider.dart';

class FakeBiometricAuthClient implements BiometricAuthClient {
  FakeBiometricAuthClient({this.authenticateResult = true});

  final bool authenticateResult;

  int canAuthenticateCalls = 0;
  int authenticateCalls = 0;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool persistAcrossBackgrounding = true,
  }) async {
    authenticateCalls += 1;
    return authenticateResult;
  }

  @override
  Future<bool> canAuthenticate() async {
    canAuthenticateCalls += 1;
    return true;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return const [BiometricType.fingerprint];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app launch triggers biometric authentication when required', () async {
    SharedPreferences.setMockInitialValues({});
    final fakeClient = FakeBiometricAuthClient();
    final container = ProviderContainer(
      overrides: [
        biometricAuthClientProvider.overrideWithValue(fakeClient),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(biometricLockStateProvider.notifier);
    await notifier.setEnabled(true);
    await notifier.setReauthInterval(BiometricReauthInterval.nextOpen);

    final outcome = await notifier.handleLifecycleTrigger(
      BiometricLockTrigger.appOpened,
      localizedReason: 'Authenticate to open trace.',
      now: DateTime(2026, 3, 30, 10),
    );

    final state = await container.read(biometricLockStateProvider.future);

    expect(outcome.decision.shouldPrompt, isTrue);
    expect(outcome.authenticated, isTrue);
    expect(fakeClient.authenticateCalls, 1);
    expect(state.sessionUnlocked, isTrue);
    expect(state.settings.lastVerifiedAt, DateTime(2026, 3, 30, 10));
  });

  test('resume within the interval skips authentication', () async {
    SharedPreferences.setMockInitialValues({});
    final fakeClient = FakeBiometricAuthClient();
    final container = ProviderContainer(
      overrides: [
        biometricAuthClientProvider.overrideWithValue(fakeClient),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(biometricLockStateProvider.notifier);
    await notifier.setEnabled(true);
    await notifier.setReauthInterval(BiometricReauthInterval.fifteenMinutes);
    await notifier.recordSuccessfulAuthentication(
      DateTime(2026, 3, 30, 10),
    );

    final outcome = await notifier.handleLifecycleTrigger(
      BiometricLockTrigger.appResumed,
      localizedReason: 'Authenticate to open trace.',
      now: DateTime(2026, 3, 30, 10, 10),
    );

    expect(outcome.decision.shouldPrompt, isFalse);
    expect(fakeClient.authenticateCalls, 0);
  });
}
