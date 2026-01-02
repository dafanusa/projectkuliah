import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../classes/controllers/classes_controller.dart';
import '../../hasil/controllers/hasil_controller.dart';
import '../../materi/controllers/materi_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../nilai/controllers/nilai_controller.dart';
import '../../tugas/controllers/tugas_controller.dart';
import '../controllers/home_controller.dart';
import '../../../models/assignment_item.dart';
import '../../../models/material_item.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final materiController = Get.find<MateriController>();
    final tugasController = Get.find<TugasController>();
    final hasilController = Get.find<HasilController>();
    final nilaiController = Get.find<NilaiController>();
    final classesController = Get.find<ClassesController>();
    final navController = Get.find<NavigationController>();

    return Obx(() {
      final isAdmin = authService.role.value == 'admin';
      final materi = materiController.materi.toList();
      final tugas = tugasController.tugas.toList();
      final hasil = hasilController.hasil.toList();
      final nilai = nilaiController.nilai.toList();
      final now = DateTime.now();

      final aktifTugas =
          tugas.where((item) => item.deadline.isAfter(now)).toList();
      final lewatTugas = tugas.length - aktifTugas.length;
      final totalMissing = hasil.fold<int>(0, (sum, item) => sum + item.missing);
      final totalCollected =
          hasil.fold<int>(0, (sum, item) => sum + item.collected);
      final totalGraded = hasil.fold<int>(0, (sum, item) => sum + item.graded);
      final avgScore = nilai.isEmpty
          ? 0
          : (nilai.fold<int>(0, (sum, item) => sum + item.score) /
                  nilai.length)
              .round();

      final recentTugas = List.of(tugas)
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      final upcomingTugas = recentTugas.take(3).toList();

      final recentMateri = List.of(materi)
        ..sort((a, b) {
          final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      final latestMateri = recentMateri.take(3).toList();

      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            materiController.loadMateri(),
            tugasController.loadTugas(),
            hasilController.loadAll(),
            nilaiController.loadAll(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _DashboardHero(
              title: isAdmin ? 'Dashboard Admin' : 'Dashboard Mahasiswa',
              subtitle: isAdmin
                  ? 'Pantau materi, tugas, dan progres penilaian.'
                  : 'Lihat ringkasan tugas dan materi terbaru.',
              dateLabel: DateFormat('EEEE, dd MMM yyyy').format(now),
            ),
            const SizedBox(height: 20),
            _StatsGrid(
              items: [
                _StatItem(
                  label: 'Materi',
                  value: materi.length.toString(),
                  caption: 'Tersimpan',
                  icon: Icons.menu_book_rounded,
                  progress: materi.isEmpty ? 0 : 1,
                ),
                _StatItem(
                  label: 'Tugas Aktif',
                  value: aktifTugas.length.toString(),
                  caption: '$lewatTugas lewat',
                  icon: Icons.assignment_rounded,
                  progress: tugas.isEmpty
                      ? 0
                      : aktifTugas.length / tugas.length,
                ),
                _StatItem(
                  label: 'Belum Dinilai',
                  value: totalMissing.toString(),
                  caption: '$totalGraded dinilai',
                  icon: Icons.fact_check_rounded,
                  progress: totalCollected + totalMissing == 0
                      ? 0
                      : totalGraded / (totalCollected + totalMissing),
                ),
                _StatItem(
                  label: 'Rata-rata',
                  value: avgScore.toString(),
                  caption: '${nilai.length} nilai',
                  icon: Icons.score_rounded,
                  progress: avgScore / 100,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isAdmin) ...[
              _SectionHeader(
                title: 'CRUD Cepat',
                actionLabel: 'Kelola Semua',
                onAction: () => navController.changeIndex(1),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumn = constraints.maxWidth >= 360;
                  final itemWidth = twoColumn
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _ActionCard(
                          title: 'Tambah Materi',
                          subtitle: 'Upload materi baru',
                          icon: Icons.cloud_upload_rounded,
                          onTap: () => showMateriForm(
                            context,
                            materiController,
                            classesController,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ActionCard(
                          title: 'Tambah Tugas',
                          subtitle: 'Set deadline tugas',
                          icon: Icons.add_task_rounded,
                          onTap: () => showTugasForm(
                            context,
                            tugasController,
                            classesController,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ActionCard(
                          title: 'Input Hasil',
                          subtitle: 'Rekap pengumpulan',
                          icon: Icons.fact_check_rounded,
                          onTap: () => showHasilForm(
                            context,
                            hasilController,
                            classesController,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _ActionCard(
                          title: 'Input Nilai',
                          subtitle: 'Tambah nilai cepat',
                          icon: Icons.score_rounded,
                          onTap: () => showNilaiForm(
                            context,
                            nilaiController,
                            classesController,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            _SectionHeader(
              title: 'Tugas Terdekat',
              actionLabel: 'Kelola Tugas',
              onAction: () => navController.changeIndex(2),
            ),
            const SizedBox(height: 12),
            if (upcomingTugas.isEmpty)
              const _EmptyCard(
                title: 'Belum ada tugas',
                subtitle: 'Tugas yang aktif akan muncul di sini.',
              )
            else
              ...upcomingTugas.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TugasTile(
                    item: item,
                    isAdmin: isAdmin,
                    onEdit: () => showTugasForm(
                      context,
                      tugasController,
                      classesController,
                      item: item,
                    ),
                    onDelete: () => _confirmDelete(
                      title: 'Hapus tugas ini?',
                      onConfirm: () => tugasController.deleteTugas(item.id),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Materi Terbaru',
              actionLabel: 'Kelola Materi',
              onAction: () => navController.changeIndex(1),
            ),
            const SizedBox(height: 12),
            if (latestMateri.isEmpty)
              const _EmptyCard(
                title: 'Belum ada materi',
                subtitle: 'Materi baru akan muncul di sini.',
              )
            else
              ...latestMateri.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MateriTile(
                    item: item,
                    isAdmin: isAdmin,
                    onEdit: () => showMateriForm(
                      context,
                      materiController,
                      classesController,
                      item: item,
                    ),
                    onDelete: () => _confirmDelete(
                      title: 'Hapus materi ini?',
                      onConfirm: () => materiController.deleteMateri(item.id),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Ringkasan Penilaian',
              actionLabel: 'Kelola Hasil',
              onAction: () => navController.changeIndex(3),
            ),
            const SizedBox(height: 12),
            _ScoreSummary(
              collected: totalCollected,
              missing: totalMissing,
              graded: totalGraded,
              onTap: () => navController.changeIndex(3),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }
}

Future<void> _confirmDelete({
  required String title,
  required VoidCallback onConfirm,
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
            await Future.sync(onConfirm);
            Get.back();
          },
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}

class _DashboardHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dateLabel;

  const _DashboardHero({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2600142B),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFD6E0F5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroChip(
                label: dateLabel,
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 8),
              const _HeroChip(
                label: 'Supabase Live',
                icon: Icons.cloud_done_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final double progress;

  const _StatItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.progress,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 680;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => _StatCard(
                  item: item,
                  width: isWide ? 240 : (constraints.maxWidth - 12) / 2,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final double width;

  const _StatCard({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final progressValue = item.progress.clamp(0.0, 1.0);
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1400142B),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.navy),
              ),
              const Spacer(),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.caption,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8ECF5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1200142B),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

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

class _TugasTile extends StatelessWidget {
  final AssignmentItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TugasTile({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = DateFormat('dd MMM yyyy - HH:mm').format(item.deadline);
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
                _InfoPill(
                  label: 'Status',
                  value: isExpired ? 'Lewat' : 'Aktif',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MateriTile extends StatelessWidget {
  final MaterialItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MateriTile({
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
                      Text(item.description),
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
                _InfoPill(label: 'Tanggal', value: dateLabel),
                _InfoPill(label: 'Pertemuan', value: item.meeting),
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
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

class _ScoreSummary extends StatelessWidget {
  final int collected;
  final int missing;
  final int graded;
  final VoidCallback onTap;

  const _ScoreSummary({
    required this.collected,
    required this.missing,
    required this.graded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = collected + missing;
    final progress = total == 0 ? 0.0 : graded / total;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.fact_check_rounded, color: AppColors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progres Penilaian',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('Terkumpul $collected, belum $missing.'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8ECF5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.navy),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dinilai $graded dari $total tugas terkumpul',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
