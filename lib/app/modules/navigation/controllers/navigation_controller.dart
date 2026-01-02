import 'package:get/get.dart';


class NavigationController extends GetxController {
  final currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentIndex.value = 0;
  }

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void reset() {
    currentIndex.value = 0;
  }
}
