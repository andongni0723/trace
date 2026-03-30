import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth/biometric_auth_client.dart';
import '../data/auth/local_auth_biometric_auth_client.dart';
import '../data/models/biometric_lock_settings.dart';
import '../data/repositories/biometric_lock_settings_repository.dart';
import 'biometric_lock_policy.dart';
import 'biometric_lock_state.dart';

final biometricAuthClientProvider = Provider<BiometricAuthClient>((ref) {
  return LocalAuthBiometricAuthClient();
});

final biometricLockServiceProvider = Provider<BiometricLockService>((ref) {
  return BiometricLockService(ref);
});

class BiometricLockService {
  const BiometricLockService(this._ref);

  final Ref _ref;

  BiometricLockSettingsRepository get _repository =>
      _ref.read(biometricLockSettingsRepositoryProvider);

  BiometricAuthClient get _authClient => _ref.read(biometricAuthClientProvider);

  BiometricLockPolicy get _policy => const BiometricLockPolicy();

  Future<BiometricLockState> loadState() async {
    final settings = await _repository.load();
    final canAuthenticate = await _authClient.canAuthenticate();

    return BiometricLockState(
      settings: settings,
      canAuthenticate: canAuthenticate,
    );
  }

  BiometricLockDecision evaluate({
    required BiometricLockState state,
    required BiometricLockTrigger trigger,
    DateTime? now,
  }) {
    return _policy.evaluate(
      settings: state.settings,
      sessionUnlocked: state.sessionUnlocked,
      trigger: trigger,
      now: now ?? DateTime.now(),
    );
  }

  Future<BiometricLockOutcome> authenticateIfNeeded({
    required BiometricLockState state,
    required BiometricLockTrigger trigger,
    required String localizedReason,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final decision = evaluate(
      state: state,
      trigger: trigger,
      now: effectiveNow,
    );

    if (!decision.shouldPrompt) {
      return BiometricLockOutcome(
        decision: decision,
        attemptedAuthentication: false,
        authenticated: false,
      );
    }

    if (!state.canAuthenticate) {
      return BiometricLockOutcome(
        decision: decision,
        attemptedAuthentication: false,
        authenticated: false,
        failureMessage: 'Biometric authentication is not available.',
      );
    }

    final didAuthenticate = await _authClient.authenticate(
      localizedReason: localizedReason,
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    if (!didAuthenticate) {
      return BiometricLockOutcome(
        decision: decision,
        attemptedAuthentication: true,
        authenticated: false,
        failureMessage: 'Biometric authentication was cancelled or failed.',
      );
    }

    await recordSuccessfulAuthentication(effectiveNow);

    return BiometricLockOutcome(
      decision: decision,
      attemptedAuthentication: true,
      authenticated: true,
      failureMessage: null,
    );
  }

  Future<BiometricLockSettings> setEnabled(bool enabled) async {
    final current = await _repository.load();
    return _repository.save(
      current.copyWith(
        enabled: enabled,
        lastVerifiedAt: enabled ? current.lastVerifiedAt : null,
      ),
    );
  }

  Future<BiometricLockSettings> setReauthInterval(
    BiometricReauthInterval interval,
  ) async {
    final current = await _repository.load();
    return _repository.save(current.copyWith(reauthInterval: interval));
  }

  Future<BiometricLockSettings> recordSuccessfulAuthentication(
    DateTime verifiedAt,
  ) async {
    final current = await _repository.load();
    return _repository.save(current.copyWith(lastVerifiedAt: verifiedAt));
  }
}
