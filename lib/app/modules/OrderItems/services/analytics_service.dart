import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';

/// الخدمة الداخلية للتحليلات والإحصائيات (تحتوي على المنطق الفعلي)
class AnalyticsService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// تحليلات الطلبات
  Future<Map<String, dynamic>> getOrderItemStats() async {
    final db = await _db;
    final totalResult = (await db.rawQuery(
      'SELECT COUNT(*) as c, SUM(Quantity) as q, SUM(Total) as v FROM OrderItems',
    )).first;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayResult = (await db.rawQuery(
      '''
      SELECT COUNT(*) as c, SUM(oi.Quantity) as q, SUM(oi.Total) as v 
      FROM OrderItems oi INNER JOIN Orders o ON oi.OrderID = o.OrderID
      WHERE date(o.OrderDate) = ?
    ''',
      [today],
    )).first;

    final avgResult = (await db.rawQuery(
      'SELECT AVG(Price) as ap, AVG(Quantity) as aq FROM OrderItems',
    )).first;

    return {
      'totalItems': totalResult['c'] as int? ?? 0,
      'totalQuantity': (totalResult['q'] as num?)?.toDouble() ?? 0.0,
      'totalValue': (totalResult['v'] as num?)?.toDouble() ?? 0.0,
      'todayItems': todayResult['c'] as int? ?? 0,
      'todayQuantity': (todayResult['q'] as num?)?.toDouble() ?? 0.0,
      'todayValue': (todayResult['v'] as num?)?.toDouble() ?? 0.0,
      'avgPrice': (avgResult['ap'] as num?)?.toDouble() ?? 0.0,
      'avgQuantity': (avgResult['aq'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// تحليلات المبيعات
  Future<Map<String, dynamic>> getSalesStats() async {
    final db = await _db;

    final totalSalesResult = (await db.rawQuery('''
        SELECT 
          COUNT(DISTINCT oi.OrderID) as totalOrders,
          COUNT(oi.OrderItemsID) as totalItems,
          SUM(oi.Total) as totalRevenue,
          AVG(oi.Total) as averageOrderValue
        FROM OrderItems oi
      ''')).first;

    final todaySalesResult = (await db.rawQuery('''
        SELECT COUNT(DISTINCT oi.OrderID) as todayOrders, SUM(oi.Total) as todayRevenue
        FROM OrderItems oi INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE date(o.OrderDate) = date('now', 'localtime')
      ''')).first;

    final monthSalesResult = (await db.rawQuery('''
        SELECT COUNT(DISTINCT oi.OrderID) as monthOrders, SUM(oi.Total) as monthRevenue
        FROM OrderItems oi INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE date(o.OrderDate) >= date('now', 'start of month')
      ''')).first;

    final topProductsResult = await db.rawQuery('''
        SELECT mi.ItemsName as itemName, SUM(oi.Quantity) as totalQuantity, SUM(oi.Total) as totalRevenue
        FROM OrderItems oi INNER JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
        GROUP BY oi.ItemsID, mi.ItemsName ORDER BY totalQuantity DESC LIMIT 5
      ''');

    return {
      'totalOrders': (totalSalesResult['totalOrders'] as num?)?.toInt() ?? 0,
      'totalItems': (totalSalesResult['totalItems'] as num?)?.toInt() ?? 0,
      'totalRevenue':
          (totalSalesResult['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      'averageOrderValue':
          (totalSalesResult['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      'todayOrders': (todaySalesResult['todayOrders'] as num?)?.toInt() ?? 0,
      'todayRevenue':
          (todaySalesResult['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      'monthOrders': (monthSalesResult['monthOrders'] as num?)?.toInt() ?? 0,
      'monthRevenue':
          (monthSalesResult['monthRevenue'] as num?)?.toDouble() ?? 0.0,
      'topProducts': topProductsResult,
    };
  }

  /// دالة تحليلات المبيعات
  Future<Map<String, dynamic>> analyzeRevenue() async {
    final db = await _db;

    final dailyRevenueResult = await db.rawQuery('''
        SELECT date(o.OrderDate) as orderDate, SUM(oi.Total) as dailyRevenue, COUNT(DISTINCT oi.OrderID) as dailyOrders
        FROM OrderItems oi INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE o.OrderDate >= datetime('now', '-30 days')
        GROUP BY date(o.OrderDate) ORDER BY orderDate DESC LIMIT 30
      ''');

    final paymentMethodResult = await db.rawQuery('''
        SELECT o.PaymentMethod, SUM(oi.Total) as revenue, COUNT(DISTINCT oi.OrderID) as orders
        FROM OrderItems oi INNER JOIN Orders o ON oi.OrderID = o.OrderID
        GROUP BY o.PaymentMethod
      ''');

    final categoryRevenueResult = await db.rawQuery('''
        SELECT mc.CategoryName, SUM(oi.Total) as categoryRevenue, SUM(oi.Quantity) as totalQuantity
        FROM OrderItems oi
        INNER JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
        INNER JOIN MenuCategories mc ON mi.CategoryID = mc.CategoryID
        GROUP BY mc.CategoryID, mc.CategoryName ORDER BY categoryRevenue DESC
      ''');

    final lastMonthRevenue =
        (await db.rawQuery('''
        SELECT SUM(oi.Total) as revenue FROM OrderItems oi
        INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE o.OrderDate >= datetime('now', '-60 days') AND o.OrderDate < datetime('now', '-30 days')
      ''')).first['revenue']
            as num? ??
        0.0;

    final currentMonthRevenue =
        (await db.rawQuery('''
        SELECT SUM(oi.Total) as revenue FROM OrderItems oi
        INNER JOIN Orders o ON oi.OrderID = o.OrderID
        WHERE o.OrderDate >= datetime('now', '-30 days')
      ''')).first['revenue']
            as num? ??
        0.0;

    final growthRate = lastMonthRevenue > 0
        ? ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100)
        : (currentMonthRevenue > 0 ? 100.0 : 0.0);

    return {
      'dailyRevenue': dailyRevenueResult,
      'paymentMethodAnalysis': paymentMethodResult,
      'categoryAnalysis': categoryRevenueResult,
      'growthRate': growthRate,
      'lastMonthRevenue': lastMonthRevenue,
      'currentMonthRevenue': currentMonthRevenue,
      'revenueComparison': {
        'increase': currentMonthRevenue > lastMonthRevenue,
        'difference': currentMonthRevenue - lastMonthRevenue,
        'percentageChange': growthRate,
      },
    };
  }
}
