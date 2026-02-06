import '../../MenuItems/models/menu_item_model.dart';
import '../../MenuCategories/models/menu_category_model.dart';

class OrderItemModel {
  final int? orderItemsID;
  final int orderID;
  final int menuItemsID;
  final double quantity;
  final double price;
  final MenuItemModel? menuItem; // لتخزين بيانات الصنف من JOIN

  OrderItemModel({
    this.orderItemsID,
    required this.orderID,
    required this.menuItemsID,
    required this.quantity,
    required this.price,
    this.menuItem,
  });

  Map<String, dynamic> toMap() => {
    'OrderItemsID': orderItemsID,
    'OrderID': orderID,
    'ItemsID': menuItemsID,
    'Quantity': quantity,
    'Price': price,
    'Total': quantity * price,
  };

  /// دالة إضافية لتحويل الموديل مع بيانات الربط إلى خريطة
  Map<String, dynamic> toMapWithJoins() {
    final map = toMap();
    map['item_name'] = menuItem?.itemsName;
    map['category_name'] = menuItem?.category?.categoryName;
    return map;
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    // قراءة الحقول الأساسية بأمان
    final qty = (map['Quantity'] as num?)?.toDouble() ??
        ((map['Quantity'] is String) ? double.tryParse(map['Quantity']) ?? 0.0 : 0.0);

    // في حال كانت هناك أعمدة من JOIN (ItemsName و CategoryName)
    final itemsName = map['ItemsName'] as String?;
    final categoryName = map['CategoryName'] as String?;
    MenuItemModel? itemModel;
    if (itemsName != null) {
      itemModel = MenuItemModel(
        menuItemsID: map['MenuItemsID'] as int?,
        itemsName: itemsName,
        price: (map['ItemPrice'] as num?)?.toDouble() ?? (map['Price'] as num?)?.toDouble() ?? 0.0,
        categoryID: (map['CategoryID'] as int?) ?? 0,
        category: categoryName != null
            ? MenuCategoryModel(categoryID: map['CategoryID'] as int?, categoryName: categoryName)
            : null,
      );
    }

    return OrderItemModel(
      orderItemsID: map['OrderItemsID'] as int?,
      orderID: map['OrderID'] as int,
      menuItemsID: map['ItemsID'] as int,
      quantity: qty,
      price: (map['Price'] as num).toDouble(),
      menuItem: itemModel,
    );
  }
}
