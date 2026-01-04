import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mvbtummaplikasi/app/services/data_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/assignment_submission.dart';
import '../../../models/class_item.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/class_access.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../../classes/controllers/classes_controller.dart';
import '../controllers/hasil_controller.dart';

class HasilView extends StatefulWidget {
  final Widget Function()? headerBuilder;

  const HasilView({super.key, this.headerBuilder});

  @override
  State<HasilView> createState() => _HasilViewState();
}

class _HasilViewState extends State<HasilView> {
  final HasilController controller = Get.find<HasilController>();

  @override
  void initState() {
    super.initState();
    controller.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final dataService = Get.find<DataService>();
    final classesController = Get.find<ClassesController>();

    return Obx(() {
      final isAdmin = authService.role.value == 'admin';
      final submissions = controller.submissions.toList();
      final isLoading = controller.isLoading.value;
      final classes = classesController.classes.toList();
      final classNameById = {for (final item in classes) item.id: item.name};
      final totalOnTime =
          submissions.where((item) => item.status == 'tepat_waktu').length;
      final totalLate =
          submissions.where((item) => item.status == 'terlambat').length;
      final hasUnassigned = submissions.any(
          (item) => item.classId == null || item.classId!.isEmpty);
      final countByClassId = <String, int>{};
      for (final item in submissions) {
        final classId = item.classId ?? '';
        countByClassId[classId] = (countByClassId[classId] ?? 0) + 1;
      }

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
          () => HasilClassView(
            classId: classItem.id,
            className: classItem.name,
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadAll,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Reveal(
                delayMs: 120,
                child: _PageHeader(
                  title: 'Hasil Tugas',
                  subtitle: 'Ringkasan pengumpulan tugas mahasiswa.',
                  stats: [
                    _HeaderStat(
                      label: 'Terkumpul',
                      value: submissions.length.toString(),
                    ),
                    _HeaderStat(label: 'Tepat', value: totalOnTime.toString()),
                    _HeaderStat(label: 'Terlambat', value: totalLate.toString()),
                  ],
                ),
              ),
              if (widget.headerBuilder != null) ...[
                const SizedBox(height: 12),
                ResponsiveCenter(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: widget.headerBuilder!(),
                ),
              ],
              const SizedBox(height: 16),
              if (!isAdmin) ...[
                _IdentityCard(authService: authService),
                const SizedBox(height: 16),
              ],
              if (isAdmin) ...[
                _SectionTitle('Pengumpulan Mahasiswa'),
                const SizedBox(height: 8),
                if (isLoading && submissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (submissions.isEmpty)
                  const _EmptyText('Belum ada pengumpulan dari mahasiswa.')
                else
                  _SubmissionGroupList(
                    submissions: submissions,
                    classNameById: classNameById,
                    dataService: dataService,
                  ),
                const SizedBox(height: 16),
              ],
              if (!isAdmin) ...[
                _SectionTitle('Riwayat Pengumpulan Saya'),
                const SizedBox(height: 8),
                const _EmptyText('Riwayat pengumpulan disembunyikan.'),
                const SizedBox(height: 16),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isLoading && submissions.isEmpty && classes.isEmpty
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : classes.isEmpty
                        ? const _EmptyState(
                            title: 'Belum ada jawaban',
                            subtitle: 'Data kelas belum tersedia.',
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 720;
                              final itemWidth = isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;
                              final tiles = <Widget>[];
                              for (final entry in classes.asMap().entries) {
                                final classItem = entry.value;
                                final count =
                                    countByClassId[classItem.id] ?? 0;
                                tiles.add(
                                  Reveal(
                                    delayMs: 140 + (entry.key * 70).toInt(),
                                    child: SizedBox(
                                      width: itemWidth,
                                      child: _ClassCard(
                                        title: classItem.name,
                                        subtitle: '$count jawaban',
                                        icon: Icons.fact_check_rounded,
                                        isLocked: !isAdmin &&
                                            classesController
                                                .isClassLocked(classItem.id),
                                        onTap: () => handleClassTap(classItem),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (hasUnassigned) {
                                tiles.add(
                                  Reveal(
                                    delayMs: 140 + tiles.length * 70,
                                    child: SizedBox(
                                      width: itemWidth,
                                      child: _ClassCard(
                                        title: 'Tanpa Kelas',
                                        subtitle:
                                            '${countByClassId[''] ?? 0} jawaban',
                                        icon: Icons.folder_off_rounded,
                                        onTap: () => Get.to(
                                          () => const HasilClassView(
                                            classId: null,
                                            className: 'Tanpa Kelas',
                                          ),
                                        ),
                                        isLocked: false,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: tiles,
                              );
                            },
                          ),
              ),
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

class HasilClassView extends GetView<HasilController> {
  final String? classId;
  final String className;

  const HasilClassView({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
        final dataService = Get.find<DataService>();

    return Scaffold(
      appBar: AppBar(title: Text('Hasil $className')),
      body: Obx(() {
        final isAdmin = authService.role.value == 'admin';
        final submissions = controller.submissions.where((item) {
          if (classId == null || classId!.isEmpty) {
            return item.classId == null || item.classId!.isEmpty;
          }
          return item.classId == classId;
        }).toList();
        final isLoading = controller.isLoading.value;
        final totalOnTime = submissions
            .where((item) => item.status == 'tepat_waktu')
            .length;
        final totalLate =
            submissions.where((item) => item.status == 'terlambat').length;

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          child: ResponsiveCenter(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _PageHeader(
                  title: 'Hasil $className',
                  subtitle: 'Ringkasan pengumpulan tugas mahasiswa.',
                  stats: [
                    _HeaderStat(
                      label: 'Terkumpul',
                      value: submissions.length.toString(),
                    ),
                    _HeaderStat(label: 'Tepat', value: totalOnTime.toString()),
                    _HeaderStat(label: 'Terlambat', value: totalLate.toString()),
                  ],
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  _SectionTitle('Pengumpulan Mahasiswa'),
                  const SizedBox(height: 8),
                  if (isLoading && submissions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (submissions.isEmpty)
                    const _EmptyText('Belum ada pengumpulan dari mahasiswa.')
                  else
                    _SubmissionGroupList(
                      submissions: submissions,
                      classNameById: const {},
                      dataService: dataService,
                    ),
                  const SizedBox(height: 16),
                ],
                if (!isAdmin)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isLoading && submissions.isEmpty
                        ? const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : submissions.isEmpty
                            ? const _EmptyState(
                                title: 'Belum ada hasil tugas',
                                subtitle: 'Belum ada jawaban yang masuk.',
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final grouped =
                                      <String, List<AssignmentSubmission>>{};
                                  for (final item in submissions) {
                                    final key =
                                        item.assignmentTitle ?? 'Tugas';
                                    grouped.putIfAbsent(key, () => []).add(item);
                                  }
                                  return Column(
                                    children: grouped.entries
                                        .map(
                                          (entry) => Card(
                                            child: ExpansionTile(
                                              title: Text(entry.key),
                                              subtitle: Text(
                                                '${entry.value.length} jawaban',
                                              ),
                                              children: entry.value
                                                  .map(
                                                    (submission) =>
                                                        _SubmissionCard(
                                                      submission: submission,
                                                      dataService: dataService,
                                                    ),
                                                  )
                                                  .toList(),
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

class _IdentityCard extends StatelessWidget {
  final AuthService authService;

  const _IdentityCard({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.badge_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.name.value.isEmpty
                          ? 'Mahasiswa'
                          : authService.name.value,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authService.nim.value.isEmpty
                          ? 'NIM: -'
                          : 'NIM: ${authService.nim.value}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;

  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _SubmissionCard({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    final displayName = submission.studentName?.isNotEmpty == true
        ? submission.studentName!
        : 'Mahasiswa';
    final nimLabel = submission.studentNim?.isNotEmpty == true
        ? 'NIM: ${submission.studentNim}'
        : 'NIM: -';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(
          () => _SubmissionDetailPage(
            submission: submission,
            dataService: dataService,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 18, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nimLabel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CompactChip(
                          label: submission.status == 'terlambat'
                              ? 'Terlambat'
                              : 'Tepat Waktu',
                        ),
                        _CompactChip(label: submittedLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String label;

  const _CompactChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _SubmissionListPage extends StatelessWidget {
  final String title;
  final List<AssignmentSubmission> submissions;
  final DataService dataService;

  const _SubmissionListPage({
    required this.title,
    required this.submissions,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.navyAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2600142B),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.group_rounded, color: Colors.white),
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
                      const SizedBox(height: 4),
                      Text(
                        '${submissions.length} jawaban masuk',
                        style: const TextStyle(color: Color(0xFFD6E0F5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...submissions.map(
            (submission) => _SubmissionCard(
              submission: submission,
              dataService: dataService,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionDetailPage extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _SubmissionDetailPage({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    final displayName = submission.studentName?.isNotEmpty == true
        ? submission.studentName!
        : 'Mahasiswa';
    final nimLabel = submission.studentNim?.isNotEmpty == true
        ? 'NIM: ${submission.studentNim}'
        : 'NIM: -';
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumpulan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.navyAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2600142B),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nimLabel,
                        style: const TextStyle(color: Color(0xFFD6E0F5)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderStat(
                            label: 'Status',
                            value: submission.status == 'terlambat'
                                ? 'Terlambat'
                                : 'Tepat Waktu',
                          ),
                          _HeaderStat(label: 'Dikirim', value: submittedLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (submission.content != null &&
              submission.content!.trim().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jawaban',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(submission.content!),
                  ],
                ),
              ),
            ),
          if (submission.filePath != null &&
              submission.filePath!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
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
                      child: const Icon(Icons.attach_file_rounded,
                          color: AppColors.navy),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lampiran tersedia',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = dataService.getPublicUrl(
                          bucket: 'assignments',
                          path: submission.filePath!,
                        );
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Buka'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyHistoryCard extends StatelessWidget {
  final AssignmentSubmission submission;
  final DataService dataService;

  const _MyHistoryCard({
    required this.submission,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final submittedLabel =
        DateFormat('dd MMM yyyy - HH:mm').format(submission.submittedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission.assignmentTitle ?? 'Tugas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Dikirim: $submittedLabel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              submission.status == 'terlambat' ? 'Terlambat' : 'Tepat Waktu',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (submission.filePath != null &&
                submission.filePath!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () async {
                    final url = dataService.getPublicUrl(
                      bucket: 'assignments',
                      path: submission.filePath!,
                    );
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Lihat lampiran'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionGroupList extends StatelessWidget {
  final List<AssignmentSubmission> submissions;
  final Map<String, String> classNameById;
  final DataService dataService;

  const _SubmissionGroupList({
    required this.submissions,
    required this.classNameById,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AssignmentSubmission>>{};
    for (final item in submissions) {
      final classLabel = classNameById[item.classId] ?? '-';
      final key = classNameById.isEmpty
          ? (item.assignmentTitle ?? 'Tugas')
          : '${item.assignmentTitle ?? 'Tugas'} • $classLabel';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return Column(
      children: grouped.entries.map((entry) {
        return Card(
          child: ListTile(
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} jawaban masuk'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Get.to(
              () => _SubmissionListPage(
                title: entry.key,
                submissions: entry.value,
                dataService: dataService,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
