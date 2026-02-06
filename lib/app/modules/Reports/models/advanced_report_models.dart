// file: models/advanced_report_models.dart

/// نماذج التقارير المتقدمة والمفصلة
library;

// ==================== التقارير المالية ====================

/// تقرير الأرباح والخسائر
class ProfitLossReportModel {
  final double totalRevenue;
  final double totalCosts;
  final double grossProfit;
  final double operatingExpenses;
  final double netProfit;
  final double profitMargin;
  final Map<String, double> revenueBreakdown;
  final Map<String, double> expenseBreakdown;
  final DateTime reportDate;

  ProfitLossReportModel({
    required this.totalRevenue,
    required this.totalCosts,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.revenueBreakdown,
    required this.expenseBreakdown,
    required this.reportDate,
  });

  factory ProfitLossReportModel.fromMap(Map<String, dynamic> map) {
    return ProfitLossReportModel(
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCosts: (map['total_costs'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (map['gross_profit'] as num?)?.toDouble() ?? 0.0,
      operatingExpenses: (map['operating_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (map['net_profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (map['profit_margin'] as num?)?.toDouble() ?? 0.0,
      revenueBreakdown: Map<String, double>.from(
        map['revenue_breakdown'] ?? {},
      ),
      expenseBreakdown: Map<String, double>.from(
        map['expense_breakdown'] ?? {},
      ),
      reportDate: DateTime.parse(map['report_date']),
    );
  }
}

/// تقرير التدفق النقدي
class CashFlowReportModel {
  final double openingBalance;
  final double totalInflow;
  final double totalOutflow;
  final double closingBalance;
  final List<CashFlowItemModel> inflows;
  final List<CashFlowItemModel> outflows;
  final Map<String, double> paymentMethodBreakdown;

  CashFlowReportModel({
    required this.openingBalance,
    required this.totalInflow,
    required this.totalOutflow,
    required this.closingBalance,
    required this.inflows,
    required this.outflows,
    required this.paymentMethodBreakdown,
  });
}

class CashFlowItemModel {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? reference;

  CashFlowItemModel({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.reference,
  });

  factory CashFlowItemModel.fromMap(Map<String, dynamic> map) {
    return CashFlowItemModel(
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      category: map['category'] ?? '',
      reference: map['reference'],
    );
  }
}

// ==================== تقارير المخزون ====================

/// تقرير المخزون المفصل
class InventoryReportModel {
  final String itemName;
  final String itemCode;
  final String category;
  final double currentStock;
  final double reorderLevel;
  final double costPerUnit;
  final double totalValue;
  final String status; // منخفض، طبيعي، مرتفع
  final DateTime? lastRestockDate;
  final double averageUsage; // متوسط الاستهلاك اليومي

  InventoryReportModel({
    required this.itemName,
    required this.itemCode,
    required this.category,
    required this.currentStock,
    required this.reorderLevel,
    required this.costPerUnit,
    required this.totalValue,
    required this.status,
    this.lastRestockDate,
    required this.averageUsage,
  });

  factory InventoryReportModel.fromMap(Map<String, dynamic> map) {
    return InventoryReportModel(
      itemName: map['item_name'] ?? '',
      itemCode: map['item_code'] ?? '',
      category: map['category'] ?? '',
      currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0.0,
      costPerUnit: (map['cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      totalValue: (map['total_value'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'طبيعي',
      lastRestockDate: map['last_restock_date'] != null
          ? DateTime.parse(map['last_restock_date'])
          : null,
      averageUsage: (map['average_usage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// تقرير المشتريات
class PurchaseReportModel {
  final String supplierName;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String status;
  final double totalAmount;
  final int itemsCount;
  final List<PurchaseItemModel> items;

  PurchaseReportModel({
    required this.supplierName,
    required this.orderNumber,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
    required this.totalAmount,
    required this.itemsCount,
    required this.items,
  });

  factory PurchaseReportModel.fromMap(Map<String, dynamic> map) {
    return PurchaseReportModel(
      supplierName: map['supplier_name'] ?? '',
      orderNumber: map['order_number'] ?? '',
      orderDate: DateTime.parse(map['order_date']),
      deliveryDate: map['delivery_date'] != null
          ? DateTime.parse(map['delivery_date'])
          : null,
      status: map['status'] ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (map['items_count'] as num?)?.toInt() ?? 0,
      items:
          (map['items'] as List?)
              ?.map((item) => PurchaseItemModel.fromMap(item))
              .toList() ??
          [],
    );
  }
}

class PurchaseItemModel {
  final String itemName;
  final double quantityOrdered;
  final double quantityReceived;
  final double unitPrice;
  final double totalPrice;

  PurchaseItemModel({
    required this.itemName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      itemName: map['item_name'] ?? '',
      quantityOrdered: (map['quantity_ordered'] as num?)?.toDouble() ?? 0.0,
      quantityReceived: (map['quantity_received'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ==================== تقارير الموظفين ====================

/// تقرير الحضور والانصراف
class AttendanceReportModel {
  final String employeeName;
  final String position;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double totalHours;
  final double overtimeHours;
  final String status; // حاضر، غائب، متأخر، إجازة
  final String? notes;

  AttendanceReportModel({
    required this.employeeName,
    required this.position,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.totalHours,
    required this.overtimeHours,
    required this.status,
    this.notes,
  });

  factory AttendanceReportModel.fromMap(Map<String, dynamic> map) {
    return AttendanceReportModel(
      employeeName: map['employee_name'] ?? '',
      position: map['position'] ?? '',
      date: DateTime.parse(map['date']),
      checkInTime: map['check_in_time'] != null
          ? DateTime.parse(map['check_in_time'])
          : null,
      checkOutTime: map['check_out_time'] != null
          ? DateTime.parse(map['check_out_time'])
          : null,
      totalHours: (map['total_hours'] as num?)?.toDouble() ?? 0.0,
      overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      notes: map['notes'],
    );
  }
}

/// تقرير أداء الموظفين
class EmployeePerformanceModel {
  final String employeeName;
  final String position;
  final double totalSales;
  final int ordersProcessed;
  final double averageOrderValue;
  final double attendanceRate;
  final int customerComplaints;
  final double performanceScore;
  final DateTime reportPeriodStart;
  final DateTime reportPeriodEnd;

  EmployeePerformanceModel({
    required this.employeeName,
    required this.position,
    required this.totalSales,
    required this.ordersProcessed,
    required this.averageOrderValue,
    required this.attendanceRate,
    required this.customerComplaints,
    required this.performanceScore,
    required this.reportPeriodStart,
    required this.reportPeriodEnd,
  });

  factory EmployeePerformanceModel.fromMap(Map<String, dynamic> map) {
    return EmployeePerformanceModel(
      employeeName: map['employee_name'] ?? '',
      position: map['position'] ?? '',
      totalSales: (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      ordersProcessed: (map['orders_processed'] as num?)?.toInt() ?? 0,
      averageOrderValue:
          (map['average_order_value'] as num?)?.toDouble() ?? 0.0,
      attendanceRate: (map['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      customerComplaints: (map['customer_complaints'] as num?)?.toInt() ?? 0,
      performanceScore: (map['performance_score'] as num?)?.toDouble() ?? 0.0,
      reportPeriodStart: DateTime.parse(map['report_period_start']),
      reportPeriodEnd: DateTime.parse(map['report_period_end']),
    );
  }
}

// ==================== تقارير العملاء المتقدمة ====================

/// تقرير ولاء العملاء
class CustomerLoyaltyModel {
  final String customerName;
  final String? phoneNumber;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final int daysAsCustomer;
  final DateTime firstOrderDate;
  final DateTime lastOrderDate;
  final String loyaltyTier; // برونزي، فضي، ذهبي، بلاتيني
  final double loyaltyScore;
  final List<String> favoriteItems;

  CustomerLoyaltyModel({
    required this.customerName,
    this.phoneNumber,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    required this.daysAsCustomer,
    required this.firstOrderDate,
    required this.lastOrderDate,
    required this.loyaltyTier,
    required this.loyaltyScore,
    required this.favoriteItems,
  });

  factory CustomerLoyaltyModel.fromMap(Map<String, dynamic> map) {
    return CustomerLoyaltyModel(
      customerName: map['customer_name'] ?? '',
      phoneNumber: map['phone_number'],
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue:
          (map['average_order_value'] as num?)?.toDouble() ?? 0.0,
      daysAsCustomer: (map['days_as_customer'] as num?)?.toInt() ?? 0,
      firstOrderDate: DateTime.parse(map['first_order_date']),
      lastOrderDate: DateTime.parse(map['last_order_date']),
      loyaltyTier: map['loyalty_tier'] ?? 'برونزي',
      loyaltyScore: (map['loyalty_score'] as num?)?.toDouble() ?? 0.0,
      favoriteItems: List<String>.from(map['favorite_items'] ?? []),
    );
  }
}

// ==================== تقارير الأداء والمقارنات ====================

/// تقرير مقارنة الأداء
class PerformanceComparisonModel {
  final String metric;
  final double currentPeriod;
  final double previousPeriod;
  final double changeAmount;
  final double changePercentage;
  final String trend; // صاعد، هابط، ثابت
  final String category;

  PerformanceComparisonModel({
    required this.metric,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.changeAmount,
    required this.changePercentage,
    required this.trend,
    required this.category,
  });

  factory PerformanceComparisonModel.fromMap(Map<String, dynamic> map) {
    return PerformanceComparisonModel(
      metric: map['metric'] ?? '',
      currentPeriod: (map['current_period'] as num?)?.toDouble() ?? 0.0,
      previousPeriod: (map['previous_period'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      changePercentage: (map['change_percentage'] as num?)?.toDouble() ?? 0.0,
      trend: map['trend'] ?? 'ثابت',
      category: map['category'] ?? '',
    );
  }
}

/// تقرير تحليل الاتجاهات
class TrendAnalysisModel {
  final String period;
  final double value;
  final double movingAverage;
  final double seasonalIndex;
  final String forecast;

  TrendAnalysisModel({
    required this.period,
    required this.value,
    required this.movingAverage,
    required this.seasonalIndex,
    required this.forecast,
  });

  factory TrendAnalysisModel.fromMap(Map<String, dynamic> map) {
    return TrendAnalysisModel(
      period: map['period'] ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      movingAverage: (map['moving_average'] as num?)?.toDouble() ?? 0.0,
      seasonalIndex: (map['seasonal_index'] as num?)?.toDouble() ?? 0.0,
      forecast: map['forecast'] ?? '',
    );
  }
}
