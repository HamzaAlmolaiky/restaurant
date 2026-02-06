// file: services/return_service.dart

// ignore_for_file: unused_field, avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../../Customers/services/customer_service.dart';
import '../../Expenses/services/expense_service.dart';
import '../../Expenses/models/expense_model.dart';
import '../models/order_return_model.dart';
import '../models/return_item_model.dart';

class ReturnService {
  final CustomerService _customerService;
  final ExpenseService _expenseService;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  ReturnService(this._customerService, this._expenseService);

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  /// ** الدالة الرئيسية لمعالجة المرتجع بالكامل داخل Transaction **
  Future<bool> processReturnTransaction(OrderReturnModel orderReturn) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        // --- الخطوة 1: الاستعلام عن الفاتورة الأصلية ---
        final orderInfoResult = await txn.query(
          'Orders',
          columns: ['CustomerID', 'PaymentMethod'],
          where: 'OrderID = ?',
          whereArgs: [orderReturn.originalOrderID],
        );

        if (orderInfoResult.isEmpty) {
          throw Exception(
            "الفاتورة الأصلية برقم ${orderReturn.originalOrderID} غير موجودة.",
          );
        }
        final orderInfo = orderInfoResult.first;
        final customerId = orderInfo['CustomerID'] as int?;
        final paymentMethod = orderInfo['PaymentMethod'] as String;

        // --- الخطوة 2: تسجيل المرتجع في جدول OrderReturns ---
        final Map<String, dynamic> returnRow = {
          'OriginalOrderID': orderReturn.originalOrderID,
          'ShiftID': orderReturn.shiftID,
          'ReturnDate': orderReturn.returnDate.toIso8601String(),
          'ReturnReason': orderReturn.returnReason,
          'UserID': orderReturn.userID,
          'TotalReturnAmount': orderReturn.totalReturnAmount,
        };
        final returnId = await txn.insert('OrderReturns', returnRow);

        // --- الخطوة 3: تسجيل عناصر المرتجع في جدول ReturnItems ---
        for (final item in orderReturn.returnItems) {
          final Map<String, dynamic> itemRow = {
            'ReturnID': returnId,
            'ProductID': item.productID,
            'Quantity': item.quantity,
            'UnitPrice': item.unitPrice,
            'SubTotal': item.subTotal,
          };
          await txn.insert('ReturnItems', itemRow);
        }

        // --- الخطوة 4: معالجة المرتجع حسب نوع الدفع ---
        if (paymentMethod == 'آجل' && customerId != null) {
          // إذا كان الطلب آجل، نقوم بتقليل رصيد العميل
          await _customerService.updateCustomerBalance(
            customerId,
            -orderReturn.totalReturnAmount,
          );
        } else if (paymentMethod == 'نقد') {
          // إذا كان الطلب نقدي، نسجل مصروف
          final expenseModel = ExpenseModel(
            shiftID: orderReturn.shiftID,
            userID: orderReturn.userID,
            amount: orderReturn.totalReturnAmount,
            description: 'مرتجع فاتورة رقم ${orderReturn.originalOrderID}',
            expenseDate: DateTime.now(),
            expenseType: 'مرتجع',
            recipientName: 'مرتجع نقدي - ${orderReturn.returnReason}',
          );
          await _expenseService.addExpense(expenseModel);
        }

