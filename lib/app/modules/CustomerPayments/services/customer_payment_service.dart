// file: services/customer_payment_service.dart

// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../models/customer_analytics_models.dart';
import '../models/customer_payment_model.dart';
import '../models/payment_view_model.dart';

/// خدمة لإدارة عمليات الدفع للعملاء
/// هذه الخدمة توفر وظائف CRUD (إنشاء، قراءة، تحديث، حذف) لسندات الدفع للعملاء
/// بالإضافة إلى وظائف إضافية مثل الحصول على الدفعات حسب العميل أو التاريخ.

class CustomerPaymentService {
  // نمط Singleton للوصول الموحد
  static final CustomerPaymentService instance =
      CustomerPaymentService._internal();
  CustomerPaymentService._internal();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // -------------------------------------------------------------------
  // دوال أساسية وتشغيلية (CRUD)
  // -------------------------------------------------------------------

  /// إضافة دفعة جديدة. يقبل خريطة (Map) لتسهيل الاستخدام من الكنترولر.
  Future<int> addPayment(Map<String, dynamic> paymentData) async {
    final paymentModel = CustomerPaymentModel.fromMap(paymentData);
    return await (await _db).insert('CustomerPayments', paymentModel.toMap());
  }

  /// إضافة دفعة ككائن (Model) داخل معاملة. دالة متقدمة للاستخدام الداخلي.
  Future<int> addPaymentInTransaction(
    CustomerPaymentModel payment,
    Transaction txn,
  ) async {
    return await txn.insert('CustomerPayments', payment.toMap());
  }

  /// تحديث بيانات دفعة
  Future<int> updatePayment(int id, Map<String, dynamic> paymentData) async {
    paymentData['updated_at'] = DateTime.now().toIso8601String();
    return await (await _db).update(
      'CustomerPayments',
      paymentData,
      where: 'PaymentID = ?',
      whereArgs: [id],
    );
  }

