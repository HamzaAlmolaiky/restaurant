// file: bindings/expense_binding.dart

import 'package:get/get.dart';
import '../../MainBox/services/main_box_service.dart';
import '../controllers/expense_controller.dart';
import '../services/expense_service.dart';
// سنحتاج خدمة الخزنة لأن addExpenseComplex قد تستدعيها

class ExpenseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainBoxService>(() => MainBoxService.instance); // تأكيد وجودها
    Get.lazyPut<ExpenseService>(() => ExpenseService.instance);
    Get.lazyPut<ExpenseController>(() => ExpenseController(Get.find()));
  }
}
