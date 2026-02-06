// file: models/employee_model.dart

/// Model للموظف
class EmployeeModel {
  final int? employeeID;
  final String name; // في الكود نستخدم name، وفي قاعدة البيانات FullName
  final String? phoneNumber;
  final String? address;
  final String position;
  final double basicSalary;
  final DateTime hireDate;
  final bool isActive;
  final String? notes;

  EmployeeModel({
    this.employeeID,
    required this.name,
    this.phoneNumber,
    this.address,
    required this.position,
    required this.basicSalary,
    required this.hireDate,
    required this.isActive,
    this.notes,
  });

  /// دالة لتحويل الكائن إلى Map لإدراجه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'EmployeeID': employeeID,
      'FullName': name, // تحويل خاصية name إلى عمود FullName
      'PhoneNumber': phoneNumber,
      'Address': address,
      'Position': position,
      'BasicSalary': basicSalary,
      'HireDate': hireDate.toIso8601String().substring(0, 10), // "yyyy-MM-dd"
      'IsActive': isActive ? 1 : 0, // تحويل bool إلى int
      'Notes': notes,
    };
  }

  /// دالة لإنشاء كائن من Map (قادم من قاعدة البيانات)
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      employeeID: map['EmployeeID'],
      name: map['FullName'], // تحويل عمود FullName إلى خاصية name
      phoneNumber: map['PhoneNumber'],
      address: map['Address'],
      position: map['Position'],
      basicSalary: map['BasicSalary'],
      hireDate: DateTime.parse(map['HireDate']),
      isActive: map['IsActive'] == 1, // تحويل int إلى bool
      notes: map['Notes'],
    );
  }

  EmployeeModel copyWith({
    String? employeeName,
    String? phone,
    String? email,
    String? position,
    double? salary,
  }) {
    return EmployeeModel(
      employeeID: employeeID,
      name: employeeName ?? name,
      phoneNumber: phone ?? phoneNumber,
      position: position ?? this.position,
      basicSalary: salary ?? basicSalary,
      hireDate: hireDate,
      isActive: isActive,
      notes: notes,
    );
  }
}
