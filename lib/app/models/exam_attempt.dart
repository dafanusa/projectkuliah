class ExamAttempt {
  final String id;
  final String examId;
  final String userId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int attemptNumber;
  final String status;
  final int? mcqScore;

  ExamAttempt({
    required this.id,
    required this.examId,
    required this.userId,
    required this.startedAt,
    required this.attemptNumber,
    required this.status,
    this.submittedAt,
    this.mcqScore,
  });

  factory ExamAttempt.fromMap(Map<String, dynamic> map) {
    return ExamAttempt(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      userId: map['user_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
      submittedAt: map['submitted_at'] == null
          ? null
          : DateTime.parse(map['submitted_at'] as String).toLocal(),
      attemptNumber: (map['attempt_number'] ?? 1) as int,
      status: (map['status'] ?? 'in_progress') as String,
      mcqScore: map['mcq_score'] as int?,
    );
  }
}
