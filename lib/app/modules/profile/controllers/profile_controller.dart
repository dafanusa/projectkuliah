import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';

class ProfileController extends GetxController {
  AuthService get authService => Get.find<AuthService>();
  final DataService _dataService = Get.find<DataService>();
  final isUploading = false.obs;

  Future<void> pickAndUploadAvatar() async {
    if (isUploading.value) {
      return;
    }
    final result = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Gambar',
          extensions: ['png', 'jpg', 'jpeg'],
        ),
      ],
    );
    if (result == null) {
      return;
    }
    final userId = authService.user.value?.id;
    if (userId == null) {
      Get.snackbar(
        'Gagal',
        'Sesi login tidak ditemukan.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    try {
      isUploading.value = true;
      final path = await _dataService.uploadAvatar(file: result);
      if (path == null) {
        Get.snackbar(
          'Gagal',
          'Upload foto gagal.',
          backgroundColor: AppColors.navy,
          colorText: Colors.white,
        );
        return;
      }
      await _dataService.updateProfile(userId, {'avatar_url': path});
      authService.avatarUrl.value = path;
      Get.snackbar(
        'Berhasil',
        'Foto profil diperbarui.',
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
      isUploading.value = false;
    }
  }
}
