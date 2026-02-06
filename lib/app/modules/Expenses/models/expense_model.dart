// file: models/expense_model.dart

class ExpenseModel {
  final int? expenseID;
  final int shiftID;
  final int userID;
  final double amount; // Dart uses double for decimal/real
  final String? description;
  final DateTime expenseDate;
  final String? expenseType;
  final String? recipientName;
  final int? employeeID;

  // حقل إضافي لنتائج الـ JOIN
  final String? userName;

  ExpenseModel({
    this.expenseID,
    required this.shiftID,
    required this.userID,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.expenseType,
    this.recipientName,
    this.employeeID,
    this.userName,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      expenseID: map['ExpenseID'],
      shiftID: map['ShiftID'],
      userID: map['UserID'],
      amount: (map['Amount'] as num).toDouble(),
      description: map['Description'],
      expenseDate: DateTime.parse(map['ExpenseDate']),
      expenseType: map['ExpenseType'],
      recipientName: map['RecipientName'],
      employeeID: map['EmployeeID'],
      userName: map['UserName'], // قد يكون null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ExpenseID': expenseID,
      'ShiftID': shiftID,
      'UserID': userID,
      'Amount': amount,
      'Description': description,
      'ExpenseDate': expenseDate.toIso8601String(),
      'ExpenseType': expenseType,
      'RecipientName': recipientName,
      'EmployeeID': employeeID,
    };
  }
}
