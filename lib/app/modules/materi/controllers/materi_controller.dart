import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../../models/lecturer_work_item.dart';
import '../../../models/material_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class MateriController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final materi = <MaterialItem>[].obs;
  final karya = <LecturerWorkItem>[].obs;
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
      await Future.wait([loadMateri(), loadKarya()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMateri() async {
    try {
      isLoading.value = true;
      materi.value = await _dataService.fetchMaterials();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadKarya() async {
    try {
      isLoading.value = true;
      karya.value = await _dataService.fetchLecturerWorks();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadMateriFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'materials',
      folder: 'materi',
    );
  }

  Future<String?> uploadKaryaFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'materials',
      folder: 'karya',
    );
  }

  Future<void> addMateri({
    required String title,
    required String description,
    required String meeting,
    required DateTime? date,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.insertMaterial({
      'title': title,
      'description': description,
      'meeting': meeting,
      'date': date?.toIso8601String(),
      'class_id': classId,
      'file_path': filePath,
    });
    await loadMateri();
  }

  Future<void> addKarya({
    required String title,
    required String description,
    required String category,
    required DateTime? date,
    required String? filePath,
  }) async {
    await _dataService.insertLecturerWork({
      'title': title,
      'description': description,
      'category': category,
      'date': date?.toIso8601String(),
      'file_path': filePath,
    });
    await loadKarya();
  }

  Future<void> updateMateri({
    required String id,
    required String title,
    required String description,
    required String meeting,
    required DateTime? date,
    required String? classId,
    required String? filePath,
  }) async {
    await _dataService.updateMaterial(id, {
      'title': title,
      'description': description,
      'meeting': meeting,
      'date': date?.toIso8601String(),
      'class_id': classId,
      'file_path': filePath,
    });
    await loadMateri();
  }

  Future<void> updateKarya({
    required String id,
    required String title,
    required String description,
    required String category,
    required DateTime? date,
    required String? filePath,
  }) async {
    await _dataService.updateLecturerWork(id, {
      'title': title,
      'description': description,
      'category': category,
      'date': date?.toIso8601String(),
      'file_path': filePath,
    });
    await loadKarya();
  }

  Future<void> deleteMateri(String id) async {
    await _dataService.deleteMaterial(id);
    await loadMateri();
  }

  Future<void> deleteKarya(String id) async {
    await _dataService.deleteLecturerWork(id);
    await loadKarya();
  }
}
