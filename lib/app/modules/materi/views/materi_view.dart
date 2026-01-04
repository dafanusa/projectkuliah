import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/material_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/class_access.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../../../models/class_item.dart';
import '../../../models/semester_item.dart';
import '../controllers/materi_controller.dart';

class MateriView extends GetView<MateriController> {
  const MateriView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final items = controller.materi.toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final semesters = classesController.semesters.toList();
      final classById = {
        for (final item in classes) item.id: item,
      };

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadMateri();
        },
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
                      title: 'Kelola Materi',
                      subtitle: 'Tambah, ubah, dan arsipkan materi.',
                      actionLabel: 'Tambah Materi',
                      onTap: () => showMateriForm(
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
                  title: 'Materi Kuliah',
                  subtitle: 'Susun dan bagikan materi per pertemuan.',
                  chip: 'Tersimpan di Supabase',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) =>
                    controller.searchQuery.value = value.trim(),
                decoration: const InputDecoration(
                  hintText: 'Cari judul materi atau kelas...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _SemesterSection(
                semesters: semesters,
                classes: classes,
                items: items,
                classById: classById,
                isLoading: isLoading,
                query: controller.searchQuery.value,
                onSemesterTap: (semesterId, semesterName) {
                  controller.semesterSearchQuery.value = '';
                  Get.to(
                    () => MateriSemesterView(
                      semesterId: semesterId,
                      semesterName: semesterName,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
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
  final String chip;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.chip,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              chip,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterSection extends StatelessWidget {
  final List<SemesterItem> semesters;
  final List<ClassItem> classes;
  final List<MaterialItem> items;
  final Map<String, ClassItem> classById;
  final bool isLoading;
  final String query;
  final void Function(String? semesterId, String semesterName) onSemesterTap;

  const _SemesterSection({
    required this.semesters,
    required this.classes,
    required this.items,
    required this.classById,
    required this.isLoading,
    required this.query,
    required this.onSemesterTap,
  });

  int _countItemsForSemester(String? semesterId) {
    return items.where((item) {
      if (semesterId == null) {
        if (item.classId == null || item.classId!.isEmpty) {
          return true;
        }
        final classItem = classById[item.classId];
        return classItem == null ||
            classItem.semesterId == null ||
            classItem.semesterId!.isEmpty;
      }
      if (item.classId == null || item.classId!.isEmpty) {
        return false;
      }
      final classItem = classById[item.classId];
      return classItem != null && classItem.semesterId == semesterId;
    }).length;
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
        title: 'Belum ada materi',
        subtitle: 'Admin bisa menambahkan materi dari panel atas.',
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
    final noSemesterItemCount = _countItemsForSemester(null);
    final normalizedQuery = query.trim().toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth;
        final cards = <Widget>[];
        for (final item in semesters) {
          final classCount =
              classes.where((c) => c.semesterId == item.id).length;
          final itemCount = _countItemsForSemester(item.id);
          if (normalizedQuery.isNotEmpty) {
            final hasClassMatch = classes.any((c) =>
                c.semesterId == item.id &&
                c.name.toLowerCase().contains(normalizedQuery));
            final hasItemMatch = items.any((m) {
              if (m.title.toLowerCase().contains(normalizedQuery)) {
                final classId = m.classId;
                if (classId == null || classId.isEmpty) {
                  return false;
                }
                final classItem = classById[classId];
                return classItem != null && classItem.semesterId == item.id;
              }
              return false;
            });
            if (!hasClassMatch && !hasItemMatch) {
              continue;
            }
          }
          cards.add(
            SizedBox(
              width: itemWidth,
              child: _SemesterCard(
                title: item.name,
                subtitle: '$classCount kelas | $itemCount materi',
                onTap: () => onSemesterTap(item.id, item.name),
              ),
            ),
          );
        }
        if (hasNoSemester) {
          if (normalizedQuery.isNotEmpty) {
            final hasClassMatch = classes.any((c) =>
                (c.semesterId == null || c.semesterId!.isEmpty) &&
                c.name.toLowerCase().contains(normalizedQuery));
            final hasItemMatch = items.any((m) {
              if (m.title.toLowerCase().contains(normalizedQuery)) {
                return m.classId == null || m.classId!.isEmpty;
              }
              return false;
            });
            if (!hasClassMatch && !hasItemMatch) {
              return cards.isEmpty
                  ? const _EmptyState(
                      title: 'Tidak ada hasil',
                      subtitle: 'Coba kata kunci lain.',
                    )
                  : Column(
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
            SizedBox(
              width: itemWidth,
              child: _SemesterCard(
                title: 'Tanpa Semester',
                subtitle:
                    '$noSemesterClassCount kelas | $noSemesterItemCount materi',
                onTap: () => onSemesterTap(null, 'Tanpa Semester'),
              ),
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
                (widget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: widget,
                ),
              )
              .toList(),
        );
      },
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

class MateriSemesterView extends GetView<MateriController> {
  final String? semesterId;
  final String semesterName;

  const MateriSemesterView({
    super.key,
    required this.semesterId,
    required this.semesterName,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Materi $semesterName')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final items = controller.materi.toList();
        final classes = classesController.classes.toList();
        final isLoading = controller.isLoading.value;
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
        for (final item in items) {
          final classId = item.classId ?? '';
          countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
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
            () => MateriClassView(
              classId: classItem.id,
              className: classItem.name,
            ),
          );
        }

        if (isLoading && items.isEmpty && filteredClasses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.loadMateri,
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
                    hintText: 'Cari judul materi atau kelas...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                if (visibleClasses.isEmpty && !showUnassigned)
                  _EmptyState(
                    title: query.isNotEmpty
                        ? 'Tidak ada hasil'
                        : 'Belum ada kelas',
                    subtitle: query.isNotEmpty
                        ? 'Coba kata kunci lain.'
                        : 'Kelas akan tampil di semester ini.',
                  )
                else ...[
                  ...visibleClasses.asMap().entries.map((entry) {
                    final classItem = entry.value;
                    final count = countByClassId[classItem.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassCard(
                        title: classItem.name,
                        subtitle: '$count materi',
                        icon: Icons.menu_book_rounded,
                        isLocked: !isAdmin &&
                            classesController.isClassLocked(classItem.id),
                        onTap: () => handleClassTap(classItem),
                      ),
                    );
                  }),
                  if (showUnassigned)
                    _ClassCard(
                      title: 'Tanpa Kelas',
                      subtitle: '${countByClassId[''] ?? 0} materi',
                      icon: Icons.folder_off_rounded,
                      onTap: () => Get.to(
                        () => const MateriClassView(
                          classId: null,
                          className: 'Tanpa Kelas',
                        ),
                      ),
                      isLocked: false,
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
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
              child: const Icon(Icons.settings_rounded, color: AppColors.navy),
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

class MateriClassView extends GetView<MateriController> {
  final String? classId;
  final String className;

  const MateriClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final classesController = Get.find<ClassesController>();

    return Scaffold(
      appBar: AppBar(title: Text('Materi $className')),
      body: Obx(() {
        final items = controller.materi.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;

        return RefreshIndicator(
          onRefresh: controller.loadMateri,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (authService.role.value == 'admin')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AdminPanel(
                      title: 'Kelola Materi',
                      subtitle: 'Tambah materi untuk $className.',
                      actionLabel: 'Tambah Materi',
                      onTap: () => showMateriForm(
                        context,
                        controller,
                        classesController,
                        fixedClassId: classId,
                        fixedClassName: className,
                      ),
                    ),
                  ),
                _ClassHero(
                  title: 'Materi $className',
                  subtitle: 'Daftar materi untuk kelas ini.',
                  badge: '${items.length} materi',
                  icon: Icons.menu_book_rounded,
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
                              title: 'Belum ada materi',
                              subtitle: 'Materi akan tampil di sini.',
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
                                          child: _ListCard(
                                            item: item,
                                            isAdmin:
                                                authService.role.value == 'admin',
                                            onEdit: () => showMateriForm(
                                              context,
                                              controller,
                                              classesController,
                                              item: item,
                                              fixedClassId: classId,
                                              fixedClassName: className,
                                            ),
                                            onDelete: () => _confirmDelete(
                                              title: 'Hapus materi ini?',
                                              successMessage:
                                                  'Materi berhasil dihapus.',
                                              onConfirm: () =>
                                                  controller.deleteMateri(
                                                item.id,
                                              ),
                                            ),
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

class _ListCard extends StatelessWidget {
  final MaterialItem item;
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
    final dateLabel = item.date == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(item.date!);
    final isPublished =
        item.date != null && item.date!.isBefore(DateTime.now());
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFF9FAFF), Color(0xFFF1F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            Expanded(
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
                              Text(item.description),
                              const SizedBox(height: 6),
                              Text(
                                'Kelas: ${item.className ?? '-'}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          Row(
                            children: [
                              _ActionIcon(
                                icon: Icons.edit_rounded,
                                color: AppColors.navy,
                                onTap: onEdit,
                              ),
                              const SizedBox(width: 8),
                              _ActionIcon(
                                icon: Icons.delete_rounded,
                                color: Colors.red,
                                onTap: onDelete,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _InfoPill(label: 'Tanggal', value: dateLabel),
                            const SizedBox(width: 8),
                            _InfoPill(
                              label: 'Status',
                              value: isPublished ? 'Terbit' : 'Terjadwal',
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(label: 'Pertemuan', value: item.meeting),
                          ],
                        ),
                        if (item.filePath != null && item.filePath!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _AttachmentCard(path: item.filePath!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _AttachmentCard extends StatelessWidget {
  final String path;

  const _AttachmentCard({required this.path});

  String _fileName(String value) {
    final parts = value.split('/');
    return parts.isEmpty ? value : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Get.find<DataService>();
    final fileName = _fileName(path);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attach_file_rounded,
                size: 16, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampiran tersedia',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final url = dataService.getPublicUrl(
                bucket: 'materials',
                path: path,
              );
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
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
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
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
        ],
      ),
    );
  }
}
