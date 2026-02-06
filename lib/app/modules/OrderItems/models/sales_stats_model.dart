import 'top_selling_item_model.dart';

/// نموذج لإحصائيات المبيعات العامة
class SalesStatsModel {
  final int totalOrders;
  final int totalItems;
  final double totalRevenue;
  final double averageOrderValue;
  final int todayOrders;
  final double todayRevenue;
  final int monthOrders;
  final double monthRevenue;
  final List<TopSellingItemModel> topProducts;

  SalesStatsModel({
    required this.totalOrders,
    required this.totalItems,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.todayOrders,
    required this.todayRevenue,
    required this.monthOrders,
    required this.monthRevenue,
    required this.topProducts,
  });

  /// تحويل النموذج إلى قاموس
  Map<String, dynamic> toMap() => {
    'totalOrders': totalOrders,
    'totalRevenue': totalRevenue,
  };
}
