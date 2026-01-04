import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/exam_item.dart';
import '../../../models/exam_question.dart';
import '../../../models/exam_attempt.dart';
import '../../../models/exam_answer.dart';
import '../../../models/exam_grade_item.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../controllers/ujian_controller.dart';

class UjianGradingView extends StatefulWidget {
  final ExamItem exam;

  const UjianGradingView({super.key, required this.exam});

  @override
  State<UjianGradingView> createState() => _UjianGradingViewState();
}

class _UjianGradingViewState extends State<UjianGradingView> {
  final UjianController _controller = Get.find<UjianController>();
  final DataService _dataService = Get.find<DataService>();
  bool _isLoading = true;
  List<ExamQuestion> _questions = [];
  List<ExamAttempt> _attempts = [];
  final Map<String, List<ExamAnswer>> _answersByAttempt = {};
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, ExamGradeItem> _gradeByStudentId = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _controller.loadQuestions(widget.exam.id);
    final attempts = await _controller.loadAttemptsForExam(widget.exam.id);
    final grades = await _dataService.fetchExamGrades();
    for (final grade in grades.where((g) => g.examId == widget.exam.id)) {
      if (grade.studentId != null) {
        _gradeByStudentId[grade.studentId!] = grade;
      }
    }
    final answersByAttempt = <String, List<ExamAnswer>>{};
    for (final attempt in attempts) {
      final answers = await _controller.loadAnswers(attempt.id);
      answersByAttempt[attempt.id] = answers;
    }
    setState(() {
      _questions = _controller.questions.toList();
      _attempts = attempts.where((a) => a.status == 'submitted').toList();
      _answersByAttempt.clear();
      _answersByAttempt.addAll(answersByAttempt);
      _isLoading = false;
    });
  }

  List<ExamQuestion> _essayQuestions() {
    return _questions.where((q) => q.type == 'essay').toList();
  }

  Future<void> _saveScores(ExamAttempt attempt) async {
    final answers = _answersByAttempt[attempt.id] ?? [];
    var essayScore = 0;
    for (final answer in answers) {
      final isEssay = _questions.any(
        (q) => q.id == answer.questionId && q.type == 'essay',
      );
      if (!isEssay) {
        continue;
      }
      final key = answer.id;
      final scoreText = _scoreControllers[key]?.text.trim() ?? '';
      final score = int.tryParse(scoreText);
      if (score != null) {
        essayScore += score;
        await _dataService.updateExamAnswer(answer.id, {
          'score': score,
        });
      }
    }
    final totalScore = (attempt.mcqScore ?? 0) + essayScore;
    final studentId = attempt.userId;
    final grade = _gradeByStudentId[studentId];
    await _dataService.upsertExamGrade({
      'student_id': studentId,
      'student_name': grade?.studentName ?? 'Mahasiswa',
      'score': totalScore,
      'class_id': widget.exam.classId,
      'exam_id': widget.exam.id,
    });
    Get.snackbar(
      'Berhasil',
      'Nilai essay berhasil disimpan.',
      backgroundColor: AppColors.navy,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final essayQuestions = _essayQuestions();
    return Scaffold(
      appBar: AppBar(title: Text('Penilaian ${widget.exam.title}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _attempts.length,
          itemBuilder: (context, index) {
            final attempt = _attempts[index];
            final answers = _answersByAttempt[attempt.id] ?? [];
            final essayAnswers = answers.where((answer) {
              return essayQuestions.any((q) => q.id == answer.questionId);
            }).toList();
            final grade = _gradeByStudentId[attempt.userId];
            final studentLabel = grade?.studentName ?? attempt.userId;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('MCQ: ${attempt.mcqScore ?? 0}'),
                    const SizedBox(height: 12),
                    if (essayAnswers.isEmpty)
                      const Text(
                        'Tidak ada jawaban essay.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...essayAnswers.map(
                        (answer) {
                          final question = essayQuestions.firstWhere(
                            (q) => q.id == answer.questionId,
                          );
                          final controller = _scoreControllers.putIfAbsent(
                            answer.id,
                            () => TextEditingController(
                              text: answer.score?.toString() ?? '',
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.prompt,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(answer.answerText ?? '-'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Nilai essay',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _saveScores(attempt),
                        child: const Text('Simpan Nilai'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
