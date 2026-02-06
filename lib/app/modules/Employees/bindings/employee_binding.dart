// file: bindings/employee_binding.dart

import 'package:get/get.dart';
import '../controllers/employee_controller.dart';
import '../services/employee_service.dart';

class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeService>(() => EmployeeService.instance);
    Get.lazyPut<EmployeeController>(() => EmployeeController());
  }
}
