class PasswordEntry {
  final String title;
  final List<MapEntry<String, String>> fields;
  final String category;

  PasswordEntry({
    required this.title,
    required this.fields,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'fields': fields.map((f) => {'key': f.key, 'value': f.value}).toList(),
        'category': category,
      };

  static PasswordEntry fromJson(Map<String, dynamic> map) => PasswordEntry(
        title: map['title'],
        fields: (map['fields'] as List)
            .map<MapEntry<String, String>>(
                (f) => MapEntry(f['key'], f['value']))
            .toList(),
        category: map['category'],
      );
}
