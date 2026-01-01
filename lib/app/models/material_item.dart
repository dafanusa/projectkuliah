class MaterialItem {
  final String id;
  final String? classId;
  final String? className;
  final String title;
  final String description;
  final String meeting;
  final DateTime? date;
  final String? filePath;

  MaterialItem({
    required this.id,
    required this.title,
    required this.description,
    required this.meeting,
    this.classId,
    this.className,
    this.date,
    this.filePath,
  });

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    return MaterialItem(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      meeting: (map['meeting'] ?? '') as String,
      classId: map['class_id'] as String?,
      className: classes is Map<String, dynamic>
          ? (classes['name'] ?? '') as String
          : null,
      date: map['date'] == null ? null : DateTime.parse(map['date'] as String),
      filePath: map['file_path'] as String?,
    );
  }
}
