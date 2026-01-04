import 'package:get/get.dart';

import '../../../models/class_item.dart';
import '../../../models/semester_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../hasil/controllers/hasil_controller.dart';
import '../../materi/controllers/materi_controller.dart';
import '../../nilai/controllers/nilai_controller.dart';
import '../../tugas/controllers/tugas_controller.dart';
import '../../ujian/controllers/ujian_controller.dart';

class ClassesController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final classes = <ClassItem>[].obs;
  final semesters = <SemesterItem>[].obs;
  final enrolledClassIds = <String>{}.obs;
  final isLoading = false.obs;
  final isJoining = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClasses();
    everAll([_authService.role, _authService.user], (_) => loadClasses());
  }

  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      semesters.value = await _dataService.fetchSemesters();
      classes.value = await _dataService.fetchClasses();
      await _loadEnrollments();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addClass(
    String name, {
    String? joinCode,
    String? semesterId,
  }) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.addClass(
      name.trim(),
      joinCode: joinCode,
      semesterId: semesterId,
    );
    await loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _dataService.deleteClass(id);
    await loadClasses();
  }

  Future<void> updateClass(
    String id,
    String name, {
    String? joinCode,
    String? semesterId,
  }) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.updateClass(
      id,
      name.trim(),
      joinCode: joinCode,
      semesterId: semesterId,
    );
    await loadClasses();
  }

  Future<void> addSemester(String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.addSemester(name.trim());
    await loadClasses();
  }

  Future<void> updateSemester(String id, String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.updateSemester(id, name.trim());
    await loadClasses();
  }

  Future<void> deleteSemester(String id) async {
    await _dataService.deleteSemester(id);
    await loadClasses();
  }

  bool isClassLocked(String classId) {
    if (_authService.role.value == 'admin') {
      return false;
    }
    if (classId.isEmpty) {
      return false;
    }
    return !enrolledClassIds.contains(classId);
  }

  Future<void> joinClass({
    required String classId,
    required String code,
  }) async {
    if (_authService.role.value == 'admin') {
      return;
    }
    final userId = _authService.user.value?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Sesi login tidak ditemukan.');
    }
    try {
      isJoining.value = true;
      await _dataService.joinClassWithCode(
        classId: classId,
        userId: userId,
        code: code,
      );
      await _loadEnrollments();
      await _refreshUserData();
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> _loadEnrollments() async {
    final userId = _authService.user.value?.id;
    if (_authService.role.value == 'admin' ||
        userId == null ||
        userId.isEmpty) {
      enrolledClassIds.value = <String>{};
      return;
    }
    final ids = await _dataService.fetchEnrolledClassIds(userId: userId);
    enrolledClassIds.value = ids.toSet();
  }

  Future<void> _refreshUserData() async {
    final futures = <Future<void>>[];
    if (Get.isRegistered<MateriController>()) {
      futures.add(Get.find<MateriController>().loadMateri());
    }
    if (Get.isRegistered<TugasController>()) {
      futures.add(Get.find<TugasController>().loadTugas());
    }
    if (Get.isRegistered<UjianController>()) {
      futures.add(Get.find<UjianController>().loadUjian());
    }
    if (Get.isRegistered<HasilController>()) {
      futures.add(Get.find<HasilController>().loadAll());
    }
    if (Get.isRegistered<NilaiController>()) {
      futures.add(Get.find<NilaiController>().loadAll());
    }
    if (futures.isEmpty) {
      return;
    }
    await Future.wait(futures);
  }
}
