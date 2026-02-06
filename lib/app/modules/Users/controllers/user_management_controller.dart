// file: controllers/user_management_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserManagementController extends GetxController {
  final UserService _userService = UserService.instance;

  /// القوائم التفاعلية
  var users = <UserModel>[].obs;
  var filteredUsers = <UserModel>[].obs;
  var isLoading = false.obs;

  /// الفلاتر
  var searchQuery = ''.obs;
  var selectedRole = 'الكل'.obs;
  var selectedStatus = 'الكل'.obs;

  /// إحصائيات عرض بسيطة مشتقة من البيانات
  var totalUsers = 0.obs;
  var activeUsersCount = 0.obs;
  var adminCount = 0.obs;
  var lastLoginText = '-'.obs;

  /// لا نملك حقل آخر دخول حالياً

  /// قوائم الفلاتر
  final roles = ['الكل', 'مشرف', 'كاشير', 'موظف'];
  final statuses = ['الكل', 'نشط', 'غير نشط'];

  @override
  void onInit() {
    super.onInit();
    fetchAllUsers();

    /// مراقبة تغييرات البحث والفلاتر
    ever(searchQuery, (_) => filterUsers());
    ever(selectedRole, (_) => filterUsers());
    ever(selectedStatus, (_) => filterUsers());
  }

  /// جلب جميع المستخدمين
  Future<void> fetchAllUsers() async {
    try {
      isLoading.value = true;
      final result = await _userService.getAllUsers();
      users.assignAll(result);
      _recalculateStats();
      filterUsers();
    } catch (e) {
      print("خطاء في جلب المستخدمين: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _recalculateStats() {
    totalUsers.value = users.length;
    activeUsersCount.value = users.where((u) => u.isActive).length;
    adminCount.value = users.where((u) => u.role == 'مشرف').length;

    /// لا تتوفر لدينا معلومات آخر تسجيل دخول في النموذج الحالي
    lastLoginText.value = activeUsersCount.value > 0 ? 'متاح' : '-';
  }

  /// إضافة مستخدم جديد
  Future<void> addUser(UserModel user) async {
    try {
      isLoading.value = true;
      final ok = await _userService.addUser(user);
      if (ok) {
        await fetchAllUsers();
      }
    } catch (e) {
      print("خطاء في إضافة المستخدم: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات مستخدم
  Future<void> updateUser(UserModel user) async {
    try {
      isLoading.value = true;
      final ok = await _userService.updateUser(user);
      if (ok) {
        await fetchAllUsers();
      }
    } catch (e) {
      print("خطاء في تحديث المستخدم: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف مستخدم
  Future<void> deleteUser(int id) async {
    try {
      isLoading.value = true;
      final ok = await _userService.deleteUser(id);
      if (ok) {
        await fetchAllUsers();
      }
    } catch (e) {
      print("خطاء في حذف المستخدم: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// تفعيل/إلغاء تفعيل مستخدم
  Future<void> toggleUserStatus(int userId, bool isActive) async {
    try {
      final ok = await _userService.toggleUserStatus(userId, isActive);
      if (ok) {
        await fetchAllUsers();
      }
    } catch (e) {
      print("خطاء في تفعيل/إلغاء تفعيل المستخدم: $e");
    }
  }

  /// تغيير كلمة المرور
  Future<void> changePassword(int userId, String newPassword) async {
    try {
      await _userService.changePassword(userId, newPassword);
    } catch (e) {
      print("خطاء في تغيير كلمة المرور: $e");
    }
  }

  /// البحث
  void searchUsers(String query) {
    searchQuery.value = query;
  }

  /// الفلترة
  void updateRoleFilter(String role) {
    selectedRole.value = role;
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
  }

  /// إعادة تعيين الفلاتر
  void resetFilters() {
    searchQuery.value = '';
    selectedRole.value = 'كاشير';
    selectedStatus.value = 'الكل';
  }

  /// تطبيق الفلاتر على القائمة
  void filterUsers() {
    var filtered = users.toList();

    /// البحث
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((u) {
        return u.username.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q);
      }).toList();
    }

    /// فلتر الدور
    if (selectedRole.value != 'الكل') {
      filtered = filtered.where((u) => u.role == selectedRole.value).toList();
    }

    /// فلتر الحالة
    if (selectedStatus.value != 'الكل') {
      final wantActive = selectedStatus.value == 'نشط';
      filtered = filtered.where((u) => u.isActive == wantActive).toList();
    }
    filteredUsers.assignAll(filtered);
  }
}
