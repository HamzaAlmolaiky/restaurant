// file: services/main_box_service.dart

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../helpers/database_helper.dart';
import '../models/main_box_transaction_model.dart';

class MainBoxService {
  // Singleton
  static final MainBoxService instance = MainBoxService._init();
  MainBoxService._init();

  /// يجلب آخر رصيد مسجل في الخزنة الرئيسية.
  Future<double> getLastBalance({DatabaseExecutor? txn}) async {
    // نستخدم 'txn' إذا كان متوفراً (داخل transaction)، وإلا نستخدم 'db' العادي.
    final db = txn ?? await DatabaseHelper.instance.database;
    const sql =
        "SELECT BalanceAfter FROM MainBoxTransactions ORDER BY TransactionDate DESC, TransactionID DESC LIMIT 1";
    final result = await db.rawQuery(sql);

    if (result.isNotEmpty) {
      return (result.first['BalanceAfter'] as num).toDouble();
    }
    return 0.0;
  }

  /// يضيف حركة جديدة ويضمن دقة الرصيد باستخدام transaction.
  Future<bool> addTransaction({
    required String? transactionType,
    required double amount,
    required bool isDeposit, // true للإيداع (AmountIn), false للصرف (AmountOut)
    String? description,
    int? userId,
    int? referenceId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    try {
      await db.transaction((txn) async {
        // الخطوة 1: الحصول على الرصيد الحالي داخل الـ Transaction
        final lastBalance = await getLastBalance(txn: txn);

        // الخطوة 2: تحديد المبلغ الداخل والخارج وحساب الرصيد الجديد
        final amountIn = isDeposit ? amount : 0.0;
        final amountOut = !isDeposit ? amount : 0.0;
        final newBalance = lastBalance + amountIn - amountOut;

        // الخطوة 3: إنشاء كائن الحركة الجديدة
        final newTransaction = MainBoxTransactionModel(
          transactionDate: DateTime.now(),
          transactionType: transactionType,
          amountIn: amountIn,
          amountOut: amountOut,
          balanceAfter: newBalance,
          description: description,
          userID: userId,
          referenceID: referenceId,
        );

        // الخطوة 4: إدراج الحركة الجديدة في قاعدة البيانات
        await txn.insert('MainBoxTransactions', newTransaction.toMap());
      });
      // إذا اكتمل الـ transaction بنجاح، يتم عمل COMMIT تلقائياً.
      return true;
    } catch (e) {
      // إذا حدث أي خطأ، يتم عمل ROLLBACK تلقائياً.
      // ignore: avoid_print
      print("فشل إضافة حركة الخزنة: $e");
      return false;
    }
  }

  /// يجلب سجل حركات الخزنة مع إمكانية الفلترة.
  Future<List<MainBoxTransactionModel>> getTransactions(
    DateTime fromDate,
    DateTime toDate, {
    String transactionType = "الكل",
  }) async {
    final db = await DatabaseHelper.instance.database;

    String whereClause = 'date(t.TransactionDate) BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10),
    ];

    if (transactionType != "الكل") {
      whereClause += ' AND t.TransactionType = ?';
      whereArgs.add(transactionType);
    }

    final String sql =
        '''
      SELECT 
          t.*, u.Username AS UserName
      FROM MainBoxTransactions t
      LEFT JOIN Users u ON t.UserID = u.UserID
      WHERE $whereClause
      ORDER BY t.TransactionDate DESC, t.TransactionID DESC
    ''';

    final maps = await db.rawQuery(sql, whereArgs);
    return maps.map((map) => MainBoxTransactionModel.fromMap(map)).toList();
  }

  /// يضيف حركة جديدة ويضمن دقة الرصيد باستخدام transaction.
  Future<void> addTransactionInTransaction({
    required Transaction txn,
    required String transactionType,
    required double amount,
    required bool isDeposit,
    String? description,
    int? userId,
    int? referenceId,
  }) async {
    // الخطوة 1: الحصول على الرصيد الحالي داخل الـ Transaction
    final lastBalance = await getLastBalance(txn: txn);

    // الخطوة 2: تحديد المبلغ الداخل والخارج وحساب الرصيد الجديد
    final amountIn = isDeposit ? amount : 0.0;
    final amountOut = !isDeposit ? amount : 0.0;
    final newBalance = lastBalance + amountIn - amountOut;

    // الخطوة 3: إنشاء كائن الحركة الجديدة
    final newTransaction = MainBoxTransactionModel(
      transactionDate: DateTime.now(),
      transactionType: transactionType,
      amountIn: amountIn,
      amountOut: amountOut,
      balanceAfter: newBalance,
      description: description,
      userID: userId,
      referenceID: referenceId,
    );

    // الخطوة 4: إدراج الحركة الجديدة في قاعدة البيانات
    await txn.insert('MainBoxTransactions', newTransaction.toMap());
  }

