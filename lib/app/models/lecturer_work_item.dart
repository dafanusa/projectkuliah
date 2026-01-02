class LecturerWorkItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? date;
  final String? filePath;

  LecturerWorkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.filePath,
  });

  factory LecturerWorkItem.fromMap(Map<String, dynamic> map) {
    final dateValue = map['date'];
    return LecturerWorkItem(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'Lainnya') as String,
      date: dateValue is String ? DateTime.tryParse(dateValue) : null,
      filePath: map['file_path'] as String?,
    );
  }
}
