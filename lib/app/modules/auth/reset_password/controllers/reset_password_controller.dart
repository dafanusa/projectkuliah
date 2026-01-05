import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';

class ResetPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final isConfirmHidden = true.obs;

  AuthService get _authService => Get.find<AuthService>();

  Future<void> submit() async {
    if (isLoading.value) {
      return;
    }
    final password = passwordController.text;
    final confirm = confirmController.text;
    if (password.isEmpty || confirm.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Password wajib diisi.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    if (password != confirm) {
      Get.snackbar(
        'Gagal',
        'Konfirmasi password tidak sama.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    try {
      isLoading.value = true;
      final recovered = await _authService.recoverSessionFromUrl();
      if (!recovered) {
        Get.snackbar(
          'Gagal',
          'Link reset tidak valid atau sudah kedaluwarsa. Minta reset ulang.',
          backgroundColor: AppColors.navy,
          colorText: Colors.white,
        );
        return;
      }
      await _authService.updatePassword(password);
      await _authService.signOut();
      Get.snackbar(
        'Berhasil',
        'Password berhasil diperbarui. Silakan login.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.login);
    } catch (error) {
      Get.snackbar(
        'Gagal',
        error.toString(),
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePassword() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirm() {
    isConfirmHidden.value = !isConfirmHidden.value;
  }

  @override
  void onInit() {
    super.onInit();
    _authService.recoverSessionFromUrl();
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
