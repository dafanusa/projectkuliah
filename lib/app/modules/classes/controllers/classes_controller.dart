import 'package:get/get.dart';

import '../../../models/class_item.dart';
import '../../../services/data_service.dart';

class ClassesController extends GetxController {
  final DataService _dataService = Get.find<DataService>();

  final classes = <ClassItem>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }

  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      classes.value = await _dataService.fetchClasses();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addClass(String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.addClass(name.trim());
    await loadClasses();
  }

  Future<void> deleteClass(String id) async {
    await _dataService.deleteClass(id);
    await loadClasses();
  }

  Future<void> updateClass(String id, String name) async {
    if (name.trim().isEmpty) {
      return;
    }
    await _dataService.updateClass(id, name.trim());
    await loadClasses();
  }
}
