import '../../Customers/models/customer_model.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../../Users/models/user_model.dart';

class OrderModel {
  int? orderID;
  final DateTime orderDate;
  final double totalAmount;
  final double taxAmount;
  final double serviceCharge;
  final String paymentMethod;
  final double amountPaid;
  final double amountDue;
  final int? customerID;
  final int userID;
  final int shiftID;
  final String? notes;
  List<OrderItemModel> orderItems;
  final CustomerModel? customer; // لتخزين بيانات العميل من JOIN
  final UserModel? user; // لتخزين بيانات المستخدم من JOIN

  OrderModel({
    this.orderID,
    required this.orderDate,
    required this.totalAmount,
    this.taxAmount = 0.0,
    this.serviceCharge = 0.0,
    required this.paymentMethod,
    required this.amountPaid,
    required this.amountDue,
    this.customerID,
    required this.userID,
    required this.shiftID,
    this.notes,
    List<OrderItemModel>? orderItems,
    this.customer,
    this.user,
  }) : orderItems = orderItems ?? [];

  Map<String, dynamic> toMap() => {
    'OrderID': orderID,
    'OrderDate': orderDate.toIso8601String(),
    'TotalAmount': totalAmount,
    'TaxAmount': taxAmount,
    'ServiceCharge': serviceCharge,
    'PaymentMethod': paymentMethod,
    'AmountPaid': amountPaid,
    'AmountDue': amountDue,
    'CustomerID': customerID,
    'UserID': userID,
    'ShiftID': shiftID,
    'Notes': notes,
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderID: map['OrderID'] as int?,
      orderDate:
          DateTime.tryParse(map['OrderDate']?.toString() ?? '') ??
          DateTime.now(),
      totalAmount: (map['TotalAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['TaxAmount'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (map['ServiceCharge'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['PaymentMethod']?.toString() ?? 'Cash',
      amountPaid: (map['AmountPaid'] as num?)?.toDouble() ?? 0.0,
      amountDue: (map['AmountDue'] as num?)?.toDouble() ?? 0.0,
      customerID: map['CustomerID'] as int?,
      userID: (map['UserID'] as num).toInt(),
      shiftID: (map['ShiftID'] as num).toInt(),
      notes: map['Notes'] as String?,
    );
  }
}
