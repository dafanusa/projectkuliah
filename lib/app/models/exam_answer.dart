class ExamAnswer {
  final String id;
  final String attemptId;
  final String questionId;
  final String? choiceId;
  final String? answerText;
  final bool? isCorrect;
  final int? score;

  ExamAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.choiceId,
    this.answerText,
    this.isCorrect,
    this.score,
  });

  factory ExamAnswer.fromMap(Map<String, dynamic> map) {
    return ExamAnswer(
      id: map['id'] as String,
      attemptId: map['attempt_id'] as String,
      questionId: map['question_id'] as String,
      choiceId: map['choice_id'] as String?,
      answerText: map['answer_text'] as String?,
      isCorrect: map['is_correct'] as bool?,
      score: map['score'] as int?,
    );
  }
}
