import 'package:get/get.dart';

import '../controllers/karya_controller.dart';

class KaryaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KaryaController>(() => KaryaController());
  }
}
