import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/auth_service.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  AuthService get _authService => Get.find<AuthService>();

  Future<void> login() async {
    if (isLoading.value) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Login gagal', 'Email dan password wajib diisi.');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.signIn(email: email, password: password);
    } catch (error) {
      Get.snackbar('Login gagal', error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void togglePassword() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
