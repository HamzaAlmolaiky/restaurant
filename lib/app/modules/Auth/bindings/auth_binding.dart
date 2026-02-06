import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Service first
    Get.put<AuthService>(AuthService(), permanent: true);
    // Then controller
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}
