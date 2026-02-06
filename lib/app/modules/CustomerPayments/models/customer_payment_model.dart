/// موديل لسندات الدفع للعملاء
class CustomerPaymentModel {
  final int? paymentId;
  final int customerID;
  final int shiftID;
  final int userID;
  final int? orderID;
  final DateTime paymentDate;
  final double amountReceived;
  final String? notes;

  // حقل إضافي لنتائج الـ JOIN
  final String? username;

  CustomerPaymentModel({
    this.paymentId,
    required this.customerID,
    required this.shiftID,
    required this.userID,
    this.orderID,
    required this.paymentDate,
    required this.amountReceived,
    this.notes,
    this.username, // حقل اختياري
  });

  /// دالة لتحويل البيانات من Map إلى CustomerPaymentModel
  /// هذه الدالة تعادل دالة fromMap في C#.
  factory CustomerPaymentModel.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentModel(
      paymentId: map['PaymentID'] ?? map['PaymentId'],
      customerID: map['CustomerID'],
      shiftID: map['ShiftID'],
      userID: map['UserID'],
      orderID: map['OrderID'],
      paymentDate: DateTime.parse(map['PaymentDate']),
      amountReceived: map['AmountReceived'],
      notes: map['Notes'],
      username: map['Username'], // قد يكون null إذا لم يكن هناك JOIN
    );
  }

  /// دالة لتحويل البيانات من CustomerPaymentModel إلى Map
  /// هذه الدالة تعادل دالة toMap في C#.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'CustomerID': customerID,
      'ShiftID': shiftID,
      'UserID': userID,
      'OrderID': orderID,
      'PaymentDate': paymentDate.toIso8601String(),
      'AmountReceived': amountReceived,
      'Notes': notes,
    };
    // لا ترسل PaymentID عند الإدراج إذا كانت null أو 0 لترك SQLite يولّده تلقائياً
    if (paymentId != null && paymentId != 0) {
      map['PaymentID'] = paymentId;
    }
    return map;
  }
}
