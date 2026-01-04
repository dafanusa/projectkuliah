import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';

import '../../../models/assignment_item.dart';
import '../../../models/assignment_submission.dart';
import '../../../models/exam_item.dart';
import '../../../models/exam_grade_item.dart';
import '../../../models/exam_submission_item.dart';
import '../../../models/grade_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/file_saver.dart';

enum ExportFormat { excel, pdf, word }

class NilaiController extends GetxController {
  final DataService _dataService = Get.find<DataService>();
  final AuthService _authService = Get.find<AuthService>();

  final nilai = <GradeItem>[].obs;
  final nilaiUjian = <ExamGradeItem>[].obs;
  final assignments = <AssignmentItem>[].obs;
  final exams = <ExamItem>[].obs;
  final isLoading = false.obs;
  final tabIndex = 0.obs;
  final selectedSemesterId = ''.obs;
  final searchQuery = ''.obs;
  final searchExamQuery = ''.obs;
  final semesterSearchQuery = ''.obs;
  final semesterExamSearchQuery = ''.obs;

  bool get isAdmin => _authService.role.value == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadAll();
    ever(_authService.role, (_) => loadAll());
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      nilai.value = await _dataService.fetchGrades();
      nilaiUjian.value = await _dataService.fetchExamGrades();
      assignments.value = await _dataService.fetchAssignments(
        includeExpired: true,
      );
      exams.value = await _dataService.fetchExams();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addGrade({
    required String studentName,
    required int score,
    required String? classId,
    required String? assignmentId,
  }) async {
    await _dataService.insertGrade({
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'assignment_id': assignmentId,
    });
    await loadAll();
  }

  Future<void> updateGrade({
    required String id,
    required String studentName,
    required int score,
    required String? classId,
    required String? assignmentId,
  }) async {
    await _dataService.updateGrade(id, {
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'assignment_id': assignmentId,
    });
    await loadAll();
  }

  Future<void> deleteGrade(String id) async {
    await _dataService.deleteGrade(id);
    await loadAll();
  }

  Future<void> addExamGrade({
    required String studentId,
    required String studentName,
    required int score,
    required String? classId,
    required String? examId,
  }) async {
    await _dataService.insertExamGrade({
      'student_id': studentId,
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'exam_id': examId,
    });
    await loadAll();
  }

  Future<void> updateExamGrade({
    required String id,
    required String studentId,
    required String studentName,
    required int score,
    required String? classId,
    required String? examId,
  }) async {
    await _dataService.updateExamGrade(id, {
      'student_id': studentId,
      'student_name': studentName,
      'score': score,
      'class_id': classId,
      'exam_id': examId,
    });
    await loadAll();
  }

  Future<void> deleteExamGrade(String id) async {
    await _dataService.deleteExamGrade(id);
    await loadAll();
  }

