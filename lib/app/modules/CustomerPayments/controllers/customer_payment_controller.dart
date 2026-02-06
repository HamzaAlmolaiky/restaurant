// file: controllers/customer_payment_controller.dart

// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables

import 'package:get/get.dart';
import '../services/customer_payment_service.dart';
import '../../../helpers/app_dialogs.dart';

class CustomerPaymentController extends GetxController {
  final CustomerPaymentService _paymentService =
      CustomerPaymentService.instance;

  var payments = <Map<String, dynamic>>[].obs;
  var filteredPayments = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedMethod = 'الكل'.obs;
  var selectedStatus = 'الكل'.obs;
  var paymentStats = <String, dynamic>{}.obs;

  // قوائم الفلاتر
  final paymentMethods = ['الكل', 'نقد', 'بطاقة ائتمان', 'تحويل بنكي', 'شيك'];
  final statuses = ['الكل', 'مكتمل', 'معلق', 'مرفوض'];

  var hasError;

  @override
  void onInit() {
    super.onInit();
    fetchAllPayments();
    fetchPaymentStats();

    // مراقبة تغييرات البحث والفلاتر
    ever(searchQuery, (_) => filterPayments());
    ever(selectedMethod, (_) => filterPayments());
    ever(selectedStatus, (_) => filterPayments());
  }

