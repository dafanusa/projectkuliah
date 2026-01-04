import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/class_item.dart';
import '../../../models/exam_item.dart';
import '../../../models/exam_attempt.dart';
import '../../../models/semester_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/class_access.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/ujian_controller.dart';
import 'ujian_attempt_view.dart';
import 'ujian_question_manage_view.dart';
import 'ujian_grading_view.dart';

class UjianView extends GetView<UjianController> {
  final Widget Function()? headerBuilder;

  const UjianView({super.key, this.headerBuilder});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final isAdmin = authService.role.value == 'admin';
      final items = controller.ujian.toList();
      final isLoading = controller.isLoading.value;
      final now = DateTime.now();
      final visibleItems = isAdmin ? items : items.toList();
      final aktif = visibleItems
          .where((item) => now.isAfter(item.startAt) && now.isBefore(item.endAt))
          .length;
      final selesai = visibleItems.length - aktif;
      final classes = classesController.classes.toList();
      final semesters = classesController.semesters.toList();
      final countByClassId = <String, int>{};
      final activeCountByClassId = <String, int>{};
      final endedCountByClassId = <String, int>{};
      for (final item in visibleItems) {
        final classId = item.classId ?? '';
        countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
        if (now.isAfter(item.startAt) && now.isBefore(item.endAt)) {
          activeCountByClassId[classId] =
              (activeCountByClassId[classId] ?? 0) + 1;
        } else {
          endedCountByClassId[classId] =
              (endedCountByClassId[classId] ?? 0) + 1;
        }
      }

