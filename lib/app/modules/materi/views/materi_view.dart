import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/material_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/materi_controller.dart';

class MateriView extends GetView<MateriController> {
  const MateriView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.materi.toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final hasUnassigned =
          items.any((item) => item.classId == null || item.classId!.isEmpty);
      final countByClassId = <String, int>{};
      for (final item in items) {
        final classId = item.classId ?? '';
        countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
      }

      return RefreshIndicator(
        onRefresh: controller.loadMateri,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (authService.role.value == 'admin')
                Reveal(
                  delayMs: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Materi',
                      subtitle: 'Tambah, ubah, atau arsipkan materi.',
                      actionLabel: 'Tambah Materi',
                      onTap: () => showMateriForm(
                        context,
                        controller,
                        classesController,
                      ),
                    ),
                  ),
                ),
              const Reveal(
                delayMs: 120,
                child: _PageHeader(
                  title: 'Materi Kuliah',
                  subtitle: 'Susun dan bagikan materi per pertemuan.',
                  chip: 'Tersimpan di Supabase',
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isLoading && items.isEmpty && classes.isEmpty
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : items.isEmpty && classes.isEmpty
                        ? const _EmptyState(
                            title: 'Belum ada materi',
                            subtitle:
                                'Admin bisa menambahkan materi dari panel atas.',
                          )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 720;
                          final itemWidth = isWide
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                          final tiles = <Widget>[];
                          for (final entry in classes.asMap().entries) {
                            final classItem = entry.value;
                            final count = countByClassId[classItem.id] ?? 0;
                            tiles.add(
                              Reveal(
                                delayMs: 140 + entry.key * 70,
                                child: SizedBox(
                                  width: itemWidth,
                                  child: _ClassCard(
                                    title: classItem.name,
                                    subtitle: '$count materi',
                                    icon: Icons.menu_book_rounded,
                                    onTap: () => Get.to(
                                      () => MateriClassView(
                                        classId: classItem.id,
                                        className: classItem.name,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (hasUnassigned) {
                            tiles.add(
                              Reveal(
                                delayMs: 140 + tiles.length * 70,
                                child: SizedBox(
                                  width: itemWidth,
                                  child: _ClassCard(
                                    title: 'Tanpa Kelas',
                                    subtitle:
                                        '${countByClassId[''] ?? 0} materi',
                                    icon: Icons.folder_off_rounded,
                                    onTap: () => Get.to(
                                      () => const MateriClassView(
                                        classId: null,
                                        className: 'Tanpa Kelas',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: tiles,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chip;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.chip,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFD6E0F5)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _AdminPanel({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
              child: const Icon(Icons.settings_rounded, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded, size: 40, color: AppColors.navy),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ClassCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class MateriClassView extends GetView<MateriController> {
  final String? classId;
  final String className;

  const MateriClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Materi $className')),
      body: Obx(() {
        final items = controller.materi.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;

        return RefreshIndicator(
          onRefresh: controller.loadMateri,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (authService.role.value == 'admin')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Materi',
                      subtitle: 'Tambah materi untuk $className.',
                      actionLabel: 'Tambah Materi',
                      onTap: () => showMateriForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _ClassHero(
                  title: 'Materi $className',
                  subtitle: 'Daftar materi untuk kelas ini.',
                  badge: '${items.length} materi',
                  icon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isLoading && items.isEmpty
                      ? const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : items.isEmpty
                          ? const _EmptyState(
                              title: 'Belum ada materi',
                              subtitle: 'Materi akan tampil di sini.',
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 820;
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
                                          child: _ListCard(
                                            item: item,
                                            isAdmin:
                                                authService.role.value == 'admin',
                                            onEdit: () => showMateriForm(
                                              context,
                                              controller,
                                              classesController,
                                              item: item,
                                              fixedClassId: classId,
                                              fixedClassName: className,
                                            ),
                                            onDelete: () =>
                                                controller.deleteMateri(item.id),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ListCard extends StatelessWidget {
  final MaterialItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListCard({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = item.date == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(item.date!);
    final isPublished =
        item.date != null && item.date!.isBefore(DateTime.now());
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFF9FAFF), Color(0xFFF1F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(item.description),
                              const SizedBox(height: 6),
                              Text(
                                'Kelas: ${item.className ?? '-'}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          Row(
                            children: [
                              _ActionIcon(
                                icon: Icons.edit_rounded,
                                color: AppColors.navy,
                                onTap: onEdit,
                              ),
                              const SizedBox(width: 8),
                              _ActionIcon(
                                icon: Icons.delete_rounded,
                                color: Colors.red,
                                onTap: onDelete,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _InfoPill(label: 'Tanggal', value: dateLabel),
                            const SizedBox(width: 8),
                            _InfoPill(
                              label: 'Status',
                              value: isPublished ? 'Terbit' : 'Terjadwal',
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(label: 'Pertemuan', value: item.meeting),
                          ],
                        ),
                        if (item.filePath != null && item.filePath!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _AttachmentCard(path: item.filePath!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF627086)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final String path;

  const _AttachmentCard({required this.path});

  String _fileName(String value) {
    final parts = value.split('/');
    return parts.isEmpty ? value : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Get.find<DataService>();
    final fileName = _fileName(path);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attach_file_rounded,
                size: 16, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampiran tersedia',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final url = dataService.getPublicUrl(
                bucket: 'materials',
                path: path,
              );
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ClassHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;

  const _ClassHero({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1E3B), Color(0xFF2C3E66), Color(0xFF21304A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2600142B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
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
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
