class InvoiceItem {
  String productId;
  String name;
  double price;
  int quantity;
  String note;
  double total;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.note,
    this.total = 0.0,
  }) {
    calculateTotal();
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? 'منتج غير محدد',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      note: map['note'] ?? '',
    );
  }

  void calculateTotal() {
    total = price * quantity;
  }
}

enum InvoiceStatus { draft, saved, paid, cancelled }
