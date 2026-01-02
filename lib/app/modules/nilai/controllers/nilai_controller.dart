import 'package:get/get.dart';

import '../../../models/assignment_item.dart';
import '../../../models/assignment_submission.dart';
import '../../../models/grade_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class NilaiController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final nilai = <GradeItem>[].obs;
  final assignments = <AssignmentItem>[].obs;
  final isLoading = false.obs;

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
      assignments.value = await _dataService.fetchAssignments(
        includeExpired: true,
      );
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
}
