// file: bindings/return_binding.dart
import 'package:get/get.dart';
import '../../Customers/services/customer_service.dart';
import '../../Expenses/services/expense_service.dart';
import '../controllers/return_controller.dart';
import '../services/return_service.dart';

class ReturnBinding extends Bindings {
  @override
  void dependencies() {
    // تسجيل الخدمات التي تعتمد عليها خدمة المرتجعات
    // GetX ذكي بما فيه الكفاية لاستخدام النسخ المسجلة بالفعل
    Get.lazyPut<CustomerService>(() => CustomerService.instance);
    Get.lazyPut<ExpenseService>(() => ExpenseService.instance);
    // AuthService يجب أن يكون مسجلاً كـ permanent في مكان آخر (مثل AuthBinding)

    // تسجيل خدمة المرتجعات
    Get.lazyPut<ReturnService>(() => ReturnService(Get.find(), Get.find()));

    // تسجيل الكنترولر
    Get.lazyPut<ReturnController>(() => ReturnController());
  }
}
