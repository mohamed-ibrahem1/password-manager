import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passwords/pages/category_grid_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _authenticated = false;
  bool _checking = false;
  String? _error;
  bool _showPasswordInput = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isPasswordSet = false;
  bool _isCreatingPassword = false;

  @override
  void initState() {
    super.initState();
    _checkIfPasswordIsSet();
  }

  Future<void> _checkIfPasswordIsSet() async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString('app_password');
    setState(() {
      _isPasswordSet = password != null;
      _isCreatingPassword = !_isPasswordSet && _showPasswordInput;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      if (!canCheck || !isSupported) {
        setState(() {
          _error = 'Biometric authentication not available.';
          _checking = false;
        });
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      setState(() {
        _authenticated = authenticated;
        _checking = false;
        if (!authenticated) {
          _error = 'Authentication failed. Try again.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _checking = false;
      });
    }
  }

  Future<void> _createPassword() async {
    if (_passwordController.text.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_password', _passwordController.text);

    setState(() {
      _isPasswordSet = true;
      _isCreatingPassword = false;
      _error = null;
      _authenticated = true;
    });
  }

  Future<void> _verifyPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('app_password');

    if (storedPassword == _passwordController.text) {
      setState(() {
        _authenticated = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = 'Incorrect password';
        _passwordController.clear();
      });
    }
  }

  void _togglePasswordInput() {
    setState(() {
      _showPasswordInput = !_showPasswordInput;
      _error = null;
      _isCreatingPassword = !_isPasswordSet && _showPasswordInput;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return const CategoryGridPage();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
        centerTitle: true,
      ),
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Unlock Your Password Manager',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!_showPasswordInput) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Unlock with Fingerprint'),
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _togglePasswordInput,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Use Password Instead'),
                      ),
                    ] else ...[
                      Text(
                        _isCreatingPassword
                            ? 'Create a password to secure your app'
                            : 'Enter your password',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (_) {
                          if (_isCreatingPassword) {
                            _createPassword();
                          } else {
                            _verifyPassword();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_isCreatingPassword) {
                            _createPassword();
                          } else {
                            _verifyPassword();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                            _isCreatingPassword ? 'Create Password' : 'Unlock'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _togglePasswordInput,
                        child: const Text('Use Fingerprint Instead'),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
