import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/modules/home/views/home_view.dart';
import '../../../../app/modules/materi/views/materi_view.dart';
import '../../../../app/modules/tugas/views/tugas_view.dart';
import '../../../../app/modules/nilai/views/nilai_view.dart';
import '../../../../app/modules/karya/views/karya_view.dart';
import '../../../../app/modules/profile/views/profile_view.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
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
      final screenWidth = MediaQuery.of(context).size.width;
      final isWide = screenWidth >= 900;
      final authService = Get.find<AuthService>();
      final displayName = authService.name.value.isEmpty
          ? (authService.role.value == 'admin' ? 'Admin' : 'Mahasiswa')
          : authService.name.value;
      final roleLabel =
          authService.role.value == 'admin' ? 'Administrator' : 'Mahasiswa';
      final isProfileLoading = authService.isProfileLoading.value;
      final titleText = index == 0
          ? 'Selamat datang di Aplikasi \nPortalNusaAkademi, $displayName'
          : items[index].label;
      final bottomInset = MediaQuery.of(context).padding.bottom;
      const navHeight = 84.0;
      final content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 140),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: IndexedStack(
          key: ValueKey(index),
          index: index,
          children: pages,
        ),
      );

      return Scaffold(
        extendBody: !isWide,
        appBar: isWide
            ? null
            : AppBar(
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
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF4F6FB), Color(0xFFE9EEF8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: isWide
                  ? Row(
                      children: [
                    SafeArea(
                      top: false,
                      bottom: false,
                      child: Container(
                        width: 240,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A00142B),
                              blurRadius: 16,
                              offset: Offset(4, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.school_rounded,
                                          color: AppColors.navy,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'PortalNusaAkademi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                roleLabel,
                                                style: const TextStyle(
                                                  color: Color(0xFFD6E0F5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, itemIndex) {
                                  final item = items[itemIndex];
                                  final isSelected = itemIndex == index;
                                  return _SidebarItem(
                                    item: item,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        controller.changeIndex(itemIndex),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 4, 12, 16),
                              child: _SidebarAction(
                                label: 'Logout',
                                icon: Icons.logout_rounded,
                                onTap: () {
                                  Get.offAllNamed(Routes.welcome);
                                  authService.signOut();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 32, 24),
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1400142B),
                                    blurRadius: 18,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      titleText,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8ECF5),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Web Dashboard',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth >= 1200
                                        ? 1080
                                        : double.infinity,
                                  ),
                                  child: content,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        bottom: navHeight + bottomInset + 8,
                      ),
                      child: content,
                    ),
            ),
            if (isProfileLoading) ...[
              const ModalBarrier(
                dismissible: false,
                color: Color(0x33000000),
              ),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : SafeArea(
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

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = Colors.white;
    final backgroundColor =
        isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent;
    final borderColor =
        isSelected ? Colors.white.withOpacity(0.45) : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Icon(item.icon, color: foregroundColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SidebarAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFB42318);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7E2F6)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
