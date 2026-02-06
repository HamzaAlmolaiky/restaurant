// file: bindings/order_binding.dart
import 'package:get/get.dart';

import '../../CustomerPayments/services/customer_payment_service.dart';
import '../../Customers/services/customer_service.dart';
import '../controllers/order_controller.dart';
import '../services/order_service.dart';
// ... استيراد الملفات ...

class OrderBinding extends Bindings {
  @override
  void dependencies() {
    // يجب تسجيل الخدمات التي تعتمد عليها خدمة الطلبات أولاً
    Get.lazyPut<CustomerService>(() => CustomerService.instance);
    Get.lazyPut<CustomerPaymentService>(() => CustomerPaymentService.instance);

    // ثم تسجيل خدمة الطلبات
    Get.lazyPut<OrderService>(() => OrderService(Get.find(), Get.find()));

    // وأخيراً تسجيل الكنترولر
    Get.lazyPut<OrderController>(() => OrderController(Get.find()));
  }
}
