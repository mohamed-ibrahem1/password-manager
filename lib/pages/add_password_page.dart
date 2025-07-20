import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/firestore_service.dart';

class AddPasswordPage extends StatefulWidget {
  final String? category;

  const AddPasswordPage({super.key, this.category});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();

  List<MapEntry<String, String>> _fields = [
    MapEntry('Username', ''),
    MapEntry('Password', ''),
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _categoryController.text = widget.category!;
    }
  }

  void _addField() {
    setState(() {
      _fields.add(MapEntry('', ''));
    });
  }

  void _removeField(int index) {
    if (_fields.length > 1) {
      setState(() {
        _fields.removeAt(index);
      });
    }
  }

  void _updateField(int index, String key, String value) {
    setState(() {
      _fields[index] = MapEntry(key, value);
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final entry = PasswordEntry(
        title: _titleController.text.trim(),
        fields: _fields
            .where((f) => f.key.isNotEmpty && f.value.isNotEmpty)
            .toList(),
        category: _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
      );

      await _firestoreService.savePassword(entry);
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Password'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePassword,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Title is required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: _fields[index].key,
                                decoration: InputDecoration(
                                  labelText: 'Field Name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _updateField(
                                    index, value, _fields[index].value),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: _fields[index].value,
                                decoration: InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(),
                                ),
                                obscureText: _fields[index]
                                    .key
                                    .toLowerCase()
                                    .contains('password'),
                                onChanged: (value) => _updateField(
                                    index, _fields[index].key, value),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeField(index),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addField,
                icon: Icon(Icons.add),
                label: Text('Add Field'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
