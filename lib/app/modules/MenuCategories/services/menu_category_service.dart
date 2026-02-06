// file: services/menu_category_service.dart
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../../MenuItems/models/menu_item_model.dart';
import '../models/menu_category_model.dart';

class MenuCategoryService {
  static final MenuCategoryService instance = MenuCategoryService._init();
  MenuCategoryService._init();

  /// جلب جميع الفئات
  /// هذه الدالة تعيد قائمة من الفئات مع العناصر المرتبطة بها
  Future<List<MenuCategoryModel>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('MenuCategory', orderBy: 'CategoryName');
    return maps.map((map) => MenuCategoryModel.fromMap(map)).toList();
  }

  /// جلب قائمة الفئات حسب المعرف
  Future<MenuCategoryModel?> getCategoryById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'MenuCategory',
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? MenuCategoryModel.fromMap(maps.first) : null;
  }

  /// جلب قائمة الفئات حسب الاسم
  Future<MenuCategoryModel?> getCategoryByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'MenuCategory',
      where: 'CategoryName = ?',
      whereArgs: [name],
    );
    return maps.isNotEmpty ? MenuCategoryModel.fromMap(maps.first) : null;
  }

  /// التحقق من وجود الفئة
  Future<bool> categoryExists(String name) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'MenuCategory',
      where: 'CategoryName = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }

  /// اضافة الفئة
  Future<int> addCategory(MenuCategoryModel category) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('MenuCategory', category.toMap());
  }

  /// تحديث الفئة
  Future<bool> updateCategory(MenuCategoryModel category) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.update(
      'MenuCategory',
      category.toMap(),
      where: 'CategoryID = ?',
      whereArgs: [category.categoryID],
    );
    return rows > 0;
  }

  /// حذف الفئة من قاعدة البيانات
  Future<bool> deleteCategory(int categoryID) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.delete(
      'MenuCategory',
      where: 'CategoryID = ?',
      whereArgs: [categoryID],
    );
    return rows > 0;
  }

  /// التحويل المباشر لدالة GetCategoriesWithItems المعقدة
  /// يتم استخدامها في جلب القائمة الكاملة للفئات والعناصر المرتبطة بها
  Future<List<MenuCategoryModel>> getCategoriesWithItems() async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT c.CategoryID, c.CategoryName, i.MenuItemsID, i.ItemsName, i.Price
      FROM MenuCategory c
      LEFT JOIN MenuItems i ON c.CategoryID = i.CategoryID
      ORDER BY c.CategoryID, i.ItemsName
    ''';
    final result = await db.rawQuery(sql);

    // استخدام Map لتجميع النتائج بكفاءة
    final Map<int, MenuCategoryModel> categoriesMap = {};

    for (final row in result) {
      final categoryId = row['CategoryID'] as int;

      // إذا لم تكن الفئة موجودة في الـ Map، أضفها
      if (!categoriesMap.containsKey(categoryId)) {
        categoriesMap[categoryId] = MenuCategoryModel.fromMap(row);
      }

      // إذا كانت هناك بيانات لعنصر قائمة (ليس null)، أضفه إلى قائمة الفئة
      if (row['MenuItemsID'] != null) {
        final menuItem = MenuItemModel(
          menuItemsID: row['MenuItemsID'] as int,
          itemsName: row['ItemsName'] as String,
          price: (row['Price'] as num).toDouble(),
          categoryID: categoryId,
        );
        categoriesMap[categoryId]?.menuItems.add(menuItem);
      }
    }
    return categoriesMap.values.toList();
  }

  // --- دوال للتعامل مع Transaction ---
  /// هذه الدوال تعمل كأدوات يمكن استخدامها داخل بلوك db.transaction

  Future<int> addCategoryInTransaction(
    MenuCategoryModel category,
    Transaction txn,
  ) async {
    return await txn.insert('MenuCategory', category.toMap());
  }

  Future<bool> updateCategoryInTransaction(
    MenuCategoryModel category,
    Transaction txn,
  ) async {
    final rows = await txn.update(
      'MenuCategory',
      category.toMap(),
      where: 'CategoryID = ?',
      whereArgs: [category.categoryID],
    );
    return rows > 0;
  }

  Future<bool> deleteCategoryInTransaction(
    int categoryID,
    Transaction txn,
  ) async {
    final rows = await txn.delete(
      'MenuCategory',
      where: 'CategoryID = ?',
      whereArgs: [categoryID],
    );
    return rows > 0;
  }
}
