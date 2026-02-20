import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/local_auth_service.dart';
import 'login_page.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final LocalAuthService _localAuthService = LocalAuthService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _canUseBiometric = false;
  bool _isPinSet = false;
  String _authMethodDescription = 'None';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final biometricEnabled = await _localAuthService.isBiometricEnabled();
    final pinEnabled = await _localAuthService.isPinEnabled();
    final canUseBiometric = await _localAuthService.canCheckBiometrics();
    final isPinSet = await _localAuthService.isPinSet();
    final authMethod = await _localAuthService.getAuthMethodDescription();

    setState(() {
      _biometricEnabled = biometricEnabled;
      _pinEnabled = pinEnabled;
      _canUseBiometric = canUseBiometric;
      _isPinSet = isPinSet;
      _authMethodDescription = authMethod;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_canUseBiometric) {
      _showErrorDialog(
          'Biometric authentication is not available on this device');
      return;
    }

    await _localAuthService.setBiometricEnabled(value);
    await _loadSettings();
  }

  Future<void> _togglePin(bool value) async {
    if (value && !_isPinSet) {
      // Need to create PIN first
      _showCreatePinDialog();
    } else {
      await _localAuthService.setPinEnabled(value);
      await _loadSettings();
    }
  }

  void _showCreatePinDialog() {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    bool obscurePin = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.pin_rounded),
          title: const Text('Create PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                obscureText: obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  hintText: 'At least 4 digits',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePin
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () {
                      setDialogState(() {
                        obscurePin = !obscurePin;
                      });
                    },
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPinController,
                obscureText: obscureConfirm,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  hintText: 'Re-enter PIN',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () {
                      setDialogState(() {
                        obscureConfirm = !obscureConfirm;
                      });
                    },
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                if (pin.length < 4) {
                  _showErrorDialog('PIN must be at least 4 digits');
                  return;
                }

                if (pin != confirmPin) {
                  _showErrorDialog('PINs do not match');
                  return;
                }

                final success = await _localAuthService.setPin(pin);
                if (!mounted) return;

                if (success) {
                  Navigator.pop(context);
                  await _loadSettings();
                  _showSuccessDialog('PIN created successfully');
                } else {
                  _showErrorDialog('Failed to create PIN');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_rounded),
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                prefixIcon: Icon(Icons.lock_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.lock_open_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final currentPin = currentPinController.text.trim();
              final newPin = newPinController.text.trim();
              final confirmPin = confirmPinController.text.trim();

              // Verify current PIN
              final isCorrect = await _localAuthService.verifyPin(currentPin);
              if (!isCorrect) {
                _showErrorDialog('Current PIN is incorrect');
                return;
              }

              if (newPin.length < 4) {
                _showErrorDialog('PIN must be at least 4 digits');
                return;
              }

              if (newPin != confirmPin) {
                _showErrorDialog('PINs do not match');
                return;
              }

              final success = await _localAuthService.setPin(newPin);
              if (!mounted) return;

              if (success) {
                Navigator.pop(context);
                _showSuccessDialog('PIN changed successfully');
              } else {
                _showErrorDialog('Failed to change PIN');
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeletePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Delete PIN'),
        content: const Text(
          'Are you sure you want to delete your PIN? You will need to create a new one next time you open the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await _localAuthService.deletePin();
              if (!mounted) return;
              Navigator.pop(context);
              await _loadSettings();
              _showSuccessDialog('PIN deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Account',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: _authService.userPhotoUrl != null
                                ? NetworkImage(_authService.userPhotoUrl!)
                                : null,
                            child: _authService.userPhotoUrl == null
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                          title: Text(_authService.userDisplayName),
                          subtitle: Text(_authService.userEmail),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await _authService.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign Out'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Local Authentication Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Local Security',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active method: $_authMethodDescription',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 24),

                        // Biometric Toggle
                        SwitchListTile(
                          title: const Text('Biometric Authentication'),
                          subtitle: Text(_canUseBiometric
                              ? 'Use fingerprint or face recognition'
                              : 'Not available on this device'),
                          value: _biometricEnabled,
                          onChanged: _canUseBiometric ? _toggleBiometric : null,
                          secondary: Icon(
                            Icons.fingerprint_rounded,
                            color: _canUseBiometric
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                        ),

                        // PIN Toggle
                        SwitchListTile(
                          title: const Text('PIN Authentication'),
                          subtitle: Text(_isPinSet
                              ? 'PIN is configured'
                              : 'No PIN set - tap to create'),
                          value: _pinEnabled,
                          onChanged: _togglePin,
                          secondary: Icon(
                            Icons.pin_rounded,
                            color: colorScheme.primary,
                          ),
                        ),

                        // PIN Management Buttons
                        if (_isPinSet) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showChangePinDialog,
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Change PIN'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showDeletePinDialog,
                                  icon: const Icon(Icons.delete_rounded),
                                  label: const Text('Delete PIN'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Local authentication adds an extra layer of security to protect your passwords on this device.',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
