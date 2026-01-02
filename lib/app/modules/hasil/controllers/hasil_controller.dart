import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/assignment_submission.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';

class HasilController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final submissions = <AssignmentSubmission>[].obs;
  final isLoading = false.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadAll();
    ever(_authService.role, (_) => loadAll());
    ever(_authService.user, (_) => loadAll());
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      if (isAdmin) {
        submissions.value = await _dataService.fetchAllSubmissions();
      } else {
        final userId = _authService.user.value?.id ??
            Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          submissions.clear();
        } else {
          submissions.value = await _dataService.fetchMySubmissionsForClass(
            userId: userId,
            classId: null,
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }
}