  Future<void> exportAssignmentGrades({
    required String className,
    required List<GradeItem> items,
    required ExportFormat format,
  }) async {
    if (items.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Tidak ada nilai untuk diekspor.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    final totals = <String, int>{};
    final names = <String>{};
    for (final item in items) {
      final key = item.studentName.trim().toLowerCase();
      totals[key] = (totals[key] ?? 0) + item.score;
      if (item.studentName.trim().isNotEmpty) {
        names.add(item.studentName.trim());
      }
    }
    final nimByName = await _dataService.fetchProfileNimByNames(names.toList());
    final rows = items.map((item) {
      final studentKey = item.studentName.trim().toLowerCase();
      final nim = nimByName[studentKey] ?? '-';
      final total = totals[studentKey] ?? 0;
      return [
        item.studentName,
        nim,
        className,
        item.assignmentTitle ?? '-',
        item.score.toString(),
        total.toString(),
      ];
    }).toList();
    await _exportRows(
      title: 'Nilai Tugas $className',
      headers: const [
        'Mahasiswa',
        'NIM',
        'Kelas',
        'Tugas',
        'Nilai',
        'Akumulasi',
      ],
      rows: rows,
      format: format,
    );
  }

  Future<void> exportExamGrades({
    required String className,
    required List<ExamGradeItem> items,
    required ExportFormat format,
  }) async {
    if (items.isEmpty) {
      Get.snackbar(
        'Gagal',
        'Tidak ada nilai ujian untuk diekspor.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
      return;
    }
    final totals = <String, int>{};
    final ids = <String>{};
    final names = <String>{};
    for (final item in items) {
      final key = _examStudentKey(item);
      totals[key] = (totals[key] ?? 0) + item.score;
      if (item.studentId != null && item.studentId!.isNotEmpty) {
        ids.add(item.studentId!);
      } else if (item.studentName.trim().isNotEmpty) {
        names.add(item.studentName.trim());
      }
    }
    final nimById = await _dataService.fetchProfileNimByIds(ids.toList());
    final nimByName = await _dataService.fetchProfileNimByNames(names.toList());
    final rows = items.map((item) {
      final key = _examStudentKey(item);
      final nim = item.studentId != null && item.studentId!.isNotEmpty
          ? (nimById[item.studentId!] ?? '-')
          : (nimByName[item.studentName.trim().toLowerCase()] ?? '-');
      final total = totals[key] ?? 0;
      return [
        item.studentName,
        nim,
        className,
        item.examTitle ?? '-',
        item.score.toString(),
        total.toString(),
      ];
    }).toList();
    await _exportRows(
      title: 'Nilai Ujian $className',
      headers: const [
        'Mahasiswa',
        'NIM',
        'Kelas',
        'Ujian',
        'Nilai',
        'Akumulasi',
      ],
      rows: rows,
      format: format,
    );
  }

  String _examStudentKey(ExamGradeItem item) {
    final id = item.studentId?.trim();
    if (id != null && id.isNotEmpty) {
      return 'id:$id';
    }
    return 'name:${item.studentName.trim().toLowerCase()}';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _exportRows({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required ExportFormat format,
  }) async {
    final safeName = title.replaceAll(' ', '_');
    final timestamp = _timestamp();
    try {
      switch (format) {
        case ExportFormat.excel:
          final excel = Excel.createExcel();
          final sheet = excel['Nilai'];
          sheet.appendRow(
            headers.map((header) => TextCellValue(header)).toList(),
          );
          for (final row in rows) {
            sheet.appendRow(
              row.map((cell) => TextCellValue(cell)).toList(),
            );
          }
          final bytes = excel.encode();
          if (bytes == null) {
            Get.snackbar(
              'Gagal',
              'Gagal membuat file Excel.',
              backgroundColor: AppColors.navy,
              colorText: Colors.white,
            );
            return;
          }
          await _saveFileBytes(
            fileName: '${safeName}_$timestamp.xlsx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            bytes: Uint8List.fromList(bytes),
          );
          break;
        case ExportFormat.pdf:
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              build: (context) => [
                pw.Text(title, style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: headers,
                  data: rows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ),
          );
          final bytes = await pdf.save();
          await _saveFileBytes(
            fileName: '${safeName}_$timestamp.pdf',
            mimeType: 'application/pdf',
            bytes: bytes,
          );
          break;
        case ExportFormat.word:
          final buffer = StringBuffer()
            ..writeln('<html><head><meta charset="utf-8"></head><body>')
            ..writeln('<h2>${_escapeHtml(title)}</h2>')
            ..writeln(
                '<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;">')
            ..writeln('<tr>')
            ..writeAll(
              headers.map((header) => '<th>${_escapeHtml(header)}</th>'),
            )
            ..writeln('</tr>');
          for (final row in rows) {
            buffer.writeln('<tr>');
            for (final cell in row) {
              buffer.writeln('<td>${_escapeHtml(cell)}</td>');
            }
            buffer.writeln('</tr>');
          }
          buffer.writeln('</table></body></html>');
          final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
          await _saveFileBytes(
            fileName: '${safeName}_$timestamp.doc',
            mimeType: 'application/msword',
            bytes: bytes,
          );
          break;
      }
    } catch (error) {
      Get.snackbar(
        'Gagal',
        'Ekspor gagal: $error',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }

  Future<void> _saveFileBytes({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    try {
      final saved = await saveFileBytes(
        fileName: fileName,
        mimeType: mimeType,
        bytes: bytes,
      );
      if (!saved) {
        return;
      }
      Get.snackbar(
        'Berhasil',
        'File berhasil disimpan.',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    } catch (error) {
      Get.snackbar(
        'Gagal',
        'Ekspor gagal: $error',
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
      );
    }
  }

  Future<List<AssignmentSubmission>> loadSubmissionStudents(
    String? assignmentId, {
    String? assignmentTitle,
    String? classId,
  }) async {
    if (assignmentId == null || assignmentId.isEmpty) {
      return [];
    }
    final submissions = await _dataService.fetchAllSubmissions();
    var filtered = submissions
        .where((item) => item.assignmentId == assignmentId)
        .toList();
    if (filtered.isEmpty &&
        assignmentTitle != null &&
        assignmentTitle.trim().isNotEmpty) {
      final titleKey = assignmentTitle.trim().toLowerCase();
      filtered = submissions.where((item) {
        final title = item.assignmentTitle?.trim().toLowerCase();
        if (title == null || title.isEmpty) {
          return false;
        }
        if (classId != null && classId.isNotEmpty && item.classId != classId) {
          return false;
        }
        return title == titleKey;
      }).toList();
    }
    return filtered;
  }

  Future<List<ExamSubmissionItem>> loadExamSubmissionStudents(
    String? examId, {
    String? examTitle,
    String? classId,
  }) async {
    if (examId == null || examId.isEmpty) {
      return [];
    }
    final submissions = await _dataService.fetchExamSubmissions(examId);
    if (submissions.isNotEmpty) {
      return submissions;
    }
    if (examTitle == null || examTitle.trim().isEmpty) {
      return submissions;
    }
    final titleKey = examTitle.trim().toLowerCase();
    return submissions.where((item) {
      final title = item.examTitle?.trim().toLowerCase();
      if (title == null || title.isEmpty) {
        return false;
      }
      if (classId != null && classId.isNotEmpty && item.classId != classId) {
        return false;
      }
      return title == titleKey;
    }).toList();
  }
}
