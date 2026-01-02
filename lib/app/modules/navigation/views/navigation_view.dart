import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mvbtummaplikasi/app/modules/home/views/home_view.dart';
import 'package:mvbtummaplikasi/app/modules/materi/views/materi_view.dart';
import 'package:mvbtummaplikasi/app/modules/tugas/views/tugas_view.dart';
import 'package:mvbtummaplikasi/app/modules/nilai/views/nilai_view.dart';
import 'package:mvbtummaplikasi/app/modules/karya/views/karya_view.dart';
import 'package:mvbtummaplikasi/app/modules/profile/views/profile_view.dart';
import 'package:mvbtummaplikasi/app/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../controllers/navigation_controller.dart';

class NavigationView extends GetView<NavigationController> {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem('Home', Icons.dashboard_rounded),
      _NavItem('Materi', Icons.menu_book_rounded),
      _NavItem('Tugas', Icons.assignment_rounded),
      _NavItem('Nilai', Icons.score_rounded),
      _NavItem('Karya', Icons.auto_stories_rounded),
      _NavItem('Profil', Icons.person_rounded),
    ];

    final pages = [
      const HomeView(),
      const MateriView(),
      const TugasView(),
      const NilaiView(),
      const KaryaView(),
      const ProfileView(),
    ];

    return Obx(() {
      final index = controller.currentIndex.value;
      final authService = Get.find<AuthService>();
      final displayName = authService.name.value.isEmpty
          ? (authService.role.value == 'admin' ? 'Admin' : 'Mahasiswa')
          : authService.name.value;
      final titleText = index == 0
          ? 'Selamat datang di Aplikasi \nPortalNusaAkademi, $displayName'
          : items[index].label;
      final bottomInset = MediaQuery.of(context).padding.bottom;
      const navHeight = 84.0;
      return Scaffold(
        extendBody: true,
        appBar: AppBar(
          toolbarHeight: 86,
          centerTitle: index != 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              titleText,
              key: ValueKey(titleText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF4F6FB), Color(0xFFE9EEF8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: navHeight + bottomInset + 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offset = Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: IndexedStack(
                key: ValueKey(index),
                index: index,
                children: pages,
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A00142B),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BottomNavigationBar(
                backgroundColor: AppColors.navy,
                currentIndex: index,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                items: items
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon: Icon(item.icon, color: Colors.white),
                        activeIcon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: AppColors.navy),
                        ),
                        label: item.label,
                      ),
                    )
                    .toList(),
                onTap: controller.changeIndex,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
