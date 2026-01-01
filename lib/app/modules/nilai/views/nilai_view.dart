import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/grade_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
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
      final average = items.isEmpty
          ? 0
          : (items.fold<int>(0, (sum, item) => sum + item.score) /
                  items.length)
              .round();

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
                title: 'Kelola Nilai',
                subtitle: 'Tambah atau koreksi nilai mahasiswa.',
                actionLabel: 'Tambah Nilai',
                onTap: () => _openNilaiForm(
                  context,
                  controller,
                  classesController,
                ),
              ),
            );
          }),
          _PageHeader(
            title: 'Nilai Mahasiswa',
            subtitle: 'Pantau performa kelas secara cepat.',
            stats: [
              _HeaderStat(label: 'Rata-rata', value: average.toString()),
              _HeaderStat(label: 'Jumlah', value: items.length.toString()),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyState(
              title: 'Belum ada nilai',
              subtitle: 'Admin bisa menambahkan nilai dari panel atas.',
            )
          else
            Card(
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
                            DataCell(Text(item.assignmentTitle ?? '-')),
                            DataCell(Text(item.score.toString())),
                            DataCell(
                              authService.role.value == 'admin'
                                  ? Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _openNilaiForm(
                                            context,
                                            controller,
                                            classesController,
                                            item: item,
                                          ),
                                          icon: const Icon(Icons.edit_rounded),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              controller.deleteGrade(item.id),
                                          icon: const Icon(Icons.delete_rounded,
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

Future<void> _openNilaiForm(
  BuildContext context,
  NilaiController controller,
  ClassesController classesController, {
  GradeItem? item,
}) async {
  final nameController = TextEditingController(text: item?.studentName ?? '');
  final scoreController =
      TextEditingController(text: item?.score.toString() ?? '');
  String? selectedClassId = item?.classId;
  String? selectedAssignmentId = item?.assignmentId;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        final assignments = controller.assignments.toList();
        return AlertDialog(
          title: Text(item == null ? 'Tambah Nilai' : 'Ubah Nilai'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Mahasiswa'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nilai'),
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
                DropdownButtonFormField<String?>(
                  value: selectedAssignmentId,
                  decoration: const InputDecoration(labelText: 'Tugas (opsional)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tanpa tugas'),
                    ),
                    ...assignments.map(
                      (assignment) => DropdownMenuItem<String?>(
                        value: assignment.id,
                        child: Text(assignment.title),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedAssignmentId = value),
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
                final name = nameController.text.trim();
                final score = int.tryParse(scoreController.text) ?? 0;
                if (name.isEmpty) {
                  Get.snackbar('Gagal', 'Nama mahasiswa wajib diisi.');
                  return;
                }
                if (item == null) {
                  await controller.addGrade(
                    studentName: name,
                    score: score,
                    classId: selectedClassId,
                    assignmentId: selectedAssignmentId,
                  );
                } else {
                  await controller.updateGrade(
                    id: item.id,
                    studentName: name,
                    score: score,
                    classId: selectedClassId,
                    assignmentId: selectedAssignmentId,
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
