import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/result_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/hasil_controller.dart';

class HasilView extends GetView<HasilController> {
  const HasilView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.hasil.toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final totalTerkumpul =
          items.fold<int>(0, (sum, item) => sum + item.collected);
      final totalBelum = items.fold<int>(0, (sum, item) => sum + item.missing);
      final totalDinilai = items.fold<int>(0, (sum, item) => sum + item.graded);
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
                      title: 'Kelola Penilaian',
                      subtitle: 'Input nilai dan finalisasi hasil tugas.',
                      actionLabel: 'Tambah Hasil',
                      onTap: () => showHasilForm(
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
                  title: 'Hasil Tugas',
                  subtitle: 'Ringkasan status pengumpulan dan penilaian.',
                  stats: [
                    _HeaderStat(
                      label: 'Terkumpul',
                      value: totalTerkumpul.toString(),
                    ),
                    _HeaderStat(label: 'Belum', value: totalBelum.toString()),
                    _HeaderStat(
                      label: 'Dinilai',
                      value: totalDinilai.toString(),
                    ),
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
                            title: 'Belum ada hasil tugas',
                            subtitle: 'Admin bisa menambahkan rekap hasil tugas.',
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
                                        subtitle: '$count hasil',
                                        icon: Icons.fact_check_rounded,
                                        onTap: () => Get.to(
                                          () => HasilClassView(
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
                                            '${countByClassId[''] ?? 0} hasil',
                                        icon: Icons.folder_off_rounded,
                                        onTap: () => Get.to(
                                          () => const HasilClassView(
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
              child: const Icon(Icons.fact_check_rounded, color: AppColors.navy),
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

class HasilClassView extends GetView<HasilController> {
  final String? classId;
  final String className;

  const HasilClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Hasil $className')),
      body: Obx(() {
        final items = controller.hasil.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;
        final totalTerkumpul =
            items.fold<int>(0, (sum, item) => sum + item.collected);
        final totalBelum = items.fold<int>(0, (sum, item) => sum + item.missing);
        final totalDinilai = items.fold<int>(0, (sum, item) => sum + item.graded);

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
                      title: 'Kelola Penilaian',
                      subtitle: 'Atur hasil untuk $className.',
                      actionLabel: 'Tambah Hasil',
                      onTap: () => showHasilForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _PageHeader(
                  title: 'Hasil $className',
                  subtitle: 'Ringkasan status pengumpulan dan penilaian.',
                  stats: [
                    _HeaderStat(
                      label: 'Terkumpul',
                      value: totalTerkumpul.toString(),
                    ),
                    _HeaderStat(label: 'Belum', value: totalBelum.toString()),
                    _HeaderStat(
                      label: 'Dinilai',
                      value: totalDinilai.toString(),
                    ),
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
                              title: 'Belum ada hasil tugas',
                              subtitle: 'Data akan tampil di sini.',
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
                                          child: _ResultCard(
                                            item: item,
                                            isAdmin:
                                                authService.role.value == 'admin',
                                            onEdit: () => showHasilForm(
                                              context,
                                              controller,
                                              classesController,
                                              item: item,
                                              fixedClassId: classId,
                                              fixedClassName: className,
                                            ),
                                            onDelete: () =>
                                                controller.deleteResult(item.id),
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

class _ResultCard extends StatelessWidget {
  final ResultItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ResultCard({
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
                        item.assignmentTitle ?? 'Tugas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Kelas: ${item.className ?? '-'}'),
                    ],
                  ),
                ),
                if (isAdmin)
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _InfoChip(label: 'Terkumpul', value: '${item.collected}'),
                _InfoChip(label: 'Belum', value: '${item.missing}'),
                _InfoChip(label: 'Dinilai', value: '${item.graded}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

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
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
