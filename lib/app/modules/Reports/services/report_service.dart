// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../models/report_model.dart';

class ReportService {
  static final ReportService instance = ReportService._internal();
  ReportService._internal();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // --- دوال مساعدة ---
  String _fromDate(DateTime date) =>
      "${date.toIso8601String().substring(0, 10)} 00:00:00";
  String _toDate(DateTime date) =>
      "${date.toIso8601String().substring(0, 10)} 23:59:59";

  // دالة مساعدة عامة للتقارير البسيطة (من Service1)
  Future<List<ReportItemModel>> _fetchSimpleReport(
    String query, [
    List<dynamic>? params,
  ]) async {
    final maps = await (await _db).rawQuery(query, params);
    if (maps.isEmpty) return [];
    final keys = maps.first.keys.toList();
    return maps
        .map(
          (map) => ReportItemModel(
            label: map[keys[0]].toString(),
            value: (map[keys[1]] as num? ?? 0.0).toDouble(),
            secondaryValue: keys.length > 2
                ? (map[keys[2]] as num? ?? 0.0).toDouble()
                : null,
          ),
        )
        .toList();
  }

  // دالة مساعدة لبناء فلاتر التاريخ (من Service2)
  Map<String, dynamic> _buildDateFilter(
    DateTime? start,
    DateTime? end, {
    String dateColumn = 'created_at',
  }) {
    String clause = '';
    List<dynamic> args = [];
    if (start != null) {
      clause += ' AND $dateColumn >= ?';
      args.add(start.toIso8601String());
    }
    if (end != null) {
      clause += ' AND $dateColumn < ?';
      args.add(end.toIso8601String());
    }
    return {'clause': clause, 'args': args};
  }

  // -------------------------------------------------------------------
  // دوال التقارير البسيطة (متوافقة مع الكنترولر)
  // -------------------------------------------------------------------

  Future<List<ReportItemModel>> getSalesByPaymentMethod(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT PaymentMethod as label, SUM(TotalAmount) as value FROM Orders WHERE OrderDate BETWEEN ? AND ? GROUP BY label";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getSalesByEmployee(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT u.Username as label, SUM(o.TotalAmount) as value FROM Orders o JOIN Users u ON o.UserID = u.UserID WHERE o.OrderDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getTopSellingItems(
    DateTime from,
    DateTime to,
  ) async {
    // Try camel-case schema first, then fallback to underscore schema
    const queryCamel =
        "SELECT mi.ItemsName as label, SUM(oi.Total) as value, SUM(oi.Quantity) as secondaryValue FROM OrderItems oi JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID JOIN Orders o ON oi.OrderID = o.OrderID WHERE o.OrderDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC LIMIT 20";
    const queryUnderscore =
        "SELECT mi.ItemName as label, SUM(oi.Total) as value, SUM(oi.Quantity) as secondaryValue FROM Order_Items oi JOIN Menu_Items mi ON oi.ItemID = mi.ItemID JOIN Orders o ON oi.OrderID = o.OrderID WHERE o.OrderDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC LIMIT 20";
    try {
      return await _fetchSimpleReport(queryCamel, [_fromDate(from), _toDate(to)]);
    } catch (_) {
      return await _fetchSimpleReport(queryUnderscore, [_fromDate(from), _toDate(to)]);
    }
  }

  Future<List<ReportItemModel>> getCustomerBalances() async {
    const query =
        "SELECT CustomerName as label, CurrentBalance as value FROM Customers WHERE CurrentBalance != 0 ORDER BY value DESC";
    return await _fetchSimpleReport(query);
  }

