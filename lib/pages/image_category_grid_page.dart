import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/image_storage_service.dart';
import 'image_list_page.dart';

class ImageCategoryGridPage extends StatefulWidget {
  const ImageCategoryGridPage({super.key});

  @override
  State<ImageCategoryGridPage> createState() => _ImageCategoryGridPageState();
}

class _ImageCategoryGridPageState extends State<ImageCategoryGridPage> {
  final ImageStorageService _imageService = ImageStorageService();
  final List<String> _categories = [];
  final Map<String, int> _categoryCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  bool _isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final images = await _imageService.getImages();
      // Get categories from images in DB
      final dbCategories = images.map((img) => img.category).toSet();
      // Get locally persisted categories (includes empty ones)
      final savedCategories = await _imageService.getSavedCategories();
      // Merge both sets
      final allCategories = {...dbCategories, ...savedCategories}.toList();
      allCategories.sort();

      final counts = <String, int>{};
      for (final cat in allCategories) {
        counts[cat] = 0;
      }
      for (final img in images) {
        counts[img.category] = (counts[img.category] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _categories.clear();
        _categories.addAll(allCategories);
        _categoryCounts.clear();
        _categoryCounts.addAll(counts);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading image categories: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _showAddCategoryDialog() async {
    String newCategory = '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.create_new_folder_rounded),
        title: const Text('Add Image Category'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Screenshots, QR Codes',
          ),
          onChanged: (value) => newCategory = value,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty &&
                !_categories.contains(value.trim())) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newCategory.trim().isNotEmpty &&
                  !_categories.contains(newCategory.trim())) {
                Navigator.pop(dialogContext, newCategory.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Persist the category so it survives page reloads even with 0 images
      await _imageService.saveCategory(result);
      setState(() {
        if (!_categories.contains(result)) {
          _categories.add(result);
          _categoryCounts[result] = 0;
        }
      });
      _navigateToImageList(result);
    }
  }

  void _showDeleteCategoryDialog(String category) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: colorScheme.error,
        ),
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$category"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    size: 16,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will delete all images in this category.',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
              Navigator.pop(context);
              await _deleteCategoryAndImages(category);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategoryAndImages(String category) async {
    try {
      final images = await _imageService.getImages();
      final categoryImages = images.where((img) => img.category == category);

      for (final image in categoryImages) {
        await _imageService.deleteImage(image.id!);
      }

      // Also remove the persisted category
      await _imageService.removeSavedCategory(category);

      await _loadCategories();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$category" deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  void _navigateToImageList(String category) {
    if (_isDesktop()) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ImageListPage(category: category),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ).then((_) => _loadCategories());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageListPage(category: category),
        ),
      ).then((_) => _loadCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // Desktop header
          if (_isDesktop())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Image Categories',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadCategories,
                    tooltip: 'Refresh Categories',
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(_isDesktop() ? 24.0 : 16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: _isDesktop() ? 96 : 64,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No image categories yet',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isDesktop()
                                    ? 'Click + to create your first category'
                                    : 'Tap + to create your first category',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _isDesktop() ? 4 : 2,
                            childAspectRatio: _isDesktop() ? 1.2 : 1.0,
                            crossAxisSpacing: _isDesktop() ? 16 : 12,
                            mainAxisSpacing: _isDesktop() ? 16 : 12,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final count = _categoryCounts[category] ?? 0;
                            return _DesktopLongPressDetector(
                              onLongPress: () =>
                                  _showDeleteCategoryDialog(category),
                              child: Card(
                                elevation: 1,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _navigateToImageList(category),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(_isDesktop() ? 20 : 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                              _isDesktop() ? 14 : 12),
                                          decoration: BoxDecoration(
                                            color:
                                                colorScheme.tertiaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            Icons.photo_library_rounded,
                                            size: _isDesktop() ? 28 : 24,
                                            color:
                                                colorScheme.onTertiaryContainer,
                                          ),
                                        ),
                                        SizedBox(
                                            height: _isDesktop() ? 12 : 10),
                                        Flexible(
                                          child: Text(
                                            category,
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$count image${count != 1 ? 's' : ''}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addImageCategory',
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
        tooltip: 'Add Category',
      ),
    );
  }
}

class _DesktopLongPressDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;

  const _DesktopLongPressDetector({
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<_DesktopLongPressDetector> createState() =>
      _DesktopLongPressDetectorState();
}

class _DesktopLongPressDetectorState extends State<_DesktopLongPressDetector> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (event) {
          _timer = Timer(widget.duration, () {
            widget.onLongPress();
          });
        },
        onPointerUp: (event) {
          _timer?.cancel();
          _timer = null;
        },
        onPointerCancel: (event) {
          _timer?.cancel();
          _timer = null;
        },
        child: widget.child,
      ),
    );
  }
}
