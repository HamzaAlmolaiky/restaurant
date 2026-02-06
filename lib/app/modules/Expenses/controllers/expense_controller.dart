// file: controllers/expense_controller.dart

import 'package:get/get.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../../../helpers/app_dialogs.dart';

class ExpenseController extends GetxController {
  final ExpenseService _expenseService;
  ExpenseController(this._expenseService);

  // حالة خاصة بوردية محددة
  var expensesForShift = <ExpenseModel>[].obs;
  var totalExpensesForShift = 0.0.obs;
  var isLoading = false.obs;

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
}
