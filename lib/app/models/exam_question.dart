class ExamQuestion {
  final String id;
  final String examId;
  final String type;
  final String prompt;
  final int points;
  final int orderIndex;

  ExamQuestion({
    required this.id,
    required this.examId,
    required this.type,
    required this.prompt,
    required this.points,
    required this.orderIndex,
  });

  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    return ExamQuestion(
      id: map['id'] as String,
      examId: map['exam_id'] as String,
      type: (map['type'] ?? 'mcq') as String,
      prompt: (map['prompt'] ?? '') as String,
      points: (map['points'] ?? 1) as int,
      orderIndex: (map['order_index'] ?? 0) as int,
    );
  }
}
