import 'invoice_item.dart';

class Invoice {
  String id;
  String number;
  String orderType; // محلي/سفري
  String paymentType; // نقد/آجل
  String customerName;
  String tableNumber;
  List<InvoiceItem> items;
  DateTime createdAt;
  DateTime? paidAt;
  InvoiceStatus status;
  double subtotal;
  double taxAmount;
  double serviceAmount;
  double total;
  double serviceCharge;

  Invoice({
    required this.id,
    required this.number,
    required this.orderType,
    required this.paymentType,
    required this.customerName,
    required this.tableNumber,
    required this.items,
    required this.createdAt,
    this.paidAt,
    this.status = InvoiceStatus.draft,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.serviceAmount = 0.0,
    this.total = 0.0,
    this.serviceCharge = 0.0,
  });

  void calculateTotals() {
    subtotal = items.fold(0.0, (sum, item) => sum + item.total);
    taxAmount = subtotal * 0.15;
    serviceAmount = subtotal * 0.10;
    total = subtotal + taxAmount + serviceAmount;
  }
}
