import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trace/features/app_settings/biometric_lock/data/models/biometric_lock_settings.dart';
import 'package:trace/features/app_settings/biometric_lock/data/repositories/biometric_lock_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('biometric settings repository persists a full round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(biometricLockSettingsRepositoryProvider);
    final savedAt = DateTime(2026, 3, 30, 10, 15);

    await repository.save(
      BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.thirtyMinutes,
        lastVerifiedAt: savedAt,
      ),
    );

    final loaded = await repository.load();

    expect(loaded.enabled, isTrue);
    expect(loaded.reauthInterval, BiometricReauthInterval.thirtyMinutes);
    expect(loaded.lastVerifiedAt, savedAt);
  });

  test('saving a null verification timestamp clears the stored value', () async {
    SharedPreferences.setMockInitialValues({
      'biometric_lock.last_verified_at_ms': 1,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(biometricLockSettingsRepositoryProvider);

    await repository.save(
      const BiometricLockSettings(
        enabled: true,
        reauthInterval: BiometricReauthInterval.nextOpen,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('biometric_lock.last_verified_at_ms'), isNull);
  });
}
