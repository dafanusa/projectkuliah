import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/assignment_item.dart';
import '../models/assignment_submission.dart';
import '../models/exam_item.dart';
import '../models/exam_grade_item.dart';
import '../models/exam_submission_item.dart';
import '../models/grade_item.dart';
import '../models/material_item.dart';
import '../models/lecturer_work_item.dart';
import '../modules/classes/controllers/classes_controller.dart';
import '../modules/materi/controllers/materi_controller.dart';
import '../modules/karya/controllers/karya_controller.dart';
import '../modules/ujian/controllers/ujian_controller.dart';
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
                    isExpanded: true,
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
                try {
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
                  Future.microtask(() {
                    Get.snackbar(
                      'Berhasil',
                      item == null
                          ? 'Materi berhasil ditambahkan.'
                          : 'Materi berhasil diperbarui.',
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
                try {
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
                  Future.microtask(() {
                    Get.snackbar(
                      'Berhasil',
                      item == null
                          ? 'Tugas berhasil ditambahkan.'
                          : 'Tugas berhasil diperbarui.',
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
        );
      },
    ),
  );
}

Future<void> showUjianForm(
  BuildContext context,
  UjianController controller,
  ClassesController classesController, {
  ExamItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final titleController = TextEditingController(text: item?.title ?? '');
  final descController = TextEditingController(text: item?.description ?? '');
  DateTime? startAt = item?.startAt;
  DateTime? endAt = item?.endAt;
  final durationController = TextEditingController(
    text: item?.durationMinutes.toString() ?? '60',
  );
  final attemptsController = TextEditingController(
    text: item?.maxAttempts.toString() ?? '1',
  );
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
          title: Text(item == null ? 'Tambah Ujian' : 'Ubah Ujian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Ujian'),
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
                        startAt == null
                            ? 'Mulai belum dipilih'
                            : DateFormat('dd MMM yyyy - HH:mm').format(startAt!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startAt ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (date == null) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(startAt ?? DateTime.now()),
                        );
                        if (time == null) {
                          return;
                        }
                        setState(() {
                          startAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: const Text('Pilih Mulai'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endAt == null
                            ? 'Selesai belum dipilih'
                            : DateFormat('dd MMM yyyy - HH:mm').format(endAt!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endAt ?? startAt ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (date == null) {
                          return;
                        }
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(endAt ?? DateTime.now()),
                        );
                        if (time == null) {
                          return;
                        }
                        setState(() {
                          endAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: const Text('Pilih Selesai'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Durasi (menit)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: attemptsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Maks. percobaan'),
                      ),
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
                                    await controller.uploadUjianFile(result);
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
                final duration =
                    int.tryParse(durationController.text.trim()) ?? 0;
                final attempts =
                    int.tryParse(attemptsController.text.trim()) ?? 1;
                if (title.isEmpty ||
                    description.isEmpty ||
                    startAt == null ||
                    endAt == null ||
                    duration <= 0 ||
                    attempts <= 0) {
                  Get.snackbar(
                    'Gagal',
                    'Judul, deskripsi, waktu, durasi, dan percobaan wajib diisi.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                if (endAt!.isBefore(startAt!)) {
                  Get.snackbar(
                    'Gagal',
                    'Waktu selesai harus setelah waktu mulai.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  if (item == null) {
                    await controller.addUjian(
                      title: title,
                      description: description,
                      startAt: startAt!,
                      endAt: endAt!,
                      durationMinutes: duration,
                      maxAttempts: attempts,
                      classId: selectedClassId,
                      filePath: selectedFilePath,
                    );
                  } else {
                    await controller.updateUjian(
                      id: item.id,
                      title: title,
                      description: description,
                      startAt: startAt!,
                      endAt: endAt!,
                      durationMinutes: duration,
                      maxAttempts: attempts,
                      classId: selectedClassId,
                      filePath: selectedFilePath,
                    );
                  }
                  Get.back();
                  Future.microtask(() {
                    Get.snackbar(
                      'Berhasil',
                      item == null
                          ? 'Ujian berhasil ditambahkan.'
                          : 'Ujian berhasil diperbarui.',
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
  const categories = ['Penelitian', 'PKM', 'Buku', 'Publikasi', 'Sertifikat', 'HAKI', 'Lainnya'];

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
                Future.microtask(() {
                  Get.snackbar(
                    'Berhasil',
                    item == null
                        ? 'Karya berhasil ditambahkan.'
                        : 'Karya berhasil diperbarui.',
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

Future<void> showNilaiForm(
  BuildContext context,
  NilaiController controller,
  ClassesController classesController, {
  GradeItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final scoreController =
      TextEditingController(text: item?.score.toString() ?? '');
  final isClassFixed = fixedClassId != null || fixedClassName != null;
  String? selectedClassId = fixedClassId ?? item?.classId;
  String? selectedAssignmentId = item?.assignmentId;
  String? selectedStudentName = item?.studentName;
  var submissions = <AssignmentSubmission>[];
  var isLoadingStudents = false;
  var didInit = false;

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
        final assignments = controller.assignments
            .where((assignment) {
              if (selectedClassId == null || selectedClassId!.isEmpty) {
                return true;
              }
              return assignment.classId == selectedClassId;
            })
            .toList();
        Future<void> loadStudents(String? assignmentId) async {
          if (assignmentId == null || assignmentId.isEmpty) {
            setState(() => submissions = []);
            return;
          }
          setState(() => isLoadingStudents = true);
          try {
            AssignmentItem? assignment;
            for (final item in assignments) {
              if (item.id == assignmentId) {
                assignment = item;
                break;
              }
            }
            submissions = await controller.loadSubmissionStudents(
              assignmentId,
              assignmentTitle: assignment?.title,
              classId: assignment?.classId,
            );
            setState(() {});
          } finally {
            setState(() => isLoadingStudents = false);
          }
        }
        if (!didInit) {
          didInit = true;
          if (selectedAssignmentId != null && selectedAssignmentId!.isNotEmpty) {
            Future.microtask(() => loadStudents(selectedAssignmentId));
          }
        }
        return AlertDialog(
          title: Text(item == null ? 'Tambah Nilai' : 'Ubah Nilai'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    onChanged: (value) {
                      setState(() {
                        selectedClassId = value;
                        selectedAssignmentId = null;
                        selectedStudentName = null;
                        submissions = [];
                      });
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedAssignmentId,
                  isExpanded: true,
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
                  onChanged: (value) async {
                    setState(() {
                      selectedAssignmentId = value;
                      selectedStudentName = null;
                      submissions = [];
                    });
                    if (value != null) {
                      AssignmentItem? assignment;
                      for (final item in assignments) {
                        if (item.id == value) {
                          assignment = item;
                          break;
                        }
                      }
                      if (!isClassFixed && assignment != null) {
                        setState(() => selectedClassId = assignment?.classId);
                      }
                    }
                    await loadStudents(value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStudentName,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mahasiswa (sudah mengumpulkan)',
                  ),
                  items: [
                    ...submissions.map(
                      (submission) {
                        final name = submission.studentName ?? 'Mahasiswa';
                        final nim = submission.studentNim;
                        final label =
                            nim == null || nim.isEmpty ? name : '$name ($nim)';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(label),
                        );
                      },
                    ),
                    if (selectedStudentName != null &&
                        selectedStudentName!.isNotEmpty &&
                        submissions
                            .where((item) => item.studentName == selectedStudentName)
                            .isEmpty)
                      DropdownMenuItem<String>(
                        value: selectedStudentName,
                        child: Text(selectedStudentName!),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedStudentName = value),
                ),
                if (isLoadingStudents)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Memuat daftar mahasiswa...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                if (!isLoadingStudents &&
                    submissions.isEmpty &&
                    selectedAssignmentId != null &&
                    selectedAssignmentId!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Belum ada mahasiswa yang mengumpulkan.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
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
                final name = selectedStudentName?.trim() ?? '';
                final score = int.tryParse(scoreController.text) ?? 0;
                if (name.isEmpty) {
                  Get.snackbar(
                    'Gagal',
                    'Pilih mahasiswa yang sudah mengumpulkan.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
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
                  Future.microtask(() {
                    Get.snackbar(
                      'Berhasil',
                      item == null
                          ? 'Nilai berhasil ditambahkan.'
                          : 'Nilai berhasil diperbarui.',
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
        );
      },
    ),
  );
}

Future<void> showNilaiUjianForm(
  BuildContext context,
  NilaiController controller,
  ClassesController classesController, {
  ExamGradeItem? item,
  String? fixedClassId,
  String? fixedClassName,
}) async {
  final scoreController =
      TextEditingController(text: item?.score.toString() ?? '');
  String? selectedStudentId = item?.studentId;
  String? selectedStudentName = item?.studentName;
  final isClassFixed = fixedClassId != null || fixedClassName != null;
  String? selectedClassId = fixedClassId ?? item?.classId;
  String? selectedExamId = item?.examId;
  var submissions = <ExamSubmissionItem>[];
  var isLoadingStudents = false;
  var didInit = false;

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
        final exams = controller.exams.where((exam) {
          if (selectedClassId == null || selectedClassId!.isEmpty) {
            return true;
          }
          return exam.classId == selectedClassId;
        }).toList();
        Future<void> loadStudents(String? examId) async {
          if (examId == null || examId.isEmpty) {
            setState(() => submissions = []);
            return;
          }
          setState(() => isLoadingStudents = true);
          try {
            ExamItem? exam;
            for (final item in exams) {
              if (item.id == examId) {
                exam = item;
                break;
              }
            }
            submissions = await controller.loadExamSubmissionStudents(
              examId,
              examTitle: exam?.title,
              classId: exam?.classId,
            );
            setState(() {});
          } finally {
            setState(() => isLoadingStudents = false);
          }
        }
        if (!didInit) {
          didInit = true;
          if (selectedExamId != null && selectedExamId!.isNotEmpty) {
            Future.microtask(() => loadStudents(selectedExamId));
          }
        }
        return AlertDialog(
          title: Text(item == null ? 'Tambah Nilai Ujian' : 'Ubah Nilai Ujian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    onChanged: (value) {
                      setState(() {
                        selectedClassId = value;
                        selectedExamId = null;
                        selectedStudentId = null;
                        selectedStudentName = null;
                        submissions = [];
                      });
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: selectedExamId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ujian'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Pilih ujian'),
                    ),
                    ...exams.map(
                      (exam) => DropdownMenuItem<String?>(
                        value: exam.id,
                        child: Text(exam.title),
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      selectedExamId = value;
                      selectedStudentId = null;
                      selectedStudentName = null;
                      submissions = [];
                    });
                    await loadStudents(value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mahasiswa (sudah ujian)',
                  ),
                  items: [
                    ...submissions.map(
                      (submission) {
                        final name = submission.studentName ?? 'Mahasiswa';
                        final nim = submission.studentNim;
                        final label =
                            nim == null || nim.isEmpty ? name : '$name ($nim)';
                        return DropdownMenuItem<String>(
                          value: submission.userId,
                          child: Text(label),
                        );
                      },
                    ),
                    if (selectedStudentId != null &&
                        selectedStudentId!.isNotEmpty &&
                        submissions
                            .where((item) => item.userId == selectedStudentId)
                            .isEmpty)
                      DropdownMenuItem<String>(
                        value: selectedStudentId,
                        child: Text(selectedStudentName ?? 'Mahasiswa'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      setState(() {
                        selectedStudentId = null;
                        selectedStudentName = null;
                      });
                      return;
                    }
                    ExamSubmissionItem? submission;
                    for (final item in submissions) {
                      if (item.userId == value) {
                        submission = item;
                        break;
                      }
                    }
                    setState(() {
                      selectedStudentId = value;
                      selectedStudentName = submission?.studentName ?? 'Mahasiswa';
                    });
                  },
                ),
                if (isLoadingStudents)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Memuat daftar mahasiswa...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                if (!isLoadingStudents &&
                    submissions.isEmpty &&
                    selectedExamId != null &&
                    selectedExamId!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Belum ada mahasiswa yang ujian.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
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
                final score = int.tryParse(scoreController.text) ?? 0;
                if (selectedStudentId == null ||
                    selectedStudentId!.isEmpty ||
                    selectedExamId == null) {
                  Get.snackbar(
                    'Gagal',
                    'Mahasiswa dan ujian wajib dipilih.',
                    backgroundColor: AppColors.navy,
                    colorText: Colors.white,
                  );
                  return;
                }
                try {
                  if (item == null) {
                    await controller.addExamGrade(
                      studentId: selectedStudentId!,
                      studentName: selectedStudentName ?? 'Mahasiswa',
                      score: score,
                      classId: selectedClassId,
                      examId: selectedExamId,
                    );
                  } else {
                    await controller.updateExamGrade(
                      id: item.id,
                      studentId: selectedStudentId!,
                      studentName: selectedStudentName ?? 'Mahasiswa',
                      score: score,
                      classId: selectedClassId,
                      examId: selectedExamId,
                    );
                  }
                  Get.back();
                  Future.microtask(() {
                    Get.snackbar(
                      'Berhasil',
                      item == null
                          ? 'Nilai ujian berhasil ditambahkan.'
                          : 'Nilai ujian berhasil diperbarui.',
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
        );
      },
    ),
  );
}
