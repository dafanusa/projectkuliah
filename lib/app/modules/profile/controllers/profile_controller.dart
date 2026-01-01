import 'package:get/get.dart';

import '../../../services/auth_service.dart';

class ProfileController extends GetxController {
  AuthService get authService => Get.find<AuthService>();
}
