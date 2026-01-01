import 'package:get/get.dart';

import '../../../models/assignment_item.dart';
import '../../../models/result_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class HasilController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final hasil = <ResultItem>[].obs;
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
      hasil.value = await _dataService.fetchResults();
      assignments.value = await _dataService.fetchAssignments(
        includeExpired: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addResult({
    required String assignmentId,
    required String? classId,
    required int collected,
    required int missing,
    required int graded,
  }) async {
    await _dataService.insertResult({
      'assignment_id': assignmentId,
      'class_id': classId,
      'collected': collected,
      'missing': missing,
      'graded': graded,
    });
    await loadAll();
  }

  Future<void> updateResult({
    required String id,
    required String assignmentId,
    required String? classId,
    required int collected,
    required int missing,
    required int graded,
  }) async {
    await _dataService.updateResult(id, {
      'assignment_id': assignmentId,
      'class_id': classId,
      'collected': collected,
      'missing': missing,
      'graded': graded,
    });
    await loadAll();
  }

  Future<void> deleteResult(String id) async {
    await _dataService.deleteResult(id);
    await loadAll();
  }
}
