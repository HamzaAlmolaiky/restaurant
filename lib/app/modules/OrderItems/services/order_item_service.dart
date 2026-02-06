import '../models/order_item_model.dart';
import 'analytics_service.dart';
import 'operational_service.dart';

// -------------------------------------------------------------------
// الواجهة العامة (Facade) - هذا هو الكلاس الوحيد الذي يتعامل معه الكنترولر
// -------------------------------------------------------------------
class OrderItemService {
  // استخدام نمط Singleton للوصول الموحد
  static final OrderItemService instance = OrderItemService._internal();

  // الخدمات الداخلية المتخصصة
  final OperationalService _opService = OperationalService();
  final AnalyticsService _analyticsService = AnalyticsService();

  OrderItemService._internal();

  // --- دوال تشغيلية (تستدعي _opService) ---
  // تم تصميمها لترجع خرائط (Map) لتتوافق مباشرة مع الكنترولر

  Future<List<Map<String, dynamic>>> getAllOrderItems() async {
    final models = await _opService.getAllOrderItems();
    return models.map((model) => model.toMapWithJoins()).toList();
  }

  Future<int> addOrderItem(OrderItemModel orderItem) =>
      _opService.addOrderItem(orderItem);

  Future<int> updateOrderItem(int id, Map<String, dynamic> data) =>
      _opService.updateOrderItem(id, data);

  Future<int> deleteOrderItem(int id) => _opService.deleteOrderItem(id);

  Future<void> updateItemQuantity(int id, int newQuantity) =>
      _opService.updateItemQuantity(id, newQuantity);

  Future<void> applyItemDiscount(int id, double amount, String type) =>
      _opService.applyItemDiscount(id, amount, type);

  Future<List<Map<String, dynamic>>> searchOrderItems(String query) async {
    final models = await _opService.searchOrderItems(query);
    return models.map((model) => model.toMapWithJoins()).toList();
  }

  Future<List<Map<String, dynamic>>> getOrderItemsByCategory(
    int categoryId,
  ) async {
    final models = await _opService.getOrderItemsByCategory(categoryId);
    return models.map((e) => e.toMapWithJoins()).toList();
  }

  Future<List<Map<String, dynamic>>> getOrderItemsByMenuItem(
    int menuItemId,
  ) async {
    final models = await _opService.getOrderItemsByMenuItem(menuItemId);
    return models.map((e) => e.toMapWithJoins()).toList();
  }

  Future<List<Map<String, dynamic>>> getOrderItemsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final models = await _opService.getOrderItemsByDateRange(start, end);
    return models.map((e) => e.toMapWithJoins()).toList();
  }

  /// --- دوال تحليلية (تستدعي _analyticsService) ---
  /// تم تصميمها لترجع خرائط (Map) لتتوافق مباشرة مع الكنترولر

  Future<Map<String, dynamic>> getOrderItemStats() =>
      _analyticsService.getOrderItemStats();

  /// دالة تحليلية للتحليلات والإحصائيات
  Future<Map<String, dynamic>> getSalesStats() =>
      _analyticsService.getSalesStats();

  Future<Map<String, dynamic>> analyzeRevenue() =>
      _analyticsService.analyzeRevenue();
}
