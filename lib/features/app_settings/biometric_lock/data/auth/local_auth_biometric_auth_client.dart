import 'package:local_auth/local_auth.dart';

import 'biometric_auth_client.dart';

class LocalAuthBiometricAuthClient implements BiometricAuthClient {
  LocalAuthBiometricAuthClient({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canAuthenticate() async {
    if (!await _auth.isDeviceSupported()) {
      return false;
    }

    final availableBiometrics = await _auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() {
    return _auth.getAvailableBiometrics();
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool persistAcrossBackgrounding = true,
  }) {
    return _auth.authenticate(
      localizedReason: localizedReason,
      biometricOnly: biometricOnly,
      persistAcrossBackgrounding: persistAcrossBackgrounding,
    );
  }
}