        // --- الخطوة 5: حذف عناصر الطلب المرتجعة من OrderItems ---
        for (final item in orderReturn.returnItems) {
          await txn.delete(
            'OrderItems',
            where: 'OrderID = ? AND ProductID = ?',
            whereArgs: [orderReturn.originalOrderID, item.productID],
          );
        }
      });
      return true;
    } catch (e) {
      print('خطأ في معالجة المرتجع: $e');
      return false;
    }
  }

  /// إضافة مرتجع جديد
  Future<int> addReturn(OrderReturnModel orderReturn) async {
    final db = await _db;

    // التحقق من وجود الطلب الأصلي
    final orderExists = await db.query(
      'Orders',
      columns: ['OrderID', 'CustomerID'],
      where: 'OrderID = ?',
      whereArgs: [orderReturn.originalOrderID],
    );

    if (orderExists.isEmpty) {
      throw Exception('الطلب رقم ${orderReturn.originalOrderID} غير موجود');
    }

    // الحصول على معرف العميل من الطلب الأصلي
    final customerID = orderExists.first['CustomerID'] as int?;

    // التحقق من عدم وجود مرتجع سابق لنفس الطلب
    final existingReturn = await db.query(
      'OrderReturns',
      columns: ['ReturnID'],
      where: 'OriginalOrderID = ?',
      whereArgs: [orderReturn.originalOrderID],
    );

    if (existingReturn.isNotEmpty) {
      throw Exception(
        'يوجد مرتجع سابق للطلب رقم ${orderReturn.originalOrderID}',
      );
    }

    // إنشاء بيانات المرتجع لجدول OrderReturns
    final returnData = {
      'OriginalOrderID': orderReturn.originalOrderID,
      'ShiftID': orderReturn.shiftID,
      'ReturnDate': orderReturn.returnDate.toIso8601String(),
      'ReturnReason': orderReturn.returnReason,
      'UserID': orderReturn.userID,
      'TotalReturnAmount': orderReturn.totalReturnAmount,
      if (customerID != null) 'CustomerID': customerID,
      'ReturnStatus': orderReturn.returnStatus ?? 'قيد المراجعة',
    };

    return await db.insert('OrderReturns', returnData);
  }

  /// الحصول على جميع المرتجعات
  Future<List<OrderReturnModel>> getAllReturns() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      ORDER BY r.ReturnDate DESC
    ''');
    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// الحصول على مرتجع بالمعرف
  Future<OrderReturnModel?> getReturnById(int id) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE r.ReturnID = ?
    ''',
      [id],
    );

    if (result.isNotEmpty) {
      return OrderReturnModel.fromMap(result.first);
    }
    return null;
  }

  /// تحديث مرتجع
  Future<int> updateReturn(int id, OrderReturnModel orderReturn) async {
    final db = await _db;
    final returnData = orderReturn.toMap();
    returnData.remove('ReturnID'); // إزالة المعرف من التحديث
    return await db.update(
      'OrderReturns',
      returnData,
      where: 'ReturnID = ?',
      whereArgs: [id],
    );
  }

  /// حذف مرتجع
  Future<int> deleteReturn(int id) async {
    final db = await _db;
    // حذف عناصر المرتجع أولاً
    await db.delete('ReturnItems', where: 'ReturnID = ?', whereArgs: [id]);
    // ثم حذف المرتجع
    return await db.delete(
      'OrderReturns',
      where: 'ReturnID = ?',
      whereArgs: [id],
    );
  }

  /// البحث في المرتجعات
  Future<List<OrderReturnModel>> searchReturns(String query) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE 
        COALESCE(c.CustomerName, '') LIKE ? OR
        COALESCE(c.PhoneNumber, '') LIKE ? OR
        COALESCE(r.ReturnReason, '') LIKE ? OR
        CAST(r.ReturnID AS TEXT) LIKE ? OR
        CAST(o.OrderID AS TEXT) LIKE ? OR
        DATE(r.ReturnDate) LIKE ?
      ORDER BY r.ReturnDate DESC
    ''',
      ['%$query%', '%$query%', '%$query%', '%$query%', '%$query%', '%$query%'],
    );

    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// فلترة المرتجعات حسب السبب
  Future<List<OrderReturnModel>> getReturnsByReason(String reason) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE r.ReturnReason = ?
      ORDER BY r.ReturnDate DESC
    ''',
      [reason],
    );

    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// فلترة المرتجعات حسب التاريخ
  Future<List<OrderReturnModel>> getReturnsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE DATE(r.ReturnDate) BETWEEN ? AND ?
      ORDER BY r.ReturnDate DESC
    ''',
      [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );

    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// الحصول على مرتجعات اليوم
  Future<List<OrderReturnModel>> getTodayReturns() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      LEFT JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE DATE(r.ReturnDate) = ?
      ORDER BY r.ReturnDate DESC
    ''',
      [today],
    );

    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// إحصائيات المرتجعات العامة
  Future<Map<String, dynamic>> getReturnStats() async {
    final db = await _db;

    // إجمالي المرتجعات
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM OrderReturns',
    );

    // قيمة المرتجعات
    final valueResult = await db.rawQuery(
      'SELECT SUM(TotalReturnAmount) as total FROM OrderReturns',
    );

    // مرتجعات اليوم
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM OrderReturns 
      WHERE DATE(ReturnDate) = ?
    ''',
      [today],
    );

    // معدل المرتجعات (نسبة مئوية من إجمالي الطلبات)
    final totalOrdersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Orders',
    );

    final totalOrders = totalOrdersResult.first['count'] as int;
    final totalReturns = totalResult.first['count'] as int;
    final returnRate = totalOrders > 0
        ? (totalReturns / totalOrders * 100)
        : 0.0;

    return {
      'totalReturns': totalReturns,
      'totalValue': valueResult.first['total'] ?? 0.0,
      'todayReturns': todayResult.first['count'] as int,
      'returnRate': returnRate,
    };
  }

  /// إحصائيات المرتجعات حسب السبب
  Future<List<Map<String, dynamic>>> getReturnStatsByReason() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT ReturnReason, COUNT(*) as count, SUM(TotalReturnAmount) as total_amount
      FROM OrderReturns
      WHERE ReturnReason IS NOT NULL AND ReturnReason != ''
      GROUP BY ReturnReason
      ORDER BY count DESC
    ''');

    return result
        .map(
          (row) => {
            'reason': row['ReturnReason'],
            'count': row['count'],
            'totalAmount': row['total_amount'] ?? 0.0,
          },
        )
        .toList();
  }

  /// إحصائيات المرتجعات الشهرية
  Future<List<Map<String, dynamic>>> getMonthlyReturnStats() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', ReturnDate) as month,
        COUNT(*) as count,
        SUM(TotalReturnAmount) as total_amount
      FROM OrderReturns
      WHERE ReturnDate >= datetime('now', '-12 months')
      GROUP BY strftime('%Y-%m', ReturnDate)
      ORDER BY month DESC
    ''');

    return result
        .map(
          (row) => {
            'month': row['month'],
            'count': row['count'],
            'totalAmount': row['total_amount'] ?? 0.0,
          },
        )
        .toList();
  }

  /// الحصول على أكثر العملاء إرجاعاً
  Future<List<Map<String, dynamic>>> getTopReturningCustomers({
    int limit = 10,
  }) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT 
        c.CustomerName as customer_name,
        c.PhoneNumber as phone,
        COUNT(r.ReturnID) as return_count,
        SUM(r.TotalReturnAmount) as total_return_amount
      FROM OrderReturns r
      JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      WHERE c.CustomerName IS NOT NULL
      GROUP BY o.CustomerID, c.CustomerName, c.PhoneNumber
      ORDER BY return_count DESC
      LIMIT ?
    ''',
      [limit],
    );

    return result
        .map(
          (row) => {
            'customerName': row['customer_name'],
            'phone': row['phone'],
            'returnCount': row['return_count'],
            'totalReturnAmount': row['total_return_amount'] ?? 0.0,
          },
        )
        .toList();
  }

  /// الحصول على أكثر المنتجات إرجاعاً
  Future<List<Map<String, dynamic>>> getTopReturnedItems({
    int limit = 10,
  }) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT 
        p.ProductName as product_name,
        SUM(ri.Quantity) as total_quantity,
        COUNT(ri.ReturnItemID) as return_count,
        SUM(ri.SubTotal) as total_amount
      FROM ReturnItems ri
      JOIN Products p ON ri.ProductID = p.ProductID
      GROUP BY ri.ProductID, p.ProductName
      ORDER BY total_quantity DESC
      LIMIT ?
    ''',
      [limit],
    );

    return result
        .map(
          (row) => {
            'productName': row['product_name'],
            'totalQuantity': row['total_quantity'] ?? 0.0,
            'returnCount': row['return_count'],
            'totalAmount': row['total_amount'] ?? 0.0,
          },
        )
        .toList();
  }

  /// إضافة عناصر للمرتجع
  Future<int> addReturnItem(ReturnItemModel returnItem) async {
    final db = await _db;
    final itemData = returnItem.toMap();
    itemData.remove('ReturnItemID'); // إزالة المعرف للإدراج التلقائي
    return await db.insert('ReturnItems', itemData);
  }

  /// الحصول على عناصر المرتجع
  Future<List<ReturnItemModel>> getReturnItems(int returnId) async {
    final db = await _db;
    final result = await db.query(
      'ReturnItems',
      where: 'ReturnID = ?',
      whereArgs: [returnId],
    );
    return result.map((map) => ReturnItemModel.fromMap(map)).toList();
  }

  /// حذف عنصر من المرتجع
  Future<int> deleteReturnItem(int itemId) async {
    final db = await _db;
    return await db.delete(
      'ReturnItems',
      where: 'ReturnItemID = ?',
      whereArgs: [itemId],
    );
  }

  /// تحديث عنصر المرتجع
  Future<int> updateReturnItem(int itemId, ReturnItemModel itemData) async {
    final db = await _db;
    final data = itemData.toMap();
    data.remove('ReturnItemID'); // إزالة المعرف من التحديث
    return db.update(
      'ReturnItems',
      data,
      where: 'ReturnItemID = ?',
      whereArgs: [itemId],
    );
  }

  /// إنشاء رقم مرتجع تلقائي
  Future<String> generateReturnNumber() async {
    final db = await _db;
    final today = DateTime.now();
    final datePrefix =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM OrderReturns 
      WHERE DATE(ReturnDate) = ?
    ''',
      [today.toIso8601String().split('T')[0]],
    );

    final count = result.first['count'] as int;
    final sequence = (count + 1).toString().padLeft(3, '0');

    return 'RT$datePrefix$sequence';
  }

  /// الحصول على المرتجعات لعميل معين
  Future<List<OrderReturnModel>> getReturnsForCustomer(int customerId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT r.*, c.CustomerName as CustomerName, c.PhoneNumber as PhoneNumber, u.UserName as UserName
      FROM OrderReturns r
      JOIN Orders o ON r.OriginalOrderID = o.OrderID
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON r.UserID = u.UserID
      WHERE o.CustomerID = ?
      ORDER BY r.ReturnDate DESC
    ''',
      [customerId],
    );

    return result.map((map) => OrderReturnModel.fromMap(map)).toList();
  }

  /// جلب قائمة العملاء
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await _db;
    final result = await db.query(
      'Customers',
      columns: ['CustomerID', 'CustomerName', 'PhoneNumber'],
      orderBy: 'CustomerName ASC',
    );
    return result;
  }
}
