// file: services/shift_service.dart
import '../../../helpers/database_helper.dart';
import '../../MainBox/services/main_box_service.dart';
import '../models/shift_details_model.dart';
import '../models/shift_model.dart';

class ShiftService {
  final MainBoxService _mainBoxService;
  ShiftService(this._mainBoxService);

  Future<ShiftModel?> findOpenShiftForUser(int userID) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'CashierShifts',
      where: 'UserID = ? AND Status = ?',
      whereArgs: [userID, 'Open'],
      limit: 1,
    );
    return maps.isNotEmpty ? ShiftModel.fromMap(maps.first) : null;
  }

  Future<int> createNewShift(ShiftModel shift) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('CashierShifts', shift.toMap());
  }

  /// ** الدالة الرئيسية لإغلاق الوردية وترحيل المبلغ للخزنة **
  Future<bool> closeShiftAndPostToMainBox(
    int shiftIdToClose,
    double actualClosingBalance,
    int supervisorId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.transaction((txn) async {
        // --- الخطوة 1: تحديث حالة الوردية إلى "مغلقة" ---
        final rowsAffected = await txn.update(
          'CashierShifts',
          {
            'EndTime': DateTime.now().toIso8601String(),
            'ClosingBalance': actualClosingBalance,
            'Status': 'Closed',
          },
          where: 'ShiftID = ?',
          whereArgs: [shiftIdToClose],
        );
        if (rowsAffected == 0) throw ("الوردية غير موجودة أو مغلقة بالفعل.");

        // --- الخطوة 2: ترحيل المبلغ إلى الخزنة الرئيسية ---
        // دالة addTransaction في MainBoxService تقوم بكل العمل داخل transaction
        // لكننا نريدها أن تعمل داخل الـ transaction الحالي، لذا سنحتاج لدالة InTransaction

        final cashierUsernameResult = await txn.rawQuery(
          "SELECT u.Username FROM Users u JOIN CashierShifts s ON u.UserID = s.UserID WHERE s.ShiftID = ?",
          [shiftIdToClose],
        );
        final cashierUsername = cashierUsernameResult.isNotEmpty
            ? cashierUsernameResult.first['Username'] as String
            : 'غير معروف';

        await _mainBoxService.addTransactionInTransaction(
          // <-- دالة جديدة يجب إنشاؤها في MainBoxService
          txn: txn,
          transactionType: "استلام من صندوق",
          amount: actualClosingBalance,
          isDeposit: true,
          description:
              "استلام إغلاق وردية من الكاشير: $cashierUsername صندوق $shiftIdToClose",
          userId: supervisorId,
          referenceId: shiftIdToClose,
        );
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print("فشل إغلاق الوردية: $e");
      rethrow;
    }
  }

  /// ** جلب سجل الورديات مع كل الإحصائيات **
  Future<List<ShiftDetailsModel>> getShiftsHistory(
    int userID,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    // نفس استعلام الـ JOIN والـ GROUP BY المعقد من C#
    const sql = """
      SELECT s.ShiftID, s.UserID, IFNULL(u.Username, 'مستخدم محذوف') AS UserName,
             s.StartTime, s.EndTime, s.OpeningBalance, s.ClosingBalance, s.Status,
             IFNULL(o.TotalSales, 0) AS TotalSales, IFNULL(r.TotalReturns, 0) AS TotalReturns,
             IFNULL(e.TotalExpenses, 0) AS TotalExpenses, IFNULL(rv.TotalReceipts, 0) AS TotalReceipts,
             CASE WHEN s.Status = 'Closed' THEN (s.ClosingBalance - (s.OpeningBalance + IFNULL(o.TotalSales, 0) + IFNULL(rv.TotalReceipts, 0) - IFNULL(r.TotalReturns, 0) - IFNULL(e.TotalExpenses, 0))) ELSE 0 END AS Difference
      FROM CashierShifts s
      LEFT JOIN Users u ON s.UserID = u.UserID
      LEFT JOIN (SELECT ShiftID, SUM(TotalAmount) as TotalSales FROM Orders WHERE PaymentMethod != 'Credit' GROUP BY ShiftID) o ON s.ShiftID = o.ShiftID
      LEFT JOIN (SELECT ret.ShiftID, SUM(ret.TotalReturnAmount) as TotalReturns FROM OrderReturns ret JOIN Orders ord ON ret.OriginalOrderID = ord.OrderID WHERE ord.PaymentMethod != 'Credit' GROUP BY ret.ShiftID) r ON s.ShiftID = r.ShiftID
      LEFT JOIN (SELECT ShiftID, SUM(Amount) as TotalExpenses FROM Expenses GROUP BY ShiftID) e ON s.ShiftID = e.ShiftID
      LEFT JOIN (SELECT ShiftID, SUM(AmountReceived) as TotalReceipts FROM CustomerPayments WHERE AmountReceived > 0 GROUP BY ShiftID) rv ON s.ShiftID = rv.ShiftID
      WHERE s.UserID = ? AND s.Status = 'Closed' AND date(s.StartTime) BETWEEN date(?) AND date(?)
      ORDER BY s.StartTime DESC
    """;
    final maps = await db.rawQuery(sql, [
      userID,
      fromDate.toIso8601String(),
      toDate.toIso8601String(),
    ]);
    return maps.map((map) => ShiftDetailsModel.fromMap(map)).toList();
  }
}
