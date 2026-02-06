// ignore_for_file: avoid_print

import 'package:get/get.dart';

import '../models/order_item_model.dart';
import '../services/order_item_service.dart';
import '../../../helpers/app_dialogs.dart';

class OrderItemController extends GetxController {
  final OrderItemService _orderItemService = OrderItemService.instance;

  // var orderItems = <Map<String, dynamic>>[].obs;
  // var filteredOrderItems = <Map<String, dynamic>>[].obs;
  var orderItems = <OrderItemModel>[].obs;
  var filteredOrderItems = <OrderItemModel>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedCategory = 'الكل'.obs;
  var selectedProduct = 'الكل'.obs;
  var orderItemStats = <String, dynamic>{}.obs;

  /// قوائم الفلاتر
  final categories = [
    'الكل',
    'الأطباق الرئيسية',
    'المقبلات',
    'المشروبات',
    'الحلويات',
    'أخرى',
  ].obs;
  final products = ['الكل'].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllOrderItems();
    fetchOrderItemStats();

    /// مراقبة تغييرات البحث والفلاتر
    ever(searchQuery, (_) => filterOrderItems());
    ever(selectedCategory, (_) => filterOrderItems());
    ever(selectedProduct, (_) => filterOrderItems());
  }

  /// جلب جميع عناصر الطلبات
  Future<void> fetchAllOrderItems() async {
    try {
      isLoading.value = true;
      final result = await _orderItemService.getAllOrderItems();
      orderItems.assignAll(
        result.map((item) => OrderItemModel.fromMap(item)).toList(),
      );
      filterOrderItems();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب عناصر الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب إحصائيات عناصر الطلبات
  Future<void> fetchOrderItemStats() async {
    try {
      final stats = await _orderItemService.getOrderItemStats();
      orderItemStats.assignAll(stats);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب إحصائيات عناصر الطلبات: ${e.toString()}');
    }
  }

  /// فلترة عناصر الطلبات
  void filterOrderItems() {
    var filtered = orderItems.where((item) {
      final name = item.menuItem?.itemsName ?? '';
      final category = item.menuItem?.category?.categoryName ?? '';
      final orderNumber = item.orderID.toString();

      final q = searchQuery.value.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          name.toLowerCase().contains(q) ||
          orderNumber.toLowerCase().contains(q);

      final matchesCategory =
          selectedCategory.value == 'الكل' ||
          category == selectedCategory.value;

      final matchesProduct =
          selectedProduct.value == 'الكل' || name == selectedProduct.value;

      return matchesSearch && matchesCategory && matchesProduct;
    }).toList();

    filteredOrderItems.assignAll(filtered);
  }

  /// إضافة عنصر طلب جديد
  Future<void> addOrderItem(OrderItemModel orderItemData) async {
    try {
      isLoading.value = true;
      await _orderItemService.addOrderItem(orderItemData);
      await fetchAllOrderItems();
      await fetchOrderItemStats();
      AppDialogs.show('نجح', 'تم إضافة عنصر الطلب بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إضافة عنصر الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث عنصر طلب
  Future<void> updateOrderItem(
    int id,
    Map<String, dynamic> orderItemData,
  ) async {
    try {
      isLoading.value = true;
      await _orderItemService.updateOrderItem(id, orderItemData);
      await fetchAllOrderItems();
      await fetchOrderItemStats();
      AppDialogs.show('نجح', 'تم تحديث عنصر الطلب بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحديث عنصر الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف عنصر طلب
  Future<void> deleteOrderItem(int id) async {
    try {
      isLoading.value = true;
      await _orderItemService.deleteOrderItem(id);
      await fetchAllOrderItems();
      await fetchOrderItemStats();
      AppDialogs.show('نجح', 'تم حذف عنصر الطلب بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حذف عنصر الطلب: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث كمية عنصر
  Future<void> updateQuantity(int id, int newQuantity) async {
    try {
      await _orderItemService.updateItemQuantity(id, newQuantity);
      await fetchAllOrderItems();
      await fetchOrderItemStats();
      AppDialogs.show('نجح', 'تم تحديث الكمية بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحديث الكمية: ${e.toString()}');
    }
  }

  /// تطبيق خصم على عنصر
  Future<void> applyDiscount(
    int id,
    double discountAmount,
    String discountType,
  ) async {
    try {
      await _orderItemService.applyItemDiscount(
        id,
        discountAmount,
        discountType,
      );
      await fetchAllOrderItems();
      await fetchOrderItemStats();
      AppDialogs.show('نجح', 'تم تطبيق الخصم بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تطبيق الخصم: ${e.toString()}');
    }
  }

  /// البحث في عناصر الطلبات
  Future<void> searchOrderItems(String query) async {
    try {
      isLoading.value = true;
      final result = await _orderItemService.searchOrderItems(query);
      filteredOrderItems.assignAll(
        result.map((item) => OrderItemModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في البحث: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// فلترة حسب الفئة
  Future<void> filterByCategory(int category) async {
    try {
      isLoading.value = true;
      final result = await _orderItemService.getOrderItemsByCategory(category);
      filteredOrderItems.assignAll(
        result.map((item) => OrderItemModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في الفلترة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// فلترة حسب المنتج
  Future<void> filterByProduct(int productName) async {
    try {
      isLoading.value = true;
      final result = await _orderItemService.getOrderItemsByMenuItem(
        productName,
      );
      filteredOrderItems.assignAll(
        result.map((item) => OrderItemModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في الفلترة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// فلترة حسب التاريخ
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      isLoading.value = true;
      final result = await _orderItemService.getOrderItemsByDateRange(
        startDate,
        endDate,
      );
      filteredOrderItems.assignAll(
        result.map((item) => OrderItemModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في الفلترة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب إحصائيات المبيعات
  Future<void> fetchSalesStats() async {
    try {
      final stats = await _orderItemService.getSalesStats();
      orderItemStats.assignAll(stats);
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب إحصائيات المبيعات: ${e.toString()}');
    }
  }

  /// تحليل الإيرادات
  Future<Map<String, dynamic>> analyzeRevenue() async {
    try {
      return await _orderItemService.analyzeRevenue();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحليل الإيرادات: ${e.toString()}');
      return {};
    }
  }

  /// تحديث البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// تحديث فلتر الفئة
  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
  }

  /// تحديث فلتر المنتج
  void updateProductFilter(String product) {
    selectedProduct.value = product;
  }

  /// مسح الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'الكل';
    selectedProduct.value = 'الكل';
    filterOrderItems();
  }

  /// تحديث البيانات
  Future<void> refreshData() async {
    await Future.wait([fetchAllOrderItems(), fetchOrderItemStats()]);
  }
}
