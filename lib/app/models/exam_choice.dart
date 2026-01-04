class ExamChoice {
  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;

  ExamChoice({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
  });

  factory ExamChoice.fromMap(Map<String, dynamic> map) {
    return ExamChoice(
      id: map['id'] as String,
      questionId: map['question_id'] as String,
      text: (map['text'] ?? '') as String,
      isCorrect: (map['is_correct'] ?? false) as bool,
    );
  }
}
