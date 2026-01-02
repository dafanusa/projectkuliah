import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/assignment_item.dart';
import '../models/grade_item.dart';
import '../models/material_item.dart';
import '../models/lecturer_work_item.dart';
import '../modules/classes/controllers/classes_controller.dart';
import '../modules/materi/controllers/materi_controller.dart';
import '../modules/karya/controllers/karya_controller.dart';
import '../modules/nilai/controllers/nilai_controller.dart';
import '../modules/tugas/controllers/tugas_controller.dart';
import '../theme/app_colors.dart';

Future<void> showMateriForm(
  BuildContext context,
  MateriController controller,
  ClassesController classesController, {
  MaterialItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final titleController = TextEditingController(text: item?.title ?? '');
  final descController = TextEditingController(text: item?.description ?? '');
  final meetingController = TextEditingController(text: item?.meeting ?? '');
  DateTime? selectedDate = item?.date;
  final isClassFixed = fixedClassId != null || fixedClassName != null;
  String? selectedClassId = fixedClassId ?? item?.classId;
  String? selectedFilePath = item?.filePath;
  String? selectedFileName;
  bool isUploading = false;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        String fixedName = fixedClassName ?? 'Tanpa Kelas';
        if (fixedClassName == null && fixedClassId != null) {
          for (final c in classes) {
            if (c.id == fixedClassId) {
              fixedName = c.name;
              break;
            }
          }
        }
        return AlertDialog(
          title: Text(item == null ? 'Tambah Materi' : 'Ubah Materi'),
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
                  controller: meetingController,
                  decoration: const InputDecoration(labelText: 'Pertemuan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 12),
                if (isClassFixed)
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: fixedName),
                    decoration: const InputDecoration(labelText: 'Kelas'),
                  )
                else
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
                        selectedDate == null
                            ? 'Tanggal belum dipilih'
                            : DateFormat('dd MMM yyyy').format(selectedDate!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: const Text('Pilih Tanggal'),
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
                                    await controller.uploadMateriFile(result);
                                if (path != null) {
                                  setState(() {
                                    selectedFilePath = path;
                                    selectedFileName = result.name;
                                  });
                                }
                              } catch (error) {
                                Get.snackbar(
                                  'Upload gagal',
                                  error.toString(),
                                  backgroundColor: AppColors.navy,
                                  colorText: Colors.white,
                                );
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
                final meeting = meetingController.text.trim();
                if (title.isEmpty || meeting.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Judul dan pertemuan wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                if (item == null) {
                  await controller.addMateri(
                    title: title,
                    description: descController.text.trim(),
                    meeting: meeting,
                    date: selectedDate,
                    classId: selectedClassId,
                    filePath: selectedFilePath,
                  );
                } else {
                  await controller.updateMateri(
                    id: item.id,
                    title: title,
                    description: descController.text.trim(),
                    meeting: meeting,
                    date: selectedDate,
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

Future<void> showTugasForm(
  BuildContext context,
  TugasController controller,
  ClassesController classesController, {
  AssignmentItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final titleController = TextEditingController(text: item?.title ?? '');
  final instructionController =
      TextEditingController(text: item?.instructions ?? '');
  DateTime? deadline = item?.deadline;
  final isClassFixed = fixedClassId != null || fixedClassName != null;
  String? selectedClassId = fixedClassId ?? item?.classId;
  String? selectedFilePath = item?.filePath;
  String? selectedFileName;
  bool isUploading = false;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        String fixedName = fixedClassName ?? 'Tanpa Kelas';
        if (fixedClassName == null && fixedClassId != null) {
          for (final c in classes) {
            if (c.id == fixedClassId) {
              fixedName = c.name;
              break;
            }
          }
        }
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
                if (isClassFixed)
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: fixedName),
                    decoration: const InputDecoration(labelText: 'Kelas'),
                  )
                else
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
                            : DateFormat('dd MMM yyyy - HH:mm')
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
                          initialTime:
                              TimeOfDay.fromDateTime(deadline ?? DateTime.now()),
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
                                Get.snackbar(
                                  'Upload gagal',
                                  error.toString(),
                                  backgroundColor: AppColors.navy,
                                  colorText: Colors.white,
                                );
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
                    'Gagal',
                    'Judul, perintah, dan deadline wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
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

Future<void> showKaryaForm(
  BuildContext context,
  KaryaController controller, {
  LecturerWorkItem? item,
}) async {
  final titleController = TextEditingController(text: item?.title ?? '');
  final descController = TextEditingController(text: item?.description ?? '');
  DateTime? selectedDate = item?.date;
  String selectedCategory = item?.category ?? 'Penelitian';
  String? selectedFilePath = item?.filePath;
  String? selectedFileName;
  bool isUploading = false;
  const categories = ['Penelitian', 'Buku', 'Publikasi', 'Lainnya'];

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(item == null ? 'Tambah Karya' : 'Ubah Karya'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Karya'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    selectedCategory = value ?? 'Penelitian';
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Tanggal belum dipilih'
                            : DateFormat('dd MMM yyyy').format(selectedDate!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                      child: const Text('Pilih Tanggal'),
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
                                    await controller.uploadKaryaFile(result);
                                if (path != null) {
                                  setState(() {
                                    selectedFilePath = path;
                                    selectedFileName = result.name;
                                  });
                                }
                              } catch (error) {
                                Get.snackbar(
                                  'Upload gagal',
                                  error.toString(),
                                  backgroundColor: AppColors.navy,
                                  colorText: Colors.white,
                                );
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
                final description = descController.text.trim();
                if (title.isEmpty || description.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Judul dan deskripsi wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                if (item == null) {
                  await controller.addKarya(
                    title: title,
                    description: description,
                    category: selectedCategory,
                    date: selectedDate,
                    filePath: selectedFilePath,
                  );
                } else {
                  await controller.updateKarya(
                    id: item.id,
                    title: title,
                    description: description,
                    category: selectedCategory,
                    date: selectedDate,
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

Future<void> showNilaiForm(
  BuildContext context,
  NilaiController controller,
  ClassesController classesController, {
  GradeItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final nameController = TextEditingController(text: item?.studentName ?? '');
  final scoreController =
      TextEditingController(text: item?.score.toString() ?? '');
  final isClassFixed = fixedClassId != null || fixedClassName != null;
  String? selectedClassId = fixedClassId ?? item?.classId;
  String? selectedAssignmentId = item?.assignmentId;

  await Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        final classes = classesController.classes.toList();
        String fixedName = fixedClassName ?? 'Tanpa Kelas';
        if (fixedClassName == null && fixedClassId != null) {
          for (final c in classes) {
            if (c.id == fixedClassId) {
              fixedName = c.name;
              break;
            }
          }
        }
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
                if (isClassFixed)
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: fixedName),
                    decoration: const InputDecoration(labelText: 'Kelas'),
                  )
                else
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
                  decoration:
                      const InputDecoration(labelText: 'Tugas (opsional)'),
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
                  Get.snackbar(
                    'Gagal',
                    'Nama mahasiswa wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
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
