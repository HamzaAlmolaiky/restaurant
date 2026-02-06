// file: services/order_service.dart
// ignore_for_file: avoid_print

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../helpers/database_helper.dart';
import '../../CustomerPayments/models/customer_payment_model.dart';
import '../../CustomerPayments/services/customer_payment_service.dart';
import '../../Customers/models/customer_model.dart';
import '../../Customers/services/customer_service.dart';
import '../../MainBox/services/main_box_service.dart';
import '../../MenuCategories/models/menu_category_model.dart';
import '../../MenuItems/models/menu_item_model.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../../Print/services/printing_service.dart';
import '../../Shift/models/credit_order_view_model.dart';
import '../../Shift/models/shift_activity_model.dart';
import '../../Users/models/user_model.dart';
import '../models/order_model.dart';

class OrderService {
  // حقن الاعتماديات لضمان التفاعل الصحيح بين الخدمات
  final CustomerService _customerService;
  final CustomerPaymentService _paymentService;

  OrderService(this._customerService, this._paymentService);

  /// ***************************************************************
  /// ** الدالة الأهم: إنشاء طلب جديد باستخدام Transaction آمن **
  /// ***************************************************************
  Future<int> createOrder(OrderModel order) async {
    final db = await DatabaseHelper.instance.database;
    int orderId = -1;

    await db.transaction((txn) async {
      // 1. إضافة الطلب الرئيسي
      orderId = await txn.insert('Orders', order.toMap());

      // 2. إضافة عناصر الطلب
      for (var item in order.orderItems) {
        await txn.insert('OrderItems', {
          'OrderID': orderId,
          'ItemsID': item.menuItemsID,
          'Quantity': item.quantity,
          'Price': item.price,
          'Total': item.quantity * item.price,
        });
      }

      // 3. معالجة الطلبات الكاش (ترحيل فوري للصندوق الرئيسي)
      // نرحّل فقط الطلبات النقدية كإيداع ضمن نفس الـ transaction لضمان الذرّية
      if (order.paymentMethod == "Cash" || order.paymentMethod == "نقدي") {
        // استدعاء الخدمة كسينجلتون لتسجيل حركة "مبيعات" باستخدام الدالة المتخصصة
        await MainBoxService.instance.addSalesInTransaction(
          txn: txn,
          amount: order.amountPaid,
          orderId: orderId,
          userId: order.userID,
          description: "مبيعات فاتورة رقم $orderId",
        );
      }

      // 4. معالجة الطلبات الآجلة (Credit)
      if ((order.paymentMethod == "Credit" || order.paymentMethod == "آجل") &&
          order.customerID != null) {
        // 4.1 تحديث رصيد العميل (زيادة المديونية بالمبلغ المتبقي)
        await _customerService.updateCustomerBalanceInTransaction(
          order.customerID!,
          order.amountDue,
          txn,
          notes: "فاتورة آجلة رقم $orderId",
        );

        final payment = CustomerPaymentModel(
          paymentId: null,
          customerID: order.customerID!,
          shiftID: order.shiftID,
          userID: order.userID,
          orderID: orderId,
          paymentDate: DateTime.now(),
          amountReceived: order.amountDue,
          notes: "فاتورة آجلة رقم $orderId",
        );
        // 4.2 تسجيل حركة الدين الكامل كدفعة سالبة
        // ملاحظة: تحتاج إلى تعديل CustomerPayment ليقبل orderId و shiftId
        await _paymentService.addPaymentInTransaction(payment, txn);
      }
    });
    return orderId;
  }

