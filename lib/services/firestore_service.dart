import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/password_entry.dart';
import 'auth_service.dart';

/// Service for managing password entries in Supabase PostgreSQL
///
/// Features:
/// - User-isolated data storage with Row Level Security
/// - Real-time synchronization
/// - PostgreSQL database (more powerful than Firestore)
/// - Comprehensive error handling
class FirestoreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Table name
  static const String _passwordsTable = 'passwords';

  // Error messages
  static const String _errorNotAuthenticated =
      'User not authenticated. Please sign in again.';
  static const String _errorPermission =
      'Permission denied. Please sign in again.';
  static const String _errorNotFound = 'Password entry not found.';

  /// Get user ID and verify authentication
  String _getUserId() {
    final userId = _authService.userId;
    if (userId.isEmpty) {
      throw FirestoreServiceException(_errorNotAuthenticated);
    }
    return userId;
  }

  /// Save a new password entry
  ///
  /// Returns the database ID of the created entry
  /// Throws [FirestoreServiceException] on failure
  Future<String> savePassword(PasswordEntry entry) async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_passwordsTable)
          .insert({
            'user_id': userId,
            'title': entry.title,
            'fields': entry.fields
                .map((f) => {'key': f.key, 'value': f.value})
                .toList(),
            'category': entry.category,
          })
          .select('id')
          .single();
      return response['id'].toString();
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(_handleDatabaseError(e, 'save'));
    } catch (e) {
      throw FirestoreServiceException('Failed to save password: $e');
    }
  }

  /// Get all password entries for the current user
  ///
  /// Returns empty list if no passwords exist
  /// Throws [FirestoreServiceException] on failure
  Future<List<PasswordEntry>> getPasswords() async {
    try {
      final userId = _getUserId();
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
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(_handleDatabaseError(e, 'fetch'));
    } catch (e) {
      throw FirestoreServiceException('Failed to fetch passwords: $e');
    }
  }

  /// Update an existing password entry
  ///
  /// Throws [FirestoreServiceException] if entry doesn't exist or update fails
  Future<void> updatePassword(PasswordEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) {
      throw FirestoreServiceException('Cannot update password: ID is missing');
    }

    try {
      final userId = _getUserId();
      await _supabase
          .from(_passwordsTable)
          .update({
            'title': entry.title,
            'fields': entry.fields
                .map((f) => {'key': f.key, 'value': f.value})
                .toList(),
            'category': entry.category,
          })
          .eq('id', int.parse(entry.id!))
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(_handleDatabaseError(e, 'update'));
    } catch (e) {
      throw FirestoreServiceException('Failed to update password: $e');
    }
  }

  /// Delete a password entry by ID
  ///
  /// Throws [FirestoreServiceException] on failure
  Future<void> deletePassword(String id) async {
    if (id.isEmpty) {
      throw FirestoreServiceException('Cannot delete password: ID is missing');
    }

    try {
      final userId = _getUserId();
      await _supabase
          .from(_passwordsTable)
          .delete()
          .eq('id', int.parse(id))
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(_handleDatabaseError(e, 'delete'));
    } catch (e) {
      throw FirestoreServiceException('Failed to delete password: $e');
    }
  }

  /// Get real-time stream of password entries
  ///
  /// Stream automatically updates when data changes in database
  Stream<List<PasswordEntry>> getPasswordsStream() {
    try {
      final userId = _getUserId();
      return _supabase
          .from(_passwordsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .map((data) => data
              .map((item) {
                try {
                  return PasswordEntry.fromJson(
                    {
                      'title': item['title'],
                      'fields': item['fields'],
                      'category': item['category'],
                    },
                    id: item['id'].toString(),
                  );
                } catch (e) {
                  print('Error parsing item: $e');
                  return null;
                }
              })
              .whereType<PasswordEntry>()
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get passwords filtered by category
  ///
  /// Returns only passwords matching the specified category
  Future<List<PasswordEntry>> getPasswordsByCategory(String category) async {
    try {
      final userId = _getUserId();
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
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(_handleDatabaseError(e, 'fetch'));
    } catch (e) {
      throw FirestoreServiceException(
          'Failed to fetch passwords by category: $e');
    }
  }

  /// Get list of all unique categories
  ///
  /// Returns empty list if no passwords exist
  Future<List<String>> getCategories() async {
    try {
      final userId = _getUserId();
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
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(
          _handleDatabaseError(e, 'fetch categories'));
    } catch (e) {
      throw FirestoreServiceException('Failed to fetch categories: $e');
    }
  }

  /// Delete all passwords in a category
  ///
  /// Returns the number of passwords deleted
  Future<int> deleteCategory(String category) async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_passwordsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('category', category);

      final count = (response as List).length;

      if (count > 0) {
        await _supabase
            .from(_passwordsTable)
            .delete()
            .eq('user_id', userId)
            .eq('category', category);
      }

      return count;
    } on PostgrestException catch (e) {
      throw FirestoreServiceException(
          _handleDatabaseError(e, 'delete category'));
    } catch (e) {
      throw FirestoreServiceException('Failed to delete category: $e');
    }
  }

  /// Handle database errors with user-friendly messages
  String _handleDatabaseError(PostgrestException error, String operation) {
    switch (error.code) {
      case '42501':
      case '42P01':
        return _errorPermission;
      case 'PGRST116':
        return _errorNotFound;
      case '23505':
        return 'This entry already exists.';
      case '23503':
        return 'Invalid reference.';
      default:
        return 'Failed to $operation: ${error.message}';
    }
  }
}

/// Custom exception for Firestore operations
class FirestoreServiceException implements Exception {
  final String message;

  FirestoreServiceException(this.message);

  @override
  String toString() => message;
}
