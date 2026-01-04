import 'package:get/get.dart';

import '../../../models/assignment_item.dart';
import '../../../models/assignment_submission.dart';
import '../../../models/exam_item.dart';
import '../../../models/exam_grade_item.dart';
import '../../../models/exam_submission_item.dart';
import '../../../models/grade_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class NilaiController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final nilai = <GradeItem>[].obs;
  final nilaiUjian = <ExamGradeItem>[].obs;
  final assignments = <AssignmentItem>[].obs;
  final exams = <ExamItem>[].obs;
  final isLoading = false.obs;
  final tabIndex = 0.obs;
  final selectedSemesterId = ''.obs;
  final searchQuery = ''.obs;
  final searchExamQuery = ''.obs;
  final semesterSearchQuery = ''.obs;
  final semesterExamSearchQuery = ''.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadAll();
    ever(_authService.role, (_) => loadAll());
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      nilai.value = await _dataService.fetchGrades();
      nilaiUjian.value = await _dataService.fetchExamGrades();
      assignments.value = await _dataService.fetchAssignments(
        includeExpired: true,
      );
      exams.value = await _dataService.fetchExams();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGrade({
    required String studentName,
    required int score,
    required String? classId,
    required String? assignmentId,
  }) async {
    await _dataService.insertGrade({
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'assignment_id': assignmentId,
    });
    await loadAll();
  }

  Future<void> updateGrade({
    required String id,
    required String studentName,
    required int score,
    required String? classId,
    required String? assignmentId,
  }) async {
    await _dataService.updateGrade(id, {
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'assignment_id': assignmentId,
    });
    await loadAll();
  }

  Future<void> deleteGrade(String id) async {
    await _dataService.deleteGrade(id);
    await loadAll();
  }

  Future<void> addExamGrade({
    required String studentId,
    required String studentName,
    required int score,
    required String? classId,
    required String? examId,
  }) async {
    await _dataService.insertExamGrade({
      'student_id': studentId,
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'exam_id': examId,
    });
    await loadAll();
  }

  Future<void> updateExamGrade({
    required String id,
    required String studentId,
    required String studentName,
    required int score,
    required String? classId,
    required String? examId,
  }) async {
    await _dataService.updateExamGrade(id, {
      'student_id': studentId,
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'exam_id': examId,
    });
    await loadAll();
  }

  Future<void> deleteExamGrade(String id) async {
    await _dataService.deleteExamGrade(id);
    await loadAll();
  }

  Future<List<AssignmentSubmission>> loadSubmissionStudents(
    String? assignmentId, {
    String? assignmentTitle,
    String? classId,
  }) async {
    if (assignmentId == null || assignmentId.isEmpty) {
      return [];
    }
    final submissions = await _dataService.fetchAllSubmissions();
    var filtered = submissions
        .where((item) => item.assignmentId == assignmentId)
        .toList();
    if (filtered.isEmpty &&
        assignmentTitle != null &&
        assignmentTitle.trim().isNotEmpty) {
      final titleKey = assignmentTitle.trim().toLowerCase();
      filtered = submissions.where((item) {
        final title = item.assignmentTitle?.trim().toLowerCase();
        if (title == null || title.isEmpty) {
          return false;
        }
        if (classId != null && classId.isNotEmpty && item.classId != classId) {
          return false;
        }
        return title == titleKey;
      }).toList();
    }
    return filtered;
  }

  Future<List<ExamSubmissionItem>> loadExamSubmissionStudents(
    String? examId, {
    String? examTitle,
    String? classId,
  }) async {
    if (examId == null || examId.isEmpty) {
      return [];
    }
    final submissions = await _dataService.fetchExamSubmissions(examId);
    if (submissions.isNotEmpty) {
      return submissions;
    }
    if (examTitle == null || examTitle.trim().isEmpty) {
      return submissions;
    }
    final titleKey = examTitle.trim().toLowerCase();
    return submissions.where((item) {
      final title = item.examTitle?.trim().toLowerCase();
      if (title == null || title.isEmpty) {
        return false;
      }
      if (classId != null && classId.isNotEmpty && item.classId != classId) {
        return false;
      }
      return title == titleKey;
    }).toList();
  }
}
