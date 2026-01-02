import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    _authService.suspendRedirect.value = true;
    await Future.delayed(const Duration(milliseconds: 5000));
    _authService.suspendRedirect.value = false;

    if (_authService.isLoggedIn) {
      Get.offAllNamed(Routes.main);
    } else {
      Get.offAllNamed(Routes.welcome);
    }
  }
}
