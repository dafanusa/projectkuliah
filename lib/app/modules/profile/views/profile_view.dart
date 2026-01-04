import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/profile_controller.dart';

const String _noSemesterId = '__no_semester__';

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
                child: Column(
                  children: [
                    _SemesterSection(classesController: classesController),
                    const SizedBox(height: 16),
                    _ClassSection(classesController: classesController),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Reveal(
              delayMs: 200,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: authService.signOutAndRedirect,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isWide = MediaQuery.of(context).size.width >= 900;
                if (isWide) {
                  return const SizedBox.shrink();
                }
                return const _FooterCredit();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterCredit extends StatelessWidget {
  const _FooterCredit();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          '© 2026',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Developed by Rizqullah Dafa Nusa',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _SemesterSection extends StatelessWidget {
  final ClassesController classesController;

  const _SemesterSection({required this.classesController});

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
                const Icon(Icons.calendar_month_rounded, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  'Manajemen Semester',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openAddSemesterDialog(classesController),
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final semesters = classesController.semesters.toList();
              final classes = classesController.classes.toList();
              if (semesters.isEmpty) {
                return const Text('Belum ada semester. Tambahkan semester baru.');
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
                    children: semesters.map((item) {
                      final classCount = classes
                          .where((c) => c.semesterId == item.id)
                          .length;
                      return SizedBox(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total kelas: $classCount',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.navy),
                                onPressed: () => _openEditSemesterDialog(
                                  classesController,
                                  item.id,
                                  item.name,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded,
                                    color: Colors.red),
                                onPressed: () => _confirmDelete(
                                  title: 'Hapus semester ini?',
                                  successMessage:
                                      'Semester berhasil dihapus.',
                                  onConfirm: () => classesController
                                      .deleteSemester(item.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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

class _ClassSection extends StatefulWidget {
  final ClassesController classesController;

  const _ClassSection({required this.classesController});

  @override
  State<_ClassSection> createState() => _ClassSectionState();
}

class _ClassSectionState extends State<_ClassSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedSemesterId = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  onPressed: () => _openAddClassDialog(widget.classesController),
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari kelas atau kode...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final items = widget.classesController.classes.toList();
              final semesters = widget.classesController.semesters.toList();
              if (items.isEmpty) {
                return const Text('Belum ada kelas. Tambahkan kelas baru.');
              }
              final hasNoSemester = items.any(
                (item) => item.semesterId == null || item.semesterId!.isEmpty,
              );
              final countBySemesterId = <String, int>{};
              for (final item in items) {
                final semesterKey = item.semesterId ?? _noSemesterId;
                countBySemesterId[semesterKey] =
                    (countBySemesterId[semesterKey] ?? 0) + 1;
              }
              final filtered = items.where((item) {
                if (_selectedSemesterId.isNotEmpty) {
                  if (_selectedSemesterId == _noSemesterId) {
                    if (item.semesterId != null &&
                        item.semesterId!.isNotEmpty) {
                      return false;
                    }
                  } else if (item.semesterId != _selectedSemesterId) {
                    return false;
                  }
                }
                if (_query.isEmpty) {
                  return true;
                }
                final name = item.name.toLowerCase();
                final code = item.joinCode.toLowerCase();
                return name.contains(_query) || code.contains(_query);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (semesters.isNotEmpty || hasNoSemester)
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _SemesterFilterChip(
                            label: 'Semua',
                            count: items.length,
                            isSelected: _selectedSemesterId.isEmpty,
                            onTap: () =>
                                setState(() => _selectedSemesterId = ''),
                          ),
                          ...semesters.map(
                            (item) => _SemesterFilterChip(
                              label: item.name,
                              count: countBySemesterId[item.id] ?? 0,
                              isSelected: _selectedSemesterId == item.id,
                              onTap: () =>
                                  setState(() => _selectedSemesterId = item.id),
                            ),
                          ),
                          if (hasNoSemester)
                            _SemesterFilterChip(
                              label: 'Tanpa Semester',
                              count: countBySemesterId[_noSemesterId] ?? 0,
                              isSelected:
                                  _selectedSemesterId == _noSemesterId,
                              onTap: () => setState(
                                () => _selectedSemesterId = _noSemesterId,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Menampilkan ${filtered.length} kelas',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Text(
                      'Kelas tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 720;
                        final itemWidth = isWide
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: filtered
                              .map(
                                (item) => SizedBox(
                                  width: itemWidth,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F9FD),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Semester: ${item.semesterName?.isNotEmpty == true ? item.semesterName : 'Tanpa Semester'}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.joinCode.isEmpty
                                                    ? 'Kode: belum diatur'
                                                    : 'Kode: ${item.joinCode}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded,
                                              color: AppColors.navy),
                                          onPressed: () => _openEditClassDialog(
                                            widget.classesController,
                                            item.id,
                                            item.name,
                                            item.joinCode,
                                            item.semesterId,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded,
                                              color: Colors.red),
                                          onPressed: () => _confirmDelete(
                                            title: 'Hapus kelas ini?',
                                            successMessage:
                                                'Kelas berhasil dihapus.',
                                            onConfirm: () =>
                                                widget.classesController
                                                    .deleteClass(item.id),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SemesterFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SemesterFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy : const Color(0xFFE8ECF5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}


Future<void> _openAddClassDialog(ClassesController controller) async {
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final semesters = controller.semesters.toList();
  String? selectedSemesterId;
  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Tambah Kelas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kelas'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kode Kelas'),
                ),
                const SizedBox(height: 12),
                if (semesters.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: selectedSemesterId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tanpa Semester'),
                      ),
                      ...semesters.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedSemesterId = value),
                    decoration: const InputDecoration(
                      labelText: 'Semester (opsional)',
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Belum ada semester, kelas akan disimpan tanpa semester.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final joinCode = codeController.text.trim();
                if (name.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Nama kelas wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                if (joinCode.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Kode kelas wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                await controller.addClass(
                  name,
                  joinCode: joinCode,
                  semesterId: selectedSemesterId,
                );
                Get.back();
                Future.microtask(() {
                  Get.snackbar(
                    'Berhasil',
                    'Kelas berhasil ditambahkan.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _openEditClassDialog(
  ClassesController controller,
  String id,
  String currentName,
  String currentCode,
  String? currentSemesterId,
) async {
  final nameController = TextEditingController(text: currentName);
  final codeController = TextEditingController(text: currentCode);
  final semesters = controller.semesters.toList();
  String? selectedSemesterId = currentSemesterId;
  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Ubah Kelas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kelas'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Kode Kelas'),
                ),
                const SizedBox(height: 12),
                if (semesters.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: selectedSemesterId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tanpa Semester'),
                      ),
                      ...semesters.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedSemesterId = value),
                    decoration: const InputDecoration(
                      labelText: 'Semester (opsional)',
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Belum ada semester, kelas akan disimpan tanpa semester.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final joinCode = codeController.text.trim();
                if (name.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Nama kelas wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                if (joinCode.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Kode kelas wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                await controller.updateClass(
                  id,
                  name,
                  joinCode: joinCode,
                  semesterId: selectedSemesterId,
                );
                Get.back();
                Future.microtask(() {
                  Get.snackbar(
                    'Berhasil',
                    'Kelas berhasil diperbarui.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _openAddSemesterDialog(ClassesController controller) async {
  final nameController = TextEditingController();
  await Get.dialog(
    AlertDialog(
      title: const Text('Tambah Semester'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'Nama Semester'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar(
                'Gagal',
                'Nama semester wajib diisi.',
                backgroundColor: AppColors.navy,
                colorText: Colors.white,
              );
              return;
            }
            try {
              await controller.addSemester(name);
              Get.back();
              Future.microtask(() {
                Get.snackbar(
                  'Berhasil',
                  'Semester berhasil ditambahkan.',
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
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<void> _openEditSemesterDialog(
  ClassesController controller,
  String id,
  String currentName,
) async {
  final nameController = TextEditingController(text: currentName);
  await Get.dialog(
    AlertDialog(
      title: const Text('Ubah Semester'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'Nama Semester'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar(
                'Gagal',
                'Nama semester wajib diisi.',
                backgroundColor: AppColors.navy,
                colorText: Colors.white,
              );
              return;
            }
            try {
              await controller.updateSemester(id, name);
              Get.back();
              Future.microtask(() {
                Get.snackbar(
                  'Berhasil',
                  'Semester berhasil diperbarui.',
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
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<void> _confirmDelete({
  required String title,
  required String successMessage,
  required Future<void> Function() onConfirm,
}) async {
  await Get.dialog(
    AlertDialog(
      title: Text(title),
      content: const Text('Tindakan ini tidak bisa dibatalkan.'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await onConfirm();
              Get.back();
              Future.microtask(() {
                Get.snackbar(
                  'Berhasil',
                  successMessage,
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
                snackPosition: SnackPosition.TOP,
              );
            }
          },
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}
