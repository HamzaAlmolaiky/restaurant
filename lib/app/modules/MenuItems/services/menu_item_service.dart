// file: services/menu_item_service.dart

// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/database_helper.dart';
import '../../MenuCategories/models/menu_category_model.dart';
import '../models/menu_item_model.dart';

class MenuItemService {
  static final MenuItemService instance = MenuItemService._init();
  MenuItemService._init();

  // === دالة مساعدة خاصة لبناء كائن MenuItem من استعلام JOIN ===
  MenuItemModel _menuItemFromJoinedMap(Map<String, dynamic> map) {
    // إنشاء كائن الفئة المتداخل
    final category = map['CategoryID'] != null
        ? MenuCategoryModel(
            categoryID: map['CategoryID'],
            categoryName: map['CategoryName'],
            imagePath: map['CategoryImagePath'] as String?,
          )
        : null;

    // إنشاء كائن عنصر القائمة مع تمرير الفئة له
    return MenuItemModel(
      menuItemsID: map['MenuItemsID'],
      itemsName: map['ItemsName'],
      price: (map['Price'] as num).toDouble(),
      categoryID: map['CategoryID'],
      imagePath: map['ImagePath'] as String?,
      category: category,
    );
  }

  // GetAllMenuItems
  Future<List<MenuItemModel>> getAllMenuItems() async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT m.*, c.CategoryName, c.ImagePath as CategoryImagePath 
      FROM MenuItems m 
      LEFT JOIN MenuCategory c ON m.CategoryID = c.CategoryID
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((map) => _menuItemFromJoinedMap(map)).toList();
  }

  // GetMenuItemsByCategory
  Future<List<MenuItemModel>> getMenuItemsByCategory(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT m.*, c.CategoryName, c.ImagePath as CategoryImagePath 
      FROM MenuItems m 
      LEFT JOIN MenuCategory c ON m.CategoryID = c.CategoryID 
      WHERE m.CategoryID = ?
    ''';
    final maps = await db.rawQuery(sql, [categoryId]);
    return maps.map((map) => _menuItemFromJoinedMap(map)).toList();
  }

  // GetMenuItemById
  Future<MenuItemModel?> getMenuItemById(int id) async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT m.*, c.CategoryName, c.ImagePath as CategoryImagePath 
      FROM MenuItems m 
      LEFT JOIN MenuCategory c ON m.CategoryID = c.CategoryID 
      WHERE m.MenuItemsID = ?
    ''';
    final maps = await db.rawQuery(sql, [id]);
    return maps.isNotEmpty ? _menuItemFromJoinedMap(maps.first) : null;
  }

  // Count items in a specific category
  Future<int> countItemsInCategory(int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM MenuItems WHERE CategoryID = ?',
      [categoryId],
    );
    final cnt = result.isNotEmpty ? (result.first['cnt'] as int) : 0;
    return cnt;
  }

  // Reassign all items from one category to another
  Future<int> reassignItemsCategory(int fromCategoryId, int toCategoryId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'MenuItems',
      {'CategoryID': toCategoryId},
      where: 'CategoryID = ?',
      whereArgs: [fromCategoryId],
    );
  }

  // AddMenuItem
  Future<int> addMenuItem(MenuItemModel menuItem) async {
    final db = await DatabaseHelper.instance.database;
    // نستخدم toMap الذي يتعامل مع الأعمدة الأساسية فقط
    return await db.insert('MenuItems', menuItem.toMap());
  }

  // UpdateMenuItem
  Future<bool> updateMenuItem(MenuItemModel menuItem) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.update(
      'MenuItems',
      menuItem.toMap(),
      where: 'MenuItemsID = ?',
      whereArgs: [menuItem.menuItemsID],
    );
    return rows > 0;
  }

  // DeleteMenuItem
  Future<bool> deleteMenuItem(int menuItemId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.delete(
      'MenuItems',
      where: 'MenuItemsID = ?',
      whereArgs: [menuItemId],
    );
    return rows > 0;
  }

  // SearchMenuItems
  Future<List<MenuItemModel>> searchMenuItems(String searchTerm) async {
    final db = await DatabaseHelper.instance.database;
    const sql = '''
      SELECT m.*, c.CategoryName, c.ImagePath as CategoryImagePath 
      FROM MenuItems m 
      LEFT JOIN MenuCategory c ON m.CategoryID = c.CategoryID 
      WHERE m.ItemsName LIKE ?
    ''';
    final maps = await db.rawQuery(sql, ['%$searchTerm%']);
    return maps.map((map) => _menuItemFromJoinedMap(map)).toList();
  }

  // --- دوال للتعامل مع Transaction ---

  Future<int> addMenuItemInTransaction(
    MenuItemModel menuItem,
    Transaction txn,
  ) async {
    return await txn.insert('MenuItems', menuItem.toMap());
  }

  Future<bool> updateMenuItemInTransaction(
    MenuItemModel menuItem,
    Transaction txn,
  ) async {
    final rows = await txn.update(
      'MenuItems',
      menuItem.toMap(),
      where: 'MenuItemsID = ?',
      whereArgs: [menuItem.menuItemsID],
    );
    return rows > 0;
  }

  Future<bool> deleteMenuItemInTransaction(
    int menuItemId,
    Transaction txn,
  ) async {
    final rows = await txn.delete(
      'MenuItems',
      where: 'MenuItemsID = ?',
      whereArgs: [menuItemId],
    );
    return rows > 0;
  }
}
