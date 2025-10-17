import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:passwords/pages/password_generator_page.dart';
import 'package:passwords/pages/password_list_page.dart';

import '../services/firestore_service.dart';

class CategoryGridPage extends StatefulWidget {
  const CategoryGridPage({super.key});

  @override
  State<CategoryGridPage> createState() => _CategoryGridPageState();
}

class _CategoryGridPageState extends State<CategoryGridPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _categories = [];
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
      // Get unique categories from Firebase passwords
      final passwords = await _firestoreService.getPasswords();
      final categories = passwords.map((p) => p.category).toSet().toList();

      setState(() {
        _categories.clear();
        _categories.addAll(categories);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.create_new_folder_rounded),
        title: const Text('Add Category'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Social Media, Banking',
          ),
          onChanged: (value) => newCategory = value,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty &&
                !_categories.contains(value.trim())) {
              setState(() {
                _categories.add(value.trim());
              });
              Navigator.pop(context);
              _navigateToPasswordList(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newCategory.trim().isNotEmpty &&
                  !_categories.contains(newCategory.trim())) {
                setState(() {
                  _categories.add(newCategory.trim());
                });
                Navigator.pop(context);
                // Navigate directly to password list for new category
                _navigateToPasswordList(newCategory.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
                      'This will delete all passwords in this category.',
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
              await _deleteCategoryAndPasswords(category);
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

  Future<void> _deleteCategoryAndPasswords(String category) async {
    try {
      // Get all passwords in this category
      final passwords = await _firestoreService.getPasswords();
      final categoryPasswords = passwords.where((p) => p.category == category);

      // Delete all passwords in this category
      for (final password in categoryPasswords) {
        await _firestoreService.deletePassword(password.id!);
      }

      // Refresh categories
      await _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$category" deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  void _navigateToPasswordList(String category) {
    if (_isDesktop()) {
      // Desktop navigation with slide transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasswordListPage(category: category),
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
      // Mobile navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordListPage(category: category),
        ),
      ).then((_) => _loadCategories());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _isDesktop()
          ? null
          : AppBar(
              title: Text(
                'Passwords',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.key_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordGeneratorPage(),
                      ),
                    );
                  },
                  tooltip: 'Generate Password',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadCategories,
                  tooltip: 'Refresh Categories',
                ),
              ],
            ),
      body: Column(
        children: [
          // Desktop header - Material 3 styled
          if (_isDesktop())
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Password Categories',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordGeneratorPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Generate Password'),
                  ),
                  const SizedBox(width: 12),
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
                                Icons.folder_open_rounded,
                                size: _isDesktop() ? 96 : 64,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No categories yet',
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
                      : StreamBuilder(
                          stream: _firestoreService.getPasswordsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              // Update categories when data changes
                              final passwords = snapshot.data ?? [];
                              final liveCategories = passwords
                                  .map((p) => p.category)
                                  .toSet()
                                  .toList();

                              // Only update if categories actually changed
                              if (liveCategories.length != _categories.length ||
                                  !liveCategories.every(_categories.contains)) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _categories.clear();
                                    _categories.addAll(liveCategories);
                                  });
                                });
                              }
                            }

                            return GridView.builder(
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
                                return DesktopLongPressDetector(
                                  onLongPress: () =>
                                      _showDeleteCategoryDialog(category),
                                  child: Card(
                                    elevation: 1,
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () =>
                                          _navigateToPasswordList(category),
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                            _isDesktop() ? 20 : 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Material 3 icon with container
                                            Container(
                                              padding: EdgeInsets.all(
                                                  _isDesktop() ? 14 : 12),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.folder_rounded,
                                                size: _isDesktop() ? 28 : 24,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                            SizedBox(
                                                height: _isDesktop() ? 12 : 10),
                                            Flexible(
                                              child: Text(
                                                category,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            StreamBuilder(
                                              stream: _firestoreService
                                                  .getPasswordsStream(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  final passwords =
                                                      snapshot.data ?? [];
                                                  final categoryCount =
                                                      passwords
                                                          .where((p) =>
                                                              p.category ==
                                                              category)
                                                          .length;
                                                  return Text(
                                                    '$categoryCount password${categoryCount != 1 ? 's' : ''}',
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
        tooltip: 'Add Category',
      ),
    );
  }
}

class DesktopLongPressDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;

  const DesktopLongPressDetector({
    Key? key,
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<DesktopLongPressDetector> createState() =>
      _DesktopLongPressDetectorState();
}

class _DesktopLongPressDetectorState extends State<DesktopLongPressDetector> {
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