  Future<List<ReportItemModel>> getSalesByShift(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT 'وردية ' || ShiftID as label, SUM(TotalAmount) as value FROM Orders WHERE OrderDate BETWEEN ? AND ? AND ShiftID IS NOT NULL GROUP BY label ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getTopCustomersSimple(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT c.CustomerName as label, SUM(o.TotalAmount) as value FROM Orders o JOIN Customers c ON o.CustomerID = c.CustomerID WHERE o.OrderDate BETWEEN ? AND ? AND o.CustomerID IS NOT NULL GROUP BY label ORDER BY value DESC LIMIT 20";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getCustomerDebts() async {
    const query =
        "SELECT CustomerName as label, CurrentBalance as value FROM Customers WHERE CurrentBalance > 0 ORDER BY value DESC";
    return await _fetchSimpleReport(query);
  }

  Future<List<ReportItemModel>> getExpensesByType(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT ExpenseType as label, SUM(Amount) as value FROM Expenses WHERE ExpenseDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getItemMovement(
    DateTime from,
    DateTime to,
  ) async {
    const queryCamel =
        "SELECT mi.ItemsName as label, SUM(oi.Quantity) as value FROM OrderItems oi JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID JOIN Orders o ON oi.OrderID = o.OrderID WHERE o.OrderDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    const queryUnderscore =
        "SELECT mi.ItemName as label, SUM(oi.Quantity) as value FROM Order_Items oi JOIN Menu_Items mi ON oi.ItemID = mi.ItemID JOIN Orders o ON oi.OrderID = o.OrderID WHERE o.OrderDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    try {
      return await _fetchSimpleReport(queryCamel, [_fromDate(from), _toDate(to)]);
    } catch (_) {
      return await _fetchSimpleReport(queryUnderscore, [_fromDate(from), _toDate(to)]);
    }
  }

  Future<List<ReportItemModel>> getTaxSummary(
    DateTime from,
    DateTime to,
  ) async {
    // ملخص ضريبي دقيق بالاعتماد على أعمدة الطلب
    // total = إجمالي الفاتورة (يشمل الضريبة ورسوم الخدمة)
    // net_before_tax = total - tax - service
    final db = await _db;
    const q =
        "SELECT IFNULL(SUM(TotalAmount),0) as total, IFNULL(SUM(TaxAmount),0) as tax, IFNULL(SUM(ServiceCharge),0) as service FROM Orders WHERE OrderDate BETWEEN ? AND ?";
    final row = (await db.rawQuery(q, [_fromDate(from), _toDate(to)])).first;

    final total = (row['total'] as num? ?? 0).toDouble();
    final tax = (row['tax'] as num? ?? 0).toDouble();
    final service = (row['service'] as num? ?? 0).toDouble();
    final netBeforeTax = total - tax - service;

    return [
      ReportItemModel(label: 'صافي المبيعات قبل الضريبة', value: netBeforeTax),
      ReportItemModel(label: 'ضريبة المخرجات', value: tax),
      ReportItemModel(label: 'رسوم الخدمة', value: service),
    ];
  }

  Future<List<ReportItemModel>> getSalesSummary(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT DATE(OrderDate) as label, SUM(TotalAmount) as value FROM Orders WHERE OrderDate BETWEEN ? AND ? GROUP BY DATE(OrderDate) ORDER BY DATE(OrderDate)";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getSalesSummaryNetGross(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT DATE(OrderDate) as label, IFNULL(SUM(TotalAmount),0) as gross, IFNULL(SUM(TotalAmount - IFNULL(TaxAmount,0) - IFNULL(ServiceCharge,0)),0) as net FROM Orders WHERE OrderDate BETWEEN ? AND ? GROUP BY DATE(OrderDate) ORDER BY DATE(OrderDate)";
    final maps = await (await _db).rawQuery(query, [_fromDate(from), _toDate(to)]);
    return maps
        .map((m) => ReportItemModel(
              label: m['label'].toString(),
              value: (m['gross'] as num? ?? 0).toDouble(),
              secondaryValue: (m['net'] as num? ?? 0).toDouble(),
            ))
        .toList();
  }

  Future<List<ReportItemModel>> getCustomerPaymentsSummary(
    DateTime from,
    DateTime to,
  ) async {
    // نحاول أولاً التجميع حسب طريقة الدفع إن كانت موجودة
    const byMethodQuery =
        "SELECT PaymentMethod as label, SUM(AmountReceived) as value FROM CustomerPayments WHERE PaymentDate BETWEEN ? AND ? GROUP BY PaymentMethod ORDER BY value DESC";
    const byDateFallbackQuery =
        "SELECT DATE(PaymentDate) as label, SUM(AmountReceived) as value FROM CustomerPayments WHERE PaymentDate BETWEEN ? AND ? GROUP BY DATE(PaymentDate) ORDER BY DATE(PaymentDate)";
    try {
      return await _fetchSimpleReport(byMethodQuery, [
        _fromDate(from),
        _toDate(to),
      ]);
    } catch (_) {
      // في حال عدم وجود عمود PaymentMethod أو أي خطأ مشابه، نستخدم ملخصاً يومياً كبديل
      return await _fetchSimpleReport(byDateFallbackQuery, [
        _fromDate(from),
        _toDate(to),
      ]);
    }
  }

  Future<List<ReportItemModel>> getReturnsSummary(
    DateTime from,
    DateTime to,
  ) async {
    // ملاحظة: تم توحيد مخطط المرتجعات لاستخدام جدول Returns وعمود Amount وReturnDate
    const query =
        "SELECT 'إجمالي المرتجعات' as label, IFNULL(SUM(Amount), 0) as value FROM Returns WHERE ReturnDate BETWEEN ? AND ?";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getShiftSummary(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT 'وردية ' || ShiftID as label, SUM(TotalAmount) as value, COUNT(*) as secondaryValue FROM Orders WHERE OrderDate BETWEEN ? AND ? AND ShiftID IS NOT NULL GROUP BY ShiftID ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getReturnsByReason(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT CASE WHEN TRIM(IFNULL(Notes,''))='' THEN 'غير محدد' ELSE TRIM(Notes) END as label, SUM(Amount) as value FROM Returns WHERE ReturnDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getProfitAndLoss(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;

    const salesAggQuery =
        "SELECT IFNULL(SUM(TotalAmount), 0) as gross, IFNULL(SUM(TaxAmount), 0) as tax, IFNULL(SUM(ServiceCharge), 0) as service FROM Orders WHERE OrderDate BETWEEN ? AND ?";
    const expensesQuery =
        "SELECT IFNULL(SUM(Amount), 0) as v FROM Expenses WHERE ExpenseDate BETWEEN ? AND ?";
    const returnsQuery =
        "SELECT IFNULL(SUM(Amount), 0) as v FROM Returns WHERE ReturnDate BETWEEN ? AND ?";

    final params = [_fromDate(from), _toDate(to)];
    final salesAgg = await db.rawQuery(salesAggQuery, params);
    final expenses = await db.rawQuery(expensesQuery, params);
    final returns = await db.rawQuery(returnsQuery, params);

    final gross = (salesAgg.first['gross'] as num? ?? 0).toDouble();
    final tax = (salesAgg.first['tax'] as num? ?? 0).toDouble();
    final service = (salesAgg.first['service'] as num? ?? 0).toDouble();
    // الإيراد المستبعد منه الضريبة (VAT excluded revenue) = إجمالي - ضريبة
    final revenueExVat = gross - tax;
    final e = (expenses.first['v'] as num? ?? 0).toDouble();
    final r = (returns.first['v'] as num? ?? 0).toDouble();
    final net = revenueExVat - e - r;

    return [
      ReportItemModel(label: 'إجمالي المبيعات (شامل الضريبة والخدمة)', value: gross),
      ReportItemModel(label: 'ضريبة المخرجات (غير محسوبة ضمن الإيراد)', value: tax),
      ReportItemModel(label: 'رسوم الخدمة (ضمن الإيراد)', value: service),
      ReportItemModel(label: 'إيرادات مستبعدة الضريبة', value: revenueExVat),
      ReportItemModel(label: 'إجمالي المصروفات', value: e),
      ReportItemModel(label: 'إجمالي المرتجعات', value: r),
      ReportItemModel(label: 'صافي الربح التقريبي', value: net),
    ];
  }

  Future<List<ReportItemModel>> getExpensesSummary(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT DATE(ExpenseDate) as label, SUM(Amount) as value FROM Expenses WHERE ExpenseDate BETWEEN ? AND ? GROUP BY DATE(ExpenseDate) ORDER BY DATE(ExpenseDate)";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<Map<String, dynamic>>> getTaxDetailByInvoice(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;
    const query = """
      SELECT 
        OrderID as order_id,
        OrderDate as order_date,
        IFNULL(TotalAmount - IFNULL(TaxAmount,0) - IFNULL(ServiceCharge,0),0) as net_before_tax,
        IFNULL(TaxAmount,0) as tax_amount,
        IFNULL(ServiceCharge,0) as service_charge,
        IFNULL(TotalAmount,0) as total_amount
      FROM Orders
      WHERE OrderDate BETWEEN ? AND ?
      ORDER BY OrderDate ASC
    """;
    return await db.rawQuery(query, [_fromDate(from), _toDate(to)]);
  }

  // -------------------------------------------------------------------
  // دوال التقارير المعقدة والمفصلة (للاستخدام المتقدم)
  // -------------------------------------------------------------------

  Future<DailySalesReportModel> getDailySalesReport(DateTime date) async {
    final db = await _db;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    final params = [startDate.toIso8601String(), endDate.toIso8601String()];

    final salesResult = await db.rawQuery(
      "SELECT COUNT(*) as total_orders, SUM(TotalAmount) as total_sales FROM Orders WHERE OrderDate >= ? AND OrderDate < ?",
      params,
    );
    final hourlyResult = await db.rawQuery(
      "SELECT strftime('%H', OrderDate) as hour, COUNT(*) as orders, SUM(TotalAmount) as sales FROM Orders WHERE OrderDate >= ? AND OrderDate < ? GROUP BY hour ORDER BY hour",
      params,
    );

    return DailySalesReportModel.fromMap({
      'summary': salesResult.first,
      'hourly': hourlyResult,
    });
  }

  // Future<List<Map<String, dynamic>>> getMonthlySalesReport(
  //   int year,
  //   int month,
  // ) async {
  //   final db = await _db;
  //   return await db.rawQuery(
  //     "SELECT DATE(OrderDate) as date, COUNT(*) as total_orders, SUM(TotalAmount) as total_sales FROM Orders WHERE strftime('%Y', OrderDate) = ? AND strftime('%m', OrderDate) = ? GROUP BY date ORDER BY date",
  //     [year.toString(), month.toString().padLeft(2, '0')],
  //   );
  // }

  // الدالة الجديدة (أكثر موثوقية)
  Future<List<Map<String, dynamic>>> getMonthlySalesReport(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;
    const query = """
    SELECT 
      DATE(OrderDate) as date, 
      COUNT(*) as total_orders, 
      SUM(TotalAmount) as total_sales 
    FROM Orders 
    WHERE OrderDate BETWEEN ? AND ? 
    GROUP BY date 
    ORDER BY date
  """;
    // نستخدم نفس دوال التنسيق الناجحة
    return await db.rawQuery(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<BestSellingItemReportModel>> getBestSellingItemsReport({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    final db = await _db;
    final dateFilter = _buildDateFilter(
      startDate,
      endDate,
      dateColumn: 'o.OrderDate',
    );
    final whereClause = "1=1" + dateFilter['clause'];
    final whereArgs = dateFilter['args']..add(limit);

    List<Map<String, Object?>> maps;
    try {
      maps = await db.rawQuery('''
        SELECT mi.ItemsName as name, mc.CategoryName as category_name, SUM(oi.Quantity) as total_quantity, SUM(oi.Total) as total_revenue, AVG(oi.Price) as avg_price
        FROM OrderItems oi
        JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
        JOIN MenuCategory mc ON mi.CategoryID = mc.CategoryID
        JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE $whereClause GROUP BY oi.ItemsID, mi.ItemsName, mc.CategoryName
        ORDER BY total_quantity DESC LIMIT ?
      ''', whereArgs);
    } catch (_) {
      maps = await db.rawQuery('''
        SELECT mi.ItemName as name, mc.CategoryName as category_name, SUM(oi.Quantity) as total_quantity, SUM(oi.Total) as total_revenue, AVG(oi.Price) as avg_price
        FROM Order_Items oi
        JOIN Menu_Items mi ON oi.ItemID = mi.ItemID
        JOIN Menu_Category mc ON mi.CategoryID = mc.CategoryID
        JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE $whereClause GROUP BY oi.ItemID, mi.ItemName, mc.CategoryName
        ORDER BY total_quantity DESC LIMIT ?
      ''', whereArgs);
    }
    return maps.map((map) => BestSellingItemReportModel.fromMap(map)).toList();
  }

  Future<List<TopCustomerReportModel>> getTopCustomersReport({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    final db = await _db;
    final dateFilter = _buildDateFilter(
      startDate,
      endDate,
      dateColumn: 'o.OrderDate',
    );
    final whereClause = "1=1" + dateFilter['clause'];
    final whereArgs = dateFilter['args']..add(limit);

    final maps = await db.rawQuery('''
        SELECT c.CustomerName as name, c.PhoneNumber as phone, COUNT(o.OrderID) as total_orders, SUM(o.TotalAmount) as total_spent, AVG(o.TotalAmount) as avg_order_value, MAX(o.OrderDate) as last_order_date
        FROM Customers c JOIN Orders o ON c.CustomerID = o.CustomerID
        WHERE $whereClause GROUP BY c.CustomerID, c.CustomerName, c.PhoneNumber
        ORDER BY total_spent DESC LIMIT ?
      ''', whereArgs);
    return maps.map((map) => TopCustomerReportModel.fromMap(map)).toList();
  }

  // Future<List<Map<String, dynamic>>> getCategoryRevenueReport({
  //   DateTime? startDate,
  //   DateTime? endDate,
  // }) async {
  //   final db = await _db;
  //   final dateFilter = _buildDateFilter(
  //     startDate,
  //     endDate,
  //     dateColumn: 'o.OrderDate',
  //   );
  //   final whereClause = "1=1" + dateFilter['clause'];
  //   final whereArgs = dateFilter['args'];

  //   return await db.rawQuery('''
  //       SELECT mc.CategoryName as category_name, SUM(oi.Quantity * oi.Price) as total_revenue
  //       FROM OrderItems oi
  //       JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
  //       JOIN MenuCategory mc ON mi.CategoryID = mc.CategoryID
  //       JOIN Orders o ON oi.OrderID = o.OrderID
  //       WHERE $whereClause GROUP BY mc.CategoryID, mc.CategoryName ORDER BY total_revenue DESC
  //     ''', whereArgs);
  // }

  // الدالة الجديدة (تستخدم BETWEEN مباشرة)
  Future<List<Map<String, dynamic>>> getCategoryRevenueReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;
    const queryCamel = """
SELECT
mc.CategoryName as category_name,
SUM(oi.Quantity * oi.Price) as total_revenue
FROM OrderItems oi
JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
JOIN MenuCategory mc ON mi.CategoryID = mc.CategoryID
JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate BETWEEN ? AND ? 
GROUP BY mc.CategoryID, mc.CategoryName
ORDER BY total_revenue DESC
""";
    const queryUnderscore = """
SELECT
mc.CategoryName as category_name,
SUM(oi.Quantity * oi.Price) as total_revenue
FROM Order_Items oi
JOIN Menu_Items mi ON oi.ItemID = mi.ItemID
JOIN Menu_Category mc ON mi.CategoryID = mc.CategoryID
JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate BETWEEN ? AND ? 
GROUP BY mc.CategoryID, mc.CategoryName
ORDER BY total_revenue DESC
""";
    try {
      return await db.rawQuery(queryCamel, [_fromDate(startDate), _toDate(endDate)]);
    } catch (_) {
      return await db.rawQuery(queryUnderscore, [_fromDate(startDate), _toDate(endDate)]);
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeePerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    final dateFilter = _buildDateFilter(
      startDate,
      endDate,
      dateColumn: 'o.OrderDate',
    );
    final whereClause = "1=1" + dateFilter['clause'];
    final whereArgs = dateFilter['args'];

    return await db.rawQuery('''
        SELECT u.Username as employee_name, COUNT(o.OrderID) as orders_handled, SUM(o.TotalAmount) as total_sales
        FROM Users u LEFT JOIN Orders o ON u.UserID = o.UserID AND $whereClause
        GROUP BY u.UserID, u.Username ORDER BY total_sales DESC
      ''', whereArgs);
  }

  Future<Map<String, dynamic>> getGeneralStats() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startOfMonth = DateTime(today.year, today.month, 1);

    final todayStats = (await db.rawQuery(
      "SELECT COUNT(*) as orders, COALESCE(SUM(TotalAmount), 0) as sales FROM Orders WHERE OrderDate >= ?",
      [startOfDay.toIso8601String()],
    )).first;
    final monthStats = (await db.rawQuery(
      "SELECT COUNT(*) as orders, COALESCE(SUM(TotalAmount), 0) as sales FROM Orders WHERE OrderDate >= ?",
      [startOfMonth.toIso8601String()],
    )).first;
    Map<String, Object?> generalStats;
    try {
      generalStats = (await db.rawQuery(
        "SELECT (SELECT COUNT(*) FROM Customers) as total_customers, (SELECT COUNT(*) FROM MenuItems) as available_items",
      )).first;
    } catch (_) {
      generalStats = (await db.rawQuery(
        "SELECT (SELECT COUNT(*) FROM Customers) as total_customers, (SELECT COUNT(*) FROM Menu_Items) as available_items",
      )).first;
    }

    return {'today': todayStats, 'month': monthStats, 'general': generalStats};
  }

  // حركة الخزنة الرئيسية (ملخص يومي: داخل/خارج)
  Future<List<ReportItemModel>> getMainBoxTransactionsSummary(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT DATE(TransactionDate) as label, IFNULL(SUM(AmountIn),0) as value, IFNULL(SUM(AmountOut),0) as secondaryValue FROM MainBoxTransactions WHERE TransactionDate BETWEEN ? AND ? GROUP BY DATE(TransactionDate) ORDER BY DATE(TransactionDate)";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getSupplierBalances() async {
    const query =
        "SELECT SupplierName as label, AmountDue as value FROM Suppliers WHERE AmountDue > 0 ORDER BY value DESC";
    return await _fetchSimpleReport(query);
  }

  Future<List<ReportItemModel>> getSupplierPaymentsSummary(
    DateTime from,
    DateTime to,
  ) async {
    const query =
        "SELECT SupplierName as label, IFNULL(SUM(AmountPaid),0) as value, IFNULL(SUM(AmountDue),0) as secondaryValue FROM Suppliers WHERE Date BETWEEN ? AND ? GROUP BY SupplierName ORDER BY value DESC";
    return await _fetchSimpleReport(query, [_fromDate(from), _toDate(to)]);
  }

  Future<List<ReportItemModel>> getReturnsByItem(
    DateTime from,
    DateTime to,
  ) async {
    // Prefer unified Returns schema; fallback to legacy names if present
    const queryUnified =
        "SELECT mi.ItemName as label, SUM(ri.Quantity) as value FROM Return_Items ri JOIN Menu_Items mi ON ri.ItemID = mi.ItemID JOIN Returns r ON ri.ReturnID = r.ReturnID WHERE r.ReturnDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    const queryLegacy =
        "SELECT mi.ItemsName as label, SUM(ri.Quantity) as value FROM ReturnItems ri JOIN MenuItems mi ON ri.ProductID = mi.MenuItemsID JOIN OrderReturns r ON ri.ReturnID = r.ReturnID WHERE r.ReturnDate BETWEEN ? AND ? GROUP BY label ORDER BY value DESC";
    try {
      return await _fetchSimpleReport(queryUnified, [_fromDate(from), _toDate(to)]);
    } catch (_) {
      return await _fetchSimpleReport(queryLegacy, [_fromDate(from), _toDate(to)]);
    }
  }

  Future<List<ReportItemModel>> getMainBoxSummary(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;

    // إجمالي المقبوض والمدفوع خلال الفترة
    const totalsQuery =
        "SELECT IFNULL(SUM(AmountIn),0) as in_total, IFNULL(SUM(AmountOut),0) as out_total FROM MainBoxTransactions WHERE TransactionDate BETWEEN ? AND ?";

    // رصيد بداية الفترة: آخر BalanceAfter قبل تاريخ البداية
    const openingQuery =
        "SELECT BalanceAfter as bal FROM MainBoxTransactions WHERE TransactionDate < ? ORDER BY TransactionDate DESC, TransactionID DESC LIMIT 1";

    // رصيد نهاية الفترة: آخر BalanceAfter حتى نهاية الفترة
    const closingQuery =
        "SELECT BalanceAfter as bal FROM MainBoxTransactions WHERE TransactionDate <= ? ORDER BY TransactionDate DESC, TransactionID DESC LIMIT 1";

    final totalsRow = (await db.rawQuery(totalsQuery, [
      _fromDate(from),
      _toDate(to),
    ])).firstOrNull ?? {'in_total': 0, 'out_total': 0};

    final openingRow = (await db.rawQuery(openingQuery, [
      _fromDate(from),
    ])).firstOrNull;

    final closingRow = (await db.rawQuery(closingQuery, [
      _toDate(to),
    ])).firstOrNull;

    final inTotal = (totalsRow['in_total'] as num? ?? 0).toDouble();
    final outTotal = (totalsRow['out_total'] as num? ?? 0).toDouble();
    final net = inTotal - outTotal;
    final opening = (openingRow?['bal'] as num? ?? 0).toDouble();
    final closing = (closingRow?['bal'] as num? ?? opening + net).toDouble();

    return [
      ReportItemModel(label: 'رصيد بداية الفترة', value: opening),
      ReportItemModel(label: 'إجمالي المقبوض', value: inTotal),
      ReportItemModel(label: 'إجمالي المدفوع', value: outTotal),
      ReportItemModel(label: 'صافي الحركة', value: net),
      ReportItemModel(label: 'رصيد نهاية الفترة', value: closing),
    ];
  }
}
