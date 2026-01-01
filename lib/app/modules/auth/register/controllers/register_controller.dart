import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../../services/auth_service.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
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
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar('Registrasi gagal', 'Semua field wajib diisi.');
      return;
    }

    try {
      isLoading.value = true;
      _authService.suspendRedirect.value = true;
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        role: 'user',
      );
      await _authService.signOut();
      Get.snackbar('Berhasil', 'Akun berhasil dibuat. Silakan login.');
      _authService.suspendRedirect.value = false;
      Get.offAllNamed(Routes.login);
    } catch (error) {
      Get.snackbar('Registrasi gagal', error.toString());
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
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
