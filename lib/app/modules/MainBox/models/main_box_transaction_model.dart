// file: models/main_box_transaction_model.dart

class MainBoxTransactionModel {
  final int? transactionID;
  final DateTime transactionDate;
  final String? transactionType;
  final double amountIn;
  final double amountOut;
  final double balanceAfter;
  final String? description;
  final int? userID;
  final int? referenceID;

  // حقل إضافي لنتائج الـ JOIN
  final String? userName;

  MainBoxTransactionModel({
    this.transactionID,
    required this.transactionDate,
    this.transactionType,
    this.amountIn = 0.0, // قيمة افتراضية
    this.amountOut = 0.0, // قيمة افتراضية
    required this.balanceAfter,
    this.description,
    this.userID,
    this.referenceID,
    this.userName,
  });

  factory MainBoxTransactionModel.fromMap(Map<String, dynamic> map) {
    return MainBoxTransactionModel(
      transactionID: map['TransactionID'],
      transactionDate: DateTime.parse(map['TransactionDate']),
      transactionType: map['TransactionType'],
      amountIn: (map['AmountIn'] as num).toDouble(),
      amountOut: (map['AmountOut'] as num).toDouble(),
      balanceAfter: (map['BalanceAfter'] as num).toDouble(),
      description: map['Description'],
      userID: map['UserID'],
      referenceID: map['ReferenceID'],
      userName: map['UserName'], // قد يكون null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TransactionID': transactionID,
      'TransactionDate': transactionDate.toIso8601String(),
      'TransactionType': transactionType,
      'AmountIn': amountIn,
      'AmountOut': amountOut,
      'BalanceAfter': balanceAfter,
      'Description': description,
      'UserID': userID,
      'ReferenceID': referenceID,
    };
  }
}
