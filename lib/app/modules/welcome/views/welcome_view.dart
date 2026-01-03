import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/responsive_center.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _WelcomeBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (!isWide) {
                  return ResponsiveCenter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          const _TopBrand(),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _GlassCard(
                              child: Stack(
                                children: [
                                  PageView(
                                    controller: _controller,
                                    onPageChanged: (value) {
                                      setState(() => _index = value);
                                    },
                                    children: const [
                                      _WelcomeSlide(
                                        imageAsset: 'assets/screen1.jpg',
                                        badge: 'Dosen STIE Jambatan Bulan',
                                        title:
                                            'Dr. Yahya Nusa, S.E., \n M.Si., CTT',
                                        subtitle:
                                            'Portal personal untuk terhubung dengan \n karya penelitian dan materi dosen.',
                                      ),
                                      _WelcomeSlide(
                                        imageAsset: 'assets/screen2.jpg',
                                        badge: 'Akademik Terpadu',
                                        title:
                                            'Manajemen Materi, Tugas \n dan Penilaian Akademik',
                                        subtitle:
                                            'Manajemen akademik terpadu untuk materi perkuliahan, tugas, dan penilaian akademik.',
                                      ),
                                      _WelcomeSlide(
                                        imageAsset: 'assets/screen3.jpg',
                                        badge: 'Real-time Dashboard',
                                        title:
                                            'Dashboard Pantau Aktivitas Akademik Mahasiswa',
                                        subtitle:
                                            'Dashboard real-time untuk \n memantau akademik mahasiswa.',
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 14,
                                    child: _PageDots(
                                      activeIndex: _index,
                                      count: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Get.toNamed(Routes.login),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Get.toNamed(Routes.register),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navy,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(
                                      color: AppColors.navy,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: ResponsiveCenter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight + 120,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Text(
                              'Portal Akademik Modern',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 36,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kelola materi, tugas, dan penilaian akademik dalam satu tempat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.5,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 420,
                              child: _GlassCard(
                                child: Stack(
                                  children: [
                                    PageView(
                                      controller: _controller,
                                      onPageChanged: (value) {
                                        setState(() => _index = value);
                                      },
                                      children: const [
                                        _WelcomeSlide(
                                          imageAsset: 'assets/screen1.jpg',
                                          badge: 'Dosen STIE Jambatan Bulan',
                                          title:
                                              'Dr. Yahya Nusa, S.E., \n M.Si., CTT',
                                          subtitle:
                                              'Portal personal untuk terhubung dengan \n karya penelitian dan materi dosen.',
                                        ),
                                        _WelcomeSlide(
                                          imageAsset: 'assets/screen2.jpg',
                                          badge: 'Akademik Terpadu',
                                          title:
                                              'Manajemen Materi, Tugas \n dan Penilaian Akademik',
                                          subtitle:
                                              'Manajemen akademik terpadu untuk materi perkuliahan, tugas, dan penilaian akademik.',
                                        ),
                                        _WelcomeSlide(
                                          imageAsset: 'assets/screen3.jpg',
                                          badge: 'Real-time Dashboard',
                                          title:
                                              'Dashboard Pantau Aktivitas Akademik Mahasiswa',
                                          subtitle:
                                              'Dashboard real-time untuk \n memantau akademik mahasiswa.',
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 14,
                                      child: _PageDots(
                                        activeIndex: _index,
                                        count: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Get.toNamed(Routes.login),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Masuk',
                                      style:
                                          TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Get.toNamed(Routes.register),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navy,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.navy,
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Daftar',
                                      style:
                                          TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBrand extends StatelessWidget {
  const _TopBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1100142B),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.school_rounded, color: AppColors.navy, size: 18),
              SizedBox(width: 8),
              Text(
                'PortalNusaAkademi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F8FF), Color(0xFFEAF0FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -90,
            right: -50,
            child: _GlassCircle(size: 240, color: Color(0xFFCFE0FF)),
          ),
          Positioned(
            top: 120,
            left: -70,
            child: _GlassCircle(size: 180, color: Color(0xFFE7EDFF)),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _GlassCircle(size: 210, color: Color(0xFFD9E6FF)),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.58),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A00142B),
                blurRadius: 26,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  final String imageAsset;
  final String badge;
  final String title;
  final String subtitle;

  const _WelcomeSlide({
    required this.imageAsset,
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // HERO IMAGE (mobile saja)
          if (!isWide)
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 18,
                    right: 18,
                    bottom: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withOpacity(0.10),
                            Colors.white.withOpacity(0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.65)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1600142B),
                            blurRadius: 26,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(imageAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),

          if (isWide) ...[
            Container(
              width: 120,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    AppColors.navy.withOpacity(0.18),
                    AppColors.navy.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A00142B),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: AppColors.navy,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
          ] else
            const SizedBox(height: 14),

          // Badge kecil biar ada “detail”
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),

          SizedBox(height: isWide ? 16 : 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              fontSize: isWide ? 26 : 20,
              letterSpacing: 0.7,
            ),
          ),
          SizedBox(height: isWide ? 16 : 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: isWide ? 16 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isWide) const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _PageDots({required this.activeIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == activeIndex ? 26 : 8,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppColors.navy
                : const Color(0xFFC9D4EE),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _WebInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WebInfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1200142B),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlassCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
      ),
    );
  }
}
