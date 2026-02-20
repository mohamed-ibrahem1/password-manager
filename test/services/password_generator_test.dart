import 'package:flutter_test/flutter_test.dart';
import 'package:passwords/pages/password_generator_page.dart';

void main() {
  group('PasswordGenerator Tests', () {
    test('generates password with default length of 12', () {
      final password = PasswordGenerator.generatePassword();
      expect(password.length, 12);
    });

    test('generates password with custom length', () {
      final password = PasswordGenerator.generatePassword(length: 20);
      expect(password.length, 20);
    });

    test('generates very short password (minimum 1)', () {
      final password = PasswordGenerator.generatePassword(length: 1);
      expect(password.length, 1);
    });

    test('generates very long password (100+ characters)', () {
      final password = PasswordGenerator.generatePassword(length: 150);
      expect(password.length, 150);
    });

    test('generates password with lowercase only', () {
      final password = PasswordGenerator.generatePassword(
        length: 50,
        includeUppercase: false,
        includeNumbers: false,
        includeSpecialChars: false,
      );

      expect(password.length, 50);
      expect(password, matches(r'^[a-z]+$'));
    });

    test('generates password with uppercase letters', () {
      final password = PasswordGenerator.generatePassword(
        length: 50,
        includeUppercase: true,
        includeNumbers: false,
        includeSpecialChars: false,
      );

      expect(password.length, 50);
      expect(password, matches(r'^[a-zA-Z]+$'));
      // With 50 characters, very likely to have at least one uppercase
      expect(password, matches(r'.*[A-Z].*'));
    });

    test('generates password with numbers', () {
      final password = PasswordGenerator.generatePassword(
        length: 50,
        includeUppercase: false,
        includeNumbers: true,
        includeSpecialChars: false,
      );

      expect(password.length, 50);
      expect(password, matches(r'^[a-z0-9]+$'));
      // With 50 characters, very likely to have at least one number
      expect(password, matches(r'.*[0-9].*'));
    });

    test('generates password with special characters', () {
      final password = PasswordGenerator.generatePassword(
        length: 50,
        includeUppercase: false,
        includeNumbers: false,
        includeSpecialChars: true,
      );

      expect(password.length, 50);
      // Check contains only lowercase and special chars
      expect(password, matches(r'^[a-z!@#\$%^&*()\-_+=\[\]{}|;:,.<>?]+$'));
    });

    test('generates password with all character types', () {
      final password = PasswordGenerator.generatePassword(
        length: 100,
        includeUppercase: true,
        includeNumbers: true,
        includeSpecialChars: true,
      );

      expect(password.length, 100);
      // With 100 characters, should contain all types
      expect(password, matches(r'.*[a-z].*')); // lowercase
      expect(password, matches(r'.*[A-Z].*')); // uppercase
      expect(password, matches(r'.*[0-9].*')); // numbers
      expect(password,
          matches(r'.*[!@#\$%^&*()\-_+=\[\]{}|;:,.<>?].*')); // special
    });

    test('generates different passwords on multiple calls', () {
      final password1 = PasswordGenerator.generatePassword(length: 20);
      final password2 = PasswordGenerator.generatePassword(length: 20);
      final password3 = PasswordGenerator.generatePassword(length: 20);

      // Extremely unlikely to generate the same password three times
      expect(password1 == password2 && password2 == password3, isFalse);
    });

    test('passwords are truly random (statistical test)', () {
      final passwords = List.generate(
        100,
        (_) => PasswordGenerator.generatePassword(length: 12),
      );

      // All should be unique (extremely high probability)
      final uniquePasswords = passwords.toSet();
      expect(uniquePasswords.length, greaterThan(95)); // Allow some collision
    });

    test('generates consistent length regardless of options', () {
      for (var length in [1, 5, 10, 15, 20, 50, 100]) {
        final p1 = PasswordGenerator.generatePassword(
          length: length,
          includeUppercase: true,
          includeNumbers: true,
          includeSpecialChars: true,
        );
        final p2 = PasswordGenerator.generatePassword(
          length: length,
          includeUppercase: false,
          includeNumbers: false,
          includeSpecialChars: false,
        );

        expect(p1.length, length);
        expect(p2.length, length);
      }
    });

    test('handles edge case: length = 0', () {
      final password = PasswordGenerator.generatePassword(length: 0);
      expect(password.isEmpty, isTrue);
    });

    test('distribution test: uppercase characters appear when enabled', () {
      // Generate many passwords and check that uppercase appears
      var hasUppercase = false;
      for (var i = 0; i < 10; i++) {
        final password = PasswordGenerator.generatePassword(
          length: 20,
          includeUppercase: true,
        );
        if (password.contains(RegExp(r'[A-Z]'))) {
          hasUppercase = true;
          break;
        }
      }
      expect(hasUppercase, isTrue);
    });

    test('distribution test: numbers appear when enabled', () {
      var hasNumbers = false;
      for (var i = 0; i < 10; i++) {
        final password = PasswordGenerator.generatePassword(
          length: 20,
          includeNumbers: true,
        );
        if (password.contains(RegExp(r'[0-9]'))) {
          hasNumbers = true;
          break;
        }
      }
      expect(hasNumbers, isTrue);
    });

    test('distribution test: special chars appear when enabled', () {
      var hasSpecial = false;
      for (var i = 0; i < 10; i++) {
        final password = PasswordGenerator.generatePassword(
          length: 20,
          includeSpecialChars: true,
        );
        if (password.contains(RegExp(r'[!@#\$%^&*()\-_+=\[\]{}|;:,.<>?]'))) {
          hasSpecial = true;
          break;
        }
      }
      expect(hasSpecial, isTrue);
    });

    test('character set constants are correct', () {
      // This test validates the internal character sets
      final lowercase = PasswordGenerator.generatePassword(
        length: 100,
        includeUppercase: false,
        includeNumbers: false,
        includeSpecialChars: false,
      );

      // Should only contain a-z
      for (var char in lowercase.split('')) {
        expect(char.codeUnitAt(0), greaterThanOrEqualTo('a'.codeUnitAt(0)));
        expect(char.codeUnitAt(0), lessThanOrEqualTo('z'.codeUnitAt(0)));
      }
    });

    test('no invalid characters in generated password', () {
      final password = PasswordGenerator.generatePassword(
        length: 100,
        includeUppercase: true,
        includeNumbers: true,
        includeSpecialChars: true,
      );

      // Should only contain valid character set
      final validChars =
          RegExp(r'^[a-zA-Z0-9!@#\$%^&*()\-_+=\[\]{}|;:,.<>?]+$');
      expect(password, matches(validChars));
    });

    test('password strength increases with character variety', () {
      final weak = PasswordGenerator.generatePassword(
        length: 8,
        includeUppercase: false,
        includeNumbers: false,
        includeSpecialChars: false,
      );

      final strong = PasswordGenerator.generatePassword(
        length: 8,
        includeUppercase: true,
        includeNumbers: true,
        includeSpecialChars: true,
      );

      // Strong password should use more of the character space
      // (This is a conceptual test - both are valid)
      expect(weak.length, 8);
      expect(strong.length, 8);
      expect(weak, matches(r'^[a-z]+$'));
      // Strong likely has variety (not guaranteed in 8 chars, but likely)
    });
  });
}
