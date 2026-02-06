// file: bindings/main_box_binding.dart

import 'package:get/get.dart';
import '../controllers/main_box_transaction_controller.dart';
import '../services/main_box_service.dart';

class MainBoxTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainBoxService>(() => MainBoxService.instance);
    Get.lazyPut<MainBoxTransactionController>(
        () => MainBoxTransactionController(Get.find()));
  }
}
