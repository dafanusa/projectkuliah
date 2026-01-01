import 'package:get/get.dart';

import '../modules/navigation/bindings/navigation_binding.dart';
import '../modules/navigation/views/navigation_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/materi/bindings/materi_binding.dart';
import '../modules/materi/views/materi_view.dart';
import '../modules/tugas/bindings/tugas_binding.dart';
import '../modules/tugas/views/tugas_view.dart';
import '../modules/hasil/bindings/hasil_binding.dart';
import '../modules/hasil/views/hasil_view.dart';
import '../modules/nilai/bindings/nilai_binding.dart';
import '../modules/nilai/views/nilai_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
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
      name: Routes.hasil,
      page: () => const HasilView(),
      binding: HasilBinding(),
    ),
    GetPage(
      name: Routes.nilai,
      page: () => const NilaiView(),
      binding: NilaiBinding(),
    ),
  ];
}
