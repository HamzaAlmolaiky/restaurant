// file: models/payment_view_model.dart

/// موديل لعرض سندات الدفع للعملاء
/// هذا الموديل يستخدم لعرض البيانات في واجهة المستخدم
class PaymentViewModel {
  final int paymentID;
  final DateTime paymentDate;
  final double amountReceived;
  final String? notes;
  final String customerName;

  PaymentViewModel({
    required this.paymentID,
    required this.paymentDate,
    required this.amountReceived,
    this.notes,
    required this.customerName,
  });

  /// دالة لتحويل البيانات من Map إلى PaymentViewModel
  /// هذه الدالة تعادل دالة fromMap في C#.
  factory PaymentViewModel.fromMap(Map<String, dynamic> map) {
    return PaymentViewModel(
      paymentID: map['PaymentID'],
      paymentDate: DateTime.parse(map['PaymentDate']),
      amountReceived: map['AmountReceived'],
      notes: map['Notes'],
      customerName: map['CustomerName'],
    );
  }
}
