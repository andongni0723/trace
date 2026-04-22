import 'package:freezed_annotation/freezed_annotation.dart';

part 'biometric_lock_settings.freezed.dart';

enum BiometricReauthInterval { nextOpen, fifteenMinutes, thirtyMinutes }

extension BiometricReauthIntervalX on BiometricReauthInterval {
  static BiometricReauthInterval fromPreference(String? value) {
    return switch (value) {
      'nextOpen' => BiometricReauthInterval.nextOpen,
      'fifteenMinutes' => BiometricReauthInterval.fifteenMinutes,
      'thirtyMinutes' => BiometricReauthInterval.thirtyMinutes,
      _ => BiometricReauthInterval.nextOpen,
    };
  }

  String get preferenceValue => switch (this) {
    BiometricReauthInterval.nextOpen => 'nextOpen',
    BiometricReauthInterval.fifteenMinutes => 'fifteenMinutes',
    BiometricReauthInterval.thirtyMinutes => 'thirtyMinutes',
  };

  Duration? get duration => switch (this) {
    BiometricReauthInterval.nextOpen => null,
    BiometricReauthInterval.fifteenMinutes => const Duration(minutes: 15),
    BiometricReauthInterval.thirtyMinutes => const Duration(minutes: 30),
  };
}

@freezed
abstract class BiometricLockSettings with _$BiometricLockSettings {
  const factory BiometricLockSettings({
    @Default(false) bool enabled,
    @Default(BiometricReauthInterval.nextOpen)
    BiometricReauthInterval reauthInterval,
    DateTime? lastVerifiedAt,
  }) = _BiometricLockSettings;
}