  /// حفظ الطلب ثم الطباعة مباشرة بدون واجهة
  Future<int> createOrderAndPrint(
    OrderModel order, {
    required String printerIp,
    int printerPort = 9100,
    bool savePdf = true,
  }) async {
    // 1) احفظ الطلب
    final orderId = await createOrder(order);

    // 2) اطبع تذكرة ESC/POS مباشرة
    try {
      await PrintingService.instance.printOrderTicket(
        order,
        order.orderItems,
        ip: printerIp,
        port: printerPort,
        orderId: orderId,
      );
    } catch (e) {
      // لا نرمي الخطأ حتى لا نفشل حفظ الطلب، يمكن تسجيله في مكان آخر
      print('تعذر الطباعة على الطابعة الحرارية: $e');
    }

    // 3) احفظ PDF اختيارياً
    if (savePdf) {
      try {
        await PrintingService.instance.saveOrderPdf(
          order,
          order.orderItems,
          fileName: 'order_$orderId.pdf',
          orderId: orderId,
        );
      } catch (e) {
        print('تعذر حفظ PDF للطلب $orderId: $e');
      }
    }

    return orderId;
  }

  /// ** دالة مساعدة لتحويل صف من قاعدة البيانات إلى كائن Order **
  Future<OrderModel> _mapRowToOrder(
    Map<String, dynamic> row,
    DatabaseExecutor db,
  ) async {
    final orderId = row['OrderID'] as int;
    return OrderModel(
      orderID: orderId,
      orderDate: DateTime.parse(row['OrderDate']),
      totalAmount: (row['TotalAmount'] as num).toDouble(),
      paymentMethod: row['PaymentMethod'],
      amountPaid: (row['AmountPaid'] as num).toDouble(),
      amountDue: (row['AmountDue'] as num).toDouble(),
      customerID: row['CustomerID'],
      userID: row['UserID'],
      shiftID: row['ShiftID'],
      notes: row['Notes'],
      customer: row['CustomerName'] != null
          ? CustomerModel.fromMap({'CustomerName': row['CustomerName']})
          : null,
      user: row['Username'] != null
          ? UserModel.fromMap({'Username': row['Username']})
          : null,
      orderItems: await getOrderItems(orderId, db),
    );
  }

  /// ** جلب عناصر طلب معين **
  Future<List<OrderItemModel>> getOrderItems(
    int orderId,
    DatabaseExecutor db,
  ) async {
    final maps = await db.rawQuery(
      '''
      SELECT 
        oi.OrderItemsID, oi.OrderID, oi.ItemsID, oi.Quantity, oi.Price,
        mi.MenuItemsID AS MenuItemsID, mi.ItemsName AS ItemsName, mi.Price AS ItemPrice, mi.CategoryID AS CategoryID
      FROM OrderItems oi 
      LEFT JOIN MenuItems mi ON oi.ItemsID = mi.MenuItemsID 
      WHERE oi.OrderID = ?
      ''',
      [orderId],
    );
    return maps
        .map(
          (map) => OrderItemModel(
            orderItemsID: map['OrderItemsID'] as int,
            orderID: map['OrderID'] as int,
            menuItemsID: map['ItemsID'] as int,
            quantity: (map['Quantity'] as num).toDouble(),
            price: (map['Price'] as num).toDouble(),
            menuItem: (map['MenuItemsID'] != null)
                ? MenuItemModel(
                    menuItemsID: map['MenuItemsID'] as int?,
                    itemsName: (map['ItemsName'] as String?) ?? '-',
                    price: (map['ItemPrice'] as num?)?.toDouble() ?? 0.0,
                    categoryID: (map['CategoryID'] as int?) ?? 0,
                  )
                : null,
          ),
        )
        .toList();
  }

