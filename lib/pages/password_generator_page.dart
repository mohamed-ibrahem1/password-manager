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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generated Password Display - Material 3 Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.key_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generated Password',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _generatedPasswordController.text,
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _generatePassword,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              'Regenerate',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Options Card - Material 3 styling
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Options',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password Length Slider
                    Text(
                      'Password Length',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _passwordLength.toDouble(),
                            min: 6,
                            max: 32,
                            divisions: 26,
                            label: _passwordLength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _passwordLength = value.toInt();
                                _generatePassword();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_passwordLength',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 8),
                    // Character Options with Material 3 styling
                    _buildOptionTile(
                      context,
                      title: 'Uppercase Letters',
                      subtitle: 'A, B, C...',
                      icon: Icons.text_fields_rounded,
                      value: _includeUppercase,
                      onChanged: (value) {
                        setState(() {
                          _includeUppercase = value ?? true;
                          _generatePassword();
                        });
                      },
                    ),
                    _buildOptionTile(
                      context,
                      title: 'Numbers',
                      subtitle: '0, 1, 2...',
                      icon: Icons.pin_rounded,
                      value: _includeNumbers,
                      onChanged: (value) {
                        setState(() {
                          _includeNumbers = value ?? true;
                          _generatePassword();
                        });
                      },
                    ),
                    _buildOptionTile(
                      context,
                      title: 'Special Characters',
                      subtitle: '!, @, #...',
                      icon: Icons.tag_rounded,
                      value: _includeSpecialChars,
                      onChanged: (value) {
                        setState(() {
                          _includeSpecialChars = value ?? true;
                          _generatePassword();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: value ? colorScheme.secondaryContainer.withOpacity(0.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        secondary: Icon(
          icon,
          color: value
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
