// file: models/report_models.dart

// لتقارير بسيطة (مثل: المبيعات حسب الدفع، الأكثر مبيعاً)
// لتقارير بسيطة (مثل: المبيعات حسب الدفع، الأكثر مبيعاً)
class ReportItemModel {
  final String label;
  final double value;
  final double? secondaryValue; // للتقارير التي تحتوي على أكثر من قيمة
  ReportItemModel({
    required this.label,
    required this.value,
    this.secondaryValue,
  });
}

// --- نماذج مخصصة لتقارير Service2 ---

// لتقرير المبيعات اليومية المفصل
class DailySalesReportModel {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> hourly;

  DailySalesReportModel({required this.summary, required this.hourly});

  factory DailySalesReportModel.fromMap(Map<String, dynamic> map) {
    return DailySalesReportModel(
      summary: Map<String, dynamic>.from(map['summary'] ?? {}),
      hourly: List<Map<String, dynamic>>.from(map['hourly'] ?? []),
    );
  }
}

// لتقرير أفضل المنتجات مبيعاً المفصل
class BestSellingItemReportModel {
  final String name;
  final String? categoryName;
  final int totalQuantity;
  final double totalRevenue;
  final double avgPrice;

  BestSellingItemReportModel({
    required this.name,
    this.categoryName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.avgPrice,
  });

  factory BestSellingItemReportModel.fromMap(Map<String, dynamic> map) {
    return BestSellingItemReportModel(
      name: map['name'] ?? 'غير محدد',
      categoryName: map['category_name'],
      totalQuantity: (map['total_quantity'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (map['avg_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// لتقرير العملاء الأكثر شراءً
class TopCustomerReportModel {
  final String name;
  final String? phone;
  final int totalOrders;
  final double totalSpent;
  final double avgOrderValue;
  final DateTime? lastOrderDate;

  TopCustomerReportModel({
    required this.name,
    this.phone,
    required this.totalOrders,
    required this.totalSpent,
    required this.avgOrderValue,
    this.lastOrderDate,
  });

  factory TopCustomerReportModel.fromMap(Map<String, dynamic> map) {
    return TopCustomerReportModel(
      name: map['name'] ?? 'غير محدد',
      phone: map['phone'],
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      avgOrderValue: (map['avg_order_value'] as num?)?.toDouble() ?? 0.0,
      lastOrderDate: map['last_order_date'] != null
          ? DateTime.parse(map['last_order_date'])
          : null,
    );
  }
}

// يمكنك إضافة باقي نماذج التقارير المعقدة هنا..
// لتقرير حركة الخزنة
class MainBoxMovementModel {
  final String transactionType;
  final double amount;
  final DateTime date;
  final String? description;
  final int? userId;

  MainBoxMovementModel({
    required this.transactionType,
    required this.amount,
    required this.date,
    this.description,
    this.userId,
  });

  factory MainBoxMovementModel.fromMap(Map<String, dynamic> map) {
    return MainBoxMovementModel(
      transactionType: map['transaction_type'] ?? 'غير محدد',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      description: map['description'],
      userId: (map['user_id'] as num?)?.toInt(),
    );
  }
}

/// لتعريف التقارير المتاحة
class ReportDefinition {
  final String displayName;
  final Future<List<ReportItemModel>> Function(DateTime from, DateTime to)
  fetchData;
  final bool isTimeBound = true; // هل التقرير يعتمد على فترة زمنية

  ReportDefinition({
    required this.displayName,
    required this.fetchData,
    isTimeBound,
  });
}

// ... وهكذا، نموذج لكل نوع من البيانات المعقدة
