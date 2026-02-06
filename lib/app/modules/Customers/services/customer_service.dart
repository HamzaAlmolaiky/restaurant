// file: services/customer_service.dart

// ignore_for_file: unintended_html_in_doc_comment, avoid_print

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../models/customer_model.dart';

/// خدمة لإدارة عمليات العملاء
/// هذه الخدمة توفر وظائف CRUD (إنشاء، قراءة، تحديث، حذف) للعملاء
/// بالإضافة إلى وظائف إضافية مثل البحث والإحصائيات.
class CustomerService {
  static final CustomerService instance = CustomerService._init();
  CustomerService._init();

  /// جلب كل العملاء - إرجاع List<Map<String, dynamic>> للتوافق مع الكونترولر
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Customers');
    return maps;
  }

  /// جلب عميل حسب المعرف
  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Customers',
      where: 'CustomerID = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  /// جلب عميل حسب الاسم
  Future<Map<String, dynamic>?> getCustomerByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Customers',
      where: 'CustomerName = ?',
      whereArgs: [name.trim()],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// إنشاء عميل جديد - تغيير اسم الدالة من addCustomer إلى createCustomer
  Future<int> createCustomer(Map<String, dynamic> customerData) async {
    final db = await DatabaseHelper.instance.database;

    // التأكد من وجود البيانات المطلوبة
    if (customerData['CustomerName'] == null ||
        customerData['CustomerName'].toString().trim().isEmpty) {
      throw ArgumentError('اسم العميل مطلوب');
    }

    // إضافة القيم الافتراضية إذا لم تكن موجودة
    customerData['CurrentBalance'] ??= 0.0;
    customerData['RegistrationDate'] ??= DateTime.now().toIso8601String();

    return await db.insert('Customers', customerData);
  }

  /// إضافة عميل جديد - للتوافق مع الكود القديم
  Future<int> addCustomer(CustomerModel customer) async {
    return await createCustomer(customer.toMap());
  }

  /// تحديث بيانات عميل - تحديث المعاملات للتوافق مع الكونترولر
  Future<int> updateCustomer(
    int customerId,
    Map<String, dynamic> customerData,
  ) async {
    final db = await DatabaseHelper.instance.database;

    // التأكد من وجود معرف العميل
    if (customerId <= 0) {
      throw ArgumentError('معرف العميل غير صالح');
    }

    // إزالة CustomerID من البيانات المحدثة لتجنب تعديله
    customerData.remove('CustomerID');

    return await db.update(
      'Customers',
      customerData,
      where: 'CustomerID = ?',
      whereArgs: [customerId],
    );
  }

  /// تحديث بيانات عميل - للتوافق مع الكود القديم
  Future<int> updateCustomerModel(CustomerModel customer) async {
    if (customer.customerID == null) {
      throw ArgumentError('معرف العميل مطلوب للتحديث');
    }
    return await updateCustomer(customer.customerID!, customer.toMap());
  }

  /// حذف عميل
  Future<int> deleteCustomer(int id) async {
    final db = await DatabaseHelper.instance.database;

    if (id <= 0) {
      throw ArgumentError('معرف العميل غير صالح');
    }

    return await db.delete(
      'Customers',
      where: 'CustomerID = ?',
      whereArgs: [id],
    );
  }

  /// البحث عن عملاء - إرجاع List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> searchCustomers(String searchTerm) async {
    final db = await DatabaseHelper.instance.database;

    if (searchTerm.trim().isEmpty) {
      return await getAllCustomers();
    }

    final maps = await db.query(
      'Customers',
      where: 'CustomerName LIKE ? OR PhoneNumber LIKE ?',
      whereArgs: ['%$searchTerm%', '%$searchTerm%'],
    );

    return maps;
  }

  /// تحديث رصيد العميل
  Future<bool> updateCustomerBalance(
    int customerId,
    double balanceChange, {
    String? notes,
  }) async {
    if (balanceChange == 0) {
      throw ArgumentError("تغيير الرصيد لا يمكن أن يكون صفراً");
    }

    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // 1. تحديث رصيد العميل
        int count = await txn.rawUpdate(
          '''
          UPDATE Customers 
          SET CurrentBalance = CurrentBalance + ?, Notes = COALESCE(?, Notes)
          WHERE CustomerID = ?
          ''',
          [balanceChange, notes, customerId],
        );

        if (count == 0) {
          throw Exception('العميل غير موجود');
        }

        // 2. قراءة الرصيد الجديد
        final List<Map> result = await txn.query(
          'Customers',
          columns: ['CurrentBalance'],
          where: 'CustomerID = ?',
          whereArgs: [customerId],
        );
        final double newBalance = result.first['CurrentBalance'];

        // 3. تسجيل الحركة في السجل (إذا كان الجدول موجود)
        try {
          await txn.insert('CustomerBalanceHistory', {
            'CustomerID': customerId,
            'ChangeAmount': balanceChange,
            'NewBalance': newBalance,
            'TransactionDate': DateTime.now().toIso8601String(),
            'Notes': notes,
          });
        } catch (e) {
          // إذا لم يكن جدول التاريخ موجود، تجاهل الخطأ
          print('تحذير: لا يمكن حفظ تاريخ الرصيد: $e');
        }
      });
      return true;
    } catch (e) {
      print('فشل في تحديث رصيد العميل: $e');
      return false;
    }
  }

  /// تحديث رصيد العميل في معاملة
  Future<void> updateCustomerBalanceInTransaction(
    int customerID,
    double amount,
    Transaction txn, {
    String? notes,
  }) async {
    await txn.rawUpdate(
      'UPDATE Customers SET CurrentBalance = CurrentBalance + ? WHERE CustomerID = ?',
      [amount, customerID],
    );

    if (notes != null) {
      await txn.rawUpdate(
        'UPDATE Customers SET Notes = ? WHERE CustomerID = ?',
        [notes, customerID],
      );
    }
  }

  /// جلب عدد العملاء الجدد اليوم
  Future<int> getNewCustomersCountToday() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(CustomerID) as count FROM Customers WHERE date(RegistrationDate) = date('now', 'localtime')",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب عدد العملاء الجدد خلال فترة معينة
  Future<int> getNewCustomersCount(int days) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(CustomerID) as count FROM Customers WHERE RegistrationDate >= datetime('now', '-$days days')",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب عدد العملاء النشطين (رصيد موجب أو صفر)
  Future<int> getActiveCustomersCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(CustomerID) as count FROM Customers WHERE CurrentBalance >= 0",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب إجمالي عدد العملاء
  Future<int> getTotalCustomersCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(CustomerID) as count FROM Customers",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب متوسط الرصيد للعملاء
  Future<double> getAverageCustomerBalance() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT AVG(CurrentBalance) as average FROM Customers",
    );
    return (result.first['average'] as num?)?.toDouble() ?? 0.0;
  }

  /// جلب إجمالي أرصدة العملاء
  Future<double> getTotalCustomersBalance() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(CurrentBalance) as total FROM Customers",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// فلترة العملاء حسب الرصيد
  Future<List<Map<String, dynamic>>> getCustomersByBalanceStatus(
    String status,
  ) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause;

    switch (status.toLowerCase()) {
      case 'نشط':
      case 'active':
        whereClause = 'CurrentBalance >= 0';
        break;
      case 'مدين':
      case 'debtor':
        whereClause = 'CurrentBalance < 0';
        break;
      default:
        return await getAllCustomers();
    }

    final maps = await db.query('Customers', where: whereClause);

    return maps;
  }

  /// فلترة العملاء حسب فترة التسجيل
  Future<List<Map<String, dynamic>>> getCustomersByRegistrationPeriod(
    String period,
  ) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause;

    switch (period) {
      case 'اليوم':
        whereClause = "date(RegistrationDate) = date('now', 'localtime')";
        break;
      case 'هذا الأسبوع':
        whereClause = "RegistrationDate >= datetime('now', '-7 days')";
        break;
      case 'هذا الشهر':
        whereClause = "RegistrationDate >= datetime('now', 'start of month')";
        break;
      case 'آخر 30 يوم':
        whereClause = "RegistrationDate >= datetime('now', '-30 days')";
        break;
      default:
        return await getAllCustomers();
    }

    final maps = await db.query('Customers', where: whereClause);

    return maps;
  }

  /// التحقق من وجود عميل بالاسم
  Future<bool> customerExistsByName(String name) async {
    final customer = await getCustomerByName(name);
    return customer != null;
  }

  /// التحقق من وجود عميل برقم الهاتف
  Future<bool> customerExistsByPhone(String phone) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Customers',
      where: 'PhoneNumber = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// إنشاء عملاء افتراضيين للاختبار
  Future<void> createDefaultCustomers() async {
    final totalCustomers = await getTotalCustomersCount();

    if (totalCustomers == 0) {
      final defaultCustomers = [
        {
          'CustomerName': 'أحمد محمد',
          'PhoneNumber': '0501234567',
          'CurrentBalance': 150.0,
          'RegistrationDate': DateTime.now()
              .subtract(const Duration(days: 15))
              .toIso8601String(),
          'Notes': 'عميل مميز',
        },
        {
          'CustomerName': 'فاطمة علي',
          'PhoneNumber': '0507654321',
          'CurrentBalance': -50.0,
          'RegistrationDate': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'Notes': 'عميل منتظم',
        },
        {
          'CustomerName': 'محمد السعيد',
          'PhoneNumber': '0509876543',
          'CurrentBalance': 0.0,
          'RegistrationDate': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'Notes': null,
        },
        {
          'CustomerName': 'نورا أحمد',
          'PhoneNumber': '0502468135',
          'CurrentBalance': 300.0,
          'RegistrationDate': DateTime.now()
              .subtract(const Duration(days: 60))
              .toIso8601String(),
          'Notes': 'عميل VIP',
        },
        {
          'CustomerName': 'خالد عبدالله',
          'PhoneNumber': '0508642097',
          'CurrentBalance': -25.0,
          'RegistrationDate': DateTime.now()
              .subtract(const Duration(days: 10))
              .toIso8601String(),
          'Notes': 'يحتاج متابعة',
        },
      ];

      for (var customerData in defaultCustomers) {
        try {
          await createCustomer(customerData);
        } catch (e) {
          print('خطأ في إنشاء العميل الافتراضي: $e');
        }
      }
    }
  }

  /// جلب إحصائيات العملاء الشاملة من قاعدة البيانات
  Future<Map<String, dynamic>> getCustomersStatistics() async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      // جلب الإحصائيات الأساسية
      final totalResult = await db.rawQuery(
        "SELECT COUNT(CustomerID) as total FROM Customers",
      );
      final totalCustomers = (totalResult.first['total'] as num?)?.toInt() ?? 0;

      final activeResult = await db.rawQuery(
        "SELECT COUNT(CustomerID) as active FROM Customers WHERE CurrentBalance >= 0",
      );
      final activeCustomers = (activeResult.first['active'] as num?)?.toInt() ?? 0;

      final debtorResult = await db.rawQuery(
        "SELECT COUNT(CustomerID) as debtors FROM Customers WHERE CurrentBalance < 0",
      );
      final debtorCustomers = (debtorResult.first['debtors'] as num?)?.toInt() ?? 0;

      final newResult = await db.rawQuery(
        "SELECT COUNT(CustomerID) as new FROM Customers WHERE RegistrationDate >= datetime('now', '-30 days')",
      );
      final newCustomers = (newResult.first['new'] as num?)?.toInt() ?? 0;

      final balanceResult = await db.rawQuery(
        "SELECT AVG(CurrentBalance) as average, SUM(CurrentBalance) as total FROM Customers",
      );
      final averageBalance = (balanceResult.first['average'] as num?)?.toDouble() ?? 0.0;
      final totalBalance = (balanceResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // حساب إجمالي الديون
      final debtResult = await db.rawQuery(
        "SELECT SUM(ABS(CurrentBalance)) as totalDebts FROM Customers WHERE CurrentBalance < 0",
      );
      final totalDebts = (debtResult.first['totalDebts'] as num?)?.toDouble() ?? 0.0;

      // حساب إجمالي المبيعات (الديون)
      final salesResult = await db.rawQuery(
        "SELECT SUM(ABS(CurrentBalance)) as totalSales FROM Customers WHERE CurrentBalance < 0",
      );
      final totalSales = (salesResult.first['totalSales'] as num?)?.toDouble() ?? 0.0;

      // حساب متوسط الطلبات لكل عميل (تقديري)
      final averageOrdersPerCustomer = activeCustomers > 0 ? (activeCustomers * 2.5) / totalCustomers : 0.0;

      return {
        'totalCustomers': totalCustomers,
        'activeCustomers': activeCustomers,
        'debtorCustomers': debtorCustomers,
        'newCustomers': newCustomers,
        'averageBalance': averageBalance,
        'totalBalance': totalBalance,
        'totalDebts': totalDebts,
        'totalSales': totalSales,
        'averageOrdersPerCustomer': averageOrdersPerCustomer,
        'customerGrowthRate': totalCustomers > 0 ? (newCustomers / totalCustomers * 100) : 0.0,
        'debtorPercentage': totalCustomers > 0 ? (debtorCustomers / totalCustomers * 100) : 0.0,
        'activePercentage': totalCustomers > 0 ? (activeCustomers / totalCustomers * 100) : 0.0,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات العملاء: $e');
      return {
        'totalCustomers': 0,
        'activeCustomers': 0,
        'debtorCustomers': 0,
        'newCustomers': 0,
        'averageBalance': 0.0,
        'totalBalance': 0.0,
        'totalDebts': 0.0,
        'totalSales': 0.0,
        'averageOrdersPerCustomer': 0.0,
        'customerGrowthRate': 0.0,
        'debtorPercentage': 0.0,
        'activePercentage': 0.0,
      };
    }
  }

  /// جلب أفضل العملاء حسب المشتريات (أكبر ديون)
  Future<List<Map<String, dynamic>>> getTopCustomersByPurchases({int limit = 5}) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final maps = await db.query(
        'Customers',
        where: 'CurrentBalance < 0',
        orderBy: 'CurrentBalance ASC', // أصغر رصيد = أكبر دين = أكثر شراءً
        limit: limit,
      );
      
      return maps;
    } catch (e) {
      print('خطأ في جلب أفضل العملاء: $e');
      return [];
    }
  }

  /// جلب العملاء الجدد خلال فترة معينة
  Future<List<Map<String, dynamic>>> getRecentCustomers({int days = 30}) async {
    final db = await DatabaseHelper.instance.database;
    
    try {
      final maps = await db.query(
        'Customers',
        where: 'RegistrationDate >= datetime(\'now\', \'-$days days\')',
        orderBy: 'RegistrationDate DESC',
      );
      
      return maps;
    } catch (e) {
      print('خطأ في جلب العملاء الجدد: $e');
      return [];
    }
  }
}
