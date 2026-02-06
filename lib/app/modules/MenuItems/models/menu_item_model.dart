// file: models/menu_item_model.dart (تحديث)

import '../../MenuCategories/models/menu_category_model.dart';

class MenuItemModel {
  final int? menuItemsID;
  final String itemsName;
  final double price;
  final int categoryID;

  // خاصية إضافية لتخزين كائن الفئة المرتبطة
  // هذه الخاصية تملأ فقط عند استخدام استعلامات JOIN
  final MenuCategoryModel? category;

  MenuItemModel({
    this.menuItemsID,
    required this.itemsName,
    required this.price,
    required this.categoryID,
    this.category, // إضافة الخاصية الجديدة للمُنشئ
  });

  // دوال toMap و fromMap تبقى كما هي للتعامل مع جدول MenuItems فقط
  // لن نعدل عليها لأنها تخص الجدول الأساسي

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      menuItemsID: map['MenuItemsID'],
      itemsName: map['ItemsName'],
      price: (map['Price'] as num).toDouble(),
      categoryID: map['CategoryID'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'MenuItemsID': menuItemsID,
      'ItemsName': itemsName,
      'Price': price,
      'CategoryID': categoryID,
    };
  }
}
