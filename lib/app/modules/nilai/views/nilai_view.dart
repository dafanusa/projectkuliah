import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/grade_item.dart';
import '../../../models/exam_grade_item.dart';
import '../../../models/class_item.dart';
import '../../../models/semester_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/class_access.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/nilai_controller.dart';

class NilaiView extends GetView<NilaiController> {
  const NilaiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabIndex = controller.tabIndex.value;
      Widget buildSwitcher() {
        return _NilaiTabSwitcher(
          currentIndex: tabIndex,
          onChanged: (index) => controller.tabIndex.value = index,
        );
      }
      return Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: [
                _NilaiTugasTab(headerBuilder: buildSwitcher),
                _NilaiUjianTab(headerBuilder: buildSwitcher),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _NilaiTugasTab extends GetView<NilaiController> {
  final Widget Function()? headerBuilder;

  const _NilaiTugasTab({this.headerBuilder});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.nilai.toList();
      final isAdmin = authService.role.value == 'admin';
      final userName = authService.name.value.trim();
      final query = controller.searchQuery.value.trim().toLowerCase();
      final visibleItems = isAdmin
          ? items
          : items
              .where(
                (item) =>
                    userName.isNotEmpty &&
                    item.studentName.toLowerCase() ==
                        userName.toLowerCase(),
              )
              .toList();
      final filteredItems = query.isEmpty
          ? visibleItems
          : visibleItems.where((item) {
              final title = item.assignmentTitle?.toLowerCase() ?? '';
              final className = item.className?.toLowerCase() ?? '';
              return title.contains(query) || className.contains(query);
            }).toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final semesters = classesController.semesters.toList();
      final totalCount = filteredItems.length;
      final average = filteredItems.isEmpty
          ? 0
          : (filteredItems.fold<int>(0, (sum, item) => sum + item.score) /
                  filteredItems.length)
              .round();

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
                      title: 'Kelola Nilai Tugas',
                      subtitle: 'Tambah atau koreksi nilai tugas mahasiswa.',
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
                  title: 'Nilai Tugas',
                  subtitle: 'Pantau performa kelas secara cepat.',
                  stats: [
                    _HeaderStat(label: 'Rata-rata', value: average.toString()),
                    _HeaderStat(label: 'Jumlah', value: totalCount.toString()),
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
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) =>
                    controller.searchQuery.value = value.trim(),
                decoration: const InputDecoration(
                  hintText: 'Cari judul tugas atau kelas...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _SemesterSection(
                semesters: semesters,
                classes: classes,
                isLoading: isLoading,
                items: filteredItems,
                itemLabel: 'nilai',
                emptyTitle: 'Belum ada nilai',
                emptySubtitle: 'Nilai akan tampil di sini.',
                isFiltering: query.isNotEmpty,
                onSemesterTap: (semesterId, semesterName) {
                  controller.semesterSearchQuery.value = '';
                  Get.to(
                    () => NilaiSemesterView(
                      semesterId: semesterId,
                      semesterName: semesterName,
                      isExam: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    });
  }
}

class _NilaiUjianTab extends GetView<NilaiController> {
  final Widget Function()? headerBuilder;

  const _NilaiUjianTab({this.headerBuilder});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.nilaiUjian.toList();
      final isAdmin = authService.role.value == 'admin';
      final userName = authService.name.value.trim();
      final userId = authService.user.value?.id;
      final query = controller.searchExamQuery.value.trim().toLowerCase();
      final visibleItems = isAdmin
          ? items
          : items
              .where(
                (item) {
                  if (userId != null &&
                      item.studentId != null &&
                      item.studentId == userId) {
                    return true;
                  }
                  return userName.isNotEmpty &&
                      item.studentName.toLowerCase() ==
                          userName.toLowerCase();
                },
              )
              .toList();
      final filteredItems = query.isEmpty
          ? visibleItems
          : visibleItems.where((item) {
              final title = item.examTitle?.toLowerCase() ?? '';
              final className = item.className?.toLowerCase() ?? '';
              return title.contains(query) || className.contains(query);
            }).toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final semesters = classesController.semesters.toList();
      final totalCount = filteredItems.length;
      final average = filteredItems.isEmpty
          ? 0
          : (filteredItems.fold<int>(0, (sum, item) => sum + item.score) /
                  filteredItems.length)
              .round();

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
                      title: 'Kelola Nilai Ujian',
                      subtitle: 'Tambah atau koreksi nilai ujian.',
                      actionLabel: 'Tambah Nilai',
                      onTap: () => showNilaiUjianForm(
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
                  title: 'Nilai Ujian',
                  subtitle: 'Pantau performa ujian secara cepat.',
                  stats: [
                    _HeaderStat(label: 'Rata-rata', value: average.toString()),
                    _HeaderStat(label: 'Jumlah', value: totalCount.toString()),
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
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) =>
                    controller.searchExamQuery.value = value.trim(),
                decoration: const InputDecoration(
                  hintText: 'Cari judul ujian atau kelas...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _SemesterSection(
                semesters: semesters,
                classes: classes,
                isLoading: isLoading,
                items: filteredItems,
                itemLabel: 'nilai',
                emptyTitle: 'Belum ada nilai ujian',
                emptySubtitle: 'Nilai ujian akan tampil di sini.',
                isFiltering: query.isNotEmpty,
                onSemesterTap: (semesterId, semesterName) {
                  controller.semesterExamSearchQuery.value = '';
                  Get.to(
                    () => NilaiSemesterView(
                      semesterId: semesterId,
                      semesterName: semesterName,
                      isExam: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    });
  }
}

class _NilaiTabSwitcher extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _NilaiTabSwitcher({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Tugas',
            isActive: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 6),
          _TabButton(
            label: 'Ujian',
            isActive: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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

class _SemesterSection extends StatelessWidget {
  final List<SemesterItem> semesters;
  final List<ClassItem> classes;
  final bool isLoading;
  final List<dynamic> items;
  final String itemLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isFiltering;
  final void Function(String? semesterId, String semesterName) onSemesterTap;

  const _SemesterSection({
    required this.semesters,
    required this.classes,
    required this.isLoading,
    required this.items,
    required this.itemLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.isFiltering,
    required this.onSemesterTap,
  });

  int _sumCounts(Map<String, int> countByClassId, Iterable<String> classIds) {
    var total = 0;
    for (final id in classIds) {
      total += countByClassId[id] ?? 0;
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
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    if (isFiltering && items.isEmpty) {
      return const _EmptyState(
        title: 'Tidak ada hasil',
        subtitle: 'Coba kata kunci lain.',
      );
    }
    if (semesters.isEmpty && !hasNoSemester) {
      return const _EmptyState(
        title: 'Belum ada semester',
        subtitle: 'Tambahkan semester untuk menampilkan kelas.',
      );
    }
    final countByClassId = <String, int>{};
    for (final item in items) {
      final classId = (item as dynamic).classId as String?;
      final key = classId ?? '';
      countByClassId[key] = (countByClassId[key] ?? 0) + 1;
    }
    final hasUnassigned = items.any((item) {
      final classId = (item as dynamic).classId as String?;
      return classId == null || classId.isEmpty;
    });
    final groups = <Widget>[];
    for (final item in semesters) {
      final semesterClasses =
          classes.where((c) => c.semesterId == item.id).toList();
      final classIds = semesterClasses.map((c) => c.id).toList();
      final classCount = semesterClasses.length;
      final itemCount = _sumCounts(countByClassId, classIds);
      if (isFiltering && itemCount == 0) {
        continue;
      }
      groups.add(
        _SemesterCard(
          title: item.name,
          subtitle: '$classCount kelas | $itemCount $itemLabel',
          onTap: () => onSemesterTap(item.id, item.name),
        ),
      );
    }
    if (hasNoSemester) {
      final semesterClasses = classes
          .where((c) => c.semesterId == null || c.semesterId!.isEmpty)
          .toList();
      final classIds = semesterClasses.map((c) => c.id).toList();
      final classCount = semesterClasses.length;
      final itemCount =
          _sumCounts(countByClassId, classIds) +
          (hasUnassigned ? (countByClassId[''] ?? 0) : 0);
      if (!isFiltering || itemCount > 0) {
      groups.add(
        _SemesterCard(
          title: 'Tanpa Semester',
          subtitle: '$classCount kelas | $itemCount $itemLabel',
          onTap: () => onSemesterTap(null, 'Tanpa Semester'),
        ),
      );
      }
    }
    if (groups.isEmpty) {
      return const _EmptyState(
        title: 'Belum ada semester',
        subtitle: 'Tambahkan semester untuk menampilkan kelas.',
      );
    }
    return Column(
      children: groups
          .map(
            (widget) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: widget,
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
              Icon(
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

class NilaiSemesterView extends GetView<NilaiController> {
  final String? semesterId;
  final String semesterName;
  final bool isExam;

  const NilaiSemesterView({
    super.key,
    required this.semesterId,
    required this.semesterName,
    required this.isExam,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Nilai $semesterName')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final userName = authService.name.value.trim();
        final userId = authService.user.value?.id;
        final classes = classesController.classes.toList();
        final isLoading = controller.isLoading.value;
        final items = isExam
            ? controller.nilaiUjian.toList()
            : controller.nilai.toList();
        final query = (isExam
                ? controller.semesterExamSearchQuery.value
                : controller.semesterSearchQuery.value)
            .trim()
            .toLowerCase();
        final visibleItems = isAdmin
            ? items
            : items.where((item) {
                if (isExam) {
                  final examItem = item as ExamGradeItem;
                  if (userId != null &&
                      examItem.studentId != null &&
                      examItem.studentId == userId) {
                    return true;
                  }
                }
                final name = (item as dynamic).studentName as String?;
                return userName.isNotEmpty &&
                    name != null &&
                    name.toLowerCase() == userName.toLowerCase();
              }).toList();
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
          return visibleItems.any((item) {
            final classId = (item as dynamic).classId as String?;
            if (classId != classItem.id) {
              return false;
            }
            final title = isExam
                ? (item as ExamGradeItem).examTitle?.toLowerCase() ?? ''
                : (item as GradeItem).assignmentTitle?.toLowerCase() ?? '';
            return title.contains(query);
          });
        }).toList();
        final countByClassId = <String, int>{};
        for (final item in visibleItems) {
          final classId = (item as dynamic).classId as String?;
          final key = classId ?? '';
          countByClassId[key] = (countByClassId[key] ?? 0) + 1;
        }
        final hasUnassigned = semesterId == null &&
            visibleItems.any((item) {
              final classId = (item as dynamic).classId as String?;
              return classId == null || classId.isEmpty;
            });
        final showUnassigned = semesterId == null &&
            (query.isEmpty ||
                visibleItems.any((item) {
                  final classId = (item as dynamic).classId as String?;
                  if (classId != null && classId.isNotEmpty) {
                    return false;
                  }
                  final title = isExam
                      ? (item as ExamGradeItem).examTitle?.toLowerCase() ?? ''
                      : (item as GradeItem).assignmentTitle?.toLowerCase() ?? '';
                  return title.contains(query);
                }));

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
          if (isExam) {
            Get.to(
              () => NilaiUjianClassView(
                classId: classItem.id,
                className: classItem.name,
              ),
            );
          } else {
            Get.to(
              () => NilaiClassView(
                classId: classItem.id,
                className: classItem.name,
              ),
            );
          }
        }

        if (isLoading && visibleItems.isEmpty && filteredClasses.isEmpty) {
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
          onRefresh: controller.loadAll,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _PageHeader(
                  title: 'Nilai $semesterName',
                  subtitle: 'Pantau performa kelas secara cepat.',
                  stats: [
                    _HeaderStat(
                      label: 'Jumlah',
                      value: visibleItems.length.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    final trimmed = value.trim();
                    if (isExam) {
                      controller.semesterExamSearchQuery.value = trimmed;
                    } else {
                      controller.semesterSearchQuery.value = trimmed;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: isExam
                        ? 'Cari judul ujian atau kelas...'
                        : 'Cari judul tugas atau kelas...',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (showEmptyState) emptyState,
                if (!showEmptyState)
                  ...visibleClasses.asMap().entries.map((entry) {
                    final classItem = entry.value;
                    final count = countByClassId[classItem.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassCard(
                        title: classItem.name,
                        subtitle: '$count nilai',
                        icon: isExam
                            ? Icons.emoji_events_rounded
                            : Icons.score_rounded,
                        isLocked: !isAdmin &&
                            classesController.isClassLocked(classItem.id),
                        onTap: () => handleClassTap(classItem),
                      ),
                    );
                  }),
                if (showUnassigned)
                  _ClassCard(
                    title: 'Tanpa Kelas',
                    subtitle: '${countByClassId[''] ?? 0} nilai',
                    icon: Icons.folder_off_rounded,
                    onTap: () => Get.to(
                      () => isExam
                          ? const NilaiUjianClassView(
                              classId: null,
                              className: 'Tanpa Kelas',
                            )
                          : const NilaiClassView(
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
                child: Icon(
                  icon,
                  color: isLocked ? AppColors.textSecondary : AppColors.navy,
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
              Icon(
                isLocked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                color: isLocked ? AppColors.textSecondary : null,
              ),
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
        final isAdmin = authService.role.value == 'admin';
        final userName = authService.name.value.trim();
        final items = controller.nilai.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).where((item) {
          if (isAdmin) {
            return true;
          }
          return userName.isNotEmpty &&
              item.studentName.toLowerCase() == userName.toLowerCase();
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
                if (isAdmin)
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
                if (isAdmin && items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showExportSheet(
                        context: context,
                        title: 'Ekspor Nilai',
                        onExport: (format) => controller.exportAssignmentGrades(
                          className: className,
                          items: items,
                          format: format,
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Ekspor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                                              isAdmin: isAdmin,
                                              onEdit: () => showNilaiForm(
                                                context,
                                                controller,
                                                classesController,
                                                item: item,
                                                fixedClassId: classId,
                                                fixedClassName: className,
                                              ),
                                              onDelete: () => _confirmDelete(
                                                title: 'Hapus nilai ini?',
                                                successMessage:
                                                    'Nilai berhasil dihapus.',
                                                onConfirm: () =>
                                                    controller.deleteGrade(
                                                  item.id,
                                                ),
                                              ),
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
                                                  isAdmin
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
                                                                  _confirmDelete(
                                                                title:
                                                                    'Hapus nilai ini?',
                                                                successMessage:
                                                                    'Nilai berhasil dihapus.',
                                                                onConfirm: () =>
                                                                    controller
                                                                        .deleteGrade(
                                                                  item.id,
                                                                ),
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

class NilaiUjianClassView extends GetView<NilaiController> {
  final String? classId;
  final String className;

  const NilaiUjianClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Nilai Ujian $className')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final userName = authService.name.value.trim();
        final userId = authService.user.value?.id;
        final items = controller.nilaiUjian.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).where((item) {
          if (isAdmin) {
            return true;
          }
          if (userId != null &&
              item.studentId != null &&
              item.studentId == userId) {
            return true;
          }
          return userName.isNotEmpty &&
              item.studentName.toLowerCase() == userName.toLowerCase();
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
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Nilai Ujian',
                      subtitle: 'Atur nilai ujian untuk $className.',
                      actionLabel: 'Tambah Nilai',
                      onTap: () => showNilaiUjianForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _PageHeader(
                  title: 'Nilai Ujian $className',
                  subtitle: 'Pantau performa ujian secara cepat.',
                  stats: [
                    _HeaderStat(label: 'Rata-rata', value: average.toString()),
                    _HeaderStat(label: 'Jumlah', value: items.length.toString()),
                  ],
                ),
                if (isAdmin && items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showExportSheet(
                        context: context,
                        title: 'Ekspor Nilai Ujian',
                        onExport: (format) => controller.exportExamGrades(
                          className: className,
                          items: items,
                          format: format,
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Ekspor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                              title: 'Belum ada nilai ujian',
                              subtitle: 'Nilai ujian akan tampil di sini.',
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
                                            child: _NilaiUjianCard(
                                              item: item,
                                              isAdmin: isAdmin,
                                              onEdit: () => showNilaiUjianForm(
                                                context,
                                                controller,
                                                classesController,
                                                item: item,
                                                fixedClassId: classId,
                                                fixedClassName: className,
                                              ),
                                              onDelete: () => _confirmDelete(
                                                title: 'Hapus nilai ujian ini?',
                                                successMessage:
                                                    'Nilai ujian berhasil dihapus.',
                                                onConfirm: () =>
                                                    controller.deleteExamGrade(
                                                  item.id,
                                                ),
                                              ),
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
                                        DataColumn(label: Text('Ujian')),
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
                                                    Text(item.examTitle ?? '-')),
                                                DataCell(Text(item.score.toString())),
                                                DataCell(
                                                  isAdmin
                                                      ? Row(
                                                          children: [
                                                            IconButton(
                                                              onPressed: () =>
                                                                  showNilaiUjianForm(
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
                                                                  _confirmDelete(
                                                                title:
                                                                    'Hapus nilai ujian ini?',
                                                                successMessage:
                                                                    'Nilai ujian berhasil dihapus.',
                                                                onConfirm: () =>
                                                                    controller
                                                                        .deleteExamGrade(
                                                                  item.id,
                                                                ),
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

class _NilaiUjianCard extends StatelessWidget {
  final ExamGradeItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NilaiUjianCard({
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
                      Text('Ujian: ${item.examTitle ?? '-'}'),
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

void _showExportSheet({
  required BuildContext context,
  required String title,
  required void Function(ExportFormat format) onExport,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_view_rounded),
            title: const Text('Excel (.xlsx)'),
            onTap: () {
              Navigator.pop(context);
              onExport(ExportFormat.excel);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: const Text('PDF (.pdf)'),
            onTap: () {
              Navigator.pop(context);
              onExport(ExportFormat.pdf);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_rounded),
            title: const Text('Word (.doc)'),
            onTap: () {
              Navigator.pop(context);
              onExport(ExportFormat.word);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
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
