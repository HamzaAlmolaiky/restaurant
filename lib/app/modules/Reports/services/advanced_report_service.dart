// file: services/advanced_report_service.dart

import '../../../helpers/database_helper.dart';
import '../models/advanced_report_models.dart';
import '../models/report_model.dart';

/// خدمة التقارير المتقدمة والمفصلة
class AdvancedReportService {
  static final AdvancedReportService instance = AdvancedReportService._init();
  AdvancedReportService._init();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ==================== التقارير المالية ====================

  /// تقرير الأرباح والخسائر
  Future<ProfitLossReportModel> getProfitLossReport(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await _db.database;

    // حساب إجمالي الإيرادات
    final revenueResult = await db.rawQuery('''
      SELECT 
        SUM(TotalAmount) as total_revenue,
        SUM(TaxAmount) as total_tax,
        SUM(ServiceCharge) as total_service
      FROM Orders 
      WHERE DATE(OrderDate) BETWEEN ? AND ?
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    // حساب التكاليف من المصروفات
    final expenseResult = await db.rawQuery('''
      SELECT 
        SUM(Amount) as total_expenses,
        ExpenseType,
        SUM(Amount) as type_total
      FROM Expenses 
      WHERE DATE(ExpenseDate) BETWEEN ? AND ?
      GROUP BY ExpenseType
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    // تفصيل الإيرادات حسب طريقة الدفع
    final revenueBreakdownResult = await db.rawQuery('''
      SELECT 
        PaymentMethod,
        SUM(TotalAmount) as amount
      FROM Orders 
      WHERE DATE(OrderDate) BETWEEN ? AND ?
      GROUP BY PaymentMethod
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    final totalRevenue = (revenueResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = expenseResult.fold<double>(0.0, (sum, row) => 
        sum + ((row['total_expenses'] as num?)?.toDouble() ?? 0.0));

    final grossProfit = totalRevenue - totalExpenses;
    final netProfit = grossProfit; // يمكن تعديلها لتشمل ضرائب إضافية
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    // بناء تفصيل الإيرادات
    final revenueBreakdown = <String, double>{};
    for (final row in revenueBreakdownResult) {
      revenueBreakdown[row['PaymentMethod'] as String] = 
          (row['amount'] as num?)?.toDouble() ?? 0.0;
    }

    // بناء تفصيل المصروفات
    final expenseBreakdown = <String, double>{};
    for (final row in expenseResult) {
      if (row['ExpenseType'] != null) {
        expenseBreakdown[row['ExpenseType'] as String] = 
            (row['type_total'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return ProfitLossReportModel(
      totalRevenue: totalRevenue,
      totalCosts: totalExpenses,
      grossProfit: grossProfit,
      operatingExpenses: totalExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
      revenueBreakdown: revenueBreakdown,
      expenseBreakdown: expenseBreakdown,
      reportDate: DateTime.now(),
    );
  }

  /// تقرير التدفق النقدي
  Future<CashFlowReportModel> getCashFlowReport(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await _db.database;

    // الرصيد الافتتاحي من الخزنة الرئيسية
    final openingBalanceResult = await db.rawQuery('''
      SELECT Balance FROM Main_Box_Transactions 
      WHERE DATE(TransactionDate) < ?
      ORDER BY TransactionDate DESC 
      LIMIT 1
    ''', [fromDate.toIso8601String().substring(0, 10)]);

    // التدفقات الداخلة (المبيعات والمدفوعات)
    final inflowsResult = await db.rawQuery('''
      SELECT 
        'مبيعات' as description,
        SUM(TotalAmount) as amount,
        OrderDate as date,
        'مبيعات' as category
      FROM Orders 
      WHERE DATE(OrderDate) BETWEEN ? AND ?
      UNION ALL
      SELECT 
        'مدفوعات عملاء' as description,
        SUM(AmountReceived) as amount,
        PaymentDate as date,
        'مدفوعات' as category
      FROM CustomerPayments 
      WHERE DATE(PaymentDate) BETWEEN ? AND ?
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    // التدفقات الخارجة (المصروفات والمشتريات)
    final outflowsResult = await db.rawQuery('''
      SELECT 
        Description as description,
        Amount as amount,
        ExpenseDate as date,
        ExpenseType as category
      FROM Expenses 
      WHERE DATE(ExpenseDate) BETWEEN ? AND ?
      UNION ALL
      SELECT 
        'أمر شراء' as description,
        TotalAmount as amount,
        OrderDate as date,
        'مشتريات' as category
      FROM Purchase_Orders 
      WHERE DATE(OrderDate) BETWEEN ? AND ?
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    // تفصيل طرق الدفع
    final paymentMethodResult = await db.rawQuery('''
      SELECT 
        PaymentMethod,
        SUM(TotalAmount) as amount
      FROM Orders 
      WHERE DATE(OrderDate) BETWEEN ? AND ?
      GROUP BY PaymentMethod
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    final openingBalance = (openingBalanceResult.isNotEmpty 
        ? (openingBalanceResult.first['Balance'] as num?)?.toDouble() 
        : null) ?? 0.0;

    final inflows = inflowsResult.map((row) => CashFlowItemModel.fromMap(row)).toList();
    final outflows = outflowsResult.map((row) => CashFlowItemModel.fromMap(row)).toList();

    final totalInflow = inflows.fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalOutflow = outflows.fold<double>(0.0, (sum, item) => sum + item.amount);
    final closingBalance = openingBalance + totalInflow - totalOutflow;

    final paymentMethodBreakdown = <String, double>{};
    for (final row in paymentMethodResult) {
      paymentMethodBreakdown[row['PaymentMethod'] as String] = 
          (row['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return CashFlowReportModel(
      openingBalance: openingBalance,
      totalInflow: totalInflow,
      totalOutflow: totalOutflow,
      closingBalance: closingBalance,
      inflows: inflows,
      outflows: outflows,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }

  // ==================== تقارير المخزون ====================

  /// تقرير المخزون المفصل
  Future<List<InventoryReportModel>> getInventoryReport() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT 
        i.ItemName as item_name,
        i.ItemCode as item_code,
        i.Category as category,
        i.CurrentStock as current_stock,
        i.ReorderLevel as reorder_level,
        i.CostPerUnit as cost_per_unit,
        (i.CurrentStock * i.CostPerUnit) as total_value,
        CASE 
          WHEN i.CurrentStock <= i.ReorderLevel THEN 'منخفض'
          WHEN i.CurrentStock > i.ReorderLevel * 2 THEN 'مرتفع'
          ELSE 'طبيعي'
        END as status,
        (SELECT MAX(TransactionDate) FROM Inventory_Transactions 
         WHERE InventoryItemID = i.InventoryItemID 
         AND TransactionType = 'استلام') as last_restock_date,
        COALESCE(
          (SELECT AVG(Quantity) FROM Inventory_Transactions 
           WHERE InventoryItemID = i.InventoryItemID 
           AND TransactionType = 'استهلاك'
           AND DATE(TransactionDate) >= DATE('now', '-30 days')), 0
        ) as average_usage
      FROM Inventory_Items i
      WHERE i.IsActive = 1
      ORDER BY i.Category, i.ItemName
    ''');

    return result.map((row) => InventoryReportModel.fromMap(row)).toList();
  }

  /// تقرير المشتريات
  Future<List<PurchaseReportModel>> getPurchaseReport(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT 
        s.SupplierName as supplier_name,
        po.OrderNumber as order_number,
        po.OrderDate as order_date,
        po.ExpectedDeliveryDate as delivery_date,
        po.Status as status,
        po.TotalAmount as total_amount,
        COUNT(poi.POItemID) as items_count
      FROM Purchase_Orders po
      JOIN Suppliers s ON po.SupplierID = s.SupplierID
      LEFT JOIN Purchase_Order_Items poi ON po.PurchaseOrderID = poi.PurchaseOrderID
      WHERE DATE(po.OrderDate) BETWEEN ? AND ?
      GROUP BY po.PurchaseOrderID
      ORDER BY po.OrderDate DESC
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    final reports = <PurchaseReportModel>[];
    for (final row in result) {
      // جلب تفاصيل العناصر لكل أمر شراء
      final itemsResult = await db.rawQuery('''
        SELECT 
          ii.ItemName as item_name,
          poi.QuantityOrdered as quantity_ordered,
          poi.QuantityReceived as quantity_received,
          poi.UnitPrice as unit_price,
          poi.TotalPrice as total_price
        FROM Purchase_Order_Items poi
        JOIN Inventory_Items ii ON poi.InventoryItemID = ii.InventoryItemID
        WHERE poi.PurchaseOrderID = (
          SELECT PurchaseOrderID FROM Purchase_Orders 
          WHERE OrderNumber = ?
        )
      ''', [row['order_number']]);

      final items = itemsResult.map((item) => PurchaseItemModel.fromMap(item)).toList();
      
      final report = PurchaseReportModel.fromMap({
        ...row,
        'items': items,
      });
      
      reports.add(report);
    }

    return reports;
  }

  // ==================== تقارير الموظفين ====================

  /// تقرير الحضور والانصراف
  Future<List<AttendanceReportModel>> getAttendanceReport(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT 
        e.FullName as employee_name,
        e.Position as position,
        a.Date as date,
        a.CheckInTime as check_in_time,
        a.CheckOutTime as check_out_time,
        a.TotalHours as total_hours,
        a.OvertimeHours as overtime_hours,
        a.Status as status,
        a.Notes as notes
      FROM Attendance a
      JOIN Employees e ON a.EmployeeID = e.EmployeeID
      WHERE DATE(a.Date) BETWEEN ? AND ?
      ORDER BY a.Date DESC, e.FullName
    ''', [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    return result.map((row) => AttendanceReportModel.fromMap(row)).toList();
  }

  /// تقرير أداء الموظفين
  Future<List<EmployeePerformanceModel>> getEmployeePerformanceReport(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT 
        e.FullName as employee_name,
        e.Position as position,
        COALESCE(SUM(o.TotalAmount), 0) as total_sales,
        COUNT(o.OrderID) as orders_processed,
        COALESCE(AVG(o.TotalAmount), 0) as average_order_value,
        COALESCE(
          (SELECT COUNT(*) * 100.0 / 
           (julianday(?) - julianday(?) + 1)
           FROM Attendance a2 
           WHERE a2.EmployeeID = e.EmployeeID 
           AND DATE(a2.Date) BETWEEN ? AND ?
           AND a2.Status = 'حاضر'), 0
        ) as attendance_rate,
        0 as customer_complaints,
        CASE 
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 10000 THEN 95
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 5000 THEN 85
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 1000 THEN 75
          ELSE 60
        END as performance_score
      FROM Employees e
      LEFT JOIN Orders o ON e.EmployeeID = o.UserID 
        AND DATE(o.OrderDate) BETWEEN ? AND ?
      WHERE e.IsActive = 1
      GROUP BY e.EmployeeID
      ORDER BY total_sales DESC
    ''', [
      toDate.toIso8601String().substring(0, 10),
      fromDate.toIso8601String().substring(0, 10),
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ]);

    return result.map((row) => EmployeePerformanceModel.fromMap({
      ...row,
      'report_period_start': fromDate.toIso8601String(),
      'report_period_end': toDate.toIso8601String(),
    })).toList();
  }

  // ==================== تقارير العملاء المتقدمة ====================

  /// تقرير ولاء العملاء
  Future<List<CustomerLoyaltyModel>> getCustomerLoyaltyReport() async {
    final db = await _db.database;

    final result = await db.rawQuery('''
      SELECT 
        c.CustomerName as customer_name,
        c.PhoneNumber as phone_number,
        COUNT(o.OrderID) as total_orders,
        COALESCE(SUM(o.TotalAmount), 0) as total_spent,
        COALESCE(AVG(o.TotalAmount), 0) as average_order_value,
        COALESCE(
          julianday('now') - julianday(MIN(o.OrderDate)), 0
        ) as days_as_customer,
        MIN(o.OrderDate) as first_order_date,
        MAX(o.OrderDate) as last_order_date,
        CASE 
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 5000 THEN 'بلاتيني'
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 2000 THEN 'ذهبي'
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 500 THEN 'فضي'
          ELSE 'برونزي'
        END as loyalty_tier,
        CASE 
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 5000 THEN 95
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 2000 THEN 85
          WHEN COALESCE(SUM(o.TotalAmount), 0) > 500 THEN 70
          ELSE 50
        END as loyalty_score
      FROM Customers c
      LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
      GROUP BY c.CustomerID
      HAVING COUNT(o.OrderID) > 0
      ORDER BY total_spent DESC
    ''');

    final loyaltyReports = <CustomerLoyaltyModel>[];
    for (final row in result) {
      // جلب الأصناف المفضلة للعميل
      final favoritesResult = await db.rawQuery('''
        SELECT mi.ItemsName
        FROM Order_Items oi
        JOIN Menu_Items mi ON oi.MenuItemID = mi.MenuItemsID
        JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE o.CustomerID = (
          SELECT CustomerID FROM Customers WHERE CustomerName = ?
        )
        GROUP BY mi.MenuItemsID
        ORDER BY SUM(oi.Quantity) DESC
        LIMIT 3
      ''', [row['customer_name']]);

      final favoriteItems = favoritesResult
          .map((item) => item['ItemsName'] as String)
          .toList();

      final loyalty = CustomerLoyaltyModel.fromMap({
        ...row,
        'favorite_items': favoriteItems,
      });
      
      loyaltyReports.add(loyalty);
    }

    return loyaltyReports;
  }

  // ==================== تقارير الأداء والمقارنات ====================

  /// تقرير مقارنة الأداء
  Future<List<PerformanceComparisonModel>> getPerformanceComparison(
    DateTime currentStart,
    DateTime currentEnd,
    DateTime previousStart,
    DateTime previousEnd,
  ) async {
    final db = await _db.database;

    final metrics = [
      {'name': 'إجمالي المبيعات', 'query': 'SUM(TotalAmount)', 'table': 'Orders', 'category': 'مالي'},
      {'name': 'عدد الطلبات', 'query': 'COUNT(OrderID)', 'table': 'Orders', 'category': 'مبيعات'},
      {'name': 'متوسط قيمة الطلب', 'query': 'AVG(TotalAmount)', 'table': 'Orders', 'category': 'مبيعات'},
      {'name': 'عدد العملاء الجدد', 'query': 'COUNT(CustomerID)', 'table': 'Customers', 'category': 'عملاء'},
    ];

    final comparisons = <PerformanceComparisonModel>[];

    for (final metric in metrics) {
      // الفترة الحالية
      final currentResult = await db.rawQuery('''
        SELECT ${metric['query']} as value
        FROM ${metric['table']}
        WHERE DATE(${metric['table'] == 'Orders' ? 'OrderDate' : 'RegistrationDate'}) 
        BETWEEN ? AND ?
      ''', [
        currentStart.toIso8601String().substring(0, 10),
        currentEnd.toIso8601String().substring(0, 10),
      ]);

      // الفترة السابقة
      final previousResult = await db.rawQuery('''
        SELECT ${metric['query']} as value
        FROM ${metric['table']}
        WHERE DATE(${metric['table'] == 'Orders' ? 'OrderDate' : 'RegistrationDate'}) 
        BETWEEN ? AND ?
      ''', [
        previousStart.toIso8601String().substring(0, 10),
        previousEnd.toIso8601String().substring(0, 10),
      ]);

      final currentValue = (currentResult.first['value'] as num?)?.toDouble() ?? 0.0;
      final previousValue = (previousResult.first['value'] as num?)?.toDouble() ?? 0.0;
      final changeAmount = currentValue - previousValue;
      final changePercentage = previousValue > 0 ? (changeAmount / previousValue) * 100 : 0.0;

      String trend;
      if (changePercentage > 5) {
        trend = 'صاعد';
      } else if (changePercentage < -5) {
        trend = 'هابط';
      } else {
        trend = 'ثابت';
      }

      comparisons.add(PerformanceComparisonModel(
        metric: metric['name'] as String,
        currentPeriod: currentValue,
        previousPeriod: previousValue,
        changeAmount: changeAmount,
        changePercentage: changePercentage,
        trend: trend,
        category: metric['category'] as String,
      ));
    }

    return comparisons;
  }

  // ==================== دوال مساعدة لتحويل البيانات إلى ReportItemModel ====================

  /// تحويل تقرير الأرباح والخسائر إلى ReportItemModel
  Future<List<ReportItemModel>> getProfitLossAsReportItems(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final report = await getProfitLossReport(fromDate, toDate);
    
    return [
      ReportItemModel(label: 'إجمالي الإيرادات', value: report.totalRevenue),
      ReportItemModel(label: 'إجمالي التكاليف', value: report.totalCosts),
      ReportItemModel(label: 'إجمالي الربح', value: report.grossProfit),
      ReportItemModel(label: 'صافي الربح', value: report.netProfit),
      ReportItemModel(label: 'هامش الربح %', value: report.profitMargin),
    ];
  }

  /// تحويل تقرير التدفق النقدي إلى ReportItemModel
  Future<List<ReportItemModel>> getCashFlowAsReportItems(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final report = await getCashFlowReport(fromDate, toDate);
    
    return [
      ReportItemModel(label: 'الرصيد الافتتاحي', value: report.openingBalance),
      ReportItemModel(label: 'إجمالي التدفق الداخل', value: report.totalInflow),
      ReportItemModel(label: 'إجمالي التدفق الخارج', value: report.totalOutflow),
      ReportItemModel(label: 'الرصيد الختامي', value: report.closingBalance),
    ];
  }
}
