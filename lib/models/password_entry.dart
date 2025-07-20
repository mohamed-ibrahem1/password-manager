class PasswordEntry {
  final String? id; // Add Firestore document ID
  final String title;
  final List<MapEntry<String, String>> fields;
  final String category;

  PasswordEntry({
    this.id,
    required this.title,
    required this.fields,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'fields': fields.map((f) => {'key': f.key, 'value': f.value}).toList(),
        'category': category,
      };

  static PasswordEntry fromJson(Map<String, dynamic> map, {String? id}) =>
      PasswordEntry(
        id: id,
        title: map['title'],
        fields: (map['fields'] as List)
            .map<MapEntry<String, String>>(
                (f) => MapEntry(f['key'], f['value']))
            .toList(),
        category: map['category'],
      );

  // Helper method to create a copy with new ID
  PasswordEntry copyWith({String? id}) => PasswordEntry(
        id: id ?? this.id,
        title: title,
        fields: fields,
        category: category,
      );
}
