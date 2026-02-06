// file: services/auth_service.dart
import 'package:get/get.dart';
import '../../../helpers/database_helper.dart';
import '../../Shift/models/shift_model.dart';
import '../../Shift/services/shift_service.dart';
import '../../Users/models/user_model.dart';

class AuthService extends GetxService {
  // بديل لـ: public static User CurrentUser
  final currentUser = Rx<UserModel?>(null);

  // بديل لـ: public static Shift CurrentShift
  final currentShift = Rx<ShiftModel?>(null);

  // بديل لـ: public static int CurrentShiftID
  int? get currentShiftId => currentShift.value?.shiftID;

  bool get isLoggedIn => currentUser.value != null;
  bool get isShiftOpen => currentShift.value != null;

  // عند تسجيل الدخول بنجاح، نقوم بتعبئة هذه المتغيرات
  Future<bool> login(String username, String password) async {
    final userFromDb = await _fetchUserFromDb(username, password);

    if (userFromDb != null) {
      currentUser.value = userFromDb;
      // بعد تسجيل الدخول، ابحث فوراً عن وردية مفتوحة لهذا المستخدم
      await _findOpenShift();
      return true;
    }
    return false;
  }

  // عند بدء وردية جديدة، نقوم بتحديث حالتها
  void startShift(ShiftModel shift) {
    currentShift.value = shift;
  }

  // عند إغلاق الوردية
  void closeShift() {
    currentShift.value = null;
  }

  void logout() {
    currentUser.value = null;
    currentShift.value = null;
  }

  /// البحث عن وردية مفتوحة للمستخدم الحالي
  /// إذا لم يكن هناك وردية مفتوحة، ستبقى currentShift فارغة
  Future<void> _findOpenShift() async {
    if (currentUser.value?.userID == null) return;
    final shiftService = Get.find<ShiftService>();
    final openShift = await shiftService.findOpenShiftForUser(
      currentUser.value!.userID!,
    );
    currentShift.value = openShift;
  }

  /// دالة مساعدة لجلب المستخدم من قاعدة البيانات
  /// التحقق من أن المستخدم نشط
  Future<UserModel?> _fetchUserFromDb(String u, String p) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Users',
      where: 'Username = ? AND Password = ? AND IsActive = 1',
      whereArgs: [u, p],
      limit: 1,
    );
    return maps.isNotEmpty ? UserModel.fromMap(maps.first) : null;
  }
}
