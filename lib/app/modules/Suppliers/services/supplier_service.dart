import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite_common/utils/utils.dart' as utils;
import '../../../helpers/database_helper.dart';
import '../models/supplier_model.dart';
import '../models/supplier_stats_model.dart';
import '../models/purchase_order_model.dart';

class SupplierService {
  // الخطوة 1: استخدام نمط Singleton لضمان وجود نسخة واحدة فقط من الخدمة
  static final SupplierService instance = SupplierService._internal();
  SupplierService._internal();

  // اختصار للوصول إلى قاعدة البيانات
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // -- العمليات الأساسية (CRUD) --

  /// إضافة مورد جديد باستخدام نموذج البيانات
  Future<int> addSupplier(SupplierModel supplier) async {
    final db = await _db;
    // toMap يعيد مفاتيح PascalCase المتوافقة مع المخطط
    final map = supplier.toMap();
    return await db.insert('Suppliers', map);
  }

  /// تحديث بيانات مورد
  Future<bool> updateSupplier(SupplierModel supplier) async {
    final db = await _db;
    final map = supplier.toMap();
    final rows = await db.update(
      'Suppliers',
      map,
      where: 'SupplierID = ?',
      whereArgs: [supplier.supplierID],
    );
    return rows > 0;
  }

  /// حذف مورد
  Future<bool> deleteSupplier(int id) async {
    final db = await _db;
    final rows = await db.delete('Suppliers', where: 'SupplierID = ?', whereArgs: [id]);
    return rows > 0;
  }

  // -- دوال الجلب والقراءة --

  /// الحصول على مورد بالمعرف مع اسم المستخدم المرتبط
  Future<SupplierModel?> getSupplierById(int id) async {
    final db = await _db;
    const sql =
        "SELECT s.*, u.Username FROM Suppliers s LEFT JOIN Users u ON s.UserID = u.UserID WHERE s.SupplierID = ?";
    final maps = await db.rawQuery(sql, [id]);
    return maps.isNotEmpty ? SupplierModel.fromMap(maps.first) : null;
  }

  /// الحصول على جميع الموردين
  Future<List<SupplierModel>> getAllSuppliers() async {
    final db = await _db;
    const sql =
        "SELECT s.*, u.Username FROM Suppliers s LEFT JOIN Users u ON s.UserID = u.UserID ORDER BY s.SupplierName ASC";
    final maps = await db.rawQuery(sql);
    return maps.map((map) => SupplierModel.fromMap(map)).toList();
  }

  // -- دوال البحث والفلترة --

  /// البحث المتقدم في الموردين (بالاسم أو اسم الصنف)
  Future<List<SupplierModel>> searchSuppliers(String query) async {
    final db = await _db;
    const sql = '''
      SELECT s.*, u.Username FROM Suppliers s 
      LEFT JOIN Users u ON s.UserID = u.UserID 
      WHERE s.SupplierName LIKE ? OR s.ItemsName LIKE ? OR s.Status LIKE ?
      ORDER BY s.SupplierName ASC
    ''';
    final like = '%$query%';
    final maps = await db.rawQuery(sql, [like, like, like]);
    return maps.map((map) => SupplierModel.fromMap(map)).toList();
  }

  /// فلترة الموردين حسب الحالة
  Future<List<SupplierModel>> getSuppliersByStatus(String status) async {
    final db = await _db;
    const sql =
        "SELECT s.*, u.Username FROM Suppliers s LEFT JOIN Users u ON s.UserID = u.UserID WHERE s.Status = ? ORDER BY s.SupplierName ASC";
    final maps = await db.rawQuery(sql, [status]);
    return maps.map((map) => SupplierModel.fromMap(map)).toList();
  }

  // -- دوال الإحصائيات والتحليلات --

  /// الحصول على إحصائيات شاملة للموردين
  Future<SupplierStatsModel> getSupplierStats() async {
    final db = await _db;
    final total = utils.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Suppliers'),
    );

    // توحيد الحالة إلى Paid/Unpaid
    final paid = utils.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Suppliers WHERE Status = ?', [
        'Paid',
      ]),
    );
    final unpaid = utils.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Suppliers WHERE Status = ?', [
        'Unpaid',
      ]),
    );

    // عدد أوامر الشراء وإجمالي قيمتها
    final purchaseOrdersCount = utils.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Purchase_Orders'),
    );
    final totalPurchasesMap = await db.rawQuery(
      'SELECT SUM(TotalAmount) as total FROM Purchase_Orders WHERE Status = ?',
      ['Paid'],
    );
    final totalPurchasesValue =
        (totalPurchasesMap.isNotEmpty ? totalPurchasesMap.first['total'] as num? : null)?.toDouble() ?? 0.0;

    return SupplierStatsModel(
      total: total ?? 0,
      active: paid ?? 0, // نستخدم active لتمثيل عدد Paid
      inactive: unpaid ?? 0, // ونستخدم inactive لتمثيل Unpaid
      suspended: 0,
      avgRating: 0.0, // لا يوجد حقل تقييم في المخطط الحالي
      purchaseOrdersCount: purchaseOrdersCount ?? 0,
      totalPurchasesValue: totalPurchasesValue,
    );
  }

  /// الحصول على أفضل الموردين حسب إجمالي المشتريات
  Future<List<SupplierModel>> getTopSuppliers({int limit = 10}) async {
    final db = await _db;
    const sql = '''
      SELECT s.*, COUNT(po.PurchaseOrderID) as purchase_count, SUM(po.TotalAmount) as total_purchases
      FROM Suppliers s
      LEFT JOIN Purchase_Orders po ON s.SupplierID = po.SupplierID AND po.Status = 'Paid'
      GROUP BY s.SupplierID
      ORDER BY total_purchases DESC
      LIMIT ?
    ''';
    final maps = await db.rawQuery(sql, [limit]);
    return maps.map((map) => SupplierModel.fromMap(map)).toList();
  }

  /// الحصول على تاريخ التعامل (طلبات الشراء) لمورد معين
  Future<List<PurchaseOrderModel>> getSupplierHistory(int supplierId) async {
    final db = await _db;
    final maps = await db.query(
      'Purchase_Orders',
      where: 'SupplierID = ?',
      whereArgs: [supplierId],
      orderBy: 'CreatedAt DESC',
    );
    return maps.map((map) => PurchaseOrderModel.fromMap(map)).toList();
  }
}
