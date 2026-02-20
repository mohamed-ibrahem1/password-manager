import 'dart:convert';
import 'dart:typed_data';

class ImageEntry {
  final String? id;
  final String title;
  final String imageData; // Base64 encoded image data
  final String category;

  ImageEntry({
    this.id,
    required this.title,
    required this.imageData,
    required this.category,
  });

  /// Get image bytes from base64 data
  Uint8List get imageBytes => base64Decode(imageData);

  Map<String, dynamic> toJson() => {
        'title': title,
        'image_data': imageData,
        'category': category,
      };

  static ImageEntry fromJson(Map<String, dynamic> map, {String? id}) =>
      ImageEntry(
        id: id,
        title: map['title'] as String,
        imageData: map['image_data'] as String,
        category: map['category'] as String,
      );

  ImageEntry copyWith(
          {String? id, String? title, String? imageData, String? category}) =>
      ImageEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        imageData: imageData ?? this.imageData,
        category: category ?? this.category,
      );
}
