import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = controller.authService;
    final classesController = Get.find<ClassesController>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navyAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authService.name.value.isEmpty
                      ? 'Profil Pengguna'
                      : authService.name.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  authService.user.value?.email ?? '-',
                  style: const TextStyle(color: Color(0xFFD6E0F5)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Role: ${authService.role.value.isEmpty ? '-' : authService.role.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (authService.role.value != 'admin') {
            return const SizedBox.shrink();
          }
          return _ClassSection(classesController: classesController);
        }),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.navy),
            title: const Text('Keluar'),
            subtitle: const Text('Akhiri sesi dan kembali ke login.'),
            onTap: authService.signOut,
          ),
        ),
      ],
    );
  }
}

class _ClassSection extends StatelessWidget {
  final ClassesController classesController;

  const _ClassSection({required this.classesController});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.class_rounded, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  'Manajemen Kelas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openAddClassDialog(classesController),
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final items = classesController.classes.toList();
              if (items.isEmpty) {
                return const Text('Belum ada kelas. Tambahkan kelas baru.');
              }
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.red),
                          onPressed: () => classesController.deleteClass(item.id),
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Future<void> _openAddClassDialog(ClassesController controller) async {
  final nameController = TextEditingController();
  await Get.dialog(
    AlertDialog(
      title: const Text('Tambah Kelas'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'Nama Kelas'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar('Gagal', 'Nama kelas wajib diisi.');
              return;
            }
            await controller.addClass(name);
            Get.back();
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
