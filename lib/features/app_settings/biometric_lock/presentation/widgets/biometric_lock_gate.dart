import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trace/core/utils/useful_extension.dart';

import 'app_opening_animation_overlay.dart';
import '../../domain/biometric_lock_policy.dart';
import '../../domain/biometric_lock_state.dart';
import '../../providers/biometric_lock_provider.dart';

class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _isBootstrapping = true;
  bool _showOpeningAnimation = false;
  bool _hasPlayedOpeningAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isBootstrapping) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_authenticate(BiometricLockTrigger.appResumed));
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(biometricLockStateProvider.notifier).clearSession());
    }
  }

  Future<void> _bootstrap() async {
    await ref.read(biometricLockStateProvider.future);
    if (!mounted) {
      return;
    }

    await _authenticate(BiometricLockTrigger.appOpened);
    if (!mounted) {
      return;
    }

    setState(() {
      _isBootstrapping = false;
      _showOpeningAnimation = _shouldPlayOpeningAnimation();
      _hasPlayedOpeningAnimation = _showOpeningAnimation;
    });
  }

  Future<void> _authenticate(BiometricLockTrigger trigger) {
    return ref
        .read(biometricLockStateProvider.notifier)
        .handleLifecycleTrigger(
          trigger,
          localizedReason: 'appSettings.fingerprint.systemPrompt'.tr(),
        );
  }

  bool _shouldPlayOpeningAnimation() {
    if (_hasPlayedOpeningAnimation) {
      return false;
    }

    final state = ref.read(biometricLockStateProvider).asData?.value;
    if (state == null) {
      return false;
    }

    if (!state.settings.enabled) {
      return true;
    }

    return state.sessionUnlocked && !state.isAuthenticating;
  }

  void _handleOpeningAnimationCompleted() {
    if (!mounted) {
      return;
    }

    setState(() {
      _showOpeningAnimation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final biometricLockState = ref.watch(biometricLockStateProvider);
    final state = biometricLockState.asData?.value;
    final shouldBlock =
        _isBootstrapping ||
        ((state?.settings.enabled ?? false) &&
            ((state?.isAuthenticating ?? false) || (state?.isLocked ?? false)));

    if (!shouldBlock) {
      if (!_showOpeningAnimation) {
        return widget.child;
      }

      return Stack(
        children: [
          widget.child,
          AppOpeningAnimationOverlay(
            onCompleted: _handleOpeningAnimationCompleted,
          ),
        ],
      );
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: _BiometricLockOverlay(
            isBootstrapping: _isBootstrapping,
            state: state,
            onRetry: () => _authenticate(BiometricLockTrigger.appResumed),
            onDisable: () =>
                ref.read(biometricLockStateProvider.notifier).setEnabled(false),
          ),
        ),
      ],
    );
  }
}

class _BiometricLockOverlay extends StatelessWidget {
  const _BiometricLockOverlay({
    required this.isBootstrapping,
    required this.state,
    required this.onRetry,
    required this.onDisable,
  });

  final bool isBootstrapping;
  final BiometricLockState? state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onDisable;

  @override
  Widget build(BuildContext context) {
    final isAuthenticating = state?.isAuthenticating ?? false;
    final canAuthenticate = state?.canAuthenticate ?? false;
    final isEnabled = state?.settings.enabled ?? false;
    final showDisableAction =
        isEnabled && !canAuthenticate && !isAuthenticating;
    final showRetryAction = isEnabled && canAuthenticate && !isAuthenticating;
    final message = _message(context);

    return Material(
      color: context.cs.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: context.cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 48,
                      color: context.cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'appSettings.fingerprint.lockTitle'.tr(),
                    style: context.tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: context.tt.bodyLarge?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (isAuthenticating || isBootstrapping)
                    const CircularProgressIndicator(),
                  if (showRetryAction)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('appSettings.fingerprint.lockRetry'.tr()),
                    ),
                  if (showDisableAction)
                    TextButton(
                      onPressed: onDisable,
                      child: Text('appSettings.fingerprint.turnOff'.tr()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _message(BuildContext context) {
    if (isBootstrapping || (state?.isAuthenticating ?? false)) {
      return 'appSettings.fingerprint.lockChecking'.tr();
    }

    if ((state?.settings.enabled ?? false) &&
        !(state?.canAuthenticate ?? false)) {
      return 'appSettings.fingerprint.unavailable'.tr();
    }

    if (state?.lastErrorMessage != null) {
      return 'appSettings.fingerprint.lockError'.tr();
    }

    return 'appSettings.fingerprint.lockSubtitle'.tr();
  }
}
