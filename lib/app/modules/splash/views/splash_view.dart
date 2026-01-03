import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0A1D37);
    const navyAccent = Color(0xFF102A52);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [navy, navyAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _GlowCircle(
                size: 260,
                color: Color(0xFF244A8D),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -90,
              child: _GlowCircle(
                size: 300,
                color: Color(0xFF1B3569),
              ),
            ),
            Positioned(
              top: 140,
              left: 24,
              child: _GlowCircle(
                size: 90,
                color: Color(0xFF2A5AA8),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: controller.fadeAnimation,
                builder: (context, child) {
                  final opacity = controller.fadeAnimation.value;
                  final slide = controller.slideAnimation.value;
                  final scale = controller.scaleAnimation.value;
                  return Opacity(
                    opacity: opacity == 0 ? 1 : opacity,
                    child: Transform.translate(
                      offset: Offset(0, slide.dy * 120),
                      child: Transform.scale(
                        scale: scale == 0 ? 1 : scale,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ================= ICON =================
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ================= TITLE =================
                    const Text(
                      "PortalNusaAkademi",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= SUBTITLE =================
                    const Text(
                      "Kelola kelas, materi, tugas, dan karya dosen.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFD6E0F5),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // ================= LOADING =================
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Color(0x3387A8E8),
                      ),
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.35),
      ),
    );
  }
}
