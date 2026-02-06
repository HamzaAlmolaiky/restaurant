// file: bindings/customer_payment_binding.dart

import 'package:get/get.dart';
import '../../Customers/services/customer_service.dart';
import '../controllers/customer_payment_controller.dart';
import '../services/customer_payment_service.dart';

class CustomerPaymentBinding extends Bindings {
  @override
  void dependencies() {
    // تسجيل الخدمات التي نحتاجها كـ Singletons
    // GetX ذكي بما فيه الكفاية لعدم إعادة إنشاء خدمة إذا كانت مسجلة بالفعل
    Get.lazyPut<CustomerService>(() => CustomerService.instance);
    Get.lazyPut<CustomerPaymentService>(() => CustomerPaymentService.instance);

    // تسجيل الـ Controller وحقن الخدمات فيه
    Get.lazyPut<CustomerPaymentController>(() => CustomerPaymentController());
  }
}
