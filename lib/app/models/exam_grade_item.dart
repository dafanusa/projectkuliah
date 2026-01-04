class ExamGradeItem {
  final String id;
  final String? classId;
  final String? className;
  final String? examId;
  final String? examTitle;
  final String? studentId;
  final String studentName;
  final int score;

  ExamGradeItem({
    required this.id,
    required this.studentName,
    required this.score,
    this.classId,
    this.className,
    this.examId,
    this.examTitle,
    this.studentId,
  });

  factory ExamGradeItem.fromMap(Map<String, dynamic> map) {
    final classes = map['classes'];
    final exams = map['exams'];
    return ExamGradeItem(
      id: map['id'] as String,
      studentName: (map['student_name'] ?? '') as String,
      score: (map['score'] ?? 0) as int,
      classId: map['class_id'] as String?,
      className:
          classes is Map<String, dynamic> ? (classes['name'] ?? '') as String : null,
      examId: map['exam_id'] as String?,
      examTitle:
          exams is Map<String, dynamic> ? (exams['title'] ?? '') as String : null,
      studentId: map['student_id'] as String?,
    );
  }
}
