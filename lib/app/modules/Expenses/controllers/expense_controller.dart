// file: controllers/expense_controller.dart

import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../../../helpers/app_dialogs.dart';

import '../../Shift/controllers/shift_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseService _expenseService;
  ExpenseController(this._expenseService);

  @override
  void onInit() {
    super.onInit();
    try {
      final shiftCtrl = Get.find<ShiftController>();
      final shiftId = shiftCtrl.currentOpenShift.value?.shiftID ?? 1;
      fetchShiftExpenses(shiftId);
    } catch (e) {
      // إذا لم يكن ShiftController جاهزاً، نجلب للوردية الافتراضية 1
      fetchShiftExpenses(1);
    }
  }

  // حالة خاصة بوردية محددة
  var expensesForShift = <ExpenseModel>[].obs;
  var totalExpensesForShift = 0.0.obs;
  var isLoading = false.obs;

  // متغيرات الفلترة
  var searchQuery = ''.obs;
  var categoryFilter = 'جميع الفئات'.obs;
  var statusFilter = 'جميع الحالات'.obs;
  var dateFilter = 'جميع التواريخ'.obs;

  /// القائمة المفلترة (computed)
  List<ExpenseModel> get filteredExpenses {
    final q = searchQuery.value.trim().toLowerCase();
    final cat = categoryFilter.value;
    final date = dateFilter.value;
    final now = DateTime.now();

    return expensesForShift.where((exp) {
      // فلتر البحث
      final matchSearch = q.isEmpty ||
          (exp.description ?? '').toLowerCase().contains(q) ||
          (exp.expenseType ?? '').toLowerCase().contains(q);

      // فلتر الفئة
      final matchCat = cat == 'جميع الفئات' ||
          (exp.expenseType ?? 'أخرى') == cat;

      // فلتر التاريخ
      bool matchDate = true;
      if (date == 'اليوم') {
        matchDate = exp.expenseDate.year == now.year &&
            exp.expenseDate.month == now.month &&
            exp.expenseDate.day == now.day;
      } else if (date == 'أمس') {
        final yesterday = now.subtract(const Duration(days: 1));
        matchDate = exp.expenseDate.year == yesterday.year &&
            exp.expenseDate.month == yesterday.month &&
            exp.expenseDate.day == yesterday.day;
      } else if (date == 'هذا الأسبوع') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        matchDate = exp.expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)));
      } else if (date == 'هذا الشهر') {
        matchDate = exp.expenseDate.year == now.year &&
            exp.expenseDate.month == now.month;
      }

      return matchSearch && matchCat && matchDate;
    }).toList();
  }

  // إحصائيات ديناميكية للترويسة
  double get totalAmount => filteredExpenses.fold(0, (s, e) => s + e.amount);
  double get avgDaily {
    if (filteredExpenses.isEmpty) return 0;
    final dates = filteredExpenses.map((e) => e.expenseDate.day).toSet();
    return totalAmount / dates.length;
  }
  double get maxExpense => filteredExpenses.isEmpty
      ? 0
      : filteredExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

  // دالة لجلب كل بيانات الوردية
  Future<void> fetchShiftExpenses(int shiftId) async {
    try {
      isLoading.value = true;
      // جلب القائمة والإجمالي معاً
      final expensesList = await _expenseService.getExpensesForShift(shiftId);
      final total = await _expenseService.getTotalExpensesForShift(shiftId);

      expensesForShift.assignAll(expensesList);
      totalExpensesForShift.value = total;
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب بيانات مصروفات الوردية');
    } finally {
      isLoading.value = false;
    }
  }

  // إضافة مصروف (مع المنطق المعقد)
  Future<void> addExpense(ExpenseModel expense, int currentShiftId) async {
    if (expense.amount <= 0) {
      AppDialogs.show('خطأ', 'المبلغ يجب أن يكون أكبر من صفر');
      return;
    }

    try {
      isLoading.value = true;
      // استخدام الدالة المعقدة التي تفحص رقم الوردية
      final success = await _expenseService.addExpenseComplex(expense);
      if (success) {
        AppDialogs.show('نجاح', 'تم تسجيل المصروف بنجاح');
        // تحديث بيانات الوردية الحالية فقط إذا كان المصروف يخصها
        if (expense.shiftID == currentShiftId) {
          await fetchShiftExpenses(currentShiftId);
        }
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية تسجيل المصروف');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث مصروف
  Future<void> updateExpense(ExpenseModel expense, int currentShiftId) async {
    if (expense.amount <= 0) {
      AppDialogs.show('خطأ', 'المبلغ يجب أن يكون أكبر من صفر');
      return;
    }

    try {
      isLoading.value = true;
      final success = await _expenseService.updateExpense(expense);
      if (success) {
        AppDialogs.show('نجاح', 'تم تحديث المصروف بنجاح');
        await fetchShiftExpenses(currentShiftId);
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية تحديث المصروف');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // حذف مصروف
  Future<void> deleteExpense(int expenseId, int currentShiftId) async {
    try {
      isLoading.value = true;
      final success = await _expenseService.deleteExpense(expenseId);
      if (success) {
        AppDialogs.show('نجاح', 'تم حذف المصروف بنجاح');
        await fetchShiftExpenses(currentShiftId);
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية حذف المصروف');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
