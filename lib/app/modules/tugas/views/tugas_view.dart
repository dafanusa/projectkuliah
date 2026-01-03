import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/assignment_item.dart';
import '../../../models/assignment_submission.dart';
import '../../../models/student_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../../hasil/controllers/hasil_controller.dart';
import '../../hasil/views/hasil_view.dart';
import '../controllers/tugas_controller.dart';

class TugasView extends GetView<TugasController> {
  const TugasView({super.key});

  @override
  Widget build(BuildContext context) {
    final hasilController = Get.find<HasilController>();
    return Obx(() {
      final tabIndex = controller.tabIndex.value;
      Widget buildSwitcher() {
        return _TabSwitcher(
          currentIndex: tabIndex,
          onChanged: (index) {
            controller.tabIndex.value = index;
            if (index == 1) {
              hasilController.loadAll();
            }
          },
        );
      }
      return Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: [
                _TugasTab(headerBuilder: buildSwitcher),
                HasilView(headerBuilder: buildSwitcher),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _TugasTab extends GetView<TugasController> {
  final Widget Function()? headerBuilder;

  const _TugasTab({this.headerBuilder});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.tugas.toList();
      final isLoading = controller.isLoading.value;
      final now = DateTime.now();
      final aktif = items.where((item) => item.deadline.isAfter(now)).length;
      final lewat = items.length - aktif;
      final classes = classesController.classes.toList();
      final hasUnassigned =
          items.any((item) => item.classId == null || item.classId!.isEmpty);
      final countByClassId = <String, int>{};
      for (final item in items) {
        final classId = item.classId ?? '';
        countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
      }

      return RefreshIndicator(
        onRefresh: controller.loadTugas,
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
                      title: 'Kelola Tugas',
                      subtitle: 'Buat tugas baru \ndan atur deadline.',
                      actionLabel: 'Buat Tugas',
                      onTap: () => showTugasForm(
                        context,
                        controller,
                        classesController,
                      ),
                    ),
                  ),
                ),
              Reveal(
                delayMs: 120,
                child: _PageHeader(
                  title: 'Tugas Mahasiswa',
                  subtitle: 'Pantau deadline dan status tugas.',
                  stats: [
                    _HeaderStat(label: 'Aktif', value: aktif.toString()),
                    _HeaderStat(label: 'Lewat', value: lewat.toString()),
                    _HeaderStat(label: 'Total', value: items.length.toString()),
                  ],
                ),
              ),
              if (headerBuilder != null) ...[
                const SizedBox(height: 12),
                ResponsiveCenter(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: headerBuilder!(),
                ),
              ],
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
                            title: 'Belum ada tugas',
                            subtitle: 'Admin bisa menambahkan tugas baru.',
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
                                final count =
                                    countByClassId[classItem.id] ?? 0;
                                tiles.add(
                                  Reveal(
                                    delayMs: 140 + entry.key * 70,
                                    child: SizedBox(
                                      width: itemWidth,
                                      child: _ClassCard(
                                        title: classItem.name,
                                        subtitle: '$count tugas',
                                        icon: Icons.assignment_rounded,
                                        onTap: () => Get.to(
                                          () => TugasClassView(
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
                                            '${countByClassId[''] ?? 0} tugas',
                                        icon: Icons.folder_off_rounded,
                                        onTap: () => Get.to(
                                          () => const TugasClassView(
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
  final List<_HeaderStat> stats;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.stats,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats,
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _TabSwitcher({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Tugas',
            isActive: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 6),
          _TabButton(
            label: 'Hasil',
            isActive: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
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
              child: const Icon(Icons.assignment_turned_in_rounded,
                  color: AppColors.navy),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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

class TugasClassView extends GetView<TugasController> {
  final String? classId;
  final String className;

  const TugasClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();
    final dataService = Get.find<DataService>();

    return Scaffold(
      appBar: AppBar(title: Text('Tugas $className')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final items = controller.tugas.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;
        final now = DateTime.now();
        final aktif = items.where((item) => item.deadline.isAfter(now)).length;
        final lewat = items.length - aktif;

        return RefreshIndicator(
          onRefresh: controller.loadTugas,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (authService.role.value == 'admin')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Tugas',
                      subtitle: 'Atur tugas untuk $className.',
                      actionLabel: 'Buat Tugas',
                      onTap: () => showTugasForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _ClassHero(
                  title: 'Tugas $className',
                  subtitle: 'Pantau deadline dan status tugas.',
                  badge: '${items.length} tugas',
                  icon: Icons.assignment_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(label: 'Aktif', value: aktif.toString()),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Lewat', value: lewat.toString()),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Total', value: items.length.toString()),
                  ],
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
                              title: 'Belum ada tugas',
                              subtitle: 'Tugas akan tampil di sini.',
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
                                            isAdmin: isAdmin,
                                            onTap: () async {
                                              final result = await Get.to(
                                                () => TugasDetailView(
                                                  assignment: item,
                                                  className: className,
                                                ),
                                              );
                                              if (result == true) {
                                                await controller.loadTugas();
                                              }
                                            },
                                            onEdit: () => showTugasForm(
                                              context,
                                              controller,
                                              classesController,
                                              item: item,
                                              fixedClassId: classId,
                                              fixedClassName: className,
                                            ),
                                            onDelete: () => _confirmDelete(
                                              title: 'Hapus tugas ini?',
                                              successMessage:
                                                  'Tugas berhasil dihapus.',
                                              onConfirm: () =>
                                                  controller.deleteTugas(
                                                item.id,
                                              ),
                                            ),
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
  final AssignmentItem item;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ListCard({
    required this.item,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = DateFormat('dd MMM yyyy - HH:mm').format(item.deadline);
    final isExpired = item.deadline.isBefore(DateTime.now());
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
                              Text(item.instructions),
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
                        Wrap(
                          spacing: 8,
                          children: [
                            _InfoPill(label: 'Deadline', value: deadlineLabel),
                            if (isExpired)
                              const _InfoPill(
                                label: 'Status',
                                value: 'Lewat',
                              )
                            else
                              const _InfoPill(
                                label: 'Status',
                                value: 'Aktif',
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: onTap,
                              icon: Icon(
                                isAdmin
                                    ? Icons.fact_check_rounded
                                    : Icons.edit_note_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isAdmin ? 'Lihat Pengumpulan' : 'Jawab Tugas',
                              ),
                            ),
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
    )
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
                bucket: 'assignments',
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

class TugasDetailView extends StatefulWidget {
  final AssignmentItem assignment;
  final String className;

  const TugasDetailView({
    super.key,
    required this.assignment,
    required this.className,
  });

  @override
  State<TugasDetailView> createState() => _TugasDetailViewState();
}

class _TugasDetailViewState extends State<TugasDetailView> {
  final TugasController _controller = Get.find<TugasController>();
  final AuthService _authService = Get.find<AuthService>();
  final DataService _dataService = Get.find<DataService>();

  List<AssignmentSubmission> _submissions = [];
  List<StudentItem> _students = [];
  AssignmentSubmission? _mySubmission;
  bool _isLoading = true;
  bool _isUploading = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final submissions =
          await _controller.loadSubmissions(widget.assignment.id);
      final isAdmin = _authService.role.value == 'admin';
      AssignmentSubmission? mySubmission;
      if (!isAdmin) {
        mySubmission =
            await _controller.loadMySubmission(widget.assignment.id);
        _answerController.text = mySubmission?.content ?? '';
        _selectedFilePath = mySubmission?.filePath;
        _selectedFileName = _selectedFilePath == null
            ? null
            : _fileNameFromPath(_selectedFilePath!);
      }
      final students = isAdmin
          ? await _controller.loadClassStudents(widget.assignment.classId)
          : <StudentItem>[];
      setState(() {
        _submissions = submissions;
        _students = students;
        _mySubmission = mySubmission;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Dokumen',
          extensions: ['pdf', 'docx', 'zip'],
        ),
      ],
    );
    if (result == null) {
      return;
    }
    setState(() => _isUploading = true);
    try {
      setState(() {
        _selectedFileName = result.name;
        _selectedFilePath = null;
      });
      final path = await _controller.uploadSubmissionFile(result);
      if (path != null) {
        setState(() {
          _selectedFilePath = path;
        });
      } else {
        _showMessage(
          title: 'Gagal',
          message: 'Upload gagal. Coba lagi.',
        );
      }
    } catch (error) {
      _showMessage(
        title: 'Gagal',
        message: error.toString(),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    final content = _answerController.text.trim();
    final hasContent = content.isNotEmpty;
    final hasFile = _selectedFilePath != null && _selectedFilePath!.isNotEmpty;
    if (!hasContent && !hasFile) {
      _showMessage(
        title: 'Gagal',
        message: 'Isi jawaban atau unggah file.',
      );
      return;
    }
    final error = await _controller.submitAssignment(
      assignmentId: widget.assignment.id,
      deadline: widget.assignment.deadline,
      content: hasContent ? content : null,
      filePath: hasFile ? _selectedFilePath : null,
    );
    if (error != null) {
      _showMessage(
        title: 'Gagal',
        message: error,
      );
      return;
    }
    const snackDuration = Duration(seconds: 2);
    _showMessage(
      title: 'Berhasil',
      message: 'Jawaban berhasil dikirim.',
      duration: snackDuration,
    );
    await Future.delayed(snackDuration + const Duration(milliseconds: 100));
    if (mounted) {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      Get.back(result: true);
    }
  }

  void _showMessage({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.navy,
      colorText: Colors.white,
      duration: duration,
    );
  }

  String _fileNameFromPath(String path) {
    final parts = path.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.role.value == 'admin';
    final deadlineLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(widget.assignment.deadline);
    final now = DateTime.now();
    final isLate = now.isAfter(widget.assignment.deadline);
    final submittedOnTime =
        _submissions.where((s) => s.status == 'tepat_waktu').length;
    final submittedLate =
        _submissions.where((s) => s.status == 'terlambat').length;
    final submittedIds = _submissions.map((s) => s.userId).toSet();
    final missingStudents = _students
        .where((student) => !submittedIds.contains(student.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Tugas ${widget.className}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveCenter(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _ClassHero(
                      title: widget.assignment.title,
                      subtitle: widget.assignment.instructions,
                      badge: 'Deadline $deadlineLabel',
                      icon: Icons.assignment_rounded,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      leftLabel: 'Status',
                      leftValue: isLate ? 'Terlambat' : 'Aktif',
                      rightLabel: 'Kelas',
                      rightValue: widget.className,
                    ),
                    const SizedBox(height: 16),
                    if (isAdmin) ...[
                      _SectionTitle('Pengumpulan'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatChip(
                              label: 'Tepat Waktu',
                              value: submittedOnTime.toString()),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: 'Terlambat',
                              value: submittedLate.toString()),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: 'Belum',
                              value: missingStudents.length.toString()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('Sudah Mengumpulkan'),
                      const SizedBox(height: 8),
                      if (_submissions.isEmpty)
                        const _EmptyText('Belum ada pengumpulan.')
                      else
                        ..._submissions.map(
                          (item) => _SubmissionCard(
                            submission: item,
                            dataService: _dataService,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionTitle('Belum Mengumpulkan'),
                      const SizedBox(height: 8),
                      if (_students.isEmpty)
                        const _EmptyText(
                          'Data mahasiswa belum tersedia.',
                        )
                      else if (missingStudents.isEmpty)
                        const _EmptyText('Semua mahasiswa sudah mengumpulkan.')
                      else
                        ...missingStudents.map(
                          (student) => _MissingCard(student: student),
                        ),
                    ] else ...[
                      _SectionTitle('Jawaban Saya'),
                      const SizedBox(height: 8),
                      if (_mySubmission != null)
                        _MySubmissionCard(
                          submission: _mySubmission!,
                          dataService: _dataService,
                        )
                      else
                        const _EmptyText('Belum ada jawaban.'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Jawaban tugas',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedFileName ??
                                  (_selectedFilePath == null
                                      ? 'Belum ada file'
                                      : 'File tersimpan'),
                            ),
                          ),
                          TextButton(
                            onPressed: _isUploading ? null : _pickFile,
                            child: Text(_isUploading ? 'Upload...' : 'Upload'),
                          ),
                        ],
                      ),
                      if (_selectedFileName != null &&
                          _selectedFileName!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _SubmissionAttachmentPreview(
                            path: _selectedFilePath,
                            fileName: _selectedFileName!,
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: _controller.isSubmitting.value
                                ? null
                                : _submit,
                            child: _controller.isSubmitting.value
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _mySubmission == null
                                        ? 'Kirim Jawaban'
                                        : 'Perbarui Jawaban',
                                  ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _InfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InfoPill(label: leftLabel, value: leftValue)),
        const SizedBox(width: 8),
        Expanded(child: _InfoPill(label: rightLabel, value: rightValue)),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _SubmissionCard({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    final nimLabel = submission.studentNim?.isNotEmpty == true
        ? 'NIM: ${submission.studentNim}'
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission.studentName ?? 'Mahasiswa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (submission.studentEmail != null &&
                submission.studentEmail!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  submission.studentEmail!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            if (nimLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  nimLabel,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 8),
            _InfoPill(label: 'Dikirim', value: submittedLabel),
            const SizedBox(height: 8),
            _InfoPill(
              label: 'Status',
              value: submission.status == 'terlambat'
                  ? 'Terlambat'
                  : 'Tepat Waktu',
            ),
            if (submission.content != null &&
                submission.content!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(submission.content!),
            ],
            if (submission.filePath != null &&
                submission.filePath!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () async {
                    final url = dataService.getPublicUrl(
                      bucket: 'assignments',
                      path: submission.filePath!,
                    );
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Lihat lampiran'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MissingCard extends StatelessWidget {
  final StudentItem student;

  const _MissingCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hourglass_empty_rounded,
            color: AppColors.navy),
        title: Text(student.name),
        subtitle:
            student.email == null ? null : Text(student.email ?? ''),
        trailing: const Text('Belum'),
      ),
    );
  }
}

class _MySubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _MySubmissionCard({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoPill(label: 'Dikirim', value: submittedLabel),
            const SizedBox(height: 8),
            _InfoPill(
              label: 'Status',
              value: submission.status == 'terlambat'
                  ? 'Terlambat'
                  : 'Tepat Waktu',
            ),
            if (submission.filePath != null &&
                submission.filePath!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () async {
                    final url = dataService.getPublicUrl(
                      bucket: 'assignments',
                      path: submission.filePath!,
                    );
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Lihat lampiran'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionAttachmentPreview extends StatelessWidget {
  final String? path;
  final String fileName;

  const _SubmissionAttachmentPreview({
    required this.path,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Get.find<DataService>();
    final hasRemotePath = path != null && path!.trim().isNotEmpty;
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
                  'Lampiran dipilih',
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
            onPressed: hasRemotePath
                ? () async {
                    final url = dataService.getPublicUrl(
                      bucket: 'assignments',
                      path: path!,
                    );
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                : null,
            child: Text(hasRemotePath ? 'Lihat' : 'Upload dulu'),
          ),
        ],
      ),
    );
  }
}

class _MyHistoryCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _MyHistoryCard({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission.assignmentTitle ?? 'Tugas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            _InfoPill(label: 'Dikirim', value: submittedLabel),
            const SizedBox(height: 6),
            _InfoPill(
              label: 'Status',
              value:
                  submission.status == 'terlambat' ? 'Terlambat' : 'Tepat Waktu',
            ),
            if (submission.filePath != null &&
                submission.filePath!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () async {
                    final url = dataService.getPublicUrl(
                      bucket: 'assignments',
                      path: submission.filePath!,
                    );
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Lihat lampiran'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
