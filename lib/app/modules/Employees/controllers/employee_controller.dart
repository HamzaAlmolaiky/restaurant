// file: controllers/employee_controller.dart

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:flutter/material.dart';

// Import Services
import '../../../helpers/database_helper.dart';
import '../services/employee_service.dart';

// Import Models
import '../models/employee_model.dart';

// Import Dialogs
import '../../../helpers/app_dialogs.dart';

/// Controller لإدارة عمليات الموظفين
/// يستخدم هذا الملف للتعامل مع عمليات الموظفين، بما في ذلك جلب البيانات وإضافة وتحديث وحذف الموظفين.
/// يستخدم Rx لتتبع الحالة والتحديثات المتزامنة.
/// يستخدم GetX لتعامل مع الحالة والتحديثات المتزامنة.
class EmployeeController extends GetxController {
  // Services
  final EmployeeService _employeeService = EmployeeService.instance;

  // Observable variables
  var isLoading = false.obs;
  var employees = <EmployeeModel>[].obs;
  var filteredEmployees = <EmployeeModel>[].obs;
  var searchQuery = ''.obs;
  var selectedDepartment = 'الكل'.obs;
  var selectedStatus = 'الكل'.obs;
  // Header statistics (reactive)
  var totalEmployees = 0.obs;
  var presentToday = 0.obs;
  var lateCount = 0.obs;
  var onLeaveCount = 0.obs;

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final positionController = TextEditingController();
  final departmentController = TextEditingController();
  final salaryController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadEmployeesFromDB();
  }

  /// جلب جميع الموظفين من قاعدة البيانات
  /// يجلب جميع الموظفين من قاعدة البيانات وتخزنها في قايمة `employees`.
  /// يستخدم `isLoading` لتتبع حالة جلب الموظفين.
  /// يستخدم `AppDialogs.show` لعرض رسائل النجاح أو الأخطاء.
  Future<void> loadEmployeesFromDB() async {
    try {
      isLoading.value = true;
      final dbEmployees = await _employeeService.getAllEmployees();
      final employeeModels = dbEmployees
          .map((employeeMap) => EmployeeModel.fromMap(employeeMap))
          .toList();
      employees.assignAll(employeeModels);
      filteredEmployees.assignAll(employeeModels);
      _recomputeStats();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحميل الموظفين من قاعدة البيانات');
    } finally {
      isLoading.value = false;
    }
  }

  /// إضافة موظف جديد
  /// يتحقق من صحة بيانات الموظف قبل الإضافة.
  /// يستخدم `isLoading` لتتبع حالة الإضافة.
  /// يستخدم `AppDialogs.show` لعرض رسائل النجاح أو الأخطاء.
  Future<void> addEmployee() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final newEmployee = EmployeeModel(
        name: nameController.text,
        phoneNumber: phoneController.text,
        position: positionController.text,
        // department: departmentController.text,
        basicSalary: double.tryParse(salaryController.text) ?? 0.0,
        hireDate: DateTime.now(),
        isActive: true,
      );

      final success = await _employeeService.addEmployee(newEmployee);

      if (success) {
        Get.back();
        _clearForm();
        await loadEmployeesFromDB();
        AppDialogs.show('نجح', 'تم إضافة الموظف بنجاح');
      } else {
        AppDialogs.show('خطأ', 'فشل في إضافة الموظف');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء إضافة الموظف');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات الموظف
  /// يتحقق من صحة بيانات الموظف قبل التحديث.
  /// يستخدم `isLoading` لتتبع حالة التحديث.
  /// يستخدم `AppDialogs.show` لعرض رسائل النجاح أو الأخطاء.
  Future<bool> updateEmployee(
    int employeeId,
    Map<String, dynamic> employeeData,
  ) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // إزالة EmployeeID من البيانات المحدثة لتجنب تعديله
      employeeData.remove('EmployeeID');

      final rowsAffected = await db.update(
        'Employees',
        employeeData,
        where: 'EmployeeID = ?',
        whereArgs: [employeeId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('خطأ في تحديث الموظف: $e');
      return false;
    }
  }

  /// حذف موظف
  /// يتحقق من صحة معرف الموظف قبل الحذف.
  /// يستخدم `AppDialogs.show` لعرض رسائل النجاح أو الأخطاء.
  Future<void> deleteEmployee(int employeeId) async {
    try {
      final success = await _employeeService.deleteEmployee(employeeId);

      if (success) {
        await loadEmployeesFromDB();
        AppDialogs.show('نجح', 'تم حذف الموظف بنجاح');
      } else {
        AppDialogs.show('خطأ', 'فشل في حذف الموظف');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء حذف الموظف');
    }
  }

  /// البحث عن موظفين
  /// يستخدم `searchQuery` للبحث عن موظفين.
  void searchEmployees(String query) {
    searchQuery.value = query;
    _filterEmployees();
  }

  /// تصفية الموظفين حسب القسم
  /// يستخدم `selectedDepartment` لتصفية الموظفين حسب القسم.
  void filterByDepartment(String department) {
    selectedDepartment.value = department;
    _filterEmployees();
  }

  /// تصفية الموظفين حسب الحالة
  /// يستخدم `selectedStatus` لتصفية الموظفين حسب الحالة.
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _filterEmployees();
  }

  /// تصفية الموظفين حسب البحث والقسم والحالة
  void _filterEmployees() {
    var filtered = employees.where((employee) {
      final matchesSearch =
          employee.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          employee.phoneNumber!.contains(searchQuery.value);

      // final matchesDepartment = selectedDepartment.value == 'الكل' ||
      //     employee.department == selectedDepartment.value;

      final matchesStatus =
          selectedStatus.value == 'الكل' ||
          (selectedStatus.value == 'نشط' && employee.isActive) ||
          (selectedStatus.value == 'غير نشط' && !employee.isActive);

      return matchesSearch && matchesStatus;
    }).toList();

    filteredEmployees.assignAll(filtered);
    _recomputeStats();
  }

  /// تعبئة النموذج للتعديل
  /// يستخدم `fillFormForEdit` لتعبئة النموذج للتعديل.
  void fillFormForEdit(EmployeeModel employee) {
    nameController.text = employee.name;
    phoneController.text = employee.phoneNumber!;
    positionController.text = employee.position;
    salaryController.text = employee.basicSalary.toString();
  }

  /// التحقق من صحة النموذج
  /// يستخدم `_validateForm` للتحقق من صحة النموذج.
  bool _validateForm() {
    if (nameController.text.isEmpty) {
      AppDialogs.show('خطأ', 'يرجى إدخال اسم الموظف');
      return false;
    }
    if (phoneController.text.isEmpty) {
      AppDialogs.show('خطأ', 'يرجى إدخال رقم الهاتف');
      return false;
    }
    if (positionController.text.isEmpty) {
      AppDialogs.show('خطأ', 'يرجى إدخال المنصب');
      return false;
    }
    return true;
  }

  /// إفراغ النموذج
  /// يستخدم `_clearForm` لإفراغ النموذج.
  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    positionController.clear();
    departmentController.clear();
    salaryController.clear();
  }

  /// recompute header stats from real data
  void _recomputeStats() {
    totalEmployees.value = employees.length;
    presentToday.value = employees.where((e) => e.isActive).length;
    lateCount.value = 0;
    onLeaveCount.value = 0;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    positionController.dispose();
    departmentController.dispose();
    salaryController.dispose();
    super.onClose();
  }
}