  /// جلب عدد الطلبات لليوم
  Future<int> getTodayOrdersCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(OrderID) as count FROM Orders WHERE date(OrderDate) = date('now', 'localtime')",
    );
    return (result.first['count'] as num).toInt();
  }

  // ignore: unintended_html_in_doc_comment
  /// جلب جميع الطلبات - إرجاع List<Map<String, dynamic>> للتوافق مع الكونترولر
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Orders',
      orderBy: 'OrderDate DESC',
    );
    return maps;
  }

  /// جلب جميع الطلبات كـ OrderModel objects
  Future<List<OrderModel>> getAllOrderModels() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Orders',
      orderBy: 'OrderDate DESC',
    );

    List<OrderModel> orders = [];
    for (var map in maps) {
      try {
        orders.add(await _mapRowToOrder(map, db));
      } catch (e) {
        print('خطأ في تحويل الطلب: $e');
        // إنشاء طلب مبسط في حالة الخطأ
        orders.add(
          OrderModel(
            orderID: map['OrderID'],
            orderDate:
                DateTime.tryParse(map['OrderDate'] ?? '') ?? DateTime.now(),
            totalAmount: (map['TotalAmount'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: map['PaymentMethod'] ?? 'Cash',
            amountPaid: (map['AmountPaid'] as num?)?.toDouble() ?? 0.0,
            amountDue: (map['AmountDue'] as num?)?.toDouble() ?? 0.0,
            customerID: map['CustomerID'],
            userID: map['UserID'],
            shiftID: map['ShiftID'],
            notes: map['Notes'],
            orderItems: [], // سيتم جلبها لاحقاً عند الحاجة
          ),
        );
      }
    }
    return orders;
  }

  /// جلب الطلبات حسب التاريخ
  Future<List<Map<String, dynamic>>> getOrdersByDate(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'Orders',
      where: 'date(OrderDate) = ?',
      whereArgs: [dateStr],
      orderBy: 'OrderDate DESC',
    );
    return maps;
  }

  /// جلب الطلبات حسب الحالة (طريقة الدفع)
  Future<List<Map<String, dynamic>>> getOrdersByPaymentMethod(
    String paymentMethod,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Orders',
      where: 'PaymentMethod = ?',
      whereArgs: [paymentMethod],
      orderBy: 'OrderDate DESC',
    );
    return maps;
  }

  /// جلب إحصائيات الطلبات
  Future<Map<String, dynamic>> getOrdersStatistics() async {
    final db = await DatabaseHelper.instance.database;

    // إجمالي الطلبات
    final totalResult = await db.rawQuery(
      "SELECT COUNT(OrderID) as count FROM Orders",
    );
    final totalOrders = (totalResult.first['count'] as num?)?.toInt() ?? 0;

    // طلبات اليوم
    final todayResult = await db.rawQuery(
      "SELECT COUNT(OrderID) as count FROM Orders WHERE date(OrderDate) = date('now', 'localtime')",
    );
    final todayOrders = (todayResult.first['count'] as num?)?.toInt() ?? 0;

    // إجمالي المبيعات
    final salesResult = await db.rawQuery(
      "SELECT IFNULL(SUM(TotalAmount), 0) as total FROM Orders",
    );
    final totalSales = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // مبيعات اليوم
    final todaySalesResult = await db.rawQuery(
      "SELECT IFNULL(SUM(TotalAmount), 0) as total FROM Orders WHERE date(OrderDate) = date('now', 'localtime')",
    );
    final todaySales =
        (todaySalesResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // متوسط قيمة الطلب
    final averageOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;

    // طلبات الكاش
    final cashResult = await db.rawQuery(
      "SELECT COUNT(OrderID) as count FROM Orders WHERE PaymentMethod = 'Cash'",
    );
    final cashOrders = (cashResult.first['count'] as num?)?.toInt() ?? 0;

    // طلبات آجلة
    final creditResult = await db.rawQuery(
      "SELECT COUNT(OrderID) as count FROM Orders WHERE PaymentMethod = 'Credit'",
    );
    final creditOrders = (creditResult.first['count'] as num?)?.toInt() ?? 0;

    return {
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'totalSales': totalSales,
      'todaySales': todaySales,
      'averageOrderValue': averageOrderValue,
      'cashOrders': cashOrders,
      'creditOrders': creditOrders,
    };
  }

  /// تحديث حالة الطلب
  Future<bool> updateOrderStatus(int orderId, String status) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final result = await db.update(
        'Orders',
        {'Status': status},
        where: 'OrderID = ?',
        whereArgs: [orderId],
      );
      return result > 0;
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  /// حذف طلب
  Future<bool> deleteOrder(int orderId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // حذف عناصر الطلب أولاً
        await txn.delete(
          'OrderItems',
          where: 'OrderID = ?',
          whereArgs: [orderId],
        );

        // ثم حذف الطلب
        await txn.delete('Orders', where: 'OrderID = ?', whereArgs: [orderId]);
      });
      return true;
    } catch (e) {
      print('خطأ في حذف الطلب: $e');
      return false;
    }
  }

  /// البحث في الطلبات
  Future<List<Map<String, dynamic>>> searchOrders(String searchTerm) async {
    final db = await DatabaseHelper.instance.database;

    if (searchTerm.trim().isEmpty) {
      return await getAllOrders();
    }

    final maps = await db.rawQuery(
      '''
      SELECT DISTINCT o.* FROM Orders o
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON o.UserID = u.UserID
      WHERE 
        CAST(o.OrderID AS TEXT) LIKE ? OR
        o.Notes LIKE ? OR
        c.CustomerName LIKE ? OR
        u.Username LIKE ?
      ORDER BY o.OrderDate DESC
    ''',
      ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
    );

    return maps;
  }

  /// إنشاء طلبات افتراضية للاختبار
  Future<void> createDefaultOrders() async {
    final totalOrders = await getTodayOrdersCount();

    if (totalOrders == 0) {
      final defaultOrders = [
        {
          'OrderDate': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
          'TotalAmount': 85.50,
          'PaymentMethod': 'Cash',
          'AmountPaid': 85.50,
          'AmountDue': 0.0,
          'CustomerID': null,
          'UserID': 1,
          'ShiftID': 1,
          'Notes': 'طلب كاش',
        },
        {
          'OrderDate': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'TotalAmount': 120.00,
          'PaymentMethod': 'Credit',
          'AmountPaid': 0.0,
          'AmountDue': 120.00,
          'CustomerID': 1,
          'UserID': 1,
          'ShiftID': 1,
          'Notes': 'طلب آجل',
        },
        {
          'OrderDate': DateTime.now()
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
          'TotalAmount': 65.00,
          'PaymentMethod': 'Cash',
          'AmountPaid': 65.00,
          'AmountDue': 0.0,
          'CustomerID': null,
          'UserID': 1,
          'ShiftID': 1,
          'Notes': 'طلب سريع',
        },
      ];

      final db = await DatabaseHelper.instance.database;
      for (var orderData in defaultOrders) {
        try {
          await db.insert('Orders', orderData);
        } catch (e) {
          print('خطأ في إنشاء الطلب الافتراضي: $e');
        }
      }
    }
  }

  /// --- دوال إدارة عناصر الطلب (OrderItem Management) ---

  /// ** إضافة عنصر جديد إلى طلب موجود وتحديث إجمالي الطلب **
  Future<bool> addOrderItemToOrder(OrderItemModel orderItem) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // 1. حساب إجمالي العنصر الجديد
        final itemTotal = orderItem.quantity * orderItem.price;

        // 2. إضافة العنصر إلى جدول OrderItems
        await txn.insert('OrderItems', {
          'OrderID': orderItem.orderID,
          'ItemsID': orderItem.menuItemsID,
          'Quantity': orderItem.quantity,
          'Price': orderItem.price,
          'Total': itemTotal,
        });

        // 3. تحديث إجمالي الطلب في جدول Orders
        await txn.rawUpdate(
          'UPDATE Orders SET TotalAmount = TotalAmount + ?, AmountDue = AmountDue + ? WHERE OrderID = ?',
          [itemTotal, itemTotal, orderItem.orderID],
        );
      });
      return true;
    } catch (e) {
      print("فشل إضافة عنصر الطلب: $e");
      return false;
    }
  }

  /// ** تحديث عنصر موجود في طلب وتحديث إجمالي الطلب **
  Future<bool> updateOrderItem(OrderItemModel orderItem) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // 1. جلب الإجمالي القديم للعنصر قبل التحديث
        final oldItemResult = await txn.query(
          'OrderItems',
          columns: ['Total'],
          where: 'OrderItemsID = ?',
          whereArgs: [orderItem.orderItemsID],
        );
        if (oldItemResult.isEmpty) throw Exception("العنصر غير موجود");
        final oldTotal = (oldItemResult.first['Total'] as num).toDouble();

        // 2. حساب الإجمالي الجديد للعنصر
        final newTotal = orderItem.quantity * orderItem.price;
        final difference = newTotal - oldTotal;

        // 3. تحديث بيانات العنصر في جدول OrderItems
        await txn.update(
          'OrderItems',
          {
            'Quantity': orderItem.quantity,
            'Price': orderItem.price,
            'Total': newTotal,
          },
          where: 'OrderItemsID = ?',
          whereArgs: [orderItem.orderItemsID],
        );

        // 4. تحديث إجمالي الطلب في جدول Orders بالفرق
        if (difference != 0) {
          await txn.rawUpdate(
            'UPDATE Orders SET TotalAmount = TotalAmount + ?, AmountDue = AmountDue + ? WHERE OrderID = ?',
            [difference, difference, orderItem.orderID],
          );
        }
      });
      return true;
    } catch (e) {
      print("فشل تحديث عنصر الطلب: $e");
      return false;
    }
  }

  /// ** حذف عنصر من طلب وتحديث إجمالي الطلب **
  Future<bool> deleteOrderItem(int orderItemId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // 1. جلب بيانات العنصر (الإجمالي ورقم الطلب) قبل حذفه
        final itemDataResult = await txn.query(
          'OrderItems',
          columns: ['Total', 'OrderID'],
          where: 'OrderItemsID = ?',
          whereArgs: [orderItemId],
        );
        if (itemDataResult.isEmpty) throw Exception("العنصر غير موجود");
        final itemData = itemDataResult.first;
        final totalToSubtract = (itemData['Total'] as num).toDouble();
        final orderId = itemData['OrderID'] as int;

        // 2. حذف العنصر من جدول OrderItems
        final deletedRows = await txn.delete(
          'OrderItems',
          where: 'OrderItemsID = ?',
          whereArgs: [orderItemId],
        );

        // 3. إذا تم الحذف بنجاح، قم بتحديث إجمالي الطلب في جدول Orders
        if (deletedRows > 0) {
          await txn.rawUpdate(
            'UPDATE Orders SET TotalAmount = TotalAmount - ?, AmountDue = AmountDue - ? WHERE OrderID = ?',
            [totalToSubtract, totalToSubtract, orderId],
          );
        }
      });
      return true;
    } catch (e) {
      print("فشل حذف عنصر الطلب: $e");
      return false;
    }
  }

  /// ** جلب عناصر طلب معين مع كل تفاصيلها (JOIN ثلاثي) **
  Future<List<OrderItemModel>> getFullOrderItems(int orderID) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, Object?>> maps = [];
    Future<List<Map<String, Object?>>> runQuery(String categoryTable) {
      final sql =
          """
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
      // حاول أولاً بالاسم المفرد (الموجود فعلياً في قاعدة بياناتك)
      maps = await runQuery('MenuCategory');
    } catch (_) {
      // إن فشل، جرّب الاسم الجمع
      maps = await runQuery('MenuCategories');
    }

    // تحويل كل صف إلى كائن OrderItem مع كائنات متداخلة
    return maps.map((map) {
      final menuItemId = map['MenuItemsID'] as int?;
      final categoryId = map['CategoryID'] as int?;
      final menuCategory = (categoryId != null)
          ? MenuCategoryModel(
              categoryID: categoryId,
              categoryName: (map['CategoryName'] as String?) ?? '-',
            )
          : null;
      final menuItem = (menuItemId != null)
          ? MenuItemModel(
              menuItemsID: menuItemId,
              itemsName: (map['ItemsName'] as String?) ?? '-',
              price: (map['ItemPrice'] as num?)?.toDouble() ?? 0.0,
              categoryID: categoryId ?? 0,
              category: menuCategory,
            )
          : null;

      final q = map['Quantity'];
      final qty = q is int ? q.toDouble() : (q is num ? q.toDouble() : 0.0);

      return OrderItemModel(
        orderItemsID: (map['OrderItemsID'] as num).toInt(),
        orderID: (map['OrderID'] as num).toInt(),
        menuItemsID: (map['ItemsID'] as num).toInt(),
        quantity: qty,
        price: (map['Price'] as num?)?.toDouble() ?? 0.0,
        menuItem: menuItem,
      );
    }).toList();
  }

  Future<OrderModel?> getOrderById(int orderId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'Orders',
      where: 'OrderID = ?',
      whereArgs: [orderId],
    );
    if (result.isEmpty) return null;
    return _mapRowToOrder(result.first, db);
  }

  /// #
  Future<double> getTodaySales() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT IFNULL(SUM(TotalAmount), 0) as total FROM Orders WHERE date(OrderDate) = date('now', 'localtime')",
    );
    return (result.first['total'] as num).toDouble();
  }

  /// دالة لجلب الطلبات الحديثة
  Future<List<OrderModel>> getRecentOrders({int limit = 5}) async {
    // implement the logic to fetch recent orders
    // for example:
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT * FROM Orders
      ORDER BY OrderDate DESC
      LIMIT ?
    ''';
    final results = await db.rawQuery(sql, [limit]);
    return results.map((map) => OrderModel.fromMap(map)).toList();
  }

  /// --- دوال إضافية للتوافق مع OrderController ---

  /// جلب طلبات عميل معين
  Future<List<Map<String, dynamic>>> getOrdersForCustomer(
    int customerId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Orders',
      where: 'CustomerID = ?',
      whereArgs: [customerId],
      orderBy: 'OrderDate DESC',
    );
    return maps;
  }

  /// جلب رقم الطلب التالي
  Future<int> getNextOrderId() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(MAX(OrderID), 0) + 1 as nextId FROM Orders',
    );
    return (result.first['nextId'] as num).toInt();
  }

  /// جلب الأنشطة الحديثة للوردية
  Future<List<ShiftActivityModel>> getRecentActivitiesForShift(
    int shiftId,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // جلب آخر 10 طلبات للوردية
    final maps = await db.rawQuery(
      '''
      SELECT 
        o.OrderID,
        o.OrderDate,
        o.TotalAmount,
        o.PaymentMethod,
        c.CustomerName,
        u.Username
      FROM Orders o
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      LEFT JOIN Users u ON o.UserID = u.UserID
      WHERE o.ShiftID = ?
      ORDER BY o.OrderDate DESC
      LIMIT 10
    ''',
      [shiftId],
    );

    return maps
        .map(
          (map) => ShiftActivityModel(
            activityID: map['OrderID'] as int,
            activityType: 'طلب',
            description: 'طلب رقم ${map['OrderID']} - ${map['PaymentMethod']}',
            amount: (map['TotalAmount'] as num).toDouble(),
            activityDate: DateTime.parse(map['OrderDate'] as String),
          ),
        )
        .toList();
  }

  /// جلب طلبات آجلة للوردية
  Future<List<CreditOrderViewModel>> getCreditOrdersForShift(
    int shiftId,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final maps = await db.rawQuery(
      '''
      SELECT 
        o.OrderID,
        o.OrderDate,
        o.TotalAmount,
        o.AmountPaid,
        o.AmountDue,
        c.CustomerName,
        c.PhoneNumber
      FROM Orders o
      LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
      WHERE o.ShiftID = ? AND o.PaymentMethod = 'Credit' AND o.AmountDue > 0
      ORDER BY o.OrderDate DESC
    ''',
      [shiftId],
    );

    return maps
        .map(
          (map) => CreditOrderViewModel(
            orderID: map['OrderID'] as int,
            orderDate: DateTime.parse(map['OrderDate'] as String),
            totalAmount: (map['TotalAmount'] as num).toDouble(),
            amountPaid: (map['AmountPaid'] as num).toDouble(),
            amountDue: (map['AmountDue'] as num).toDouble(),
            customerName: map['CustomerName'] as String? ?? 'عميل غير محدد',
          ),
        )
        .toList();
  }

  /// جلب إجمالي المبيعات النقدية للوردية
  Future<double> getTotalCashSalesForShift(int shiftId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(TotalAmount), 0) as total 
      FROM Orders 
      WHERE ShiftID = ? AND PaymentMethod = 'Cash'
    ''',
      [shiftId],
    );

    return (result.first['total'] as num).toDouble();
  }
}
