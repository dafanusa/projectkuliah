import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/auth_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../navigation/controllers/navigation_controller.dart';
import '../../../../routes/app_routes.dart';

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
      Get.snackbar(
        'Login gagal',
        'Email dan password wajib diisi.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      _authService.suspendRedirect.value = true;
      _authService.role.value = '';
      _authService.name.value = '';
      _authService.nim.value = '';
      _authService.avatarUrl.value = '';
      final currentUser = _authService.user.value;
      if (currentUser != null) {
        await _authService.signOut(scope: SignOutScope.local);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await _authService.signIn(email: email, password: password);
      _authService.user.value = Supabase.instance.client.auth.currentUser;
      await _authService.loadProfile();
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().reset();
      }
      Get.offAllNamed(Routes.main);
    } catch (error) {
      Get.snackbar(
        'Login gagal',
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

  Future<void> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Email wajib diisi.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    try {
      isLoading.value = true;
      await _authService.sendPasswordResetEmail(trimmed);
      Get.snackbar(
        'Berhasil',
        'Link reset password sudah dikirim ke email.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
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

  Future<void> loginWithGoogle() async {
    if (isLoading.value) {
      return;
    }
    try {
      isLoading.value = true;
      _authService.suspendRedirect.value = true;
      final currentUser = _authService.user.value;
      if (currentUser != null) {
        await _authService.signOut(scope: SignOutScope.local);
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await _authService.signInWithGoogle();
    } catch (error) {
      Get.snackbar(
        'Login gagal',
        error.toString(),
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    } finally {
      _authService.suspendRedirect.value = false;
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
