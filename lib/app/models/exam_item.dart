class ExamItem {
  final String id;
  final String? classId;
  final String? className;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final int maxAttempts;
  final String? filePath;

  ExamItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.maxAttempts,
    this.classId,
    this.className,
    this.filePath,
  });

  factory ExamItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    final rawStart = map['start_at'];
    final rawEnd = map['end_at'] ?? map['date'] ?? map['exam_date'];
    DateTime parsedStart;
    DateTime parsedEnd;
    if (rawStart is String && rawStart.isNotEmpty) {
      parsedStart = DateTime.parse(rawStart).toLocal();
    } else if (rawStart is DateTime) {
      parsedStart = rawStart;
    } else {
      parsedStart = DateTime.now();
    }
    if (rawEnd is String && rawEnd.isNotEmpty) {
      parsedEnd = DateTime.parse(rawEnd).toLocal();
    } else if (rawEnd is DateTime) {
      parsedEnd = rawEnd;
    } else {
      parsedEnd = parsedStart;
    }
    return ExamItem(
      id: map['id'] as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      startAt: parsedStart,
      endAt: parsedEnd,
      durationMinutes: (map['duration_minutes'] ?? 60) as int,
      maxAttempts: (map['max_attempts'] ?? 1) as int,
      classId: map['class_id'] as String?,
      className: classes is Map<String, dynamic>
          ? (classes['name'] ?? '') as String
          : null,
      filePath: map['file_path'] as String?,
    );
  }
}
