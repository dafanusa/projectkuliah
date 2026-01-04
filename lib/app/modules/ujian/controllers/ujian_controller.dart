import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../../models/exam_item.dart';
import '../../../models/exam_submission_item.dart';
import '../../../models/exam_question.dart';
import '../../../models/exam_choice.dart';
import '../../../models/exam_attempt.dart';
import '../../../models/exam_answer.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class UjianController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final ujian = <ExamItem>[].obs;
  final mySubmissions = <ExamSubmissionItem>[].obs;
  final isLoading = false.obs;
  final mySubmissionsClassId = ''.obs;
  final questions = <ExamQuestion>[].obs;
  final choices = <ExamChoice>[].obs;
  final myAttemptsByExamId = <String, List<ExamAttempt>>{}.obs;
  final myAttemptsClassId = ''.obs;
  final searchQuery = ''.obs;
  final semesterSearchQuery = ''.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadUjian();
    ever(_authService.role, (_) => loadUjian());
  }

  Future<void> loadUjian() async {
    try {
      isLoading.value = true;
      ujian.value = await _dataService.fetchExams();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMySubmissionsForClass(String? classId) async {
    final userId = _authService.user.value?.id;
    if (userId == null || userId.isEmpty) {
      mySubmissions.value = [];
      mySubmissionsClassId.value = classId ?? '';
      return;
    }
    mySubmissions.value = await _dataService.fetchMyExamSubmissionsForClass(
      userId: userId,
      classId: classId,
    );
    mySubmissionsClassId.value = classId ?? '';
  }

  Future<void> loadMyAttemptsForClass(String? classId) async {
    final userId = _authService.user.value?.id;
    if (userId == null || userId.isEmpty) {
      myAttemptsByExamId.value = {};
      myAttemptsClassId.value = classId ?? '';
      return;
    }
    final attempts = await _dataService.fetchMyExamAttemptsForClass(
      userId: userId,
      classId: classId,
    );
    final grouped = <String, List<ExamAttempt>>{};
    for (final attempt in attempts) {
      grouped.putIfAbsent(attempt.examId, () => []);
      grouped[attempt.examId]!.add(attempt);
    }
    myAttemptsByExamId.value = grouped;
    myAttemptsClassId.value = classId ?? '';
  }

  Future<String?> uploadUjianFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'assignments',
      folder: 'ujian',
    );
  }

  Future<void> addUjian({
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required int durationMinutes,
    required int maxAttempts,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.insertExam({
      'title': title,
      'description': description,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'date': endAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'max_attempts': maxAttempts,
      'class_id': classId,
      'file_path': filePath,
    });
    await loadUjian();
  }

  Future<void> updateUjian({
    required String id,
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    required int durationMinutes,
    required int maxAttempts,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.updateExam(id, {
      'title': title,
      'description': description,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'date': endAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'max_attempts': maxAttempts,
      'class_id': classId,
      'file_path': filePath,
    });
    await loadUjian();
  }

  Future<void> deleteUjian(String id) async {
    await _dataService.deleteExam(id);
    await loadUjian();
  }

  Future<void> loadQuestions(String examId) async {
    questions.value = await _dataService.fetchExamQuestions(examId);
    final choiceList = <ExamChoice>[];
    for (final question in questions) {
      if (question.type == 'mcq') {
        final fetched = await _dataService.fetchExamChoices(question.id);
        choiceList.addAll(fetched);
      }
    }
    choices.value = choiceList;
  }

  Future<void> saveQuestion({
    ExamQuestion? question,
    required String examId,
    required String type,
    required String prompt,
    required int points,
    required int orderIndex,
    required List<Map<String, dynamic>> options,
  }) async {
    ExamQuestion? savedQuestion = question;
    if (question == null) {
      savedQuestion = await _dataService.insertExamQuestion({
        'exam_id': examId,
        'type': type,
        'prompt': prompt,
        'points': points,
        'order_index': orderIndex,
      });
    } else {
      await _dataService.updateExamQuestion(question.id, {
        'type': type,
        'prompt': prompt,
        'points': points,
        'order_index': orderIndex,
      });
      await _dataService.deleteExamChoicesForQuestion(question.id);
    }
    if (type == 'mcq') {
      for (final option in options) {
        final text = (option['text'] as String?)?.trim() ?? '';
        if (text.isEmpty) {
          continue;
        }
        await _dataService.insertExamChoice({
          'question_id': savedQuestion?.id,
          'text': text,
          'is_correct': option['is_correct'] ?? false,
        });
      }
    }
  }

  Future<void> deleteQuestion(String id) async {
    await _dataService.deleteExamQuestion(id);
  }

  Future<void> recalcQuestionPoints(String examId) async {
    final items = await _dataService.fetchExamQuestions(examId);
    if (items.isEmpty) {
      return;
    }
    final total = items.length;
    final base = 100 ~/ total;
    var remainder = 100 - (base * total);
    for (final item in items) {
      final points = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) {
        remainder -= 1;
      }
      await _dataService.updateExamQuestion(item.id, {
        'points': points,
      });
    }
    await loadQuestions(examId);
  }

  Future<ExamAttempt?> getActiveAttempt({
    required String examId,
    required String userId,
  }) async {
    final attempts =
        await _dataService.fetchExamAttempts(examId: examId, userId: userId);
    for (final attempt in attempts) {
      if (attempt.status == 'in_progress') {
        return attempt;
      }
    }
    return null;
  }

  Future<List<ExamAttempt>> loadAttempts({
    required String examId,
    required String userId,
  }) async {
    return _dataService.fetchExamAttempts(examId: examId, userId: userId);
  }

  Future<List<ExamAttempt>> loadAttemptsForExam(String examId) async {
    return _dataService.fetchExamAttemptsForExam(examId);
  }

  Future<ExamAttempt> createAttempt({
    required String examId,
    required String userId,
    required int attemptNumber,
  }) async {
    return _dataService.insertExamAttempt({
      'exam_id': examId,
      'user_id': userId,
      'attempt_number': attemptNumber,
      'status': 'in_progress',
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<ExamAnswer>> loadAnswers(String attemptId) async {
    return _dataService.fetchExamAnswers(attemptId);
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    String? choiceId,
    String? answerText,
  }) async {
    await _dataService.upsertExamAnswer({
      'attempt_id': attemptId,
      'question_id': questionId,
      'choice_id': choiceId,
      'answer_text': answerText,
    });
  }

  Future<String?> submitAttempt({
    required ExamItem exam,
    required ExamAttempt attempt,
    required List<ExamQuestion> questions,
    required List<ExamChoice> choices,
    required List<ExamAnswer> answers,
  }) async {
    final now = DateTime.now();
    if (now.isAfter(exam.endAt)) {
      return 'Ujian sudah berakhir.';
    }
    final choiceMap = {for (final c in choices) c.id: c};
    var mcqScore = 0;
    for (final question in questions) {
      if (question.type != 'mcq') {
        continue;
      }
      ExamAnswer? answer;
      for (final item in answers) {
        if (item.questionId == question.id) {
          answer = item;
          break;
        }
      }
      if (answer == null || answer.choiceId == null) {
        continue;
      }
      final choice = choiceMap[answer.choiceId];
      final isCorrect = choice?.isCorrect == true;
      final score = isCorrect ? question.points : 0;
      mcqScore += score;
      await _dataService.upsertExamAnswer({
        'attempt_id': attempt.id,
        'question_id': question.id,
        'choice_id': answer.choiceId,
        'is_correct': isCorrect,
        'score': score,
      });
    }
    await _dataService.updateExamAttempt(attempt.id, {
      'submitted_at': now.toIso8601String(),
      'status': 'submitted',
      'mcq_score': mcqScore,
    });
    final studentId = _authService.user.value?.id;
    final studentName = _authService.name.value.isNotEmpty
        ? _authService.name.value
        : 'Mahasiswa';
    if (studentId != null) {
      await _dataService.upsertExamGrade({
        'student_id': studentId,
        'student_name': studentName,
        'score': mcqScore,
        'class_id': exam.classId,
        'exam_id': exam.id,
      });
      await _dataService.upsertExamSubmission({
        'exam_id': exam.id,
        'user_id': studentId,
        'submitted_at': now.toIso8601String(),
      });
    }
    return null;
  }
}
