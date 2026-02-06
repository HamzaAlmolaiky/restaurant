// file: models/customer_model.dart

/// موديل للعملاء
/// يحتوي على معلومات عن العميل
class CustomerModel {
  final int? customerID; // يكون null قبل إضافته لقاعدة البيانات
  final String customerName;
  final String? phoneNumber;
  final double currentBalance;
  final DateTime registrationDate;
  final String? notes;

  CustomerModel({
    this.customerID,
    required this.customerName,
    this.phoneNumber,
    required this.currentBalance,
    required this.registrationDate,
    this.notes,
  });

  /// دالة لتحويل الكائن إلى Map لإدراجه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'CustomerID': customerID,
      'CustomerName': customerName,
      'PhoneNumber': phoneNumber,
      'CurrentBalance': currentBalance,
      // تخزين التاريخ كنص بصيغة ISO 8601 القياسية
      'RegistrationDate': registrationDate.toIso8601String(),
      'Notes': notes,
    };
  }

  /// دالة لإنشاء كائن من Map (قادم من قاعدة البيانات)
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      customerID: map['CustomerID'],
      customerName: map['CustomerName'],
      phoneNumber: map['PhoneNumber']?.toString(),
      currentBalance: (map['CurrentBalance'] is num)
          ? (map['CurrentBalance'] as num).toDouble()
          : double.tryParse(map['CurrentBalance']?.toString() ?? '0') ?? 0.0,
      // تحويل التاريخ سواء كان String أو DateTime
      registrationDate: map['RegistrationDate'] is String
          ? DateTime.parse(map['RegistrationDate'])
          : (map['RegistrationDate'] is DateTime
              ? map['RegistrationDate'] as DateTime
              : DateTime.now()),
      notes: map['Notes'],
    );
  }
}
