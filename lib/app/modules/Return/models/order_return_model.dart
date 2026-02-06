// file: models/order_return_model.dart
import '../models/return_item_model.dart';

// دوال مساعدة للتحويل الآمن
int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int _toInt(dynamic v, {int fallback = 0}) {
  return _toIntOrNull(v) ?? fallback;
}

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String? _toStringOrNull(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

String _toString(dynamic v, {String fallback = ''}) {
  return v == null ? fallback : v.toString();
}

class OrderReturnModel {
  // --- الخصائص الأساسية (من جدول OrderReturns) ---
  final int? returnID;
  final int originalOrderID;
  final int shiftID;
  final DateTime returnDate;
  final String returnReason;
  final int userID;
  final double totalReturnAmount;
  final int? customerID; // إضافة معرف العميل
  final String? returnStatus; // حالة المرتجع (قيد المراجعة/مقبول/مرفوض/مكتمل)
  List<ReturnItemModel> returnItems;

  // --- الخصائص الإضافية (من جداول JOIN) ---
  final String? customerName;
  final String? customerPhone;
  final String? userName; // اسم المستخدم الذي أنشأ المرتجع

  OrderReturnModel({
    // الأساسية
    this.returnID,
    required this.originalOrderID,
    required this.shiftID,
    required this.returnDate,
    required this.returnReason,
    required this.userID,
    required this.totalReturnAmount,
    this.customerID,
    this.returnStatus,
    List<ReturnItemModel>? returnItems,

    // الإضافية
    this.customerName,
    this.customerPhone,
    this.userName,
  }) : returnItems = returnItems ?? [];

  // toMap تحديث لتشمل CustomerID
  Map<String, dynamic> toMap() => {
    'OriginalOrderID': originalOrderID,
    'ShiftID': shiftID,
    'ReturnDate': returnDate.toIso8601String(),
    'ReturnReason': returnReason,
    'UserID': userID,
    'TotalReturnAmount': totalReturnAmount,
    if (customerID != null) 'CustomerID': customerID,
    if (returnStatus != null) 'ReturnStatus': returnStatus,
  };

  // fromMap يتم تحديثها لتقرأ الحقول الجديدة
  factory OrderReturnModel.fromMap(Map<String, dynamic> map) =>
      OrderReturnModel(
        // الأساسية
        returnID: _toIntOrNull(map['ReturnID']),
        originalOrderID: _toInt(map['OriginalOrderID']),
        shiftID: _toInt(map['ShiftID']),
        returnDate: DateTime.parse(_toString(map['ReturnDate'])),
        returnReason: _toString(map['ReturnReason']),
        userID: _toInt(map['UserID']),
        totalReturnAmount: _toDouble(map['TotalReturnAmount']),
        customerID: _toIntOrNull(map['CustomerID']),
        returnStatus: _toStringOrNull(map['ReturnStatus']),

        // الإضافية (يقرأها من نتيجة الـ JOIN)
        customerName: _toStringOrNull(map['CustomerName']),
        customerPhone: _toStringOrNull(map['PhoneNumber']),
        userName: _toStringOrNull(map['UserName']),
      );
}
