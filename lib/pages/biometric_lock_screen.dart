import 'package:flutter/material.dart';

import '../services/local_auth_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthService _localAuthService = LocalAuthService();
  final TextEditingController _pinController = TextEditingController();

  bool _isLoading = true;
  bool _showPinInput = false;
  bool _isCreatingPin = false;
  String? _errorMessage;
  String _confirmPin = '';
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _checkAuthSetup();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthSetup() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final isPinSet = await _localAuthService.isPinSet();
    final biometricEnabled = await _localAuthService.isBiometricEnabled();
    final canUseBiometric = await _localAuthService.canCheckBiometrics();

    if (!mounted) return;

    if (!isPinSet) {
      // First time - ask user to set up PIN
      setState(() {
        _isCreatingPin = true;
        _showPinInput = true;
        _isLoading = false;
      });
    } else if (biometricEnabled && canUseBiometric) {
      // Try biometric first
      setState(() => _isLoading = false);
      _authenticateWithBiometric();
    } else {
      // Show PIN input
      setState(() {
        _showPinInput = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated =
          await _localAuthService.authenticateWithBiometrics();

      if (!mounted) return;

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed';
          _showPinInput = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Biometric authentication unavailable';
        _showPinInput = true;
      });
    }
  }

  Future<void> _createPin() async {
    final pin = _pinController.text.trim();

    if (pin.length < 4) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_confirmPin.isEmpty) {
      // First entry - ask for confirmation
      if (!mounted) return;
      setState(() {
        _confirmPin = pin;
        _errorMessage = null;
        _pinController.clear();
      });
      return;
    }

    // Verify confirmation matches
    if (_confirmPin != pin) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _pinController.clear();
      });
      return;
    }

    // Save PIN
    final success = await _localAuthService.setPin(pin);

    if (!mounted) return;

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'Failed to save PIN';
        _confirmPin = '';
        _pinController.clear();
      });
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter your PIN';
      });
      return;
    }

    final isCorrect = await _localAuthService.verifyPin(pin);

    if (!mounted) return;

    if (isCorrect) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
      });
    }
  }

  void _handlePinSubmit() {
    if (_isCreatingPin) {
      _createPin();
    } else {
      _verifyPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lock Icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 64,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          _isCreatingPin
                              ? 'Create Your PIN'
                              : 'Unlock Password Manager',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          _isCreatingPin
                              ? (_confirmPin.isEmpty
                                  ? 'Enter a PIN to secure your passwords'
                                  : 'Confirm your PIN')
                              : 'Enter your PIN or use biometrics',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // PIN Input Section
                        if (_showPinInput) ...[
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _pinController,
                                    obscureText: _obscurePin,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: _isCreatingPin
                                          ? (_confirmPin.isEmpty
                                              ? 'Create PIN'
                                              : 'Confirm PIN')
                                          : 'Enter PIN',
                                      hintText: 'At least 4 digits',
                                      prefixIcon: const Icon(Icons.pin_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePin
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePin = !_obscurePin;
                                          });
                                        },
                                      ),
                                      counterText: '',
                                    ),
                                    onSubmitted: (_) => _handlePinSubmit(),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _handlePinSubmit,
                                    icon: Icon(_isCreatingPin
                                        ? Icons.check_rounded
                                        : Icons.lock_open_rounded),
                                    label: Text(_isCreatingPin
                                        ? (_confirmPin.isEmpty
                                            ? 'Continue'
                                            : 'Create PIN')
                                        : 'Unlock'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Biometric button (only if not creating PIN)
                          if (!_isCreatingPin)
                            FutureBuilder<bool>(
                              future: _localAuthService.canCheckBiometrics(),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return TextButton.icon(
                                    onPressed: _authenticateWithBiometric,
                                    icon: const Icon(Icons.fingerprint_rounded),
                                    label: const Text('Use Biometrics'),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ] else ...[
                          // Biometric-only button
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  FilledButton.icon(
                                    onPressed: _authenticateWithBiometric,
                                    icon: const Icon(Icons.fingerprint_rounded,
                                        size: 28),
                                    label: const Text('Authenticate'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showPinInput = true;
                                      });
                                    },
                                    child: const Text('Use PIN Instead'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
