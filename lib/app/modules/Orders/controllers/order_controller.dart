// file: controllers/order_controller.dart

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../../Shift/models/credit_order_view_model.dart';
import '../../Shift/models/shift_activity_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../../../helpers/app_dialogs.dart';

class OrderController extends GetxController {
  final OrderService _orderService;
  OrderController(this._orderService);

  /// --- متغيرات الحالة التفاعلية ---
  var isLoading = false.obs;
  var allOrders = <OrderModel>[].obs;
  var customerOrders = <OrderModel>[].obs;
  var shiftActivities = <ShiftActivityModel>[].obs;
  var creditOrdersForShift = <CreditOrderViewModel>[].obs;
  var nextOrderId = 1.obs;
  var shiftTotals = <String, double>{}.obs;

  /// فلاتر و بحث الواجهة
  var searchQuery = ''.obs;
  var statusFilter = 'جميع الحالات'.obs;
  var dateFilter = 'الكل'.obs; // القيم: اليوم/أمس/هذا الأسبوع/هذا الشهر/الكل

  @override
  void onInit() {
    super.onInit();
    fetchAllOrders();
    fetchNextOrderId();
  }

  /// --- دوال التحكم ---

  Future<void> createNewOrder(OrderModel order) async {
    try {
      isLoading.value = true;
      final newOrderId = await _orderService.createOrder(order);
      if (newOrderId != -1) {
        AppDialogs.show('نجاح', 'تم إنشاء الطلب رقم $newOrderId بنجاح');
        await fetchAllOrders();
        await fetchNextOrderId();

        /// تحديث رقم الطلب التالي
        /// يمكنك هنا تحديث أي قائمة أخرى معروضة
      } else {
        throw Exception("فشلت عملية حفظ الطلب في قاعدة البيانات");
      }
    } catch (e) {
      AppDialogs.show('خطأ فادح', 'فشلت عملية إنشاء الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب عدد طلبات اليوم
  int getTodayOrdersCount() {
    final today = DateTime.now();
    return allOrders.where((order) {
      return order.orderDate.year == today.year &&
          order.orderDate.month == today.month &&
          order.orderDate.day == today.day;
    }).length;
  }

  /// جلب الطلبات حسب طريقة الدفع (بدلاً من الحالة غير الموجودة)
  List<OrderModel> getOrdersByPaymentMethod(String paymentMethod) {
    return allOrders
        .where((order) => order.paymentMethod == paymentMethod)
        .toList();
  }

  /// جلب الطلبات حسب الحالة
  List<OrderModel> getOrdersByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'مكتمل':
      case 'completed':
        // الطلبات المكتملة = الطلبات المدفوعة بالكامل
        return allOrders.where((order) => order.amountDue == 0).toList();

      case 'معلق':
      case 'pending':
        // الطلبات المعلقة = الطلبات التي لم تدفع بالكامل
        return allOrders.where((order) => order.amountDue > 0).toList();

      case 'نقدي':
      case 'cash':
        return allOrders
            .where((order) => order.paymentMethod == 'نقدي')
            .toList();

      case 'آجل':
      case 'credit':
        return allOrders
            .where((order) => order.paymentMethod == 'آجل')
            .toList();

      case 'اليوم':
      case 'today':
        final today = DateTime.now();
        return allOrders.where((order) {
          return order.orderDate.year == today.year &&
              order.orderDate.month == today.month &&
              order.orderDate.day == today.day;
        }).toList();

      case 'هذا الأسبوع':
      case 'this_week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return allOrders
            .where((order) => order.orderDate.isAfter(startOfWeek))
            .toList();

      case 'هذا الشهر':
      case 'this_month':
        final now = DateTime.now();
        return allOrders.where((order) {
          return order.orderDate.year == now.year &&
              order.orderDate.month == now.month;
        }).toList();

      default:
        return allOrders;
    }
  }

  /// جلب عدد الطلبات حسب الحالة
  int getOrdersCountByStatus(String status) {
    return getOrdersByStatus(status).length;
  }

  /// جلب الطلبات المكتملة
  List<OrderModel> getCompletedOrders() {
    return getOrdersByStatus('مكتمل');
  }

  /// جلب الطلبات المعلقة
  List<OrderModel> getPendingOrders() {
    return getOrdersByStatus('معلق');
  }

  /// جلب طلبات اليوم
  List<OrderModel> getTodayOrders() {
    return getOrdersByStatus('اليوم');
  }

  /// جلب الطلبات المدفوعة بالكامل
  List<OrderModel> getPaidOrders() {
    return allOrders.where((order) => order.amountDue == 0).toList();
  }

  /// جلب جميع الطلبات
  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;
      final ordersData = await _orderService.getAllOrders();
      // تحويل البيانات من Map إلى OrderModel
      final orders = ordersData
          .map((orderMap) => OrderModel.fromMap(orderMap))
          .toList();
      allOrders.assignAll(orders);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب الطلبات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب الطلبات الحديثة (آخر 10 طلبات)
  List<OrderModel> getRecentOrders({int limit = 10}) {
    final sortedOrders = List<OrderModel>.from(allOrders);
    sortedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return sortedOrders.take(limit).toList();
  }

  Future<void> fetchOrdersForCustomer(int customerId) async {
    try {
      isLoading.value = true;
      final ordersData = await _orderService.getOrdersForCustomer(customerId);
      // تحويل البيانات من Map إلى OrderModel
      final orders = ordersData
          .map((orderMap) => OrderModel.fromMap(orderMap))
          .toList();
      customerOrders.assignAll(orders);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل جلب طلبات العميل: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchShiftReport(int shiftId) async {
    try {
      isLoading.value = true;

      /// جلب كل البيانات دفعة واحدة باستخدام Future.wait
      final results = await Future.wait([
        _orderService.getRecentActivitiesForShift(shiftId),
        _orderService.getCreditOrdersForShift(shiftId),
        _orderService.getTotalCashSalesForShift(shiftId),
      ]);

      shiftActivities.assignAll(results[0] as List<ShiftActivityModel>);
      creditOrdersForShift.assignAll(results[1] as List<CreditOrderViewModel>);
      shiftTotals['cashSales'] = results[2] as double;
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحميل تقرير الوردية: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchNextOrderId() async {
    try {
      nextOrderId.value = await _orderService.getNextOrderId();
    } catch (e) {
      /// لا داعي لإزعاج المستخدم برسالة هنا
      print("Error fetching next order ID: $e");
    }
  }

  /// --- متغيرات حالة جديدة لإدارة تفاصيل الطلب ---
  var currentOrderItems = <OrderItemModel>[].obs;
  var selectedOrder = Rx<OrderModel?>(null);

  /// لتخزين الطلب الذي يتم تعديله حالياً

  //// ** دالة لجلب تفاصيل طلب معين وعناصره **
  Future<void> fetchOrderDetails(int orderId) async {
    try {
      isLoading.value = true;

      /// جلب الطلب الأساسي وعناصره المفصلة
      /// هذه الدوال يفترض أنها موجودة في OrderService
      final orderFuture = _orderService.getOrderById(orderId);
      final itemsFuture = _orderService.getFullOrderItems(orderId);

      final results = await Future.wait([orderFuture, itemsFuture]);

      selectedOrder.value = results[0] as OrderModel?;
      currentOrderItems.assignAll(results[1] as List<OrderItemModel>);
    } catch (e) {
      print("خطأ في جلب تفاصيل الطلب: $e");
      AppDialogs.show('خطأ', 'فشل في جلب تفاصيل الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  //// ** إضافة عنصر إلى الطلب المفتوح حالياً **
  Future<void> addItemToCurrentOrder(OrderItemModel newItem) async {
    _validateOrderItem(newItem);

    /// التحقق من البيانات أولاً

    await _performItemOperation(() async {
      await _orderService.addOrderItemToOrder(newItem);
      AppDialogs.show('نجاح', 'تمت إضافة العنصر');
    });
  }

  //// ** تحديث عنصر في الطلب المفتوح حالياً **
  Future<void> updateItemInCurrentOrder(OrderItemModel updatedItem) async {
    _validateOrderItem(updatedItem);

    await _performItemOperation(() async {
      await _orderService.updateOrderItem(updatedItem);
      AppDialogs.show('نجاح', 'تم تحديث العنصر');
    });
  }

  //// ** حذف عنصر من الطلب المفتوح حالياً **
  Future<void> deleteItemFromCurrentOrder(int orderItemId) async {
    await _performItemOperation(() async {
      await _orderService.deleteOrderItem(orderItemId);
      AppDialogs.show('نجاح', 'تم حذف العنصر');
    });
  }

  //// ** دالة مساعدة لتجنب تكرار الكود **
  Future<void> _performItemOperation(Future<void> Function() operation) async {
    try {
      isLoading.value = true;
      await operation();

      /// بعد أي تغيير على العناصر، أعد تحميل تفاصيل الطلب لضمان التناسق
      if (selectedOrder.value != null) {
        await fetchOrderDetails(selectedOrder.value!.orderID!);
      }
    } catch (e) {
      print("خطاء في عملية العنصر: $e");
      AppDialogs.show('خطأ في العملية', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  //// ** دالة التحقق من البيانات (Validation) **
  void _validateOrderItem(OrderItemModel item) {
    if (item.orderID <= 0) throw ArgumentError("Invalid Order ID");
    if (item.menuItemsID <= 0) throw ArgumentError("Invalid Item ID");
    if (item.quantity <= 0) throw ArgumentError("Quantity must be > 0");
    if (item.price < 0) throw ArgumentError("Price cannot be negative");
  }

  /// --- دوال إضافية للتوافق مع DashboardController ---

  /// حساب إجمالي المبيعات
  double getTotalSales() {
    return allOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// حساب مبيعات اليوم
  double getTodaySales() {
    final today = DateTime.now();
    return allOrders
        .where((order) {
          return order.orderDate.year == today.year &&
              order.orderDate.month == today.month &&
              order.orderDate.day == today.day;
        })
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// حساب متوسط قيمة الطلب
  double getAverageOrderValue() {
    if (allOrders.isEmpty) return 0.0;
    return getTotalSales() / allOrders.length;
  }

  /// جلب الطلبات النقدية
  List<OrderModel> getCashOrders() {
    return allOrders
        .where(
          (order) =>
              order.paymentMethod == 'نقدي' || order.paymentMethod == 'Cash',
        )
        .toList();
  }

  /// جلب الطلبات الآجلة
  List<OrderModel> getCreditOrders() {
    return allOrders
        .where(
          (order) =>
              order.paymentMethod == 'آجل' || order.paymentMethod == 'Credit',
        )
        .toList();
  }

  /// حساب إجمالي المبيعات النقدية
  double getTotalCashSales() {
    return getCashOrders().fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// حساب إجمالي المبيعات الآجلة
  double getTotalCreditSales() {
    return getCreditOrders().fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// جلب إحصائيات شاملة للطلبات
  Map<String, dynamic> getOrdersStatistics() {
    final totalOrders = allOrders.length;
    final todayOrders = getTodayOrdersCount();
    final totalSales = getTotalSales();
    final todaySales = getTodaySales();
    final averageOrderValue = getAverageOrderValue();
    final cashOrders = getCashOrders().length;
    final creditOrders = getCreditOrders().length;
    final paidOrders = getPaidOrders().length;
    final pendingOrders = getPendingOrders().length;

    return {
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'totalSales': totalSales,
      'todaySales': todaySales,
      'averageOrderValue': averageOrderValue,
      'cashOrders': cashOrders,
      'creditOrders': creditOrders,
      'paidOrders': paidOrders,
      'pendingOrders': pendingOrders,
      'totalCashSales': getTotalCashSales(),
      'totalCreditSales': getTotalCreditSales(),
    };
  }

  /// تحديث الإحصائيات (يستدعى من DashboardController)
  Future<void> refreshStatistics() async {
    await fetchAllOrders();
  }

  /// قائمة الطلبات بعد تطبيق الفلاتر والبحث
  List<OrderModel> get filteredOrders {
    Iterable<OrderModel> result = allOrders;

    // فلتر الحالة
    final status = statusFilter.value;
    if (status != 'جميع الحالات') {
      if (status == 'مكتمل') {
        result = result.where((o) => o.amountDue == 0);
      } else if (status == 'معلق') {
        result = result.where((o) => o.amountDue > 0);
      } else if (status == 'نقدي') {
        result = result.where(
          (o) => o.paymentMethod == 'نقدي' || o.paymentMethod == 'Cash',
        );
      } else if (status == 'آجل') {
        result = result.where(
          (o) => o.paymentMethod == 'آجل' || o.paymentMethod == 'Credit',
        );
      }
    }

    // فلتر التاريخ
    final df = dateFilter.value;
    if (df != 'الكل') {
      final now = DateTime.now();
      if (df == 'اليوم') {
        result = result.where(
          (o) =>
              o.orderDate.year == now.year &&
              o.orderDate.month == now.month &&
              o.orderDate.day == now.day,
        );
      } else if (df == 'أمس') {
        final y = now.subtract(const Duration(days: 1));
        result = result.where(
          (o) =>
              o.orderDate.year == y.year &&
              o.orderDate.month == y.month &&
              o.orderDate.day == y.day,
        );
      } else if (df == 'هذا الأسبوع') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        result = result.where(
          (o) => !o.orderDate.isBefore(
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          ),
        );
      } else if (df == 'هذا الشهر') {
        result = result.where(
          (o) => o.orderDate.year == now.year && o.orderDate.month == now.month,
        );
      }
    }

    // البحث
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((o) {
        final id = o.orderID?.toString() ?? '';
        final cust =
            (o.customer?.customerName ?? o.customerID?.toString() ?? '')
                .toLowerCase();
        final notes = (o.notes ?? '').toLowerCase();
        return id.contains(q) || cust.contains(q) || notes.contains(q);
      });
    }

    // ترتيب الأحدث أولاً
    final list = result.toList();
    list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return list;
  }

  /// محدّثات الفلاتر والبحث
  void setSearchQuery(String value) => searchQuery.value = value;
  void setStatusFilter(String value) => statusFilter.value = value;
  void setDateFilter(String value) => dateFilter.value = value;
}
