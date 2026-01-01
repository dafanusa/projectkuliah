import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/result_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
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
      final totalTerkumpul =
          items.fold<int>(0, (sum, item) => sum + item.collected);
      final totalBelum =
          items.fold<int>(0, (sum, item) => sum + item.missing);
      final totalDinilai =
          items.fold<int>(0, (sum, item) => sum + item.graded);

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Obx(() {
            if (authService.role.value != 'admin') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AdminPanel(
                title: 'Kelola Penilaian',
                subtitle: 'Input nilai dan finalisasi hasil tugas.',
                actionLabel: 'Tambah Hasil',
                onTap: () => _openHasilForm(
                  context,
                  controller,
                  classesController,
                ),
              ),
            );
          }),
          _PageHeader(
            title: 'Hasil Tugas',
            subtitle: 'Ringkasan status pengumpulan dan penilaian.',
            stats: [
              _HeaderStat(label: 'Terkumpul', value: totalTerkumpul.toString()),
              _HeaderStat(label: 'Belum', value: totalBelum.toString()),
              _HeaderStat(label: 'Dinilai', value: totalDinilai.toString()),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyState(
              title: 'Belum ada hasil tugas',
              subtitle: 'Admin bisa menambahkan rekap hasil tugas.',
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResultCard(
                  item: item,
                  isAdmin: authService.role.value == 'admin',
                  onEdit: () => _openHasilForm(
                    context,
                    controller,
                    classesController,
                    item: item,
                  ),
                  onDelete: () => controller.deleteResult(item.id),
                ),
              ),
            ),
        ],
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

Future<void> _openHasilForm(
  BuildContext context,
  HasilController controller,
  ClassesController classesController, {
  ResultItem? item,
}) async {
  final collectedController =
      TextEditingController(text: item?.collected.toString() ?? '');
  final missingController =
      TextEditingController(text: item?.missing.toString() ?? '');
  final gradedController =
      TextEditingController(text: item?.graded.toString() ?? '');
  String? selectedClassId = item?.classId;
  String? selectedAssignmentId = item?.assignmentId;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        final assignments = controller.assignments.toList();
        return AlertDialog(
          title: Text(item == null ? 'Tambah Hasil' : 'Ubah Hasil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedAssignmentId,
                  decoration: const InputDecoration(labelText: 'Tugas'),
                  items: assignments
                      .map(
                        (assignment) => DropdownMenuItem(
                          value: assignment.id,
                          child: Text(assignment.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedAssignmentId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedClassId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: collectedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Terkumpul'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: missingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Belum'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gradedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dinilai'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedAssignmentId == null) {
                  Get.snackbar('Gagal', 'Tugas wajib dipilih.');
                  return;
                }
                final collected = int.tryParse(collectedController.text) ?? 0;
                final missing = int.tryParse(missingController.text) ?? 0;
                final graded = int.tryParse(gradedController.text) ?? 0;
                if (item == null) {
                  await controller.addResult(
                    assignmentId: selectedAssignmentId!,
                    classId: selectedClassId,
                    collected: collected,
                    missing: missing,
                    graded: graded,
                  );
                } else {
                  await controller.updateResult(
                    id: item.id,
                    assignmentId: selectedAssignmentId!,
                    classId: selectedClassId,
                    collected: collected,
                    missing: missing,
                    graded: graded,
                  );
                }
                Get.back();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );
}
