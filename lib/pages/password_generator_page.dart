import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  final TextEditingController _generatedPasswordController =
      TextEditingController();
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;
  int _passwordLength = 12;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    final password = PasswordGenerator.generatePassword(
      length: _passwordLength,
      includeUppercase: _includeUppercase,
      includeNumbers: _includeNumbers,
      includeSpecialChars: _includeSpecialChars,
    );

    setState(() {
      _generatedPasswordController.text = password;
    });
  }

  void _copyToClipboard() {
    if (_generatedPasswordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPasswordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Generator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _generatedPasswordController,
              readOnly: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Generated Password',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyToClipboard,
                      tooltip: 'Copy password',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generatePassword,
                      tooltip: 'Generate new password',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Length: $_passwordLength'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Slider(
                            value: _passwordLength.toDouble(),
                            min: 6,
                            max: 20,
                            divisions: 14,
                            label: _passwordLength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _passwordLength = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      title: const Text('Include Uppercase Letters'),
                      subtitle: const Text('A, B, C...'),
                      value: _includeUppercase,
                      onChanged: (value) {
                        setState(() {
                          _includeUppercase = value ?? true;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Include Numbers'),
                      subtitle: const Text('0, 1, 2...'),
                      value: _includeNumbers,
                      onChanged: (value) {
                        setState(() {
                          _includeNumbers = value ?? true;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Include Special Characters'),
                      subtitle: const Text('!, @, #...'),
                      value: _includeSpecialChars,
                      onChanged: (value) {
                        setState(() {
                          _includeSpecialChars = value ?? true;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate New Password'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generatePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    String chars = _lowercase;

    if (includeUppercase) chars += _uppercase;
    if (includeNumbers) chars += _numbers;
    if (includeSpecialChars) chars += _specialChars;

    Random random = Random();
    String password = '';

    for (int i = 0; i < length; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    return password;
  }
}
