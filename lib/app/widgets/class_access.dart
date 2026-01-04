import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/classes/controllers/classes_controller.dart';
import '../theme/app_colors.dart';

Future<bool> showJoinClassDialog({
  required ClassesController controller,
  required String classId,
  required String className,
}) async {
  final codeController = TextEditingController();
  bool isSubmitting = false;

  final result = await Get.dialog<bool>(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Masukkan kode $className'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(labelText: 'Kode kelas'),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) {
                        Get.snackbar(
                          'Gagal',
                          'Kode kelas wajib diisi.',
                          backgroundColor: AppColors.navy,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        await controller.joinClass(
                          classId: classId,
                          code: code,
                        );
                        Get.back(result: true);
                        Future.microtask(() {
                          Get.snackbar(
                            'Berhasil',
                            'Kelas berhasil dibuka.',
                            backgroundColor: AppColors.navy,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        });
                      } catch (error) {
                        Get.snackbar(
                          'Gagal',
                          error.toString(),
                          backgroundColor: AppColors.navy,
                          colorText: Colors.white,
                        );
                      } finally {
                        if (Get.isDialogOpen ?? false) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: Text(isSubmitting ? 'Memproses...' : 'Buka Kelas'),
            ),
          ],
        );
      },
    ),
  );

  return result == true;
}
