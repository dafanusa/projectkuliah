class ExamSubmissionItem {
  final String id;
  final String examId;
  final String userId;
  final DateTime submittedAt;
  final String? studentName;
  final String? studentEmail;
  final String? studentNim;
  final String? examTitle;
  final String? classId;

  ExamSubmissionItem({
    required this.id,
    required this.examId,
    required this.userId,
    required this.submittedAt,
    this.studentName,
    this.studentEmail,
    this.studentNim,
    this.examTitle,
    this.classId,
  });

  factory ExamSubmissionItem.fromMap(Map<String, dynamic> map) {
    final profiles = map['profiles'];
    final exams = map['exams'];
    return ExamSubmissionItem(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      userId: map['user_id'] as String,
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      studentName:
          profiles is Map<String, dynamic> ? profiles['name'] as String? : null,
      studentEmail:
          profiles is Map<String, dynamic> ? profiles['email'] as String? : null,
      studentNim:
          profiles is Map<String, dynamic> ? profiles['nim'] as String? : null,
      examTitle:
          exams is Map<String, dynamic> ? exams['title'] as String? : null,
      classId: exams is Map<String, dynamic> ? exams['class_id'] as String? : null,
    );
  }
}