  /// جلب جميع المدفوعات
  Future<void> fetchAllPayments() async {
    try {
      isLoading.value = true;
      final result = await _paymentService.getAllPayments();
      payments.assignAll(result);
      filterPayments();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب بيانات المدفوعات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب إحصائيات المدفوعات
  Future<void> fetchPaymentStats() async {
    try {
      final stats = await _paymentService.getPaymentStats();
      paymentStats.assignAll(stats);
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  /// إضافة دفعة جديدة
  Future<void> addPayment(Map<String, dynamic> paymentData) async {
    try {
      isLoading.value = true;

      // إنشاء رقم دفعة تلقائي
      final paymentNumber = await _paymentService.generatePaymentNumber();
      paymentData['payment_number'] = paymentNumber;

      await _paymentService.addPayment(paymentData);
      await fetchAllPayments();
      await fetchPaymentStats();
      AppDialogs.show('نجح', 'تم إضافة الدفعة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إضافة الدفعة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات دفعة
  Future<void> updatePayment(int id, Map<String, dynamic> paymentData) async {
    try {
      isLoading.value = true;
      await _paymentService.updatePayment(id, paymentData);
      await fetchAllPayments();
      await fetchPaymentStats();
      AppDialogs.show('نجح', 'تم تحديث بيانات الدفعة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحديث الدفعة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف دفعة
  Future<void> deletePayment(int id) async {
    try {
      isLoading.value = true;
      await _paymentService.deletePayment(id);
      await fetchAllPayments();
      await fetchPaymentStats();
      AppDialogs.show('نجح', 'تم حذف الدفعة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حذف الدفعة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// معالجة دفعة (تأكيد أو رفض)
  Future<void> processPayment(int id, String status, String? notes) async {
    try {
      isLoading.value = true;
      await _paymentService.processPayment(id, status, notes);
      await fetchAllPayments();
      await fetchPaymentStats();

      String message = '';
      switch (status) {
        case 'مكتمل':
          message = 'تم تأكيد الدفعة بنجاح';
          break;
        case 'مرفوض':
          message = 'تم رفض الدفعة';
          break;
        default:
          message = 'تم تحديث حالة الدفعة';
      }

      AppDialogs.show('نجح', message);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في معالجة الدفعة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث حالة الدفعة
  Future<void> updatePaymentStatus(int id, String status) async {
    try {
      await _paymentService.updatePaymentStatus(id, status);
      await fetchAllPayments();
      await fetchPaymentStats();
      AppDialogs.show('نجح', 'تم تحديث حالة الدفعة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحديث حالة الدفعة: $e');
    }
  }

  /// الحصول على مدفوعات عميل معين
  Future<List<Map<String, dynamic>>> getCustomerPayments(int customerId) async {
    try {
      return await _paymentService.getCustomerPayments(customerId);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب مدفوعات العميل: $e');
      return [];
    }
  }

  /// الحصول على مدفوعات طلب معين
  Future<List<Map<String, dynamic>>> getOrderPayments(int orderId) async {
    try {
      return await _paymentService.getOrderPayments(orderId);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب مدفوعات الطلب: $e');
      return [];
    }
  }

  /// البحث في المدفوعات
  void searchPayments(String query) {
    searchQuery.value = query;
  }

  /// فلترة المدفوعات
  void filterPayments() {
    var filtered = payments.toList();

    // تطبيق البحث
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((payment) {
        return (payment['payment_number'] ?? '')
                .toString()
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            (payment['customer_name'] ?? '').toString().toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            (payment['order_number'] ?? '').toString().toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // تطبيق فلتر طريقة الدفع
    if (selectedMethod.value != 'الكل') {
      filtered = filtered
          .where((payment) => payment['payment_method'] == selectedMethod.value)
          .toList();
    }

    // تطبيق فلتر الحالة
    if (selectedStatus.value != 'الكل') {
      filtered = filtered
          .where((payment) => payment['status'] == selectedStatus.value)
          .toList();
    }

    filteredPayments.assignAll(filtered);
  }

  /// الحصول على مدفوعات اليوم
  Future<List<Map<String, dynamic>>> getTodayPayments() async {
    try {
      return await _paymentService.getTodayPayments();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب مدفوعات اليوم: $e');
      return [];
    }
  }

  /// الحصول على أكثر العملاء دفعاً
  Future<List<Map<String, dynamic>>> getTopPayingCustomers() async {
    try {
      return await _paymentService.getTopPayingCustomers();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب أكثر العملاء دفعاً: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات المدفوعات حسب طريقة الدفع
  Future<List<Map<String, dynamic>>> getPaymentStatsByMethod() async {
    try {
      return await _paymentService.getPaymentStatsByMethod();
    } catch (e) {
      print('خطأ في جلب إحصائيات طرق الدفع: $e');
      AppDialogs.show('خطأ', 'فشل في جلب إحصائيات طرق الدفع: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات المدفوعات الشهرية
  Future<List<Map<String, dynamic>>> getMonthlyPaymentStats() async {
    try {
      return await _paymentService.getMonthlyPaymentStats();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب الإحصائيات الشهرية: $e');
      return [];
    }
  }

  /// حساب إجمالي مدفوعات عميل
  Future<double> getCustomerTotalPayments(int customerId) async {
    try {
      return await _paymentService.getCustomerTotalPayments(customerId);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حساب إجمالي مدفوعات العميل: $e');
      return 0.0;
    }
  }

  /// حساب رصيد العميل المستحق
  Future<double> getCustomerBalance(int customerId) async {
    try {
      return await _paymentService.getCustomerBalance(customerId);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حساب رصيد العميل المستحق: $e');
      return 0.0;
    }
  }

  /// الحصول على المدفوعات المتأخرة
  Future<List<Map<String, dynamic>>> getOverduePayments() async {
    try {
      return await _paymentService.getOverduePayments();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب المدفوعات المتأخرة: $e');
      return [];
    }
  }

  /// إضافة ملاحظة للدفعة
  Future<void> addPaymentNote(int id, String note) async {
    try {
      await _paymentService.addPaymentNote(id, note);
      await fetchAllPayments();
      AppDialogs.show('نجح', 'تم إضافة الملاحظة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إضافة الملاحظة: $e');
    }
  }

  /// إرسال تذكير دفع
  Future<void> sendPaymentReminder(int paymentId, String reminderType) async {
    try {
      await _paymentService.sendPaymentReminder(paymentId, reminderType);
      AppDialogs.show('نجح', 'تم إرسال التذكير بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إرسال التذكير: $e');
    }
  }

  /// تحديث الفلاتر
  void updateMethodFilter(String method) {
    selectedMethod.value = method;
  }

  void updateStatusFilter(String status) {
    selectedStatus.value = status;
  }

  /// إعادة تعيين الفلاتر
  void resetFilters() {
    searchQuery.value = '';
    selectedMethod.value = 'الكل';
    selectedStatus.value = 'الكل';
  }

  /// الحصول على لون حالة الدفعة
  String getPaymentStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return '#10B981';
      case 'معلق':
        return '#F59E0B';
      case 'مرفوض':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  /// الحصول على أيقونة حالة الدفعة
  String getPaymentStatusIcon(String status) {
    switch (status) {
      case 'مكتمل':
        return '✅';
      case 'معلق':
        return '⏳';
      case 'مرفوض':
        return '❌';
      default:
        return '💳';
    }
  }

  /// الحصول على لون طريقة الدفع
  String getPaymentMethodColor(String method) {
    switch (method) {
      case 'نقد':
        return '#10B981';
      case 'بطاقة ائتمان':
        return '#3B82F6';
      case 'تحويل بنكي':
        return '#8B5CF6';
      case 'شيك':
        return '#F59E0B';
      default:
        return '#6B7280';
    }
  }

  /// الحصول على أيقونة طريقة الدفع
  String getPaymentMethodIcon(String method) {
    switch (method) {
      case 'نقد':
        return '💵';
      case 'بطاقة ائتمان':
        return '💳';
      case 'تحويل بنكي':
        return '🏦';
      case 'شيك':
        return '📄';
      default:
        return '💰';
    }
  }
}
