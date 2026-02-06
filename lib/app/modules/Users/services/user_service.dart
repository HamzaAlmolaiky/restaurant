// file: services/user_service.dart

// ignore_for_file: avoid_print

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../helpers/database_helper.dart';
import '../models/user_daily_stats_model.dart';
import '../models/user_model.dart';

class UserService {
  /// Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  static UserService get instance => _instance;

  Future<bool> addUser(UserModel user) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(
      'Users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return id > 0;
  }

  Future<bool> updateUser(UserModel user) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.update(
      'Users',
      user.toMap(),
      where: 'UserID = ?',
      whereArgs: [user.userID],
    );
    return rows > 0;
  }

  Future<bool> deleteUser(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.delete('Users', where: 'UserID = ?', whereArgs: [id]);
    return rows > 0;
  }

  /// جلب جميع المستخدمين
  Future<List<UserModel>> getAllUsers() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final maps = await db.query(
        'Users',
        orderBy: 'Username ASC',
        where: 'IsActive = ?',
        whereArgs: [1], // جلب المستخدمين النشطين فقط
      );
      return maps.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('خطأ في جلب جميع المستخدمين: $e');
      return [];
    }
  }

  /// جلب المستخدمين النشطين
  Future<List<UserModel>> getActiveUsers() async {
    final db = await DatabaseHelper.instance.database;

    try {
      final maps = await db.query(
        'Users',
        where: 'IsActive = ?',
        whereArgs: [1],
        orderBy: 'Username ASC',
      );

      return maps.map((map) => UserModel.fromMap(map)).toList();
    } catch (e) {
      print('خطأ في جلب المستخدمين النشطين: $e');
      return [];
    }
  }

  /// تحديث حالة التفعيل لمستخدم
  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.update(
      'Users',
      {'IsActive': isActive ? 1 : 0},
      where: 'UserID = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  /// تغيير كلمة مرور مستخدم
  Future<bool> changePassword(int userId, String newPassword) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.update(
      'Users',
      {'Password': newPassword},
      where: 'UserID = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  /// تغيير كلمة المرور بعد التحقق من الكلمة الحالية
  Future<bool> changePasswordWithOld(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final db = await DatabaseHelper.instance.database;
    // لن نحدّث إلا إذا طابقت كلمة المرور القديمة
    final rows = await db.update(
      'Users',
      {'Password': newPassword},
      where: 'UserID = ? AND Password = ?',
      whereArgs: [userId, oldPassword],
    );
    return rows > 0;
  }

  /// جلب المستخدمين النشطين
  Future<List<UserDailyStatsModel>> getUserHistoricalStats(
    int userId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT 
        u.UserID,
        u.Username,
        DATE(o.OrderDate) AS OrderDate,
        COUNT(o.OrderID) AS OrdersCount,
        SUM(o.TotalAmount) AS TotalSales
      FROM Users u
      LEFT JOIN Orders o ON u.UserID = o.UserID 
        AND DATE(o.OrderDate) BETWEEN ? AND ?
      WHERE u.UserID = ?
      GROUP BY u.UserID, DATE(o.OrderDate)
      ORDER BY DATE(o.OrderDate) DESC
    ''';
    final maps = await db.rawQuery(sql, [
      userId,
      fromDate.toIso8601String(),
      toDate.toIso8601String(),
    ]);
    return maps.map((map) => UserDailyStatsModel.fromMap(map)).toList();
  }
}
