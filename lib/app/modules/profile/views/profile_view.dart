import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = controller.authService;
    final classesController = Get.find<ClassesController>();
    final dataService = Get.find<DataService>();

    return RefreshIndicator(
      onRefresh: classesController.loadClasses,
      child: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Reveal(
              delayMs: 60,
              child: _ProfileHero(
                authService: authService,
                dataService: dataService,
                controller: controller,
              ),
            ),
            const SizedBox(height: 16),
            Reveal(
              delayMs: 120,
              child: _ProfileStats(authService: authService),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (authService.role.value != 'admin') {
                return const SizedBox.shrink();
              }
              return Reveal(
                delayMs: 160,
                child: _ClassSection(classesController: classesController),
              );
            }),
            const SizedBox(height: 16),
            Reveal(
              delayMs: 200,
              child: Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.navy),
                  title: const Text('Keluar'),
                  subtitle: const Text('Akhiri sesi dan kembali ke login.'),
                  onTap: authService.signOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AuthService authService;
  final DataService dataService;
  final ProfileController controller;

  const _ProfileHero({
    required this.authService,
    required this.dataService,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        () {
          final name = authService.name.value;
          final nim = authService.nim.value;
          final email = authService.user.value?.email ?? '-';
          final avatarPath = authService.avatarUrl.value;
          final avatarUrl = avatarPath.isEmpty
              ? null
              : dataService.getPublicUrl(bucket: 'avatars', path: avatarPath);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage:
                        avatarUrl == null ? null : NetworkImage(avatarUrl),
                    child: avatarUrl == null
                        ? const Icon(Icons.person_rounded,
                            color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Profil Pengguna' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nim.isEmpty ? 'NIM: -' : 'NIM: $nim',
                          style: const TextStyle(color: Color(0xFFD6E0F5)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: Color(0xFFD6E0F5)),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => IconButton(
                      onPressed: controller.isUploading.value
                          ? null
                          : controller.pickAndUploadAvatar,
                      icon: Icon(
                        controller.isUploading.value
                            ? Icons.hourglass_empty_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Ubah foto',
                    ),
                  ),
                ],
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
          );
        },
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final AuthService authService;

  const _ProfileStats({required this.authService});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 820;
        final width = isWide ? (constraints.maxWidth - 24) / 3 : null;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              width: width,
              label: 'Status',
              value: 'Aktif',
              icon: Icons.verified_rounded,
            ),
            Obx(
              () => _StatCard(
                width: width,
                label: 'NIM',
                value: authService.nim.value.isEmpty
                    ? '-'
                    : authService.nim.value,
                icon: Icons.badge_rounded,
              ),
            ),
            Obx(
              () => _StatCard(
                width: width,
                label: 'Role',
                value: authService.role.value.isEmpty
                    ? '-'
                    : authService.role.value,
                icon: Icons.badge_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double? width;
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item.name)),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        color: AppColors.navy),
                                    onPressed: () =>
                                        _openEditClassDialog(classesController, item.id, item.name),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded,
                                        color: Colors.red),
                                    onPressed: () =>
                                        classesController.deleteClass(item.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
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
              Get.snackbar(
                'Gagal',
                'Nama kelas wajib diisi.',
                backgroundColor: AppColors.navy,
                colorText: Colors.white,
              );
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

Future<void> _openEditClassDialog(
  ClassesController controller,
  String id,
  String currentName,
) async {
  final nameController = TextEditingController(text: currentName);
  await Get.dialog(
    AlertDialog(
      title: const Text('Ubah Nama Kelas'),
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
              Get.snackbar(
                'Gagal',
                'Nama kelas wajib diisi.',
                backgroundColor: AppColors.navy,
                colorText: Colors.white,
              );
              return;
            }
            await controller.updateClass(id, name);
            Get.back();
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
