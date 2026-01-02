import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final nimController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  AuthService get _authService => Get.find<AuthService>();

  Future<void> register() async {
    if (isLoading.value) {
      return;
    }

    final name = nameController.text.trim();
    final nim = nimController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || nim.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Registrasi gagal',
        'Semua field wajib diisi.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      _authService.suspendRedirect.value = true;
      await _authService.signUp(
        name: name,
        nim: nim,
        email: email,
        password: password,
        role: 'user',
      );
      await _authService.signOut();
      Get.snackbar(
        'Berhasil',
        'Akun berhasil dibuat. Silakan login.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      _authService.suspendRedirect.value = false;
      Get.offAllNamed(Routes.login);
    } catch (error) {
      Get.snackbar(
        'Registrasi gagal',
        error.toString(),
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    } finally {
      _authService.suspendRedirect.value = false;
      isLoading.value = false;
    }
  }

  void togglePassword() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  @override
  void onClose() {
    nameController.dispose();
    nimController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