  /// حذف دفعة مع تحديث رصيد العميل (منطق صحيح وكامل)
  Future<bool> deletePayment(int paymentId) async {
    final db = await _db;
    try {
      await db.transaction((txn) async {
        final paymentMapList = await txn.query(
          'CustomerPayments',
          where: 'PaymentID = ?',
          whereArgs: [paymentId],
        );
        if (paymentMapList.isEmpty)
          throw Exception('Payment with ID $paymentId not found.');
        final payment = CustomerPaymentModel.fromMap(paymentMapList.first);

        await txn.delete(
          'CustomerPayments',
          where: 'PaymentID = ?',
          whereArgs: [paymentId],
        );
        await txn.rawUpdate(
          'UPDATE Customers SET CurrentBalance = CurrentBalance - ? WHERE CustomerID = ?',
          [payment.amountReceived, payment.customerID],
        );
      });
      return true;
    } catch (e) {
      print('فشل حذف الدفعة: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------
  // دوال الجلب والفلترة
  // -------------------------------------------------------------------

  /// الحصول على جميع المدفوعات (معلومات العميل)
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT cp.*, c.CustomerName as customer_name, c.PhoneNumber as phone
      FROM CustomerPayments cp LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID
      ORDER BY cp.PaymentDate DESC
    ''');
  }

  /// الحصول على دفعة واحدة بالمعرف
  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT cp.*, c.CustomerName as customer_name, c.PhoneNumber as phone, c.Email
      FROM CustomerPayments cp LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID
      WHERE cp.PaymentID = ?
    ''',
      [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// الحصول على مدفوعات عميل معين
  Future<List<Map<String, dynamic>>> getCustomerPayments(int customerId) async {
    final db = await _db;
    return await db.rawQuery(
      'SELECT * FROM CustomerPayments WHERE CustomerID = ? ORDER BY PaymentDate DESC',
      [customerId],
    );
  }

  /// (من Service1) الحصول على دفعات عميل مع اسم المستخدم الذي سجل الدفعة
  Future<List<CustomerPaymentModel>> getPaymentsByCustomerIdWithUsername(
    int customerId,
  ) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT cp.*, u.Username 
      FROM CustomerPayments cp LEFT JOIN Users u ON cp.UserID = u.UserID
      WHERE cp.CustomerID = ? AND cp.AmountReceived > 0
    ''',
      [customerId],
    );
    return maps.map((map) => CustomerPaymentModel.fromMap(map)).toList();
  }

  /// الحصول على مدفوعات طلب معين
  Future<List<Map<String, dynamic>>> getOrderPayments(int orderId) async {
    final db = await _db;
    return await db.rawQuery(
      'SELECT * FROM CustomerPayments WHERE OrderID = ? ORDER BY PaymentDate DESC',
      [orderId],
    );
  }

  /// البحث في المدفوعات
  Future<List<Map<String, dynamic>>> searchPayments(String query) async {
    final db = (await _db).database;
    return await db.rawQuery(
      '''
      SELECT cp.*, c.CustomerName as customer_name, c.PhoneNumber as phone
      FROM CustomerPayments cp
      LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID
      WHERE c.CustomerName LIKE ? OR c.PhoneNumber LIKE ?
      ORDER BY cp.PaymentDate DESC
    ''',
      ['%$query%', '%$query%'],
    );
  }

  /// فلترة المدفوعات حسب طريقة الدفع
  Future<List<Map<String, dynamic>>> getPaymentsByMethod(String method) async {
    final db = (await _db).database;
    return await db.rawQuery(
      '''
      SELECT cp.*, c.CustomerName as customer_name, c.PhoneNumber as phone
      FROM CustomerPayments cp
      LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID
      WHERE cp.PaymentMethod = ?
      ORDER BY cp.PaymentDate DESC
    ''',
      [method],
    );
  }

  /// فلترة المدفوعات حسب الحالة
  Future<List<Map<String, dynamic>>> getPaymentsByStatus(String status) async {
    /// Status is not tracked in schema; return empty list to avoid invalid column errors
    return [];
  }

  /// فلترة المدفوعات حسب التاريخ
  Future<List<Map<String, dynamic>>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final startDateStr = start.toIso8601String().split('T')[0];
    final endDateStr = end.toIso8601String().split('T')[0];
    return await db.rawQuery(
      "SELECT cp.*, c.CustomerName as customer_name FROM CustomerPayments cp LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID WHERE DATE(cp.PaymentDate) BETWEEN ? AND ?",
      [startDateStr, endDateStr],
    );
  }

  /// الحصول على مدفوعات اليوم
  Future<List<Map<String, dynamic>>> getTodayPayments() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await db.rawQuery(
      "SELECT cp.*, c.CustomerName as customer_name FROM CustomerPayments cp LEFT JOIN Customers c ON cp.CustomerID = c.CustomerID WHERE DATE(cp.PaymentDate) = ?",
      [today],
    );
  }

  // -------------------------------------------------------------------
  // دوال إدارة الحالة والبيانات الوصفية
  // -------------------------------------------------------------------

  /// معالجة دفعة (تأكيد أو رفض)
  Future<int> processPayment(int id, String status, String? notes) async {
    final updateData = {
      'status': status,
      'processed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      if (notes != null) 'processing_notes': notes,
    };
    return await (await _db).update(
      'CustomerPayments',
      updateData,
      where: 'PaymentID = ?',
      whereArgs: [id],
    );
  }

  /// تحديث حالة الدفعة
  Future<int> updatePaymentStatus(int id, String status) async {
    return await (await _db).update(
      'CustomerPayments',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'PaymentID = ?',
      whereArgs: [id],
    );
  }

  /// إضافة ملاحظة للدفعة
  Future<int> addPaymentNote(int id, String note) async {
    return await (await _db).update(
      'CustomerPayments',
      {'Notes': note, 'updated_at': DateTime.now().toIso8601String()},
      where: 'PaymentID = ?',
      whereArgs: [id],
    );
  }

  /// توليد رقم دفعة تلقائي
  Future<String> generatePaymentNumber() async {
    final db = await _db;
    final today = DateTime.now();
    final datePrefix =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM CustomerPayments WHERE PaymentNumber LIKE ?",
      ['PAY$datePrefix%'],
    );
    final count = result.first['count'] as int;
    final sequence = (count + 1).toString().padLeft(3, '0');
    return 'PAY$datePrefix$sequence';
  }

  /// إرسال تذكير دفع (وظيفة وهمية)
  Future<int> sendPaymentReminder(int paymentId, String reminderType) async {
    print('تم إرسال تذكير من نوع "$reminderType" للدفعة رقم $paymentId');
    return 1;
  }

  // -------------------------------------------------------------------
  // دوال تحليلية وإحصائية
  // -------------------------------------------------------------------

  /// جلب إحصائيات المدفوعات العامة
  Future<Map<String, dynamic>> getPaymentStats() async {
    final db = await _db;
    final totalResult = (await db.rawQuery(
      'SELECT COUNT(*) as c, SUM(AmountReceived) as a FROM CustomerPayments',
    )).first;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayResult = (await db.rawQuery(
      "SELECT COUNT(*) as c, SUM(AmountReceived) as a FROM CustomerPayments WHERE DATE(PaymentDate) = ?",
      [today],
    )).first;

    final stats = PaymentStatsModel(
      totalCount: totalResult['c'] as int? ?? 0,
      totalAmount: (totalResult['a'] as num?)?.toDouble() ?? 0.0,
      todayCount: todayResult['c'] as int? ?? 0,
      todayAmount: (todayResult['a'] as num?)?.toDouble() ?? 0.0,
    );
    return stats.toMap();
  }

  /// أكثر العملاء دفعاً
  Future<List<Map<String, dynamic>>> getTopPayingCustomers({
    int limit = 10,
  }) async {
    final db = await _db;
    return await db.rawQuery(
      '''
      SELECT c.CustomerName as customer_name, c.PhoneNumber as phone, COUNT(cp.PaymentID) as payment_count, SUM(cp.AmountReceived) as total_amount
      FROM CustomerPayments cp JOIN Customers c ON cp.CustomerID = c.CustomerID
      GROUP BY cp.CustomerID, c.CustomerName, c.PhoneNumber ORDER BY total_amount DESC LIMIT ?
    ''',
      [limit],
    );
  }

  /// إحصائيات المدفوعات حسب طريقة الدفع
  Future<List<Map<String, dynamic>>> getPaymentStatsByMethod() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT PaymentMethod, COUNT(*) as count, SUM(AmountReceived) as total_amount
      FROM CustomerPayments GROUP BY PaymentMethod ORDER BY total_amount DESC
    ''');
  }

  /// إحصائيات المدفوعات الشهرية
  Future<List<Map<String, dynamic>>> getMonthlyPaymentStats() async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT strftime('%Y-%m', PaymentDate) as month, COUNT(*) as count, SUM(AmountReceived) as total_amount
      FROM CustomerPayments WHERE PaymentDate >= datetime('now', '-12 months')
      GROUP BY month ORDER BY month DESC
    ''');
  }

  /// حساب إجمالي مدفوعات عميل
  Future<double> getCustomerTotalPayments(int customerId) async {
    final db = await _db;
    final result = (await db.rawQuery(
      'SELECT SUM(AmountReceived) as total FROM CustomerPayments WHERE CustomerID = ?',
      [customerId],
    )).first;
    return (result['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// حساب رصيد العميل المستحق
  Future<double> getCustomerBalance(int customerId) async {
    final db = await _db;
    final ordersTotal =
        (await db.rawQuery(
              "SELECT SUM(TotalAmount) as total FROM Orders WHERE CustomerID = ? AND PaymentMethod = 'credit'",
              [customerId],
            )).first['total']
            as num? ??
        0.0;
    final paymentsTotal = await getCustomerTotalPayments(customerId);
    return ordersTotal - paymentsTotal;
  }

  /// الحصول على المدفوعات المتأخرة
  Future<List<Map<String, dynamic>>> getOverduePayments() async {
    return []; // المنطق يعتمد على وجود حقل `DueDate`، وهو غير موجود حالياً
  }

  // -------------------------------------------------------------------
  // دوال خاصة بالورديات (Shifts) - (من Service1)
  // -------------------------------------------------------------------

  /// الحصول على إجمالي الدفعات النقدية لوردية معينة
  Future<double> getTotalCashPaymentsForShift(int shiftId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(AmountReceived) as total FROM CustomerPayments WHERE ShiftID = ? AND AmountReceived > 0',
      [shiftId],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// الحصول على قائمة الدفعات النقدية لوردية معينة، ويعيد ViewModel للعرض
  Future<List<PaymentViewModel>> getCashPaymentsListForShift(
    int shiftId,
  ) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT p.PaymentID, p.PaymentDate, p.AmountReceived, c.CustomerName, p.Notes
      FROM CustomerPayments p JOIN Customers c ON p.CustomerID = c.CustomerID
      WHERE p.ShiftID = ? AND p.AmountReceived > 0
    ''',
      [shiftId],
    );
    return maps.map((map) => PaymentViewModel.fromMap(map)).toList();
  }
}
