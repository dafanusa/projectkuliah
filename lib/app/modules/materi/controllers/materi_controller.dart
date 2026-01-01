import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../../models/material_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class MateriController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final materi = <MaterialItem>[].obs;
  final isLoading = false.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadMateri();
    ever(_authService.role, (_) => loadMateri());
  }

  Future<void> loadMateri() async {
    try {
      isLoading.value = true;
      materi.value = await _dataService.fetchMaterials();
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

  Future<void> deleteMateri(String id) async {
    await _dataService.deleteMaterial(id);
    await loadMateri();
  }
}
