// file: bindings/supplier_binding.dart
import 'package:get/get.dart';
import '../controllers/supplier_controller.dart';

class SupplierBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupplierController>()) {
      Get.lazyPut<SupplierController>(() => SupplierController(Get.find()), fenix: true);
    }
  }
}
