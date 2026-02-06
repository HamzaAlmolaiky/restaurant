// file: controllers/return_controller.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../../OrderItems/services/operational_service.dart';
import '../services/return_service.dart';
import '../../../helpers/app_dialogs.dart';
import '../models/order_return_model.dart';
import '../models/return_item_model.dart';

class ReturnController extends GetxController {
  final ReturnService _returnService = Get.find<ReturnService>();
  final OperationalService _orderItemsOpService = OperationalService();

  var returns = <OrderReturnModel>[].obs;
  var filteredReturns = <OrderReturnModel>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedStatus = 'الكل'.obs;
  var selectedReason = 'الكل'.obs;
  var returnStats = <String, dynamic>{}.obs;
  var customers = <Map<String, dynamic>>[].obs;

  // حالة نموذج إضافة مرتجع جديد
  final Rxn<int> newReturnCustomerId = Rxn<int>();
  final RxString newReturnStatus = 'قيد المراجعة'.obs;
  final RxString newReturnReason = 'منتج معيب'.obs;

  // قوائم الفلاتر
  final statuses = ['الكل', 'قيد المراجعة', 'مقبول', 'مرفوض', 'مكتمل'];
  final reasons = [
    'الكل',
    'منتج معيب',
    'طلب خاطئ',
    'عدم الرضا',
    'تأخير التوصيل',
    'أخرى',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchAllReturns();
    fetchReturnStats();
    fetchCustomers();

    // مراقبة تغييرات البحث والفلاتر
    ever(searchQuery, (_) => filterReturns());
    ever(selectedStatus, (_) => filterReturns());
    ever(selectedReason, (_) => filterReturns());
  }

  /// جلب جميع المرتجعات
  Future<void> fetchAllReturns() async {
    try {
      isLoading.value = true;
      final result = await _returnService.getAllReturns();
      returns.assignAll(result);
      filterReturns();
    } catch (e) {
      print('خطأ في جلب المرتجعات: $e');
      AppDialogs.showError('خطأ', 'خطأ في جلب المرتجعات');
    } finally {
      isLoading.value = false;
    }
  }

  /// فلترة المرتجعات
  void filterReturns() {
    var filtered = returns.toList();

    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((returnItem) {
        final query = searchQuery.value.toLowerCase();
        return returnItem.returnReason.toLowerCase().contains(query) == true ||
            returnItem.returnID.toString().contains(query) ||
            returnItem.originalOrderID.toString().contains(query);
      }).toList();
    }

    // فلترة حسب الحالة
    if (selectedStatus.value != 'الكل') {
      filtered = filtered
          .where(
            (returnItem) => getStatusText(returnItem) == selectedStatus.value,
          )
          .toList();
    }

    // فلترة حسب السبب
    if (selectedReason.value != 'الكل') {
      filtered = filtered.where((returnItem) {
        return returnItem.returnReason == selectedReason.value;
      }).toList();
    }

