// file: controllers/auth_controller.dart
import 'package:get/get.dart';
import '../../Auth/services/auth_service.dart';
import '../../../helpers/app_dialogs.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find(); // الحصول على خدمة المصادقة
  var isLoading = false.obs;

  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      final success = await _authService.login(username, password);
      if (success) {
        Get.offAllNamed(
          '/home',
        ); // الانتقال للشاشة الرئيسية وإلغاء كل الشاشات السابقة
      } else {
        AppDialogs.show('خطأ', 'اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _authService.logout();
    Get.offAllNamed('/login'); // الانتقال لشاشة تسجيل الدخول
  }
}
