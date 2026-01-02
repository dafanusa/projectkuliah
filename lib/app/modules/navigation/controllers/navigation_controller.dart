import 'package:get/get.dart';

import '../../hasil/controllers/hasil_controller.dart';

class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.value = 0;
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    if (index == 3 && Get.isRegistered<HasilController>()) {
      Get.find<HasilController>().loadAll();
    }
  }

  void reset() {
    currentIndex.value = 0;
  }
}
