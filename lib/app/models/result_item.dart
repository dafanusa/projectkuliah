class ResultItem {
  final String id;
  final String? classId;
  final String? className;
  final String? assignmentId;
  final String? assignmentTitle;
  final int collected;
  final int missing;
  final int graded;

  ResultItem({
    required this.id,
    required this.collected,
    required this.missing,
    required this.graded,
    this.classId,
    this.className,
    this.assignmentId,
    this.assignmentTitle,
  });

  factory ResultItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    final assignments = map['assignments'];
    return ResultItem(
      id: map['id'] as String,
      collected: (map['collected'] ?? 0) as int,
      missing: (map['missing'] ?? 0) as int,
      graded: (map['graded'] ?? 0) as int,
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
