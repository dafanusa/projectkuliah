import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthService _authService = Get.find<AuthService>();
  late final AnimationController _animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> scaleAnimation;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void onReady() {
    super.onReady();
    _boot();
  }

  Future<void> _boot() async {
    _authService.suspendRedirect.value = true;
    await Future.delayed(const Duration(seconds: 30));
    _authService.suspendRedirect.value = false;

    if (_authService.isLoggedIn) {
      Get.offAllNamed(Routes.main);
    } else {
      Get.offAllNamed(Routes.welcome);
    }
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }
}
