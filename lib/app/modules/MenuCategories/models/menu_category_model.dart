// file: models/menu_category_model.dart

import '../../MenuItems/models/menu_item_model.dart';

class MenuCategoryModel {
  final int? categoryID;
  final String categoryName;
  List<MenuItemModel> menuItems; // قائمة العناصر التابعة لهذه الفئة

  MenuCategoryModel({
    this.categoryID,
    required this.categoryName,
    List<MenuItemModel>? menuItems, // نجعلها اختيارية في المُنشئ
  }) : menuItems = menuItems ?? []; // إذا كانت null، يتم تهيئتها كقائمة فارغة

  // ملاحظة: toMap و fromMap هنا تخص جدول MenuCategory فقط
  // قائمة menuItems يتم ملؤها عبر دوال خاصة مثل getCategoriesWithItems

  factory MenuCategoryModel.fromMap(Map<String, dynamic> map) {
    return MenuCategoryModel(
      categoryID: map['CategoryID'],
      categoryName: map['CategoryName'],
    );
  }

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      categoryID: json['CategoryID'],
      categoryName: json['CategoryName'],
    );
  }

  /// تحويل النموذج إلى خريطة (Map) لتخزينه في قاعدة البيانات
  /// هذا مفيد عند إضافة أو تحديث الفئات في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {'CategoryID': categoryID, 'CategoryName': categoryName};
  }
}
