class GradeItem {
  final String id;
  final String studentName;
  final int score;
  final String? classId;
  final String? className;
  final String? assignmentId;
  final String? assignmentTitle;

  GradeItem({
    required this.id,
    required this.studentName,
    required this.score,
    this.classId,
    this.className,
    this.assignmentId,
    this.assignmentTitle,
  });

  factory GradeItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    final assignments = map['assignments'];
    return GradeItem(
      id: map['id'] as String,
      studentName: (map['student_name'] ?? '') as String,
      score: (map['score'] ?? 0) as int,
      classId: map['class_id'] as String?,
      className: classes is Map<String, dynamic>
          ? (classes['name'] ?? '') as String
          : null,
      assignmentId: map['assignment_id'] as String?,
      assignmentTitle: assignments is Map<String, dynamic>
          ? (assignments['title'] ?? '') as String
          : null,
    );
  }
}
