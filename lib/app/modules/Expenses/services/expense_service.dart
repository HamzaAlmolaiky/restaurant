// file: services/expense_service.dart

import '../../../helpers/database_helper.dart';
import '../../MainBox/services/main_box_service.dart';
import '../models/expense_model.dart';
// سنحتاج إلى خدمة الخزنة الرئيسية لاحقاً

class ExpenseService {
  // Singleton pattern
  static final ExpenseService instance = ExpenseService._init();
  ExpenseService._init();

  // AddExpense (النسخة البسيطة)
  Future<bool> addExpense(ExpenseModel expense) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('Expenses', expense.toMap());
    return id > 0;
  }

  // AddExpense3 (النسخة المعقدة مع منطق العمل)
  Future<bool> addExpenseComplex(ExpenseModel expense) async {
    // الشرط الحاسم لتوجيه المصروف
    if (expense.shiftID == 1) {
      // 1 قد يمثل الخزنة الرئيسية
      // الحالة 1: المصروف من الخزنة الرئيسية
      // نستدعي خدمة الخزنة بدلاً من الـ Controller مباشرة
      return MainBoxService.instance.addTransaction(
        transactionType: 'صرف - ${expense.expenseType ?? ""}',
        amount: expense.amount,
        isDeposit: false, // حركة صرف
        description: expense.description,
        userId: expense.userID,
        referenceId: expense.expenseID,
      );
    } else {
      // الحالة 2: المصروف من صندوق كاشير (الكود الأصلي)
      return addExpense(expense);
    }
  }

  // GetExpensesForShift
  Future<List<ExpenseModel>> getExpensesForShift(int shiftID) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Expenses',
      where: 'ShiftID = ?',
      whereArgs: [shiftID],
      orderBy: 'ExpenseDate DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // GetTotalExpensesForShift
  Future<double> getTotalExpensesForShift(int shiftID) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(Amount), 0) as total FROM Expenses WHERE ShiftID = ?',
      [shiftID],
    );
    return (result.first['total'] as num).toDouble();
  }

  // GetTodayTotalExpenses
  Future<double> getTodayTotalExpenses() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        "SELECT IFNULL(SUM(Amount), 0) as total FROM Expenses WHERE date(ExpenseDate) = date('now', 'localtime')");
    return (result.first['total'] as num).toDouble();
  }

  // GetExpensesByFilter (مع JOIN وفلترة ديناميكية)
  Future<List<ExpenseModel>> getExpensesByFilter(
      DateTime fromDate, DateTime toDate,
      {String? expenseType}) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'date(e.ExpenseDate) BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10)
    ];

    if (expenseType != null && expenseType.isNotEmpty) {
      whereClause += ' AND e.ExpenseType = ?';
      whereArgs.add(expenseType);
    }

    final String sql = '''
      SELECT e.*, u.Username AS UserName 
      FROM Expenses e
      LEFT JOIN Users u ON e.UserID = u.UserID
      WHERE $whereClause
      ORDER BY e.ExpenseDate DESC;
    ''';

    final maps = await db.rawQuery(sql, whereArgs);
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // GetDistinctExpenseTypes
  Future<List<String>> getDistinctExpenseTypes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Expenses',
      distinct: true,
      columns: ['ExpenseType'],
      where: 'ExpenseType IS NOT NULL AND ExpenseType != ?',
      whereArgs: [''],
      orderBy: 'ExpenseType',
    );

    return maps.map((map) => map['ExpenseType'] as String).toList();
  }

  // GetExpenseStats (إحصائيات مجمعة)
  Future<double> getExpenseStats(DateTime fromDate, DateTime toDate,
      {String? expenseType}) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'date(ExpenseDate) BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      fromDate.toIso8601String().substring(0, 10),
      toDate.toIso8601String().substring(0, 10)
    ];

    if (expenseType != null && expenseType.isNotEmpty) {
      whereClause += ' AND ExpenseType = ?';
      whereArgs.add(expenseType);
    }

    final String sql =
        'SELECT IFNULL(SUM(Amount), 0) as total FROM Expenses WHERE $whereClause';
    final result = await db.rawQuery(sql, whereArgs);
    return (result.first['total'] as num).toDouble();
  }

  // DeleteExpense
  Future<bool> deleteExpense(int expenseId) async {
    final db = await DatabaseHelper.instance.database;
    final rowsAffected = await db.delete(
      'Expenses',
      where: 'ExpenseID = ?',
      whereArgs: [expenseId],
    );
    return rowsAffected > 0;
  }
}
