import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/assignment_item.dart';
import '../../../models/assignment_submission.dart';
import '../../../models/student_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class TugasController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final tugas = <AssignmentItem>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final tabIndex = 0.obs;

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

  Future<String?> uploadSubmissionFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'assignments',
      folder: 'jawaban',
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

  Future<List<AssignmentSubmission>> loadSubmissions(String assignmentId) async {
    return _dataService.fetchAssignmentSubmissions(assignmentId);
  }

  Future<AssignmentSubmission?> loadMySubmission(String assignmentId) async {
    final userId = _authService.user.value?.id;
    if (userId == null) {
      return null;
    }
    return _dataService.fetchMySubmission(assignmentId, userId);
  }

  Future<List<StudentItem>> loadClassStudents(String? classId) async {
    if (classId == null || classId.isEmpty) {
      return [];
    }
    return _dataService.fetchClassStudents(classId);
  }

  Future<List<AssignmentSubmission>> loadMySubmissionsForClass(
    String? classId,
  ) async {
    final userId = _authService.user.value?.id;
    if (userId == null) {
      return [];
    }
    return _dataService.fetchMySubmissionsForClass(
      userId: userId,
      classId: classId,
    );
  }

  Future<String?> submitAssignment({
    required String assignmentId,
    required DateTime deadline,
    required String? content,
    required String? filePath,
  }) async {
    final userId = _authService.user.value?.id;
    if (userId == null) {
      return 'Sesi login tidak ditemukan.';
    }
    final now = DateTime.now();
    final status = now.isAfter(deadline) ? 'terlambat' : 'tepat_waktu';
    try {
      isSubmitting.value = true;
      final payload = <String, dynamic>{
        'assignment_id': assignmentId,
        'user_id': userId,
        'content': content,
        'file_path': filePath,
        'submitted_at': now.toIso8601String(),
        'status': status,
      };
      await _dataService.upsertAssignmentSubmission({
        ...payload,
      });
      final profilePayload = <String, dynamic>{};
      if (_authService.name.value.isNotEmpty) {
        profilePayload['name'] = _authService.name.value;
      }
      if (_authService.nim.value.isNotEmpty) {
        profilePayload['nim'] = _authService.nim.value;
      }
      if (profilePayload.isNotEmpty) {
        await _dataService.updateProfile(userId, profilePayload);
      }
      return null;
    } on PostgrestException catch (error) {
      return 'Gagal: ${error.message}';
    } catch (_) {
      return 'Gagal mengirim jawaban.';
    } finally {
      isSubmitting.value = false;
    }
  }
}
