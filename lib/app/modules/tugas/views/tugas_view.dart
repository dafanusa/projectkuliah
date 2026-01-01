import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/assignment_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/tugas_controller.dart';

class TugasView extends GetView<TugasController> {
  const TugasView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.tugas.toList();
      final now = DateTime.now();
      final aktif = items.where((item) => item.deadline.isAfter(now)).length;
      final lewat = items.length - aktif;

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
                title: 'Kelola Tugas',
                subtitle: 'Buat tugas baru dan atur deadline.',
                actionLabel: 'Buat Tugas',
                onTap: () => _openTugasForm(
                  context,
                  controller,
                  classesController,
                ),
              ),
            );
          }),
          _PageHeader(
            title: 'Tugas Mahasiswa',
            subtitle: 'Pantau deadline dan status tugas.',
            stats: [
              _HeaderStat(label: 'Aktif', value: aktif.toString()),
              _HeaderStat(label: 'Lewat', value: lewat.toString()),
              _HeaderStat(label: 'Total', value: items.length.toString()),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyState(
              title: 'Belum ada tugas',
              subtitle: 'Admin bisa menambahkan tugas baru.',
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ListCard(
                  item: item,
                  isAdmin: authService.role.value == 'admin',
                  onEdit: () => _openTugasForm(
                    context,
                    controller,
                    classesController,
                    item: item,
                  ),
                  onDelete: () => controller.deleteTugas(item.id),
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

class _ListCard extends StatelessWidget {
  final AssignmentItem item;
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
    final deadlineLabel = DateFormat('dd MMM yyyy • HH:mm').format(item.deadline);
    final isExpired = item.deadline.isBefore(DateTime.now());
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
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(item.instructions),
                      const SizedBox(height: 6),
                      Text(
                        'Kelas: ${item.className ?? '-'}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
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
                _InfoPill(label: 'Deadline', value: deadlineLabel),
                if (isExpired)
                  const _InfoPill(
                    label: 'Status',
                    value: 'Lewat',
                  ),
                if (item.filePath != null && item.filePath!.isNotEmpty)
                  _FilePill(path: item.filePath!),
              ],
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

class _FilePill extends StatelessWidget {
  final String path;

  const _FilePill({required this.path});

  @override
  Widget build(BuildContext context) {
    final dataService = Get.find<DataService>();
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFE8ECF5),
        foregroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      onPressed: () async {
        final url = dataService.getPublicUrl(
          bucket: 'assignments',
          path: path,
        );
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.attach_file_rounded, size: 16),
      label: const Text('File'),
    );
  }
}

Future<void> _openTugasForm(
  BuildContext context,
  TugasController controller,
  ClassesController classesController, {
  AssignmentItem? item,
}) async {
  final titleController = TextEditingController(text: item?.title ?? '');
  final instructionController =
      TextEditingController(text: item?.instructions ?? '');
  DateTime? deadline = item?.deadline;
  String? selectedClassId = item?.classId;
  String? selectedFilePath = item?.filePath;
  String? selectedFileName;
  bool isUploading = false;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        return AlertDialog(
          title: Text(item == null ? 'Tambah Tugas' : 'Ubah Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionController,
                  decoration: const InputDecoration(labelText: 'Perintah Tugas'),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deadline == null
                            ? 'Deadline belum dipilih'
                            : DateFormat('dd MMM yyyy • HH:mm')
                                .format(deadline!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (date == null) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              deadline ?? DateTime.now()),
                        );
                        if (time == null) {
                          return;
                        }
                        setState(() {
                          deadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: const Text('Pilih Deadline'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedFileName ??
                            (selectedFilePath == null
                                ? 'Belum ada file'
                                : 'File tersimpan'),
                      ),
                    ),
                    TextButton(
                      onPressed: isUploading
                          ? null
                          : () async {
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
                              setState(() => isUploading = true);
                              try {
                                final path =
                                    await controller.uploadTugasFile(result);
                                if (path != null) {
                                  setState(() {
                                    selectedFilePath = path;
                                    selectedFileName = result.name;
                                  });
                                }
                              } catch (error) {
                                Get.snackbar('Upload gagal', error.toString());
                              } finally {
                                setState(() => isUploading = false);
                              }
                            },
                      child: Text(isUploading ? 'Upload...' : 'Upload File'),
                    ),
                  ],
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
                final title = titleController.text.trim();
                final instructions = instructionController.text.trim();
                if (title.isEmpty || instructions.isEmpty || deadline == null) {
                  Get.snackbar(
                      'Gagal', 'Judul, perintah, dan deadline wajib diisi.');
                  return;
                }
                if (item == null) {
                  await controller.addTugas(
                    title: title,
                    instructions: instructions,
                    deadline: deadline!,
                    classId: selectedClassId,
                    filePath: selectedFilePath,
                  );
                } else {
                  await controller.updateTugas(
                    id: item.id,
                    title: title,
                    instructions: instructions,
                    deadline: deadline!,
                    classId: selectedClassId,
                    filePath: selectedFilePath,
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