    filteredReturns.assignAll(filtered);
  }

  /// تحديث فلتر الحالة
  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    filterReturns();
  }

  /// تحديث فلتر السبب
  void updateReasonFilter(String reason) {
    selectedReason.value = reason;
    filterReturns();
  }

  /// إضافة مرتجع جديد
  Future<void> addReturn(OrderReturnModel orderReturn) async {
    isLoading.value = true;
    try {
      final result = await _returnService.addReturn(orderReturn);
      if (result > 0) {
        AppDialogs.showSuccess('نجاح', 'تم إضافة المرتجع بنجاح');
        fetchAllReturns();
        fetchReturnStats();
      } else {
        throw Exception('فشل في إضافة المرتجع');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث مرتجع
  Future<void> updateReturn(int id, OrderReturnModel orderReturn) async {
    try {
      isLoading.value = true;
      final result = await _returnService.updateReturn(id, orderReturn);
      if (result > 0) {
        AppDialogs.showSuccess('نجاح', 'تم تحديث المرتجع بنجاح');
        fetchAllReturns();
        fetchReturnStats();
      } else {
        AppDialogs.showError('خطأ', 'فشل في تحديث المرتجع');
      }
    } catch (e) {
      print('خطأ في تحديث المرتجع: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف مرتجع
  Future<void> deleteReturn(int id) async {
    try {
      isLoading.value = true;
      final result = await _returnService.deleteReturn(id);
      if (result > 0) {
        AppDialogs.showSuccess('نجاح', 'تم حذف المرتجع بنجاح');
        fetchAllReturns();
        fetchReturnStats();
      } else {
        AppDialogs.showError('خطأ', 'فشل في حذف المرتجع');
      }
    } catch (e) {
      print('خطأ في حذف المرتجع: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// معالجة مرتجع (استخدام المعاملة المتقدمة)
  Future<void> processReturn(OrderReturnModel orderReturn) async {
    try {
      isLoading.value = true;
      final result = await _returnService.processReturnTransaction(orderReturn);
      if (result) {
        AppDialogs.showSuccess('نجاح', 'تم معالجة المرتجع بنجاح');
        fetchAllReturns();
        fetchReturnStats();
      } else {
        AppDialogs.showError('خطأ', 'فشل في معالجة المرتجع');
      }
    } catch (e) {
      print('خطأ في معالجة المرتجع: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// البحث في المرتجعات
  Future<void> searchReturns(String query) async {
    try {
      isLoading.value = true;
      final result = await _returnService.searchReturns(query);
      returns.assignAll(result);
      filterReturns();
    } catch (e) {
      print('خطأ في البحث: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب إحصائيات المرتجعات
  Future<void> fetchReturnStats() async {
    try {
      final stats = await _returnService.getReturnStats();
      returnStats.assignAll(stats);
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    }
  }

  /// جلب إحصائيات المرتجعات حسب السبب
  Future<List<Map<String, dynamic>>> getReturnStatsByReason() async {
    try {
      return await _returnService.getReturnStatsByReason();
    } catch (e) {
      print('خطأ في جلب إحصائيات الأسباب: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return [];
    }
  }

  /// جلب إحصائيات المرتجعات الشهرية
  Future<List<Map<String, dynamic>>> getMonthlyReturnStats() async {
    try {
      return await _returnService.getMonthlyReturnStats();
    } catch (e) {
      print('خطأ في جلب الإحصائيات الشهرية: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return [];
    }
  }

  /// جلب أكثر العملاء إرجاعاً
  Future<List<Map<String, dynamic>>> getTopReturningCustomers() async {
    try {
      return await _returnService.getTopReturningCustomers();
    } catch (e) {
      print('خطأ في جلب أكثر العملاء إرجاعاً: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return [];
    }
  }

  /// جلب أكثر المنتجات إرجاعاً
  Future<List<Map<String, dynamic>>> getTopReturnedItems() async {
    try {
      return await _returnService.getTopReturnedItems();
    } catch (e) {
      print('خطأ في جلب أكثر المنتجات إرجاعاً: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return [];
    }
  }

  /// جلب المرتجعات حسب السبب
  Future<void> fetchReturnsByReason(String reason) async {
    try {
      isLoading.value = true;
      final result = await _returnService.getReturnsByReason(reason);
      returns.assignAll(result);
      filterReturns();
    } catch (e) {
      print('خطأ في جلب المرتجعات حسب السبب: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب المرتجعات حسب التاريخ
  Future<void> fetchReturnsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      isLoading.value = true;
      final result = await _returnService.getReturnsByDateRange(
        startDate,
        endDate,
      );
      returns.assignAll(result);
      filterReturns();
    } catch (e) {
      print('خطأ في جلب المرتجعات حسب التاريخ: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب مرتجعات اليوم
  Future<void> fetchTodayReturns() async {
    try {
      isLoading.value = true;
      final result = await _returnService.getTodayReturns();
      returns.assignAll(result);
      filterReturns();
    } catch (e) {
      print('خطأ في جلب مرتجعات اليوم: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء رقم مرتجع تلقائي
  Future<String> generateReturnNumber() async {
    try {
      return await _returnService.generateReturnNumber();
    } catch (e) {
      print('خطأ في إنشاء رقم المرتجع: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return 'RT${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// جلب المرتجعات لعميل معين
  Future<List<OrderReturnModel>> getReturnsForCustomer(int customerId) async {
    try {
      return await _returnService.getReturnsForCustomer(customerId);
    } catch (e) {
      print('خطأ في جلب مرتجعات العميل: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
      return [];
    }
  }

  /// جلب العملاء
  Future<void> fetchCustomers() async {
    try {
      final result = await _returnService.getCustomers();
      customers.assignAll(result);
    } catch (e) {
      print('خطأ في جلب العملاء: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // إزالة "Exception: "
      }
      AppDialogs.showError('خطأ', errorMessage);
    }
  }

  /// جلب عناصر مرتجع محدد (لعرض التفاصيل)
  Future<List<ReturnItemModel>> getReturnItems(int returnId) async {
    try {
      return await _returnService.getReturnItems(returnId);
    } catch (e) {
      print('خطأ في جلب عناصر المرتجع: $e');
      return [];
    }
  }

  /// جلب عناصر الطلب الأصلية من جدول OrderItems لعرضها في تفاصيل المرتجع
  Future<List<OrderItemModel>> getOriginalOrderItems(int orderId) async {
    try {
      return await _orderItemsOpService.getFullOrderItems(orderId);
    } catch (e) {
      print('خطأ في جلب عناصر الطلب الأصلية: $e');
      return [];
    }
  }

  /// جلب مرتجع واحد بالمعرف (لاستخدامه في نافذة التفاصيل)
  Future<OrderReturnModel?> getReturnById(int id) async {
    try {
      return await _returnService.getReturnById(id);
    } catch (e) {
      print('خطأ في جلب بيانات المرتجع: $e');
      return null;
    }
  }

  // دوال مساعدة للواجهة
  String getStatusText(OrderReturnModel returnItem) {
    // إن كانت الحالة موجودة في الموديل (من قاعدة البيانات)، نستخدمها مباشرة
    if (returnItem.returnStatus != null &&
        returnItem.returnStatus!.isNotEmpty) {
      return returnItem.returnStatus!;
    }
    // منطق مرحلي لتحديد الحالة بناءً على سبب الإرجاع
    // ملاحظة: عند إضافة عمود ReturnStatus في القاعدة، سيتم استبدال هذا المنطق بالقيمة الفعلية من الجدول
    switch (returnItem.returnReason) {
      case 'منتج معيب':
      case 'طلب خاطئ':
        return 'مقبول';
      case 'تأخير التوصيل':
        return 'مرفوض';
      case 'أخرى':
        return 'قيد المراجعة';
      default:
        return 'قيد المراجعة';
    }
  }

  String getStatusColor(OrderReturnModel returnItem) {
    final status = getStatusText(returnItem);
    switch (status) {
      case 'قيد المراجعة':
        return '#2196F3';
      case 'مقبول':
        return '#4CAF50';
      case 'مرفوض':
        return '#F44336';
      case 'مكتمل':
        return '#9C27B0';
      default:
        return '#757575';
    }
  }

  String getReasonIcon(String reason) {
    switch (reason) {
      case 'منتج معيب':
        return '🔧';
      case 'طلب خاطئ':
        return '❌';
      case 'عدم الرضا':
        return '😞';
      case 'تأخير التوصيل':
        return '⏰';
      default:
        return '📋';
    }
  }

  String getReasonColor(String reason) {
    switch (reason) {
      case 'منتج معيب':
        return '#FF5722';
      case 'طلب خاطئ':
        return '#F44336';
      case 'عدم الرضا':
        return '#FF9800';
      case 'تأخير التوصيل':
        return '#2196F3';
      default:
        return '#757575';
    }
  }

  // إحصائيات سريعة للواجهة
  int get totalReturns => returns.length;

  double get totalReturnValue =>
      returns.fold(0.0, (sum, item) => sum + item.totalReturnAmount);

  int get todayReturnsCount => returns.where((item) {
    final today = DateTime.now();
    final returnDate = item.returnDate;
    return returnDate.year == today.year &&
        returnDate.month == today.month &&
        returnDate.day == today.day;
  }).length;

  double get returnRate {
    // حساب معدل المرتجعات (يحتاج لإجمالي الطلبات)
    // يمكن تحسينه لاحقاً بربطه مع خدمة الطلبات
    return totalReturns > 0 ? (totalReturns / 100 * 100) : 0.0;
  }

  // دوال إضافية للفلاتر
  void resetFilters() {
    searchQuery.value = '';
    selectedStatus.value = 'الكل';
    selectedReason.value = 'الكل';
  }

  /// إعادة تهيئة قيم نموذج إضافة المرتجع
  void resetNewReturnForm() {
    newReturnCustomerId.value = null;
    newReturnStatus.value = 'قيد المراجعة';
    newReturnReason.value = 'منتج معيب';
  }
}
