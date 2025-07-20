import 'dart:async';

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
        title: const Text('Add Category'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category Name'),
          onChanged: (value) => newCategory = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newCategory.trim().isNotEmpty &&
                  !_categories.contains(newCategory.trim())) {
                setState(() {
                  _categories.add(newCategory.trim());
                });
                Navigator.pop(context);
                // Navigate directly to password list for new category
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PasswordListPage(category: newCategory.trim()),
                  ),
                ).then((_) => _loadCategories()); // Refresh when returning
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$category"?'),
            SizedBox(height: 8),
            Text(
              'This will delete all passwords in this category.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategoryAndPasswords(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Passwords',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.password),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh Categories',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No categories yet',
                            style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Tap + to create your first category'),
                      ],
                    ),
                  )
                : StreamBuilder(
                    stream: _firestoreService.getPasswordsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // Update categories when data changes
                        final passwords = snapshot.data ?? [];
                        final liveCategories =
                            passwords.map((p) => p.category).toSet().toList();

                        // Only update if categories actually changed
                        if (liveCategories.length != _categories.length ||
                            !liveCategories.every(_categories.contains)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _categories.clear();
                              _categories.addAll(liveCategories);
                            });
                          });
                        }
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return DesktopLongPressDetector(
                            onLongPress: () =>
                                _showDeleteCategoryDialog(category),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PasswordListPage(category: category),
                                  ),
                                ).then((_) =>
                                    _loadCategories()); // Refresh when returning
                              },
                              // Removed onLongPress to prevent duplicate dialogs
                              child: Card(
                                elevation: 4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        category,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8),
                                      StreamBuilder(
                                        stream: _firestoreService
                                            .getPasswordsStream(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            final passwords =
                                                snapshot.data ?? [];
                                            final categoryCount = passwords
                                                .where((p) =>
                                                    p.category == category)
                                                .length;
                                            return Text(
                                              '$categoryCount password${categoryCount != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            );
                                          }
                                          return SizedBox.shrink();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
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
