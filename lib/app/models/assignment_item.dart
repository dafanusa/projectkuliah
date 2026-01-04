class AssignmentItem {
  final String id;
  final String? classId;
  final String? className;
  final String title;
  final String instructions;
  final DateTime deadline;
  final String? filePath;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.instructions,
    required this.deadline,
    this.classId,
    this.className,
    this.filePath,
  });

  factory AssignmentItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    return AssignmentItem(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      instructions: (map['instructions'] ?? '') as String,
      deadline: DateTime.parse(map['deadline'] as String).toLocal(),
      classId: map['class_id'] as String?,
      className: classes is Map<String, dynamic>
          ? (classes['name'] ?? '') as String
          : null,
      filePath: map['file_path'] as String?,
    );
  }
}
