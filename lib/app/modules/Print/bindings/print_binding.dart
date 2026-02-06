import 'package:get/get.dart';

import '../controllers/print_controller.dart';

class PrintBinding extends Bindings {
  @override
  void dependencies() {
    Get.create<PrintController>(
      () => PrintController(),
    );
  }
}
