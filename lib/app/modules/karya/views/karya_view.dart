import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/lecturer_work_item.dart';
import '../../../services/data_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/admin_forms.dart';
import '../../../widgets/responsive_center.dart';
import '../../../widgets/reveal.dart';
import '../controllers/karya_controller.dart';

class KaryaView extends GetView<KaryaController> {
  const KaryaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final karya = controller.karya.toList();
      final isLoading = controller.isLoading.value;
      final isAdmin = controller.isAdmin;

      return RefreshIndicator(
        onRefresh: controller.loadKarya,
        child: ResponsiveCenter(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Reveal(
                delayMs: 120,
                child: const _PageHeader(
                  title: 'Karya Dosen',
                  subtitle: 'Koleksi penelitian, buku, dan karya unggulan.',
                  chip: 'Akses untuk mahasiswa',
                ),
              ),
              const SizedBox(height: 12),
              _LecturerHeader(
                onAdd: isAdmin
                    ? () => showKaryaForm(
                          context,
                          controller,
                        )
                    : null,
              ),
              const SizedBox(height: 16),
              if (isLoading && karya.isEmpty)
                const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (karya.isEmpty)
                const _EmptyState(
                  title: 'Belum ada karya dosen',
                  subtitle: 'Unggah karya agar mahasiswa bisa melihatnya.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    final itemWidth = isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: karya
                          .map(
                            (item) => SizedBox(
                              width: itemWidth,
                              child: _KaryaCard(
                                item: item,
                                isAdmin: isAdmin,
                                onEdit: () => showKaryaForm(
                                  context,
                                  controller,
                                  item: item,
                                ),
                                onDelete: () => _confirmDelete(
                                  title: 'Hapus karya ini?',
                                  successMessage: 'Karya berhasil dihapus.',
                                  onConfirm: () =>
                                      controller.deleteKarya(item.id),
                                ),
                              ),
                            ),
                          )
                          .toList(),
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

class _LecturerHeader extends StatelessWidget {
  final VoidCallback? onAdd;

  const _LecturerHeader({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2600142B),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                'assets/karya.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dr. Yahya Nusa, S.E., M.Si., CTT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Koleksi karya, publikasi, dan buku dosen.',
            style: TextStyle(
              color: Color(0xFFD6E0F5),
              fontSize: 12,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Tambah Karya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KaryaCard extends StatelessWidget {
  final LecturerWorkItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KaryaCard({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = Get.find<DataService>();
    final dateLabel =
        item.date == null ? '-' : DateFormat('dd MMM yyyy').format(item.date!);
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
                  child: const Icon(Icons.auto_stories_rounded,
                      color: AppColors.navy),
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
                        item.category,
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
            Text(
              item.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _InfoPill(label: 'Tanggal', value: dateLabel),
            if (item.filePath != null && item.filePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = dataService.getPublicUrl(
                        bucket: 'materials',
                        path: item.filePath!,
                      );
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    label: const Text('Lihat karya'),
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
