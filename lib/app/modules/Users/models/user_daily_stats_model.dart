// file: models/user_stats_model.dart

class UserDailyStatsModel {
  final DateTime date;
  final int totalOrders;
  final double totalSales;
  final int creditOrders;
  final double creditAmount;

  UserDailyStatsModel({
    required this.date,
    required this.totalOrders,
    required this.totalSales,
    required this.creditOrders,
    required this.creditAmount,
  });

  factory UserDailyStatsModel.fromMap(Map<String, dynamic> map) {
    return UserDailyStatsModel(
      date: DateTime.parse(map['التاريخ']),
      totalOrders: map['إجمالي عدد الطلبات'] ?? 0,
      totalSales: (map['إجمالي المبيعات'] as num? ?? 0.0).toDouble(),
      creditOrders: map['عدد الطلبات آجل'] ?? 0,
      creditAmount: (map['المبلغ الإجمالي آجل'] as num? ?? 0.0).toDouble(),
    );
  }
}
