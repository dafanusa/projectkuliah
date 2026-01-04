import 'package:get/get.dart';

import '../../home/controllers/home_controller.dart';
import '../../materi/controllers/materi_controller.dart';
import '../../tugas/controllers/tugas_controller.dart';
import '../../hasil/controllers/hasil_controller.dart';
import '../../karya/controllers/karya_controller.dart';
import '../../nilai/controllers/nilai_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../classes/controllers/classes_controller.dart';
import '../../ujian/controllers/ujian_controller.dart';
import '../controllers/navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MateriController>(() => MateriController());
    Get.lazyPut<KaryaController>(() => KaryaController());
    Get.lazyPut<TugasController>(() => TugasController());
    Get.lazyPut<UjianController>(() => UjianController());
    Get.lazyPut<HasilController>(() => HasilController());
    Get.lazyPut<NilaiController>(() => NilaiController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<ClassesController>(() => ClassesController());
  }
}
