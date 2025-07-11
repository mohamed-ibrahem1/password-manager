import 'dart:async';

import 'package:flutter/material.dart';
import 'package:passwords/pages/password_generator_page.dart';
import 'package:passwords/pages/password_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryGridPage extends StatefulWidget {
  const CategoryGridPage({super.key});

  @override
  State<CategoryGridPage> createState() => _CategoryGridPageState();
}

class _CategoryGridPageState extends State<CategoryGridPage> {
  final List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = prefs.getStringList('categories') ?? [];
    setState(() {
      _categories.addAll(savedCategories);
    });
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', _categories);
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
                _saveCategories();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content:
            Text('Are you sure you want to delete "${_categories[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(index);
              });
              _saveCategories();
              Navigator.pop(context);
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PasswordListPage(category: category),
                  ),
                );
              },
              onLongPress: () => _showDeleteCategoryDialog(index),
              child: Card(
                elevation: 4,
                child: Center(
                  child: Text(
                    category,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
