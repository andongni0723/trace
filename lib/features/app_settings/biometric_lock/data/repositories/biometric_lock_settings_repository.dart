import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/app_settings_provider.dart';
import '../models/biometric_lock_settings.dart';

final biometricLockSettingsRepositoryProvider =
    Provider<BiometricLockSettingsRepository>((ref) {
      return BiometricLockSettingsRepository(ref);
    });

class BiometricLockSettingsRepository {
  BiometricLockSettingsRepository(this._ref);

  static const _enabledKey = 'biometric_lock.enabled';
  static const _reauthIntervalKey = 'biometric_lock.reauth_interval';
  static const _lastVerifiedAtKey = 'biometric_lock.last_verified_at_ms';

  final Ref _ref;

  Future<BiometricLockSettings> load() async {
    final prefs = await _sharedPreferences;

    return BiometricLockSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      reauthInterval: BiometricReauthIntervalX.fromPreference(
        prefs.getString(_reauthIntervalKey),
      ),
      lastVerifiedAt: _readLastVerifiedAt(prefs),
    );
  }

  Future<BiometricLockSettings> save(BiometricLockSettings settings) async {
    final prefs = await _sharedPreferences;

    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setString(
      _reauthIntervalKey,
      settings.reauthInterval.preferenceValue,
    );

    if (settings.lastVerifiedAt == null) {
      await prefs.remove(_lastVerifiedAtKey);
    } else {
      await prefs.setInt(
        _lastVerifiedAtKey,
        settings.lastVerifiedAt!.millisecondsSinceEpoch,
      );
    }

    return settings;
  }

  Future<SharedPreferences> get _sharedPreferences {
    return _ref.read(sharedPreferencesProvider.future);
  }

  DateTime? _readLastVerifiedAt(SharedPreferences prefs) {
    final millis = prefs.getInt(_lastVerifiedAtKey);
    if (millis == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
