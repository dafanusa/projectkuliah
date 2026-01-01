import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mvbtummaplikasi/app/modules/home/views/home_view.dart';
import 'package:mvbtummaplikasi/app/modules/materi/views/materi_view.dart';
import 'package:mvbtummaplikasi/app/modules/tugas/views/tugas_view.dart';
import 'package:mvbtummaplikasi/app/modules/hasil/views/hasil_view.dart';
import 'package:mvbtummaplikasi/app/modules/nilai/views/nilai_view.dart';
import 'package:mvbtummaplikasi/app/modules/profile/views/profile_view.dart';
import '../controllers/navigation_controller.dart';

class NavigationView extends GetView<NavigationController> {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem('Home', Icons.dashboard_rounded),
      _NavItem('Materi', Icons.menu_book_rounded),
      _NavItem('Tugas', Icons.assignment_rounded),
      _NavItem('Hasil', Icons.fact_check_rounded),
      _NavItem('Nilai', Icons.score_rounded),
      _NavItem('Profil', Icons.person_rounded),
    ];

    final pages = [
      const HomeView(),
      const MateriView(),
      const TugasView(),
      const HasilView(),
      const NilaiView(),
      const ProfileView(),
    ];

    return Obx(() {
      final index = controller.currentIndex.value;
      return Scaffold(
        extendBody: true,
        appBar: AppBar(title: Text(items[index].label)),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF4F6FB), Color(0xFFE9EEF8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: IndexedStack(
              key: ValueKey(index),
              index: index,
              children: pages,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                currentIndex: index,
                items: items
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
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
