class PurchaseOrderModel {
  final int purchaseOrderID;
  final int supplierID;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  PurchaseOrderModel({
    required this.purchaseOrderID,
    required this.supplierID,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      purchaseOrderID: map['PurchaseOrderID'],
      supplierID: map['SupplierID'],
      totalAmount: (map['TotalAmount'] as num).toDouble(),
      status: map['Status'],
      createdAt: DateTime.parse(map['CreatedAt']),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'PurchaseOrderID': purchaseOrderID,
      'SupplierID': supplierID,
      'TotalAmount': totalAmount,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }
}
