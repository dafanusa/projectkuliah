import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/exam_question.dart';
import '../../../theme/app_colors.dart';
import '../controllers/ujian_controller.dart';

class UjianQuestionManageView extends GetView<UjianController> {
  final String examId;

  const UjianQuestionManageView({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Soal Ujian')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () async {
            await controller.recalcQuestionPoints(examId);
            Get.snackbar(
              'Berhasil',
              'Poin tiap soal disesuaikan ke total 100.',
              backgroundColor: AppColors.navy,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
          },
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Auto Poin (Total 100)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
      ),
      body: Obx(() {
        final questions = controller.questions.toList();
        if (questions.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada soal.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            return Card(
              child: ListTile(
                title: Text(question.prompt),
                subtitle: Text(
                  '${question.type == 'mcq' ? 'PG' : 'Essay'} • ${question.points} poin',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showQuestionForm(
                        context,
                        question: question,
                      ),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(context, question),
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExamQuestion question,
  ) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Hapus soal ini?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.deleteQuestion(question.id);
              await controller.loadQuestions(examId);
              Get.back();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuestionForm(
    BuildContext context, {
    ExamQuestion? question,
  }) async {
    final promptController = TextEditingController(text: question?.prompt ?? '');
    final pointsController = TextEditingController(
      text: question?.points.toString() ?? '1',
    );
    final orderController = TextEditingController(
      text: question?.orderIndex.toString() ?? '0',
    );
    String type = question?.type ?? 'mcq';
    final optionControllers = List.generate(
      4,
      (index) => TextEditingController(),
    );
    int correctIndex = 0;

    if (question != null && question.type == 'mcq') {
      final relatedChoices = controller.choices
          .where((item) => item.questionId == question.id)
          .toList();
      for (var i = 0; i < optionControllers.length; i++) {
        if (i < relatedChoices.length) {
          optionControllers[i].text = relatedChoices[i].text;
          if (relatedChoices[i].isCorrect) {
            correctIndex = i;
          }
        }
      }
    }

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(question == null ? 'Tambah Soal' : 'Ubah Soal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipe Soal'),
                    items: const [
                      DropdownMenuItem(
                          value: 'mcq', child: Text('Pilihan Ganda')),
                      DropdownMenuItem(value: 'essay', child: Text('Essay')),
                    ],
                    onChanged: (value) =>
                        setState(() => type = value ?? 'mcq'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: promptController,
                    decoration: const InputDecoration(labelText: 'Pertanyaan'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Poin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: orderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Urutan'),
                        ),
                      ),
                    ],
                  ),
                  if (type == 'mcq') ...[
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Opsi Jawaban',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(optionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Opsi ${index + 1}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Radio<int>(
                              value: index,
                              groupValue: correctIndex,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => correctIndex = value);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
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
                  final prompt = promptController.text.trim();
                  final points = int.tryParse(pointsController.text.trim()) ?? 1;
                  final order = int.tryParse(orderController.text.trim()) ?? 0;
                  if (prompt.isEmpty) {
                    Get.snackbar(
                      'Gagal',
                      'Pertanyaan wajib diisi.',
                      backgroundColor: AppColors.navy,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  final options = <Map<String, dynamic>>[];
                  if (type == 'mcq') {
                    for (var i = 0; i < optionControllers.length; i++) {
                      options.add({
                        'text': optionControllers[i].text.trim(),
                        'is_correct': i == correctIndex,
                      });
                    }
                  }
                  await controller.saveQuestion(
                    question: question,
                    examId: examId,
                    type: type,
                    prompt: prompt,
                    points: points,
                    orderIndex: order,
                    options: options,
                  );
                  await controller.loadQuestions(examId);
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
}
