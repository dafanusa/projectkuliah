import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/grade_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/nilai_controller.dart';

class NilaiView extends GetView<NilaiController> {
  const NilaiView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.nilai.toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final average = items.isEmpty
          ? 0
          : (items.fold<int>(0, (sum, item) => sum + item.score) /
                  items.length)
              .round();
      final hasUnassigned =
          items.any((item) => item.classId == null || item.classId!.isEmpty);
      final countByClassId = <String, int>{};
      for (final item in items) {
        final classId = item.classId ?? '';
        countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
      }

      return RefreshIndicator(
        onRefresh: controller.loadAll,
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
                      title: 'Kelola Nilai',
                      subtitle: 'Tambah atau koreksi nilai mahasiswa.',
                      actionLabel: 'Tambah Nilai',
                      onTap: () => showNilaiForm(
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
                  title: 'Nilai Mahasiswa',
                  subtitle: 'Pantau performa kelas secara cepat.',
                  stats: [
                    _HeaderStat(label: 'Rata-rata', value: average.toString()),
                    _HeaderStat(label: 'Jumlah', value: items.length.toString()),
                  ],
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
                            title: 'Belum ada nilai',
                            subtitle: 'Admin bisa menambahkan nilai dari panel atas.',
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
                                        subtitle: '$count nilai',
                                        icon: Icons.score_rounded,
                                        onTap: () => Get.to(
                                          () => NilaiClassView(
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
                                            '${countByClassId[''] ?? 0} nilai',
                                        icon: Icons.folder_off_rounded,
                                        onTap: () => Get.to(
                                          () => const NilaiClassView(
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
              child: const Icon(Icons.score_rounded, color: AppColors.navy),
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

class NilaiClassView extends GetView<NilaiController> {
  final String? classId;
  final String className;

  const NilaiClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Nilai $className')),
      body: Obx(() {
        final items = controller.nilai.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;
        final average = items.isEmpty
            ? 0
            : (items.fold<int>(0, (sum, item) => sum + item.score) /
                    items.length)
                .round();

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (authService.role.value == 'admin')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Nilai',
                      subtitle: 'Atur nilai untuk $className.',
                      actionLabel: 'Tambah Nilai',
                      onTap: () => showNilaiForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _PageHeader(
                  title: 'Nilai $className',
                  subtitle: 'Pantau performa kelas secara cepat.',
                  stats: [
                    _HeaderStat(label: 'Rata-rata', value: average.toString()),
                    _HeaderStat(label: 'Jumlah', value: items.length.toString()),
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
                              title: 'Belum ada nilai',
                              subtitle: 'Nilai akan tampil di sini.',
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final useCards = constraints.maxWidth < 720;
                                if (useCards) {
                                  return Column(
                                    children: items
                                        .map(
                                          (item) => Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 12),
                                            child: _NilaiCard(
                                              item: item,
                                              isAdmin:
                                                  authService.role.value == 'admin',
                                              onEdit: () => showNilaiForm(
                                                context,
                                                controller,
                                                classesController,
                                                item: item,
                                                fixedClassId: classId,
                                                fixedClassName: className,
                                              ),
                                              onDelete: () =>
                                                  controller.deleteGrade(item.id),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                }
                                return Card(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: MaterialStateProperty.all(
                                        const Color(0xFFE8ECF5),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Mahasiswa')),
                                        DataColumn(label: Text('Kelas')),
                                        DataColumn(label: Text('Tugas')),
                                        DataColumn(label: Text('Nilai')),
                                        DataColumn(label: Text('Aksi')),
                                      ],
                                      rows: items
                                          .map(
                                            (item) => DataRow(
                                              cells: [
                                                DataCell(Text(item.studentName)),
                                                DataCell(Text(item.className ?? '-')),
                                                DataCell(
                                                    Text(item.assignmentTitle ?? '-')),
                                                DataCell(Text(item.score.toString())),
                                                DataCell(
                                                  authService.role.value == 'admin'
                                                      ? Row(
                                                          children: [
                                                            IconButton(
                                                              onPressed: () =>
                                                                  showNilaiForm(
                                                                context,
                                                                controller,
                                                                classesController,
                                                                item: item,
                                                              ),
                                                              icon: const Icon(
                                                                  Icons.edit_rounded),
                                                            ),
                                                            IconButton(
                                                              onPressed: () =>
                                                                  controller.deleteGrade(
                                                                item.id,
                                                              ),
                                                              icon: const Icon(
                                                                  Icons.delete_rounded,
                                                                  color: Colors.red),
                                                            ),
                                                          ],
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
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

class _NilaiCard extends StatelessWidget {
  final GradeItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NilaiCard({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                        item.studentName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Kelas: ${item.className ?? '-'}'),
                      const SizedBox(height: 4),
                      Text('Tugas: ${item.assignmentTitle ?? '-'}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.score.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Ubah'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
