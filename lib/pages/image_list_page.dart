import 'dart:convert';
import 'dart:io' show File, Platform, Process;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../models/image_entry.dart';
import '../services/image_storage_service.dart';

class ImageListPage extends StatefulWidget {
  final String category;
  const ImageListPage({super.key, required this.category});

  @override
  State<ImageListPage> createState() => _ImageListPageState();
}

class _ImageListPageState extends State<ImageListPage> {
  final ImageStorageService _imageService = ImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<ImageEntry> _images = [];
  bool _isLoading = true;

  bool _isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      final images = await _imageService.getImagesByCategory(widget.category);
      if (!mounted) return;
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndAddImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;
      _showAddImageDialog(base64Image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showAddImageDialog(String base64Image, {ImageEntry? existingEntry}) {
    final isEdit = existingEntry != null;
    final titleController =
        TextEditingController(text: existingEntry?.title ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
            isEdit ? Icons.edit_rounded : Icons.add_photo_alternate_rounded),
        title: Text(isEdit ? 'Edit Image' : 'Add Image'),
        content: SizedBox(
          width: _isDesktop() ? 400 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(base64Image),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Image Title',
                    hintText: 'e.g., WiFi QR Code',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _saveImage(
                        title: value.trim(),
                        imageData: base64Image,
                        existingEntry: existingEntry,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _saveImage(
                  title: titleController.text.trim(),
                  imageData: base64Image,
                  existingEntry: existingEntry,
                );
              }
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage({
    required String title,
    required String imageData,
    ImageEntry? existingEntry,
  }) async {
    try {
      final entry = ImageEntry(
        id: existingEntry?.id,
        title: title,
        imageData: imageData,
        category: widget.category,
      );

      if (existingEntry != null) {
        await _imageService.updateImage(entry);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image updated successfully')),
        );
      } else {
        await _imageService.saveImage(entry);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image added successfully')),
        );
      }
      _loadImages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  Future<void> _deleteImage(ImageEntry entry) async {
    try {
      await _imageService.deleteImage(entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted')),
      );
      _loadImages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    }
  }

  Future<void> _copyImageToClipboard(ImageEntry entry) async {
    try {
      final rawBytes = entry.imageBytes;

      // Decode the image and re-encode as proper PNG for clipboard compatibility
      final pngBytes = await _convertToPng(rawBytes);

      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem();
        item.add(Formats.png(pngBytes));
        await clipboard.write([item]);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image copied to clipboard')),
        );
      } else {
        // Fallback: save to temp file and copy path
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/copied_image_${entry.id}.png');
        await tempFile.writeAsBytes(pngBytes);
        await Clipboard.setData(ClipboardData(text: tempFile.path));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to: ${tempFile.path}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error copying image: $e')),
      );
    }
  }

  /// Convert any image bytes (JPEG, PNG, etc.) to proper PNG format
  Future<Uint8List> _convertToPng(Uint8List imageBytes) async {
    // If already PNG (starts with PNG signature), return as-is
    if (imageBytes.length >= 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return imageBytes;
    }

    // Decode the image using Flutter's image codec and re-encode as PNG
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();

    if (byteData == null) {
      throw Exception('Failed to convert image to PNG');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _shareImage(ImageEntry entry) async {
    try {
      final rawBytes = entry.imageBytes;
      final pngBytes = await _convertToPng(rawBytes);

      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle =
          entry.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final tempFile = File('${tempDir.path}/share_$sanitizedTitle.png');
      await tempFile.writeAsBytes(pngBytes);

      if (!kIsWeb && Platform.isWindows) {
        // Windows: show custom share dialog with practical options
        if (!mounted) return;
        await _showWindowsShareDialog(pngBytes, tempFile, entry.title);
      } else {
        // Android / iOS / macOS / Linux: use native share sheet
        final xFile = XFile(tempFile.path, mimeType: 'image/png');
        final result = await SharePlus.instance.share(
          ShareParams(files: [xFile], title: entry.title),
        );

        if (!mounted) return;
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image shared successfully')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }

  Future<void> _showWindowsShareDialog(
    Uint8List pngBytes,
    File tempFile,
    String title,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.share_rounded),
        title: const Text('Share Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose how to share "$title":',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Copy to clipboard
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Image to Clipboard'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    final clipboard = SystemClipboard.instance;
                    if (clipboard != null) {
                      final item = DataWriterItem();
                      item.add(Formats.png(pngBytes));
                      await clipboard.write([item]);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Image copied to clipboard')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error copying image: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Save to Downloads
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save to Downloads'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    final downloadsPath =
                        '${Platform.environment['USERPROFILE']}\\Downloads';
                    final sanitized =
                        title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\s]'), '_');
                    final savePath = '$downloadsPath\\$sanitized.png';
                    await File(savePath).writeAsBytes(pngBytes);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Image saved to Downloads: $sanitized.png')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving image: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Open with default viewer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open in Image Viewer'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await Process.run('explorer', [tempFile.path]);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening image: $e')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(ImageEntry entry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _isDesktop() ? 800 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () => _copyImageToClipboard(entry),
                      tooltip: 'Copy Image',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      onPressed: () => _shareImage(entry),
                      tooltip: 'Share Image',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      child: Image.memory(
                        entry.imageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 300,
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSearchQuery(ImageEntry entry) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return entry.title.toLowerCase().contains(query);
  }

  void _showEditTitleDialog(ImageEntry entry) {
    final titleController = TextEditingController(text: entry.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_rounded),
        title: const Text('Edit Title'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Image Title',
            prefixIcon: Icon(Icons.title_rounded),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              _saveImage(
                title: value.trim(),
                imageData: entry.imageData,
                existingEntry: entry,
              );
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
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _saveImage(
                  title: titleController.text.trim(),
                  imageData: entry.imageData,
                  existingEntry: entry,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeImage(ImageEntry entry) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;
      _showAddImageDialog(base64Image, existingEntry: entry);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showDeleteDialog(ImageEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_rounded,
          color: colorScheme.error,
        ),
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(entry);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _isDesktop()
          ? null
          : AppBar(
              title: Text(
                widget.category,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
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
                  IconButton.filledTonal(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back to Categories',
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.photo_library_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.category,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          // Search field
          Padding(
            padding: EdgeInsets.all(_isDesktop() ? 24.0 : 16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search images...',
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
          // Image list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filteredImages = _images
                          .where((img) => _matchesSearchQuery(img))
                          .toList();

                      if (filteredImages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_rounded,
                                size: 64,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No images yet'
                                    : 'No images found',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Add your first image'
                                    : 'Try a different search term',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isDesktop() ? 24.0 : 16.0,
                        ),
                        itemCount: filteredImages.length,
                        itemBuilder: (context, index) {
                          final image = filteredImages[index];
                          return _ImageListTile(
                            entry: image,
                            onCopy: () => _copyImageToClipboard(image),
                            onShare: () => _shareImage(image),
                            onTap: () => _showImagePreview(image),
                            onEdit: () => _showEditTitleDialog(image),
                            onChangeImage: () => _changeImage(image),
                            onDelete: () => _showDeleteDialog(image),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndAddImage,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Add Image'),
        tooltip: 'Add Image',
      ),
    );
  }
}

class _ImageListTile extends StatelessWidget {
  final ImageEntry entry;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onChangeImage;
  final VoidCallback onDelete;

  const _ImageListTile({
    required this.entry,
    required this.onCopy,
    required this.onShare,
    required this.onTap,
    required this.onEdit,
    required this.onChangeImage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Uint8List? imageBytes;
    try {
      imageBytes = entry.imageBytes;
    } catch (_) {
      imageBytes = null;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: colorScheme.errorContainer,
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  entry.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Title'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'change_image',
                    child: Row(
                      children: [
                        Icon(Icons.image_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Change Image'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'change_image') {
                    onChangeImage();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
              // Share button
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: onShare,
                tooltip: 'Share Image',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
