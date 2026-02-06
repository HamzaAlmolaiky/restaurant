// file: controllers/main_box_controller.dart

import 'package:get/get.dart';
import '../models/main_box_transaction_model.dart';
import '../services/main_box_service.dart';
import '../../Auth/services/auth_service.dart';
import '../../../helpers/app_dialogs.dart';

class MainBoxTransactionController extends GetxController {
  final MainBoxService _mainBoxService;
  MainBoxTransactionController(this._mainBoxService);

  var transactions = <MainBoxTransactionModel>[].obs;
  var currentBalance = 0.0.obs;
  var isLoading = false.obs;
  // Dashboard stats
  var todayRevenue = 0.0.obs; // مجموع AmountIn لليوم
  var todayExpenses = 0.0.obs; // مجموع AmountOut لليوم
  var todayTransactionsCount = 0.obs; // عدد معاملات اليوم
  var lastUpdate = Rxn<DateTime>();
  var selectedType = 'الكل'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentBalance();
    fetchDashboardStats();
    // تحميل معاملات اليوم افتراضياً
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day);
    fetchFilteredTransactions(from, to, transactionType: selectedType.value);
  }

  Future<void> fetchCurrentBalance() async {
    try {
      currentBalance.value = await _mainBoxService.getLastBalance();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب رصيد الخزنة');
    }
  }

  /// يجلب إحصائيات اليوم من قاعدة البيانات ويحدّث آخر وقت تحديث.
  Future<void> fetchDashboardStats() async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(now.year, now.month, now.day);
      final list = await _mainBoxService.getTransactions(
        from,
        to,
        transactionType: 'الكل',
      );
      double revenue = 0.0;
      double expenses = 0.0;
      for (final t in list) {
        revenue += t.amountIn;
        expenses += t.amountOut;
      }
      todayRevenue.value = revenue;
      todayExpenses.value = expenses;
      todayTransactionsCount.value = list.length;
      lastUpdate.value = await _mainBoxService.getLastTransactionDate();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب إحصائيات الصندوق: ${e.toString()}');
    }
  }

  Future<void> createTransaction({
    required String transactionType,
    required double amount,
    required bool isDeposit,
    String? description,
    int? userId,
    int? referenceId,
  }) async {
    // التحقق من المدخلات
    if (transactionType.trim().isEmpty || amount <= 0) {
      AppDialogs.show('خطأ', 'البيانات المدخلة غير صالحة');
      return;
    }

    try {
      isLoading.value = true;
      // احصل على userId من AuthService إن لم يُمرَّر
      final auth = Get.isRegistered<AuthService>()
          ? Get.find<AuthService>()
          : null;
      final uid = userId ?? auth?.currentUser.value?.userID;

      bool success = false;
      switch (transactionType) {
        case 'إيداع':
          success = await _mainBoxService.addDeposit(
            amount: amount,
            userId: uid,
            description: description,
            referenceId: referenceId,
          );
          break;
        case 'سحب':
          success = await _mainBoxService.addWithdrawal(
            amount: amount,
            userId: uid,
            description: description,
            referenceId: referenceId,
          );
          break;
        case 'مصروف':
          success = await _mainBoxService.addExpense(
            amount: amount,
            userId: uid,
            description: description,
            expenseId: referenceId,
          );
          break;
        case 'تحويل':
          if (isDeposit) {
            success = await _mainBoxService.addTransferIn(
              amount: amount,
              userId: uid,
              description: description,
              referenceId: referenceId,
            );
          } else {
            success = await _mainBoxService.addTransferOut(
              amount: amount,
              userId: uid,
              description: description,
              referenceId: referenceId,
            );
          }
          break;
        case 'مبيعات':
          success = await _mainBoxService.addSales(
            amount: amount,
            userId: uid,
            orderId: referenceId,
            description: description,
          );
          break;
        case 'فتح وردية':
          success = await _mainBoxService.addShiftOpen(
            amount: amount,
            userId: uid,
            shiftId: referenceId,
            description: description,
          );
          break;
        default:
          // مسار احتياطي: استخدام الدالة العامة مع isDeposit
          success = await _mainBoxService.addTransaction(
            transactionType: transactionType,
            amount: amount,
            isDeposit: isDeposit,
            description: description,
            userId: uid,
            referenceId: referenceId,
          );
      }

      if (success) {
        AppDialogs.show('نجاح', 'تم تسجيل الحركة بنجاح');
        // تحديث الرصيد والحركات المعروضة
        await fetchCurrentBalance();
        await fetchDashboardStats();
        // إعادة تحميل معاملات اليوم وفق الفلتر الحالي
        final now = DateTime.now();
        final from = DateTime(now.year, now.month, now.day);
        final to = DateTime(now.year, now.month, now.day);
        await fetchFilteredTransactions(
          from,
          to,
          transactionType: selectedType.value,
        );
        // يمكنك هنا استدعاء دالة لجلب آخر الحركات إذا كانت الشاشة تعرضها
        // await fetchFilteredTransactions(...);
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية تسجيل الحركة');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFilteredTransactions(
    DateTime fromDate,
    DateTime toDate, {
    String transactionType = "الكل",
  }) async {
    if (fromDate.isAfter(toDate)) {
      AppDialogs.show('خطأ', 'تاريخ البداية لا يمكن أن يكون بعد تاريخ النهاية');
      return;
    }

    try {
      isLoading.value = true;
      final result = await _mainBoxService.getTransactions(
        fromDate,
        toDate,
        transactionType: transactionType,
      );
      transactions.assignAll(result);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل جلب سجل الحركات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تغيير نوع الفلتر وإعادة تحميل معاملات اليوم
  Future<void> changeTypeFilter(String type) async {
    selectedType.value = type;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day);
    await fetchFilteredTransactions(from, to, transactionType: type);
  }

  /// إعادة تحميل البيانات
  // ignore: annotate_overrides
  Future<void> refresh() async {
    await fetchCurrentBalance();
    await fetchDashboardStats();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day);
    await fetchFilteredTransactions(
      from,
      to,
      transactionType: selectedType.value,
    );
  }

  // ===============================
  // Read / Update / Delete helpers
  // ===============================

  Future<MainBoxTransactionModel?> getTransactionById(int id) async {
    try {
      return await _mainBoxService.getById(id);
    } catch (e) {
      AppDialogs.show('خطأ', 'تعذر جلب تفاصيل المعاملة');
      return null;
    }
  }

  Future<bool> updateTransactionMeta({
    required int id,
    String? description,
    String? transactionType,
  }) async {
    try {
      final ok = await _mainBoxService.updateTransactionDescriptionAndType(
        transactionId: id,
        description: description,
        transactionType: transactionType,
      );
      if (ok) {
        await refresh();
        AppDialogs.show('تم', 'تم تحديث بيانات المعاملة');
      } else {
        AppDialogs.show('خطأ', 'فشل تحديث بيانات المعاملة');
      }
      return ok;
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء التحديث: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateTransactionAmounts({
    required int id,
    double? amountIn,
    double? amountOut,
    String? description,
  }) async {
    try {
      final isDeposit = (amountIn ?? 0) > 0;
      final amount = amountIn ?? amountOut ?? 0.0;
      final ok = await _mainBoxService.updateTransactionAmount(
        transactionId: id,
        amount: amount,
        isDeposit: isDeposit,
      );
      if (ok) {
        await refresh();
        AppDialogs.show('تم', 'تم تحديث مبالغ المعاملة');
      } else {
        AppDialogs.show('خطأ', 'فشل تحديث مبالغ المعاملة');
      }
      return ok;
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء التحديث: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final ok = await _mainBoxService.deleteTransaction(id);
      if (ok) {
        await refresh();
        AppDialogs.show('تم', 'تم حذف المعاملة بنجاح');
      } else {
        AppDialogs.show('خطأ', 'فشل حذف المعاملة');
      }
      return ok;
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء الحذف: ${e.toString()}');
      return false;
    }
  }
}
