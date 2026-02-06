// file: bindings/user_management_binding.dart
import 'package:get/get.dart';
import '../controllers/user_management_controller.dart';
import '../services/user_service.dart';

class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<UserService>(UserService.instance);
    Get.put<UserManagementController>(UserManagementController());
  }
}
