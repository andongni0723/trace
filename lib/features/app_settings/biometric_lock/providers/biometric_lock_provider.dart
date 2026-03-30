import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/biometric_lock_settings.dart';
import '../domain/biometric_lock_policy.dart';
import '../domain/biometric_lock_service.dart';
import '../domain/biometric_lock_state.dart';

final biometricLockStateProvider =
    AsyncNotifierProvider<BiometricLockNotifier, BiometricLockState>(
      BiometricLockNotifier.new,
    );

class BiometricLockNotifier extends AsyncNotifier<BiometricLockState> {
  BiometricLockService get _service => ref.read(biometricLockServiceProvider);

  @override
  Future<BiometricLockState> build() async {
    return _service.loadState();
  }

  Future<BiometricLockOutcome> handleLifecycleTrigger(
    BiometricLockTrigger trigger, {
    required String localizedReason,
    DateTime? now,
  }) async {
    final currentState = state.asData?.value ?? await _service.loadState();

    state = AsyncData(currentState.copyWith(isAuthenticating: true));
    final outcome = await _service.authenticateIfNeeded(
      state: currentState,
      trigger: trigger,
      localizedReason: localizedReason,
      now: now,
    );

    if (outcome.authenticated) {
      final refreshedState = await _service.loadState();
      state = AsyncData(
        refreshedState.copyWith(
          sessionUnlocked: true,
          isAuthenticating: false,
          lastErrorMessage: null,
        ),
      );
    } else {
      final shouldUnlockSession =
          currentState.settings.enabled &&
          !outcome.decision.shouldPrompt &&
          outcome.failureMessage == null;

      state = AsyncData(
        currentState.copyWith(
          sessionUnlocked: shouldUnlockSession,
          isAuthenticating: false,
          lastErrorMessage: shouldUnlockSession ? null : outcome.failureMessage,
        ),
      );
    }

    return outcome;
  }

  Future<void> setEnabled(bool enabled) async {
    final currentState = state.asData?.value ?? await _service.loadState();
    final updatedSettings = await _service.setEnabled(enabled);
    state = AsyncData(
      currentState.copyWith(
        settings: updatedSettings,
        sessionUnlocked: enabled ? currentState.sessionUnlocked : false,
        lastErrorMessage: null,
      ),
    );
  }

  Future<void> setReauthInterval(BiometricReauthInterval interval) async {
    final currentState = state.asData?.value ?? await _service.loadState();
    final updatedSettings = await _service.setReauthInterval(interval);
    state = AsyncData(
      currentState.copyWith(
        settings: updatedSettings,
        lastErrorMessage: null,
      ),
    );
  }

  Future<void> recordSuccessfulAuthentication([DateTime? verifiedAt]) async {
    final currentState = state.asData?.value ?? await _service.loadState();
    final updatedSettings = await _service.recordSuccessfulAuthentication(
      verifiedAt ?? DateTime.now(),
    );
    state = AsyncData(
      currentState.copyWith(
        settings: updatedSettings,
        sessionUnlocked: true,
        lastErrorMessage: null,
      ),
    );
  }

  Future<void> clearSession() async {
    final currentState = state.asData?.value ?? await _service.loadState();
    state = AsyncData(currentState.copyWith(sessionUnlocked: false));
  }
}
