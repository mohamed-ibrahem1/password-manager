import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/image_entry.dart';
import 'auth_service.dart';

/// Service for managing saved images in Supabase PostgreSQL
///
/// Features:
/// - User-isolated data storage with Row Level Security
/// - Real-time synchronization
/// - Base64 image storage
/// - Comprehensive error handling
class ImageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Shared broadcast StreamController for real-time updates
  static StreamController<List<ImageEntry>>? _streamController;
  static Timer? _pollingTimer;

  // Table name
  static const String _imagesTable = 'saved_images';

  // SharedPreferences key prefix for persisted categories
  static const String _categoriesKeyPrefix = 'image_categories_';

  // Error messages
  static const String _errorNotAuthenticated =
      'User not authenticated. Please sign in again.';
  static const String _errorPermission =
      'Permission denied. Please sign in again.';
  static const String _errorNotFound = 'Image entry not found.';

  /// Get user ID and verify authentication
  String _getUserId() {
    final userId = _authService.userId;
    if (userId.isEmpty) {
      throw ImageStorageServiceException(_errorNotAuthenticated);
    }
    return userId;
  }

  /// Save a new image entry
  ///
  /// Returns the database ID of the created entry
  Future<String> saveImage(ImageEntry entry) async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_imagesTable)
          .insert({
            'user_id': userId,
            'title': entry.title,
            'image_data': entry.imageData,
            'category': entry.category,
          })
          .select('id')
          .single();
      return response['id'].toString();
    } on PostgrestException catch (e) {
      if (e.code == '42P01' ||
          (e.message.contains('relation') &&
              e.message.contains('does not exist'))) {
        throw ImageStorageServiceException(
            'The saved_images table does not exist. Please create it in your Supabase database. See SUPABASE_SETUP.md for instructions.');
      }
      throw ImageStorageServiceException(_handleDatabaseError(e, 'save'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to save image: $e');
    }
  }

  /// Get all image entries for the current user
  Future<List<ImageEntry>> getImages() async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_imagesTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => ImageEntry.fromJson(
                {
                  'title': data['title'],
                  'image_data': data['image_data'],
                  'category': data['category'],
                },
                id: data['id'].toString(),
              ))
          .toList();
    } on PostgrestException catch (e) {
      // Table may not exist yet - return empty list instead of throwing
      if (e.code == '42P01' ||
          (e.message.contains('relation') &&
              e.message.contains('does not exist'))) {
        return [];
      }
      throw ImageStorageServiceException(_handleDatabaseError(e, 'fetch'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to fetch images: $e');
    }
  }

  /// Update an existing image entry
  Future<void> updateImage(ImageEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) {
      throw ImageStorageServiceException('Cannot update image: ID is missing');
    }

    try {
      final userId = _getUserId();
      await _supabase
          .from(_imagesTable)
          .update({
            'title': entry.title,
            'image_data': entry.imageData,
            'category': entry.category,
          })
          .eq('id', int.parse(entry.id!))
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ImageStorageServiceException(_handleDatabaseError(e, 'update'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to update image: $e');
    }
  }

  /// Delete an image entry by ID
  Future<void> deleteImage(String id) async {
    if (id.isEmpty) {
      throw ImageStorageServiceException('Cannot delete image: ID is missing');
    }

    try {
      final userId = _getUserId();
      await _supabase
          .from(_imagesTable)
          .delete()
          .eq('id', int.parse(id))
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ImageStorageServiceException(_handleDatabaseError(e, 'delete'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to delete image: $e');
    }
  }

  /// Get real-time stream of image entries
  ///
  /// Uses a shared broadcast StreamController so multiple listeners
  /// can subscribe/unsubscribe safely.
  Stream<List<ImageEntry>> getImagesStream() {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<List<ImageEntry>>.broadcast();
      // Fetch immediately, then poll
      _pollImages();
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _pollImages();
      });
    }
    return _streamController!.stream;
  }

  /// Poll the database and push to stream
  Future<void> _pollImages() async {
    if (_streamController == null || _streamController!.isClosed) return;
    final images = await _safeGetImages();
    if (_streamController != null && !_streamController!.isClosed) {
      _streamController!.add(images);
    }
  }

  /// Stop polling (call when no longer needed)
  void disposeStream() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _streamController?.close();
    _streamController = null;
  }

  /// Safely get images, returning empty list on any error
  Future<List<ImageEntry>> _safeGetImages() async {
    try {
      return await getImages();
    } catch (e) {
      return [];
    }
  }

  /// Get images filtered by category
  Future<List<ImageEntry>> getImagesByCategory(String category) async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_imagesTable)
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((data) => ImageEntry.fromJson(
                {
                  'title': data['title'] ?? '',
                  'image_data': data['image_data'] ?? '',
                  'category': data['category'] ?? category,
                },
                id: data['id'].toString(),
              ))
          .toList();
    } on PostgrestException catch (e) {
      // Table may not exist yet - return empty list instead of throwing
      if (e.code == '42P01' ||
          (e.message.contains('relation') &&
              e.message.contains('does not exist'))) {
        return [];
      }
      throw ImageStorageServiceException(_handleDatabaseError(e, 'fetch'));
    } catch (e) {
      throw ImageStorageServiceException(
          'Failed to fetch images by category: $e');
    }
  }

  /// Get list of all unique categories (merged from DB + locally persisted)
  Future<List<String>> getCategories() async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_imagesTable)
          .select('category')
          .eq('user_id', userId);

      final dbCategories =
          (response as List).map((data) => data['category'] as String).toSet();

      // Merge with locally persisted categories
      final savedCategories = await getSavedCategories();
      final allCategories = {...dbCategories, ...savedCategories}.toList();

      allCategories.sort();
      return allCategories;
    } on PostgrestException catch (e) {
      throw ImageStorageServiceException(
          _handleDatabaseError(e, 'fetch categories'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to fetch categories: $e');
    }
  }

  /// Save a category name to local storage so it persists even with 0 images
  Future<void> saveCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _getUserId();
    final key = '$_categoriesKeyPrefix$userId';
    final categories = prefs.getStringList(key) ?? [];
    if (!categories.contains(category)) {
      categories.add(category);
      await prefs.setStringList(key, categories);
    }
  }

  /// Remove a category from local storage
  Future<void> removeSavedCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _getUserId();
    final key = '$_categoriesKeyPrefix$userId';
    final categories = prefs.getStringList(key) ?? [];
    categories.remove(category);
    await prefs.setStringList(key, categories);
  }

  /// Get locally persisted category names
  Future<List<String>> getSavedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _getUserId();
      final key = '$_categoriesKeyPrefix$userId';
      return prefs.getStringList(key) ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Delete all images in a category
  Future<int> deleteCategory(String category) async {
    try {
      final userId = _getUserId();
      final response = await _supabase
          .from(_imagesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('category', category);

      final count = (response as List).length;

      if (count > 0) {
        await _supabase
            .from(_imagesTable)
            .delete()
            .eq('user_id', userId)
            .eq('category', category);
      }

      return count;
    } on PostgrestException catch (e) {
      throw ImageStorageServiceException(
          _handleDatabaseError(e, 'delete category'));
    } catch (e) {
      throw ImageStorageServiceException('Failed to delete category: $e');
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

/// Custom exception for Image storage operations
class ImageStorageServiceException implements Exception {
  final String message;

  ImageStorageServiceException(this.message);

  @override
  String toString() => message;
}
