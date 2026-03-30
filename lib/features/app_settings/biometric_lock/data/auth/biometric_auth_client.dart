import 'package:local_auth/local_auth.dart';

abstract class BiometricAuthClient {
  Future<bool> canAuthenticate();

  Future<List<BiometricType>> getAvailableBiometrics();

  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool persistAcrossBackgrounding = true,
  });
}
