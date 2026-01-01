import 'package:get/get.dart';

import '../../../models/assignment_item.dart';
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
}
