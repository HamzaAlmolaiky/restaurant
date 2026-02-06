// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Users/models/user_model.dart';
import '../../Users/services/user_service.dart';
import '../services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../../../helpers/app_dialogs.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // Observable variables
  var isLoading = false.obs;
  var currentUser = Rxn<UserModel>();
  var isLoggedIn = false.obs;
  var activeUsers = <UserModel>[].obs;
  var allUsers = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveUsers();
    loadAllUsers();
  }

  /// جلب كل المستخدمين من قاعدة البيانات
  Future<void> loadAllUsers() async {
    try {
      isLoading.value = true;
      final users = await UserService.instance.getAllUsers();
      allUsers.assignAll(users);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب المستخدمين: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب المستخدمين النشطين من قاعدة البيانات
  Future<void> loadActiveUsers() async {
    try {
      isLoading.value = true;
      final users = await UserService.instance.getActiveUsers();
      activeUsers.assignAll(users);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب المستخدمين: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الدخول
  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;

      final success = await _authService.login(username, password);

      if (success) {
        currentUser.value = _authService.currentUser.value;
        isLoggedIn.value = true;
        final role = currentUser.value?.role.toLowerCase();
        if (role == 'مشرف') {
          Get.offAllNamed(Routes.HOME);
        } else {
          Get.offAllNamed(Routes.CASH_DRAWER_SETUP);
        }
      } else {
        AlertDialog(
          title: const Text('خطأ في تسجيل الدخول'),
          content: const Text('اسم المستخدم أو كلمة المرور غير صحيحة.'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('حسناً')),
          ],
        );
        print('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      AlertDialog(
        title: const Text('خطأ في تسجيل الدخول'),
        content: Text('حدث خطأ أثناء تسجيل الدخول: ${e.toString()}'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('حسناً')),
        ],
      );
      print('خطأ أثناء تسجيل الدخول: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      _authService.logout();
      currentUser.value = null;
      isLoggedIn.value = false;
      Get.offAllNamed('/auth');

      AppDialogs.show('نجاح', 'تم تسجيل الخروج بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تسجيل الخروج: ${e.toString()}');
    }
  }

  /// التحقق من الصلاحيات
  bool hasPermission(String permission) {
    final user = currentUser.value;
    if (user == null) return false;

    if (user.role.toLowerCase() == 'مشرف') return true;

    switch (permission) {
      case 'returns':
        return user.canProcessReturns;
      case 'expenses':
        return user.canProcessExpenses;
      case 'payments':
        return user.canReceivePayments;
      default:
        return false;
    }
  }

  /// الحصول على المستخدم الحالي
  UserModel? getCurrentUser() {
    return currentUser.value;
  }

  /// التحقق من حالة تسجيل الدخول
  bool get isUserLoggedIn => isLoggedIn.value;

  /// الحصول على دور المستخدم الحالي
  String? getCurrentUserRole() {
    return currentUser.value?.role;
  }

  /// تحديث البيانات
  Future<void> refreshData() async {
    await loadActiveUsers();
    await loadAllUsers();
  }
}
