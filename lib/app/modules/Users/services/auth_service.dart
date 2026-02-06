// file: services/auth_service.dart (تذكير)
import 'package:get/get.dart';
import '../../Shift/models/shift_model.dart';
import '../../Shift/services/shift_service.dart';
import '../models/user_model.dart';

class AuthServices extends GetxService {
  // بديل لـ: public static User CurrentUser
  final currentUser = Rx<UserModel?>(null);

  // بديل لـ: public static Shift CurrentShift
  final currentShift = Rx<ShiftModel?>(null);

  // بديل لـ: public static int CurrentShiftID
  int? get currentShiftId => currentShift.value?.shiftID;

  bool get isLoggedIn => currentUser.value != null;
  bool get isShiftOpen => currentShift.value != null;

  /// عند تسجيل الدخول بنجاح، نقوم بتعبئة هذه المتغيرات
  Future<bool> login(String username, String password) async {
    // ... منطق جلب المستخدم من قاعدة البيانات ...
    final userFromDb = await _fetchUserFromDb(username, password);

    if (userFromDb != null) {
      currentUser.value = userFromDb;
      // بعد تسجيل الدخول، ابحث فوراً عن وردية مفتوحة لهذا المستخدم
      await _findOpenShift();
      return true;
    }
    return false;
  }

  /// عند بدء وردية جديدة، نقوم بتحديث حالتها
  void startShift(ShiftModel shift) {
    currentShift.value = shift;
  }

  /// عند إغلاق الوردية
  void closeShift() {
    currentShift.value = null;
  }

  void logout() {
    currentUser.value = null;
    currentShift.value = null;
  }

  Future<void> _findOpenShift() async {
    // استدعاء ShiftService للبحث عن وردية مفتوحة للمستخدم الحالي
    final shiftService = Get.find<ShiftService>();
    currentShift.value = await shiftService.findOpenShiftForUser(
      currentUser.value!.userID!,
    );
  }

  /// محاكاة جلب المستخدم من قاعدة البيانات
  Future<UserModel?> _fetchUserFromDb(String u, String p) async {
    return null;
  }
}
