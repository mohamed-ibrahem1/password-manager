import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
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
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  bool _isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.savePassword(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding password: $e')),
      );
    }
  }

  Future<void> _updateEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.updatePassword(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  }

  Future<void> _deleteEntry(PasswordEntry entry) async {
    try {
      await _firestoreService.deletePassword(entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password deleted')),
      );
    } catch (e) {
      if (!mounted) return;
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

  bool _matchesSearchQuery(PasswordEntry entry) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    // Search in title
    if (entry.title.toLowerCase().contains(query)) {
      return true;
    }

    // Search in field keys (labels)
    for (final field in entry.fields) {
      if (field.key.toLowerCase().contains(query)) {
        return true;
      }
    }

    // Search in field values
    for (final field in entry.fields) {
      if (field.value.toLowerCase().contains(query)) {
        return true;
      }
    }

    return false;
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

    if (_isDesktop()) {
      // Show dialog for desktop
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: StatefulBuilder(
                  builder: (context, setStateDialog) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - Fixed
                      Row(
                        children: [
                          Icon(
                            isEdit ? Icons.edit_rounded : Icons.add_rounded,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Password' : 'Add Password',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  hintText: 'e.g., Gmail Account',
                                  prefixIcon: Icon(Icons.title_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: labelControllers.length,
                                onReorder: (oldIndex, newIndex) {
                                  setStateDialog(() {
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final labelController =
                                        labelControllers.removeAt(oldIndex);
                                    final valueController =
                                        valueControllers.removeAt(oldIndex);
                                    labelControllers.insert(
                                        newIndex, labelController);
                                    valueControllers.insert(
                                        newIndex, valueController);
                                  });
                                },
                                itemBuilder: (context, i) {
                                  return Padding(
                                    key: ValueKey('field_$i'),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        ReorderableDragStartListener(
                                          index: i,
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.grab,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.drag_indicator_rounded,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: labelControllers[i],
                                            decoration: const InputDecoration(
                                              labelText: 'Field Name',
                                              hintText: 'e.g., Username',
                                              prefixIcon:
                                                  Icon(Icons.label_rounded),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: valueControllers[i],
                                            obscureText: labelControllers[i]
                                                .text
                                                .toLowerCase()
                                                .contains('password'),
                                            decoration: const InputDecoration(
                                              labelText: 'Value',
                                              hintText: 'Enter value',
                                              prefixIcon:
                                                  Icon(Icons.vpn_key_rounded),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton.outlined(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded),
                                          onPressed: labelControllers.length > 1
                                              ? () {
                                                  setStateDialog(() {
                                                    labelControllers
                                                        .removeAt(i);
                                                    valueControllers
                                                        .removeAt(i);
                                                  });
                                                }
                                              : null,
                                          tooltip: 'Remove field',
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    setStateDialog(() {
                                      labelControllers
                                          .add(TextEditingController());
                                      valueControllers
                                          .add(TextEditingController());
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Field'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer buttons - Fixed
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            icon: Icon(isEdit
                                ? Icons.save_rounded
                                : Icons.add_rounded),
                            label: Text(isEdit ? 'Save' : 'Add'),
                            onPressed: () async {
                              final validFields = <MapEntry<String, String>>[];
                              for (int i = 0;
                                  i < labelControllers.length;
                                  i++) {
                                final key = labelControllers[i].text.trim();
                                final value = valueControllers[i].text.trim();
                                if (key.isNotEmpty && value.isNotEmpty) {
                                  validFields.add(MapEntry(key, value));
                                }
                              }
                              if (titleController.text.trim().isNotEmpty &&
                                  validFields.isNotEmpty) {
                                Navigator.pop(context);

                                final newEntry = PasswordEntry(
                                  id: isEdit ? entry.id : null,
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Show bottom sheet for mobile
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
                    Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_rounded,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? 'Edit Password' : 'Add Password',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Gmail Account',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: labelControllers.length,
                      onReorder: (oldIndex, newIndex) {
                        setStateSheet(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final labelController =
                              labelControllers.removeAt(oldIndex);
                          final valueController =
                              valueControllers.removeAt(oldIndex);
                          labelControllers.insert(newIndex, labelController);
                          valueControllers.insert(newIndex, valueController);
                        });
                      },
                      itemBuilder: (context, i) {
                        return Padding(
                          key: ValueKey('mobile_field_$i'),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: labelControllers.length > 1
                                    ? () {
                                        setStateSheet(() {
                                          labelControllers.removeAt(i);
                                          valueControllers.removeAt(i);
                                        });
                                      }
                                    : null,
                                tooltip: 'Remove field',
                              ),
                            ],
                          ),
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
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
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
                              Navigator.pop(context);

                              final newEntry = PasswordEntry(
                                id: isEdit ? entry.id : null,
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
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewPasswordIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewPasswordIntent: CallbackAction<NewPasswordIntent>(
            onInvoke: (intent) => _showEntryBottomSheet(),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              FocusScope.of(context).requestFocus(_searchFocusNode);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: _isDesktop()
                ? null
                : AppBar(
                    title: Text(
                      widget.category,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
            body: Column(
              children: [
                // Desktop header - Material 3 styled
                if (_isDesktop())
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back to Categories',
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.lock_rounded,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.category,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const Spacer(),
                        if (_isDesktop())
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.keyboard_rounded,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ctrl+N: New  •  Ctrl+F: Search',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                // Search field - Material 3 styled
                Padding(
                  padding: EdgeInsets.all(_isDesktop() ? 24.0 : 16.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search passwords...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Search results indicator - Material 3 chip
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktop() ? 24.0 : 16.0,
                    ),
                    child: StreamBuilder<List<PasswordEntry>>(
                      stream: _firestoreService.getPasswordsStream(),
                      builder: (context, snapshot) {
                        final allPasswords = snapshot.data ?? [];
                        final count = allPasswords
                            .where((p) => p.category == widget.category)
                            .where((entry) => _matchesSearchQuery(entry))
                            .length;

                        return Chip(
                          avatar: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          label: Text(
                            'Found $count result${count != 1 ? 's' : ''}',
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          deleteIcon: const Icon(Icons.clear_rounded, size: 18),
                          onDeleted: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_searchQuery.isNotEmpty) const SizedBox(height: 12),
                // Password list
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
                          .where((password) =>
                              password.category == widget.category)
                          .where((entry) => _matchesSearchQuery(entry))
                          .toList();

                      if (filteredEntries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.key_off_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No passwords yet'
                                    : 'No passwords found',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add your first password'
                                    : 'Try a different search term',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_isDesktop()) {
                        // Desktop grid layout with dynamic heights
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: filteredEntries.map((entry) {
                              return SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 64) /
                                        2,
                                child: DesktopPasswordCard(
                                  entry: entry,
                                  onCopy: _copyToClipboard,
                                  onDelete: () => _deleteEntry(entry),
                                  onTap: () =>
                                      _showEntryBottomSheet(entry: entry),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      } else {
                        // Mobile list layout
                        return ListView.builder(
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return SwipeToDeleteCard(
                              entry: entry,
                              onCopy: _copyToClipboard,
                              onDelete: () => _deleteEntry(entry),
                              onTap: () => _showEntryBottomSheet(entry: entry),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showEntryBottomSheet(),
              tooltip: _isDesktop() ? 'Add Password (Ctrl+N)' : 'Add Password',
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Password'),
            ),
          ),
        ),
      ),
    );
  }
}

// Desktop-specific password card - Material 3 styled
class DesktopPasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final void Function(String) onCopy;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const DesktopPasswordCard({
    super.key,
    required this.entry,
    required this.onCopy,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.more_vert_rounded),
                    iconSize: 20,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: Icon(
                            Icons.warning_rounded,
                            color: colorScheme.error,
                          ),
                          title: const Text('Delete Password'),
                          content: Text(
                            'Are you sure you want to delete "${entry.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.fields
                    .map((field) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      field.key,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      field.value,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontFamily: field.key
                                                .toLowerCase()
                                                .contains('password')
                                            ? 'monospace'
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                onPressed: () => onCopy(field.value),
                                tooltip: 'Copy ${field.key}',
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.key_rounded,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 8),
            ...entry.fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.key,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              field.value,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontFamily:
                                    field.key.toLowerCase().contains('password')
                                        ? 'monospace'
                                        : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () => onCopy(field.value),
                        tooltip: 'Copy ${field.key}',
                      ),
                    ],
                  ),
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

// Intent classes for keyboard shortcuts
class NewPasswordIntent extends Intent {
  const NewPasswordIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}
