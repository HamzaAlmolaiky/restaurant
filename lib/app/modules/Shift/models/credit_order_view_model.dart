// file: models/credit_order_view_model.dart

class CreditOrderViewModel {
  final int orderID;
  final DateTime orderDate;
  final double amountPaid;
  final double amountDue;
  final String customerName;
  final double totalAmount;

  CreditOrderViewModel(
      {required this.orderID,
      required this.orderDate,
      required this.amountPaid,
      required this.amountDue,
      required this.customerName,
      required this.totalAmount});

  factory CreditOrderViewModel.fromMap(Map<String, dynamic> map) {
    return CreditOrderViewModel(
      orderID: map['OrderID'],
      orderDate: DateTime.parse(map['OrderDate']),
      amountPaid: (map['AmountPaid'] as num).toDouble(),
      amountDue: (map['AmountDue'] as num).toDouble(),
      customerName: map['CustomerName'],
      totalAmount: (map['TotalAmount'] as num).toDouble(),
    );
  }
}
