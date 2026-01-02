import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';

import '../../../models/lecturer_work_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class KaryaController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final karya = <LecturerWorkItem>[].obs;
  final isLoading = false.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadKarya();
    ever(_authService.role, (_) => loadKarya());
  }

  Future<void> loadKarya() async {
    try {
      isLoading.value = true;
      karya.value = await _dataService.fetchLecturerWorks();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadKaryaFile(XFile file) async {
    return _dataService.uploadFile(
      file: file,
      bucket: 'materials',
      folder: 'karya',
    );
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

  Future<void> deleteKarya(String id) async {
    await _dataService.deleteLecturerWork(id);
    await loadKarya();
  }
}