      return RefreshIndicator(
        onRefresh: controller.loadUjian,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (isAdmin)
                Reveal(
                  delayMs: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Ujian',
                      subtitle: 'Buat jadwal ujian \ndan atur kelas.',
                      actionLabel: 'Buat Ujian',
                      onTap: () => showUjianForm(
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
                  title: 'Ujian Mahasiswa',
                  subtitle: 'Jadwal ujian dan informasi penting.',
                  stats: [
                    _HeaderStat(label: 'Aktif', value: aktif.toString()),
                    _HeaderStat(label: 'Selesai', value: selesai.toString()),
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
              TextField(
                onChanged: (value) =>
                    controller.searchQuery.value = value.trim(),
                decoration: const InputDecoration(
                  hintText: 'Cari judul ujian atau kelas...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _SemesterSection(
                semesters: semesters,
                classes: classes,
                items: visibleItems,
                isLoading: isLoading,
                countByClassId: countByClassId,
                activeCountByClassId: activeCountByClassId,
                endedCountByClassId: endedCountByClassId,
                query: controller.searchQuery.value,
                onSemesterTap: (semesterId, semesterName) {
                  controller.semesterSearchQuery.value = '';
                  Get.to(
                    () => UjianSemesterView(
                      semesterId: semesterId,
                      semesterName: semesterName,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SemesterSection extends StatelessWidget {
  final List<SemesterItem> semesters;
  final List<ClassItem> classes;
  final List<ExamItem> items;
  final bool isLoading;
  final Map<String, int> countByClassId;
  final Map<String, int> activeCountByClassId;
  final Map<String, int> endedCountByClassId;
  final String query;
  final void Function(String? semesterId, String semesterName) onSemesterTap;

  const _SemesterSection({
    required this.semesters,
    required this.classes,
    required this.items,
    required this.isLoading,
    required this.countByClassId,
    required this.activeCountByClassId,
    required this.endedCountByClassId,
    required this.query,
    required this.onSemesterTap,
  });

  int _sumCounts(Iterable<String> classIds, Map<String, int> map) {
    var total = 0;
    for (final id in classIds) {
      total += map[id] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final hasNoSemester = classes.any(
      (item) => item.semesterId == null || item.semesterId!.isEmpty,
    );
    if (isLoading && items.isEmpty && classes.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty && classes.isEmpty) {
      return const _EmptyState(
        title: 'Belum ada ujian',
        subtitle: 'Admin bisa menjadwalkan ujian baru.',
      );
    }
    if (semesters.isEmpty && !hasNoSemester) {
      return const _EmptyState(
        title: 'Belum ada semester',
        subtitle: 'Tambahkan semester untuk menampilkan kelas.',
      );
    }

    final noSemesterClassCount = classes
        .where((item) => item.semesterId == null || item.semesterId!.isEmpty)
        .length;
    final noSemesterClassIds = classes
        .where((item) => item.semesterId == null || item.semesterId!.isEmpty)
        .map((item) => item.id)
        .toList();
    final noSemesterExamCount =
        _sumCounts(noSemesterClassIds, countByClassId) +
            (countByClassId[''] ?? 0);
    final noSemesterActive =
        _sumCounts(noSemesterClassIds, activeCountByClassId) +
            (activeCountByClassId[''] ?? 0);
    final noSemesterEnded =
        _sumCounts(noSemesterClassIds, endedCountByClassId) +
            (endedCountByClassId[''] ?? 0);
    final normalizedQuery = query.trim().toLowerCase();

    final cards = <Widget>[];
    for (final item in semesters) {
      final semesterClasses =
          classes.where((c) => c.semesterId == item.id).toList();
      final classIds = semesterClasses.map((c) => c.id).toList();
      final classCount = semesterClasses.length;
      final examCount = _sumCounts(classIds, countByClassId);
      final activeCount = _sumCounts(classIds, activeCountByClassId);
      final endedCount = _sumCounts(classIds, endedCountByClassId);
      if (normalizedQuery.isNotEmpty) {
        final hasClassMatch = semesterClasses.any(
          (c) => c.name.toLowerCase().contains(normalizedQuery),
        );
        final hasExamMatch = items.any((e) {
          if (!e.title.toLowerCase().contains(normalizedQuery)) {
            return false;
          }
          final classId = e.classId;
          if (classId == null || classId.isEmpty) {
            return false;
          }
          return semesterClasses.any((c) => c.id == classId);
        });
        if (!hasClassMatch && !hasExamMatch) {
          continue;
        }
      }
      cards.add(
        _SemesterCard(
          title: item.name,
          subtitle:
              '$classCount kelas | $examCount ujian | $activeCount aktif / $endedCount berakhir',
          onTap: () => onSemesterTap(item.id, item.name),
        ),
      );
    }
    if (hasNoSemester) {
      if (normalizedQuery.isNotEmpty) {
        final semesterClasses = classes
            .where((c) => c.semesterId == null || c.semesterId!.isEmpty)
            .toList();
        final hasClassMatch = semesterClasses.any(
          (c) => c.name.toLowerCase().contains(normalizedQuery),
        );
        final hasExamMatch = items.any((e) {
          if (!e.title.toLowerCase().contains(normalizedQuery)) {
            return false;
          }
          return e.classId == null || e.classId!.isEmpty;
        });
        if (!hasClassMatch && !hasExamMatch) {
          if (cards.isEmpty) {
            return const _EmptyState(
              title: 'Tidak ada hasil',
              subtitle: 'Coba kata kunci lain.',
            );
          }
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
      }
      cards.add(
        _SemesterCard(
          title: 'Tanpa Semester',
          subtitle:
              '$noSemesterClassCount kelas | $noSemesterExamCount ujian | $noSemesterActive aktif / $noSemesterEnded berakhir',
          onTap: () => onSemesterTap(null, 'Tanpa Semester'),
        ),
      );
    }
    if (cards.isEmpty) {
      if (normalizedQuery.isNotEmpty) {
        return const _EmptyState(
          title: 'Tidak ada hasil',
          subtitle: 'Coba kata kunci lain.',
        );
      }
      return const _EmptyState(
        title: 'Belum ada semester',
        subtitle: 'Tambahkan semester untuk menampilkan kelas.',
      );
    }
    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          )
          .toList(),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SemesterCard({
    required this.title,
    required this.subtitle,
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
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.navy,
                ),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UjianSemesterView extends GetView<UjianController> {
  final String? semesterId;
  final String semesterName;

  const UjianSemesterView({
    super.key,
    required this.semesterId,
    required this.semesterName,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Ujian $semesterName')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final items = controller.ujian.toList();
        final isLoading = controller.isLoading.value;
        final now = DateTime.now();
        final classes = classesController.classes.toList();
        final query = controller.semesterSearchQuery.value.trim().toLowerCase();
        final filteredClasses = semesterId == null
            ? classes
                .where((c) => c.semesterId == null || c.semesterId!.isEmpty)
                .toList()
            : classes.where((c) => c.semesterId == semesterId).toList();
        final visibleClasses = filteredClasses.where((classItem) {
          if (query.isEmpty) {
            return true;
          }
          if (classItem.name.toLowerCase().contains(query)) {
            return true;
          }
          return items.any((item) =>
              item.classId == classItem.id &&
              item.title.toLowerCase().contains(query));
        }).toList();
        final countByClassId = <String, int>{};
        final activeCountByClassId = <String, int>{};
        final endedCountByClassId = <String, int>{};
        for (final item in items) {
          final classId = item.classId ?? '';
          countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
          if (now.isAfter(item.startAt) && now.isBefore(item.endAt)) {
            activeCountByClassId[classId] =
                (activeCountByClassId[classId] ?? 0) + 1;
          } else {
            endedCountByClassId[classId] =
                (endedCountByClassId[classId] ?? 0) + 1;
          }
        }
        final hasUnassigned = semesterId == null &&
            items.any((item) => item.classId == null || item.classId!.isEmpty);
        final showUnassigned = semesterId == null &&
            (query.isEmpty ||
                items.any((item) =>
                    (item.classId == null || item.classId!.isEmpty) &&
                    item.title.toLowerCase().contains(query)));

        Future<void> handleClassTap(ClassItem classItem) async {
          final isLocked = classesController.isClassLocked(classItem.id);
          if (isLocked) {
            final opened = await showJoinClassDialog(
              controller: classesController,
              classId: classItem.id,
              className: classItem.name,
            );
            if (!opened) {
              return;
            }
          }
          Get.to(
            () => UjianClassView(
              classId: classItem.id,
              className: classItem.name,
            ),
          );
        }

        if (isLoading && items.isEmpty && filteredClasses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final showEmptyState = visibleClasses.isEmpty && !showUnassigned;
        final emptyState = query.isNotEmpty
            ? const _EmptyState(
                title: 'Tidak ada hasil',
                subtitle: 'Coba kata kunci lain.',
              )
            : const _EmptyState(
                title: 'Belum ada kelas',
                subtitle: 'Kelas akan tampil di semester ini.',
              );

        return RefreshIndicator(
          onRefresh: controller.loadUjian,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ClassHero(
                  title: 'Semester $semesterName',
                  subtitle: 'Daftar kelas untuk semester ini.',
                  badge: '${visibleClasses.length} kelas',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) =>
                      controller.semesterSearchQuery.value = value.trim(),
                  decoration: const InputDecoration(
                    hintText: 'Cari judul ujian atau kelas...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (showEmptyState) emptyState,
                if (!showEmptyState)
                  ...visibleClasses.asMap().entries.map((entry) {
                    final classItem = entry.value;
                    final count = countByClassId[classItem.id] ?? 0;
                    final activeCount =
                        activeCountByClassId[classItem.id] ?? 0;
                    final endedCount = endedCountByClassId[classItem.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassCard(
                        title: classItem.name,
                        subtitle:
                            '$count ujian | $activeCount aktif / $endedCount berakhir',
                        icon: Icons.quiz_rounded,
                        isLocked: !isAdmin &&
                            classesController.isClassLocked(classItem.id),
                        onTap: () => handleClassTap(classItem),
                      ),
                    );
                  }),
                if (showUnassigned)
                  _ClassCard(
                    title: 'Tanpa Kelas',
                    subtitle:
                        '${countByClassId[''] ?? 0} ujian | ${activeCountByClassId[''] ?? 0} aktif / ${endedCountByClassId[''] ?? 0} berakhir',
                    icon: Icons.folder_off_rounded,
                    onTap: () => Get.to(
                      () => const UjianClassView(
                        classId: null,
                        className: 'Tanpa Kelas',
                      ),
                    ),
                    isLocked: false,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class UjianClassView extends GetView<UjianController> {
  final String? classId;
  final String className;

  const UjianClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final dataService = Get.find<DataService>();
    return Obx(() {
      final isAdmin = authService.role.value == 'admin';
      if (!isAdmin &&
          controller.myAttemptsClassId.value != (classId ?? '')) {
        Future.microtask(() => controller.loadMyAttemptsForClass(classId));
      }
      final now = DateTime.now();
      final items = controller.ujian.where((item) {
        if (classId == null || classId!.isEmpty) {
          return item.classId == null || item.classId!.isEmpty;
        }
        return item.classId == classId;
      }).where((item) => isAdmin || item.endAt.isAfter(now)).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));

      return Scaffold(
        appBar: AppBar(title: Text('Ujian $className')),
        body: RefreshIndicator(
          onRefresh: controller.loadUjian,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ClassHero(
                  title: className,
                  subtitle: 'Daftar ujian yang dijadwalkan.',
                  badge: 'Total ${items.length} ujian',
                  icon: Icons.quiz_rounded,
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  _AdminPanel(
                    title: 'Kelola Ujian',
                    subtitle: 'Atur ujian untuk kelas ini.',
                    actionLabel: 'Buat Ujian',
                    onTap: () => showUjianForm(
                      context,
                      controller,
                      Get.find<ClassesController>(),
                      fixedClassId: classId,
                      fixedClassName: className,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (items.isEmpty)
                  const _EmptyState(
                    title: 'Belum ada ujian',
                    subtitle: 'Ujian akan tampil saat admin menambahkannya.',
                  )
                else
                  ...items.map(
                    (item) => _UjianCard(
                      item: item,
                      isAdmin: isAdmin,
                      attempts: controller.myAttemptsByExamId[item.id] ?? const [],
                      dataService: dataService,
                      onStart: () async {
                        final result = await Get.to(
                          () => UjianAttemptView(exam: item),
                        );
                        if (result == true) {
                          await controller.loadMyAttemptsForClass(classId);
                        }
                      },
                      onManageQuestions: () async {
                        await controller.loadQuestions(item.id);
                        Get.to(
                          () => UjianQuestionManageView(examId: item.id),
                        );
                      },
                      onGrade: () => Get.to(
                        () => UjianGradingView(exam: item),
                      ),
                      onEdit: () => showUjianForm(
                        context,
                        controller,
                        Get.find<ClassesController>(),
                        item: item,
                      ),
                      onDelete: () => _confirmDelete(
                        title: 'Hapus ujian ini?',
                        successMessage: 'Ujian berhasil dihapus.',
                        onConfirm: () => controller.deleteUjian(item.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _UjianCard extends StatelessWidget {
  final ExamItem item;
  final bool isAdmin;
  final List<ExamAttempt> attempts;
  final DataService dataService;
  final VoidCallback onStart;
  final VoidCallback onManageQuestions;
  final VoidCallback onGrade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UjianCard({
    required this.item,
    required this.isAdmin,
    required this.attempts,
    required this.dataService,
    required this.onStart,
    required this.onManageQuestions,
    required this.onGrade,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy - HH:mm').format(item.endAt);
    final now = DateTime.now();
    final isUpcoming = now.isBefore(item.startAt);
    final isOverdue = now.isAfter(item.endAt);
    final isActive = !isUpcoming && !isOverdue;
    final hasActiveAttempt =
        attempts.any((attempt) => attempt.status == 'in_progress');
    final submittedCount =
        attempts.where((attempt) => attempt.status == 'submitted').length;
    final attemptsCount = attempts.length;
    final attemptsLabel = '$attemptsCount/${item.maxAttempts}';
    final statusLabel =
        isUpcoming ? 'Belum mulai' : (isOverdue ? 'Berakhir' : 'Aktif');
    final statusColor = isOverdue
        ? const Color(0xFFB42318)
        : (isUpcoming ? const Color(0xFF64748B) : const Color(0xFF0F8A4B));
    final progressLabel = hasActiveAttempt
        ? 'Sedang dikerjakan'
        : (submittedCount > 0 ? 'Sudah submit' : 'Belum submit');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: AppColors.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  Row(
                    children: [
                      IconButton(
                        onPressed: onManageQuestions,
                        icon: const Icon(Icons.list_alt_rounded),
                      ),
                      IconButton(
                        onPressed: onGrade,
                        icon: const Icon(Icons.fact_check_rounded),
                      ),
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
              runSpacing: 8,
              children: [
                _InfoPill(label: 'Deadline', value: dateLabel),
                _InfoPill(
                  label: 'Status',
                  value: statusLabel,
                  valueColor: statusColor,
                ),
                _InfoPill(
                  label: 'Percobaan',
                  value: attemptsLabel,
                ),
                if (!isAdmin)
                  _InfoPill(
                    label: 'Pengerjaan',
                    value: progressLabel,
                    valueColor: hasActiveAttempt
                        ? const Color(0xFF0F8A4B)
                        : AppColors.navy,
                  ),
              ],
            ),
            if (!isAdmin) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: (!isActive ||
                          (!hasActiveAttempt &&
                              attemptsCount >= item.maxAttempts))
                      ? null
                      : onStart,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    hasActiveAttempt
                        ? 'Lanjutkan Ujian'
                        : (attemptsCount >= item.maxAttempts
                            ? 'Percobaan habis'
                            : 'Mulai Ujian'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (item.filePath != null && item.filePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = dataService.getPublicUrl(
                        bucket: 'assignments',
                        path: item.filePath!,
                      );
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Lihat lampiran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
              child:
                  const Icon(Icons.quiz_rounded, color: AppColors.navy),
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

class _ClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLocked;

  const _ClassCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                    Text(subtitle),
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock_rounded, color: AppColors.navy),
            ],
          ),
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

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoPill({
    required this.label,
    required this.value,
    this.valueColor,
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
            style: const TextStyle(fontSize: 11, color: Color(0xFF627086)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.navy,
            ),
          ),
        ],
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
      child: Row(
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
