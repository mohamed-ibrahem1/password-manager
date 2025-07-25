import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/password_entry.dart';
import '../services/firestore_service.dart';

class PasswordListPage extends StatefulWidget {
  final String category;
  const PasswordListPage({super.key, required this.category});

  @override
  State<PasswordListPage> createState() => _PasswordListPageState();
}

class _PasswordListPageState extends State<PasswordListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.savePassword(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding password: $e')),
      );
    }
  }

  Future<void> _updateEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.updatePassword(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  }

  Future<void> _deleteEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.deletePassword(entry.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting password: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _showEntryBottomSheet({PasswordEntry? entry}) {
    final isEdit = entry != null;
    final titleController = TextEditingController(text: entry?.title ?? '');
    List<TextEditingController> labelControllers =
        entry?.fields.map((f) => TextEditingController(text: f.key)).toList() ??
            [TextEditingController()];
    List<TextEditingController> valueControllers = entry?.fields
            .map((f) => TextEditingController(text: f.value))
            .toList() ??
        [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setStateSheet) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Edit Password' : 'Add Password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: labelControllers.length,
                    itemBuilder: (context, i) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: labelControllers[i],
                              decoration:
                                  const InputDecoration(labelText: 'Label'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: valueControllers[i],
                              decoration:
                                  const InputDecoration(labelText: 'Value'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: labelControllers.length > 1
                                ? () {
                                    setStateSheet(() {
                                      labelControllers.removeAt(i);
                                      valueControllers.removeAt(i);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setStateSheet(() {
                          labelControllers.add(TextEditingController());
                          valueControllers.add(TextEditingController());
                        });
                      },
                      child: const Text('Add Field'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple),
                        onPressed: () async {
                          final validFields = <MapEntry<String, String>>[];
                          for (int i = 0; i < labelControllers.length; i++) {
                            final key = labelControllers[i].text.trim();
                            final value = valueControllers[i].text.trim();
                            if (key.isNotEmpty && value.isNotEmpty) {
                              validFields.add(MapEntry(key, value));
                            }
                          }
                          if (titleController.text.trim().isNotEmpty &&
                              validFields.isNotEmpty) {
                            // Close the bottom sheet first
                            Navigator.pop(context);

                            final newEntry = PasswordEntry(
                              id: isEdit ? entry!.id : null,
                              title: titleController.text.trim(),
                              fields: validFields,
                              category: widget.category,
                            );

                            if (isEdit) {
                              await _updateEntry(newEntry);
                            } else {
                              await _addEntry(newEntry);
                            }
                          }
                        },
                        child: Text(isEdit ? 'Save' : 'Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PasswordEntry>>(
              stream: _firestoreService.getPasswordsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Filter passwords by category and search query
                final allPasswords = snapshot.data ?? [];
                final filteredEntries = allPasswords
                    .where((password) => password.category == widget.category)
                    .where((entry) => entry.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filteredEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(_searchQuery.isEmpty
                            ? 'No passwords in this category'
                            : 'No passwords found'),
                        SizedBox(height: 8),
                        Text(_searchQuery.isEmpty
                            ? 'Tap + to add your first password'
                            : 'Try a different search term'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return Dismissible(
                      key: ValueKey(entry.id ?? entry.title),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        // Prevent auto-dismiss, just reveal the background
                        return false;
                      },
                      child: SwipeToDeleteCard(
                        entry: entry,
                        onCopy: _copyToClipboard,
                        onDelete: () => _deleteEntry(entry),
                        onTap: () => _showEntryBottomSheet(entry: entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryBottomSheet(),
        tooltip: 'Add Password',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final void Function(String) onCopy;

  const PasswordCard({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...entry.fields.map((field) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(field.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(field.value),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => onCopy(field.value),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class SwipeToDeleteCard extends StatefulWidget {
  final PasswordEntry entry;
  final void Function(String) onCopy;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const SwipeToDeleteCard({
    super.key,
    required this.entry,
    required this.onCopy,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<SwipeToDeleteCard> createState() => _SwipeToDeleteCardState();
}

class _SwipeToDeleteCardState extends State<SwipeToDeleteCard> {
  double _offset = 0.0;
  static const double maxOffset = 80.0;
  static const double cardRadius = 12.0;
  static const EdgeInsets cardMargin = EdgeInsets.all(8);

  bool get isDeleteActive => _offset > maxOffset / 2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: cardMargin,
      child: Stack(
        children: [
          // Delete background fills the card
          Positioned.fill(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              margin: EdgeInsets.zero,
              color: Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    opacity: isDeleteActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: isDeleteActive ? widget.onDelete : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          // Swipable card
          Transform.translate(
            offset: Offset(-_offset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _offset = (_offset - details.delta.dx).clamp(0.0, maxOffset);
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  if (_offset > maxOffset / 2) {
                    _offset = maxOffset;
                  } else {
                    _offset = 0.0;
                  }
                });
              },
              onTap: widget.onTap,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                margin: EdgeInsets.zero,
                child: PasswordCard(
                  entry: widget.entry,
                  onCopy: widget.onCopy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
