import 'package:flutter_test/flutter_test.dart';
import 'package:passwords/models/password_entry.dart';

void main() {
  group('PasswordEntry Model Tests', () {
    test('creates PasswordEntry with all fields', () {
      final entry = PasswordEntry(
        id: 'test-id-123',
        title: 'Gmail Account',
        category: 'Email',
        fields: [
          const MapEntry('Username', 'user@gmail.com'),
          const MapEntry('Password', 'securePass123'),
          const MapEntry('Recovery Email', 'backup@email.com'),
        ],
      );

      expect(entry.id, 'test-id-123');
      expect(entry.title, 'Gmail Account');
      expect(entry.category, 'Email');
      expect(entry.fields.length, 3);
      expect(entry.fields[0].key, 'Username');
      expect(entry.fields[0].value, 'user@gmail.com');
    });

    test('creates PasswordEntry without id (for new entries)', () {
      final entry = PasswordEntry(
        title: 'New Entry',
        category: 'Social Media',
        fields: [
          const MapEntry('Email', 'test@example.com'),
        ],
      );

      expect(entry.id, isNull);
      expect(entry.title, 'New Entry');
      expect(entry.category, 'Social Media');
    });

    test('toJson converts PasswordEntry to Map correctly', () {
      final entry = PasswordEntry(
        id: 'doc-123',
        title: 'Bank Account',
        category: 'Banking',
        fields: [
          const MapEntry('Account Number', '1234567890'),
          const MapEntry('PIN', '9876'),
        ],
      );

      final json = entry.toJson();

      expect(json['title'], 'Bank Account');
      expect(json['category'], 'Banking');
      expect(json['fields'], isA<List>());
      expect(json['fields'].length, 2);
      expect(json['fields'][0]['key'], 'Account Number');
      expect(json['fields'][0]['value'], '1234567890');
      expect(json['fields'][1]['key'], 'PIN');
      expect(json['fields'][1]['value'], '9876');
      // Note: id is not included in toJson (Firestore handles it separately)
      expect(json.containsKey('id'), isFalse);
    });

    test('fromJson creates PasswordEntry from Map', () {
      final json = {
        'title': 'Netflix',
        'category': 'Entertainment',
        'fields': [
          {'key': 'Email', 'value': 'user@netflix.com'},
          {'key': 'Password', 'value': 'netflixPass'},
        ],
      };

      final entry = PasswordEntry.fromJson(json, id: 'netflix-doc-id');

      expect(entry.id, 'netflix-doc-id');
      expect(entry.title, 'Netflix');
      expect(entry.category, 'Entertainment');
      expect(entry.fields.length, 2);
      expect(entry.fields[0].key, 'Email');
      expect(entry.fields[0].value, 'user@netflix.com');
    });

    test('fromJson works without id parameter', () {
      final json = {
        'title': 'Test Entry',
        'category': 'Test',
        'fields': [],
      };

      final entry = PasswordEntry.fromJson(json);

      expect(entry.id, isNull);
      expect(entry.title, 'Test Entry');
    });

    test('toJson and fromJson are reversible', () {
      final original = PasswordEntry(
        title: 'Original Entry',
        category: 'Test Category',
        fields: [
          const MapEntry('Field1', 'Value1'),
          const MapEntry('Field2', 'Value2'),
          const MapEntry('Field3', 'Value3'),
        ],
      );

      final json = original.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.fields.length, original.fields.length);
      for (var i = 0; i < original.fields.length; i++) {
        expect(restored.fields[i].key, original.fields[i].key);
        expect(restored.fields[i].value, original.fields[i].value);
      }
    });

    test('copyWith creates copy with same values', () {
      final original = PasswordEntry(
        id: 'old-id',
        title: 'Original',
        category: 'Test',
        fields: [const MapEntry('key', 'value')],
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.category, original.category);
      expect(copy.fields, original.fields);
    });

    test('copyWith updates id when provided', () {
      final original = PasswordEntry(
        id: 'old-id',
        title: 'Entry',
        category: 'Test',
        fields: [const MapEntry('key', 'value')],
      );

      final withNewId = original.copyWith(id: 'new-id-456');

      expect(withNewId.id, 'new-id-456');
      expect(withNewId.title, original.title);
      expect(withNewId.category, original.category);
      expect(withNewId.fields, original.fields);
    });

    test('handles empty fields list', () {
      final entry = PasswordEntry(
        title: 'Empty Entry',
        category: 'Test',
        fields: [],
      );

      final json = entry.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(entry.fields.isEmpty, isTrue);
      expect(restored.fields.isEmpty, isTrue);
    });

    test('handles special characters in fields', () {
      final entry = PasswordEntry(
        title: 'Special Chars',
        category: 'Test',
        fields: [
          const MapEntry('Password', 'P@ss!#\$%^&*()'),
          const MapEntry('Email', 'test+label@example.com'),
          const MapEntry('Notes', 'Line1\nLine2\tTabbed'),
        ],
      );

      final json = entry.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(restored.fields[0].value, 'P@ss!#\$%^&*()');
      expect(restored.fields[1].value, 'test+label@example.com');
      expect(restored.fields[2].value, 'Line1\nLine2\tTabbed');
    });

    test('handles unicode characters', () {
      final entry = PasswordEntry(
        title: '测试条目',
        category: 'テスト',
        fields: [
          const MapEntry('Email', 'مستخدم@example.com'),
          const MapEntry('Emoji', '🔒🔑🛡️'),
        ],
      );

      final json = entry.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(restored.title, '测试条目');
      expect(restored.category, 'テスト');
      expect(restored.fields[0].value, 'مستخدم@example.com');
      expect(restored.fields[1].value, '🔒🔑🛡️');
    });

    test('handles very long field values', () {
      final longValue = 'a' * 10000;
      final entry = PasswordEntry(
        title: 'Long Entry',
        category: 'Test',
        fields: [
          MapEntry('LongField', longValue),
        ],
      );

      final json = entry.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(restored.fields[0].value.length, 10000);
      expect(restored.fields[0].value, longValue);
    });

    test('handles multiple fields with same key', () {
      final entry = PasswordEntry(
        title: 'Duplicate Keys',
        category: 'Test',
        fields: [
          const MapEntry('Note', 'First note'),
          const MapEntry('Note', 'Second note'),
          const MapEntry('Note', 'Third note'),
        ],
      );

      final json = entry.toJson();
      final restored = PasswordEntry.fromJson(json);

      expect(restored.fields.length, 3);
      expect(restored.fields.where((f) => f.key == 'Note').length, 3);
    });
  });
}
