class SupplierStatsModel {
  final int total;
  final int active;
  final int inactive;
  final int suspended;
  final double avgRating;
  final int purchaseOrdersCount;
  final double totalPurchasesValue;

  SupplierStatsModel({
    required this.total,
    required this.active,
    required this.inactive,
    required this.suspended,
    required this.avgRating,
    required this.purchaseOrdersCount,
    required this.totalPurchasesValue,
  });
}