  Future<double> getCurrentBalance() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT BalanceAfter FROM MainBoxTransactions ORDER BY TransactionDate DESC, TransactionID DESC LIMIT 1",
    );
    return (result.first['BalanceAfter'] as num).toDouble();
  }

  /// يجلب تاريخ آخر معاملة مسجلة بالصندوق.
  Future<DateTime?> getLastTransactionDate() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT TransactionDate FROM MainBoxTransactions ORDER BY TransactionDate DESC, TransactionID DESC LIMIT 1",
    );
    if (result.isNotEmpty && result.first['TransactionDate'] != null) {
      final v = result.first['TransactionDate'];
      if (v is String) return DateTime.parse(v);
    }
    return null;
  }

  // ===============================
  // Read / Update / Delete helpers
  // ===============================
  Future<MainBoxTransactionModel?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'MainBoxTransactions',
      where: 'TransactionID = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return MainBoxTransactionModel.fromMap(res.first);
  }

  Future<bool> updateTransactionDescriptionAndType({
    required int transactionId,
    String? description,
    String? transactionType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final Map<String, Object?> data = {};
      if (description != null) data['Description'] = description;
      if (transactionType != null) data['TransactionType'] = transactionType;
      if (data.isEmpty) return true;
      final count = await db.update(
        'MainBoxTransactions',
        data,
        where: 'TransactionID = ?',
        whereArgs: [transactionId],
      );
      return count > 0;
    } catch (e) {
      // ignore: avoid_print
      print('updateTransactionDescriptionAndType failed: $e');
      return false;
    }
  }

  Future<bool> updateTransactionAmount({
    required int transactionId,
    required double amount,
    required bool isDeposit,
  }) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        final amountIn = isDeposit ? amount : 0.0;
        final amountOut = isDeposit ? 0.0 : amount;
        await txn.update(
          'MainBoxTransactions',
          {
            'AmountIn': amountIn,
            'AmountOut': amountOut,
          },
          where: 'TransactionID = ?',
          whereArgs: [transactionId],
        );
        await _recalculateAllBalancesInTxn(txn);
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('updateTransactionAmount failed: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int transactionId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        await txn.delete(
          'MainBoxTransactions',
          where: 'TransactionID = ?',
          whereArgs: [transactionId],
        );
        await _recalculateAllBalancesInTxn(txn);
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('deleteTransaction failed: $e');
      return false;
    }
  }

  Future<void> recalculateAllBalances() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await _recalculateAllBalancesInTxn(txn);
    });
  }

  Future<void> _recalculateAllBalancesInTxn(Transaction txn) async {
    final rows = await txn.rawQuery(
      'SELECT TransactionID, AmountIn, AmountOut FROM MainBoxTransactions ORDER BY TransactionDate ASC, TransactionID ASC',
    );
    double running = 0.0;
    for (final r in rows) {
      final inAmt = (r['AmountIn'] as num?)?.toDouble() ?? 0.0;
      final outAmt = (r['AmountOut'] as num?)?.toDouble() ?? 0.0;
      running = running + inAmt - outAmt;
      await txn.update(
        'MainBoxTransactions',
        {'BalanceAfter': running},
        where: 'TransactionID = ?',
        whereArgs: [r['TransactionID']],
      );
    }
  }

  // ===============================
  // Phase 2: Specialized helpers
  // ===============================
  // ملاحظة: هذه الدوال عبارة عن مغلفات تسهيلاً للاستخدام من الوحدات المختلفة
  // وتحافظ على التوافق مع دوال addTransaction / addTransactionInTransaction.

  // أنواع موحدة للاستخدام عبر النظام
  static const List<String> allowedTypes = <String>[
    'مبيعات',
    'فتح وردية',
    'مرتجع',
    'مصروف',
    'سحب',
    'إيداع',
    'تحويل',
  ];

  // ---- خارج Transaction ----
  Future<bool> addSales({
    required double amount,
    int? orderId,
    int? userId,
    String? description,
  }) {
    return addTransaction(
      transactionType: 'مبيعات',
      amount: amount,
      isDeposit: true,
      description: description ?? 'مبيعات نقدية',
      userId: userId,
      referenceId: orderId,
    );
  }

  Future<bool> addShiftOpen({
    required double amount,
    int? shiftId,
    int? userId,
    String? description,
  }) {
    return addTransaction(
      transactionType: 'فتح وردية',
      amount: amount,
      isDeposit: false, // صرف من الخزنة الرئيسية للصندوق
      description: description ?? 'فتح وردية',
      userId: userId,
      referenceId: shiftId,
    );
  }

  Future<bool> addReturn({
    required double amount,
    int? returnId,
    int? userId,
    String? description,
  }) {
    return addTransaction(
      transactionType: 'مرتجع',
      amount: amount,
      isDeposit: false, // إعادة مبلغ للعميل
      description: description ?? 'مرتجع عميل',
      userId: userId,
      referenceId: returnId,
    );
  }

  Future<bool> addExpense({
    required double amount,
    int? expenseId,
    int? userId,
    String? description,
  }) {
    return addTransaction(
      transactionType: 'مصروف',
      amount: amount,
      isDeposit: false,
      description: description ?? 'مصروف تشغيلي',
      userId: userId,
      referenceId: expenseId,
    );
  }

  Future<bool> addWithdrawal({
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransaction(
      transactionType: 'سحب',
      amount: amount,
      isDeposit: false,
      description: description,
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<bool> addDeposit({
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransaction(
      transactionType: 'إيداع',
      amount: amount,
      isDeposit: true,
      description: description,
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<bool> addTransferIn({
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransaction(
      transactionType: 'تحويل',
      amount: amount,
      isDeposit: true,
      description: description ?? 'تحويل وارد',
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<bool> addTransferOut({
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransaction(
      transactionType: 'تحويل',
      amount: amount,
      isDeposit: false,
      description: description ?? 'تحويل صادر',
      userId: userId,
      referenceId: referenceId,
    );
  }

  // ---- داخل Transaction ----
  Future<void> addSalesInTransaction({
    required Transaction txn,
    required double amount,
    int? orderId,
    int? userId,
    String? description,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'مبيعات',
      amount: amount,
      isDeposit: true,
      description: description ?? 'مبيعات نقدية',
      userId: userId,
      referenceId: orderId,
    );
  }

  Future<void> addShiftOpenInTransaction({
    required Transaction txn,
    required double amount,
    int? shiftId,
    int? userId,
    String? description,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'فتح وردية',
      amount: amount,
      isDeposit: false,
      description: description ?? 'فتح وردية',
      userId: userId,
      referenceId: shiftId,
    );
  }

  Future<void> addReturnInTransaction({
    required Transaction txn,
    required double amount,
    int? returnId,
    int? userId,
    String? description,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'مرتجع',
      amount: amount,
      isDeposit: false,
      description: description ?? 'مرتجع عميل',
      userId: userId,
      referenceId: returnId,
    );
  }

  Future<void> addExpenseInTransaction({
    required Transaction txn,
    required double amount,
    int? expenseId,
    int? userId,
    String? description,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'مصروف',
      amount: amount,
      isDeposit: false,
      description: description ?? 'مصروف تشغيلي',
      userId: userId,
      referenceId: expenseId,
    );
  }

  Future<void> addDepositInTransaction({
    required Transaction txn,
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'إيداع',
      amount: amount,
      isDeposit: true,
      description: description,
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<void> addWithdrawalInTransaction({
    required Transaction txn,
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'سحب',
      amount: amount,
      isDeposit: false,
      description: description,
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<void> addTransferInTransactionIn({
    required Transaction txn,
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'تحويل',
      amount: amount,
      isDeposit: true,
      description: description ?? 'تحويل وارد',
      userId: userId,
      referenceId: referenceId,
    );
  }

  Future<void> addTransferInTransactionOut({
    required Transaction txn,
    required double amount,
    int? userId,
    String? description,
    int? referenceId,
  }) {
    return addTransactionInTransaction(
      txn: txn,
      transactionType: 'تحويل',
      amount: amount,
      isDeposit: false,
      description: description ?? 'تحويل صادر',
      userId: userId,
      referenceId: referenceId,
    );
  }
}
