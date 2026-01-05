import 'package:get/get.dart';

import 'package:mvbtummaplikasi/app/modules/navigation/bindings/navigation_binding.dart';
import 'package:mvbtummaplikasi/app/modules/navigation/views/navigation_view.dart';
import 'package:mvbtummaplikasi/app/modules/auth/login/bindings/login_binding.dart';
import 'package:mvbtummaplikasi/app/modules/auth/login/views/login_view.dart';
import 'package:mvbtummaplikasi/app/modules/auth/register/bindings/register_binding.dart';
import 'package:mvbtummaplikasi/app/modules/auth/register/views/register_view.dart';
import 'package:mvbtummaplikasi/app/modules/auth/reset_password/bindings/reset_password_binding.dart';
import 'package:mvbtummaplikasi/app/modules/auth/reset_password/views/reset_password_view.dart';
import 'package:mvbtummaplikasi/app/modules/home/bindings/home_binding.dart';
import 'package:mvbtummaplikasi/app/modules/home/views/home_view.dart';
import 'package:mvbtummaplikasi/app/modules/materi/bindings/materi_binding.dart';
import 'package:mvbtummaplikasi/app/modules/materi/views/materi_view.dart';
import 'package:mvbtummaplikasi/app/modules/karya/bindings/karya_binding.dart';
import 'package:mvbtummaplikasi/app/modules/karya/views/karya_view.dart';
import 'package:mvbtummaplikasi/app/modules/tugas/bindings/tugas_binding.dart';
import 'package:mvbtummaplikasi/app/modules/tugas/views/tugas_view.dart';
import 'package:mvbtummaplikasi/app/modules/nilai/bindings/nilai_binding.dart';
import 'package:mvbtummaplikasi/app/modules/nilai/views/nilai_view.dart';
import 'package:mvbtummaplikasi/app/modules/profile/bindings/profile_binding.dart';
import 'package:mvbtummaplikasi/app/modules/profile/views/profile_view.dart';
import 'app_routes.dart';
import 'package:mvbtummaplikasi/app/modules/splash/bindings/splash_binding.dart';
import 'package:mvbtummaplikasi/app/modules/splash/views/splash_view.dart';
import 'package:mvbtummaplikasi/app/modules/welcome/views/welcome_view.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.welcome,
      page: () => const WelcomeView(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: Routes.main,
      page: () => const NavigationView(),
      binding: NavigationBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.materi,
      page: () => const MateriView(),
      binding: MateriBinding(),
    ),
    GetPage(
      name: Routes.tugas,
      page: () => const TugasView(),
      binding: TugasBinding(),
    ),
    GetPage(
      name: Routes.nilai,
      page: () => const NilaiView(),
      binding: NilaiBinding(),
    ),
    GetPage(
      name: Routes.karya,
      page: () => const KaryaView(),
      binding: KaryaBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
  ];
}
