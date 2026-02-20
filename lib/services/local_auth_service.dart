import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if device supports biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Check if device supports any authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await canCheckBiometrics();
      final isSupported = await isDeviceSupported();

      if (!canCheck || !isSupported) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN/Pattern as fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  // PIN Code Management
  static const String _pinKey = 'app_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Check if PIN is set
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  // Check if PIN authentication is enabled
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? true; // Enabled by default
  }

  // Set/Update PIN
  Future<bool> setPin(String pin) async {
    if (pin.length < 4) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, pin);
      await prefs.setBool(_pinEnabledKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    return storedPin == pin;
  }

  // Enable/Disable PIN authentication
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  // Enable/Disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  // Delete PIN
  Future<void> deletePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  // Check if any local authentication is configured
  Future<bool> hasLocalAuth() async {
    final isPinConfigured = await isPinSet();
    final isBiometricAvailable = await canCheckBiometrics();
    return isPinConfigured || isBiometricAvailable;
  }

  // Get preferred authentication method description
  Future<String> getAuthMethodDescription() async {
    final biometricEnabled = await isBiometricEnabled();
    final pinEnabled = await isPinEnabled();
    final biometrics = await getAvailableBiometrics();

    if (biometricEnabled && biometrics.isNotEmpty) {
      if (biometrics.contains(BiometricType.face)) {
        return 'Face Recognition';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris Scan';
      }
      return 'Biometric Authentication';
    } else if (pinEnabled) {
      return 'PIN';
    }

    return 'None';
  }
}
