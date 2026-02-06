/// نموذج لإحصائيات المدفوعات
class PaymentStatsModel {
  final int totalCount;
  final double totalAmount;
  final int todayCount;
  final double todayAmount;

  PaymentStatsModel({
    required this.totalCount,
    required this.totalAmount,
    required this.todayCount,
    required this.todayAmount,
  });

  /// دالة لتحويل النموذج إلى خريطة لتتوافق مع الكنترولر
  Map<String, dynamic> toMap() => {
    'total': totalCount,
    'totalAmount': totalAmount,
    'todayCount': todayCount,
    'todayAmount': todayAmount,
  };
}

/// نموذج لأفضل العملاء دفعاً
class TopPayingCustomerModel {
  final String customerName;
  final String? phone;
  final int paymentCount;
  final double totalAmount;

  TopPayingCustomerModel({
    required this.customerName,
    this.phone,
    required this.paymentCount,
    required this.totalAmount,
  });

  /// دالة لتحويل النموذج إلى خريطة
  Map<String, dynamic> toMap() => {
    'customer_name': customerName,
    'phone': phone,
    'payment_count': paymentCount,
    'total_amount': totalAmount,
  };
}
