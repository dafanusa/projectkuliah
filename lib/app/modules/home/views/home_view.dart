import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _HeroBanner(
          title: 'Dashboard Dosen',
          subtitle: 'Ringkasan aktivitas perkuliahan minggu ini.',
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (authService.role.value != 'admin') {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle('Pintasan Admin'),
              SizedBox(height: 12),
              _QuickActions(),
              SizedBox(height: 20),
            ],
          );
        }),
        const _SectionTitle('Ringkasan Cepat'),
        const SizedBox(height: 12),
        Obx(() => _SummaryGrid(items: controller.summary.toList())),
        const SizedBox(height: 20),
        const _SectionTitle('Aktivitas Terbaru'),
        const SizedBox(height: 12),
        Obx(() {
          final items = controller.activities.toList();
          return Column(
            children: items
                .map(
                  (item) => _ActivityTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    trailing: item.time,
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroBanner({
    required this.title,
    required this.subtitle,
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
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFD6E0F5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            children: [
              _TagChip('Semester Genap 2025/2026'),
              _TagChip('Dummy Data'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<SummaryItem> items;

  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => _SummaryCard(
                  title: item.title,
                  value: item.value,
                  icon: item.icon,
                  wide: isWide,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool wide;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 260 : 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A00142B),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.navyAccent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
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

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        _ActionCard(
          label: 'Upload Materi',
          icon: Icons.cloud_upload_rounded,
        ),
        _ActionCard(
          label: 'Buat Tugas',
          icon: Icons.add_task_rounded,
        ),
        _ActionCard(
          label: 'Input Nilai',
          icon: Icons.edit_rounded,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1200142B),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.circle, color: AppColors.navy, size: 10),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: const TextStyle(color: Color(0xFF7A879A), fontSize: 12),
        ),
      ),
    );
  }
}
