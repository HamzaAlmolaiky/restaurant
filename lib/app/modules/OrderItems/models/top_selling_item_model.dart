/// نموذج لأكثر المنتجات مبيعاً
class TopSellingItemModel {
  final String itemName;
  final String? categoryName;
  final int totalQuantity;
  final double totalRevenue;
  final int orderCount;

  TopSellingItemModel({
    required this.itemName,
    this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.orderCount,
  });

  factory TopSellingItemModel.fromMap(Map<String, dynamic> map) {
    return TopSellingItemModel(
      itemName: map['ItemsName'] as String? ?? 'غير محدد',
      categoryName: map['CategoryName'] as String?,
      totalQuantity: (map['totalQuantity'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: (map['orderCount'] as num?)?.toInt() ?? 0,
    );
  }
}
