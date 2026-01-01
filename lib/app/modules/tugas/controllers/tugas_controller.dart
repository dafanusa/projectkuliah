import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../../models/assignment_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class TugasController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final tugas = <AssignmentItem>[].obs;
  final isLoading = false.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadTugas();
    ever(_authService.role, (_) => loadTugas());
  }

  Future<void> loadTugas() async {
    try {
      isLoading.value = true;
      tugas.value = await _dataService.fetchAssignments(
        includeExpired: isAdmin,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadTugasFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'assignments',
      folder: 'tugas',
    );
  }

  Future<void> addTugas({
    required String title,
    required String instructions,
    required DateTime deadline,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.insertAssignment({
      'title': title,
      'instructions': instructions,
      'deadline': deadline.toIso8601String(),
      'class_id': classId,
      'file_path': filePath,
    });
    await loadTugas();
  }

  Future<void> updateTugas({
    required String id,
    required String title,
    required String instructions,
    required DateTime deadline,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.updateAssignment(id, {
      'title': title,
      'instructions': instructions,
      'deadline': deadline.toIso8601String(),
      'class_id': classId,
      'file_path': filePath,
    });
    await loadTugas();
  }

  Future<void> deleteTugas(String id) async {
    await _dataService.deleteAssignment(id);
    await loadTugas();
  }
}
