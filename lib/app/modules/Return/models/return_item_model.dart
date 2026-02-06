// file: models/return_item_model.dart
class ReturnItemModel {
  final int? returnItemID;
  final int returnID;
  final int productID; // corresponds to MenuItemsID
  final double quantity;
  final double unitPrice;
  final double subTotal;

  ReturnItemModel({
    this.returnItemID,
    required this.returnID,
    required this.productID,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
  });

  Map<String, dynamic> toMap() => {
    'ReturnID': returnID,
    'ProductID': productID,
    'Quantity': quantity,
    'UnitPrice': unitPrice,
    'SubTotal': subTotal,
  };

  factory ReturnItemModel.fromMap(Map<String, dynamic> map) => ReturnItemModel(
    returnID: map['ReturnID'],
    productID: map['ProductID'],
    quantity: map['Quantity'],
    unitPrice: map['UnitPrice'],
    subTotal: map['SubTotal'],
  );
}
