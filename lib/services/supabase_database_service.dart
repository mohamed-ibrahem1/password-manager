import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/password_entry.dart';

/// Supabase Database Service for Password Management
///
/// Handles all database operations using Supabase Postgres
/// Replaces Firebase Firestore with Supabase
class SupabaseDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Table name
  static const String _passwordsTable = 'passwords';

  /// Add a new password entry
  Future<void> addPassword(PasswordEntry entry, String userId) async {
    try {
      await _supabase.from(_passwordsTable).insert({
        'user_id': userId,
        'title': entry.title,
        'fields':
            entry.fields.map((f) => {'key': f.key, 'value': f.value}).toList(),
        'category': entry.category,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Get all passwords for a user
  Future<List<PasswordEntry>> getPasswords(String userId) async {
    try {
      final response = await _supabase
          .from(_passwordsTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => PasswordEntry.fromJson(
                {
                  'title': data['title'],
                  'fields': data['fields'],
                  'category': data['category'],
                },
                id: data['id'].toString(),
              ))
          .toList();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Get passwords by category
  Future<List<PasswordEntry>> getPasswordsByCategory(
      String userId, String category) async {
    try {
      final response = await _supabase
          .from(_passwordsTable)
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => PasswordEntry.fromJson(
                {
                  'title': data['title'],
                  'fields': data['fields'],
                  'category': data['category'],
                },
                id: data['id'].toString(),
              ))
          .toList();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Update a password entry
  Future<void> updatePassword(
      String id, PasswordEntry entry, String userId) async {
    try {
      await _supabase
          .from(_passwordsTable)
          .update({
            'title': entry.title,
            'fields': entry.fields
                .map((f) => {'key': f.key, 'value': f.value})
                .toList(),
            'category': entry.category,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(id))
          .eq('user_id', userId);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Delete a password entry
  Future<void> deletePassword(String id, String userId) async {
    try {
      await _supabase
          .from(_passwordsTable)
          .delete()
          .eq('id', int.parse(id))
          .eq('user_id', userId);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Get all unique categories for a user
  Future<List<String>> getCategories(String userId) async {
    try {
      final response = await _supabase
          .from(_passwordsTable)
          .select('category')
          .eq('user_id', userId);

      final categories = (response as List)
          .map((data) => data['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Search passwords by title
  Future<List<PasswordEntry>> searchPasswords(
      String userId, String query) async {
    try {
      final response = await _supabase
          .from(_passwordsTable)
          .select()
          .eq('user_id', userId)
          .ilike('title', '%$query%')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => PasswordEntry.fromJson(
                {
                  'title': data['title'],
                  'fields': data['fields'],
                  'category': data['category'],
                },
                id: data['id'].toString(),
              ))
          .toList();
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Delete all passwords in a category
  Future<void> deleteCategory(String userId, String category) async {
    try {
      await _supabase
          .from(_passwordsTable)
          .delete()
          .eq('user_id', userId)
          .eq('category', category);
    } catch (e) {
      throw _handleDatabaseError(e);
    }
  }

  /// Handle database errors with user-friendly messages
  Exception _handleDatabaseError(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return Exception('A password with this title already exists');
        case '42501':
          return Exception('Permission denied - please sign in again');
        case '23503':
          return Exception('Invalid reference');
        case 'PGRST116':
          return Exception('No data found');
        default:
          return Exception('Database error: ${error.message}');
      }
    }
    return Exception('An unexpected error occurred: $error');
  }
}
