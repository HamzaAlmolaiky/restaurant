// -------------------------------------------------------------------
// الخدمة الداخلية للعمليات التشغيلية (تحتوي على المنطق الفعلي)
// -------------------------------------------------------------------
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../models/order_item_model.dart';

class OperationalService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// استرجاع جميع عناصر الطلب مع تفاصيل إضافية من الجداول المرتبطة
  Future<List<OrderItemModel>> getAllOrderItems() async {
    final db = await _db;
    final maps = await db.rawQuery('''
    SELECT 
      oi.*, 
      mi.ItemsName, 
      mc.CategoryName
    FROM 
      OrderItems AS oi
    LEFT JOIN 
      Orders AS o ON oi.OrderID = o.OrderID
    LEFT JOIN 
      MenuItems AS mi ON oi.ItemsID = mi.MenuItemsID
    LEFT JOIN 
      MenuCategory AS mc ON mi.CategoryID = mc.CategoryID
    ORDER BY 
      o.OrderDate DESC, oi.OrderItemsID DESC
  ''');
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// اضافة عنصر جديد
  Future<int> addOrderItem(OrderItemModel orderItem) async {
    final db = await _db;
    return await db.insert('OrderItems', orderItem.toMap());
  }

  /// تحديث عنصر طلب موجود
  Future<int> updateOrderItem(int id, Map<String, dynamic> data) async {
    final db = await _db;
    return await db.update(
      'OrderItems',
      data,
      where: 'OrderItemsID = ?',
      whereArgs: [id],
    );
  }

  /// حذف عنصر طلب
  Future<int> deleteOrderItem(int id) async {
    final db = await _db;
    return await db.delete(
      'OrderItems',
      where: 'OrderItemsID = ?',
      whereArgs: [id],
    );
  }

  /// تحديث كمية عنصر الطلب وإعادة حساب الإجمالي
  Future<void> updateItemQuantity(int id, int newQuantity) async {
    final db = await _db;
    final maps = await db.query(
      'OrderItems',
      where: 'OrderItemsID = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return;

    final item = OrderItemModel.fromMap(maps.first);
    final newTotal = newQuantity * item.price;

    await db.update(
      'OrderItems',
      {'Quantity': newQuantity, 'Total': newTotal},
      where: 'OrderItemsID = ?',
      whereArgs: [id],
    );
  }

  /// تطبيق خصم على عنصر الطلب
  Future<void> applyItemDiscount(int id, double amount, String type) async {
    final db = await _db;
    final maps = await db.query(
      'OrderItems',
      where: 'OrderItemsID = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return;

    final currentTotal = (maps.first['Total'] as num).toDouble();
    double newTotal = currentTotal;

    if (type.toLowerCase() == 'percentage') {
      newTotal = currentTotal * (1 - amount / 100);
    } else {
      newTotal = currentTotal - amount;
    }
    newTotal = newTotal < 0 ? 0 : newTotal;

    await db.update(
      'OrderItems',
      {'Total': newTotal},
      where: 'OrderItemsID = ?',
      whereArgs: [id],
    );
  }

  /// بحث عن عناصر الطلب بناءً على اسم العنصر أو معرف الطلب
  Future<List<OrderItemModel>> searchOrderItems(String query) async {
    final db = await _db;
    final q = '%$query%';
    final maps = await db.rawQuery(
      '''
      SELECT oi.*, mi.ItemsName, mc.CategoryName
      FROM OrderItems oi
      LEFT JOIN Orders o ON oi.OrderID = o.OrderID
      LEFT JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
      LEFT JOIN MenuCategory mc ON mi.CategoryID = mc.CategoryID
      WHERE mi.ItemsName LIKE ? OR CAST(o.OrderID AS TEXT) LIKE ?
    ''',
      [q, q],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// استرجاع عناصر الطلب بناءً على معرف الفئة
  Future<List<OrderItemModel>> getOrderItemsByCategory(int categoryId) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT oi.*, mi.ItemsName, mc.CategoryName
      FROM OrderItems oi
      INNER JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
      INNER JOIN MenuCategory mc ON mi.CategoryID = mc.CategoryID
      WHERE mc.CategoryID = ?
    ''',
      [categoryId],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// استرجاع عناصر الطلب بناءً على معرف العنصر في القائمة
  Future<List<OrderItemModel>> getOrderItemsByMenuItem(int menuItemId) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT oi.*, mi.ItemsName FROM OrderItems oi
      INNER JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
      WHERE mi.MenuItemsID = ?
    ''',
      [menuItemId],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// استرجاع عناصر الطلب ضمن نطاق زمني معين
  Future<List<OrderItemModel>> getOrderItemsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT oi.*, mi.ItemsName
      FROM OrderItems oi
      INNER JOIN Orders o ON oi.OrderID = o.OrderID
      INNER JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID
      WHERE o.OrderDate BETWEEN ? AND ?
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// استرجاع عناصر الطلب بناءً على معرف الطلب
  Future<List<OrderItemModel>> getOrderItemsByOrderId(int orderId) async {
    final db = await _db;
    final maps = await db.query(
      'OrderItems',
      where: 'OrderID = ?',
      whereArgs: [orderId],
    );
    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }

  /// جلب عناصر طلب معين بكل تفاصيلها (JOIN مع MenuItems و MenuCategory)
  Future<List<OrderItemModel>> getFullOrderItems(int orderID) async {
    final db = await _db;
    List<Map<String, Object?>> maps = [];

    Future<List<Map<String, Object?>>> runQuery(String categoryTable) {
      final sql = """
        SELECT 
          oi.OrderItemsID,
          oi.OrderID,
          oi.ItemsID,
          oi.Quantity,
          oi.Price,
          mi.MenuItemsID AS MenuItemsID,
          mi.ItemsName AS ItemsName,
          mi.Price AS ItemPrice,
          mi.CategoryID AS CategoryID,
          mc.CategoryName AS CategoryName
        FROM OrderItems oi 
        LEFT JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID 
        LEFT JOIN $categoryTable mc ON mi.CategoryID = mc.CategoryID 
        WHERE oi.OrderID = ?
      """;
      return db.rawQuery(sql, [orderID]);
    }

    try {
      // الاسم الشائع في مخططك الحالي
      maps = await runQuery('MenuCategory');
    } catch (_) {
      // دعم جدول باسم بديل إن وُجد
      maps = await runQuery('MenuCategories');
    }

    return maps.map((map) => OrderItemModel.fromMap(map)).toList();
  }
}
