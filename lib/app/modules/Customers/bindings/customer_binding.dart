// file: bindings/customer_binding.dart

import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../services/customer_service.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    // تسجيل الخدمة (Service) كـ Singleton
    Get.lazyPut<CustomerService>(() => CustomerService.instance);

    // تسجيل الـ Controller
    // سيتم إنشاء نسخة جديدة منه في كل مرة نحتاجه فيها
    Get.lazyPut<CustomerController>(() => CustomerController());
  }
}
