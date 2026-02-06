// file: bindings/shift_binding.dart
import 'package:get/get.dart';
import '../../Auth/services/auth_service.dart';
import '../controllers/shift_controller.dart';

class ShiftBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShiftController>(
      () => ShiftController(Get.find(), Get.find<AuthService>()),
    );
  }
}
