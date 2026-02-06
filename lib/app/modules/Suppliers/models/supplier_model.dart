// file: models/supplier_model.dart

import '../../Users/models/user_model.dart';

class SupplierModel {
  final int? supplierID;
  final String? supplierName;
  final String itemsName;
  final double quantity;
  final double price;
  final String status; // e.g., 'Paid', 'Unpaid'
  final double? amountPaid;
  final double? amountDue;
  final DateTime date;
  final int userID;

  // خاصية إضافية لتخزين كائن المستخدم المرتبط
  final UserModel? user;

  SupplierModel({
    this.supplierID,
    this.supplierName,
    required this.itemsName,
    required this.quantity,
    required this.price,
    required this.status,
    this.amountPaid,
    this.amountDue,
    required this.date,
    required this.userID,
    this.user,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      supplierID: map['SupplierID'],
      supplierName: map['SupplierName'],
      itemsName: map['ItemsName'],
      quantity: (map['Quantity'] as num).toDouble(),
      price: (map['Price'] as num).toDouble(),
      status: map['Status'],
      amountPaid: map['AmountPaid'] != null
          ? (map['AmountPaid'] as num).toDouble()
          : null,
      amountDue: map['AmountDue'] != null
          ? (map['AmountDue'] as num).toDouble()
          : null,
      date: DateTime.parse(map['Date']),
      userID: map['UserID'],
      user: map['Username'] != null
          ? UserModel(
              userID: map['UserID'],
              username: map['Username'],
              password: '',
              role: '')
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'SupplierID': supplierID,
      'SupplierName': supplierName,
      'ItemsName': itemsName,
      'Quantity': quantity,
      'Price': price,
      'Status': status,
      'AmountPaid': amountPaid,
      'AmountDue': amountDue,
      'Date': date.toIso8601String(),
      'UserID': userID,
    };
  }
}
