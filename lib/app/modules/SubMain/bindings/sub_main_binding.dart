import 'package:get/get.dart';

import '../controllers/sub_main_controller.dart';

class SubMainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubMainController>(
      () => SubMainController(),
    );
  }
}
