// file: models/user_model.dart

class UserModel {
  final int? userID;
  final String username;
  final String password; // في التطبيق الحقيقي، يجب أن تكون مشفرة (hashed)
  final String role;
  final int? roleID; // الربط مع جدول الأدوار الجديد
  final String? lastLogin; // آخر تسجيل دخول
  final bool canProcessReturns;
  final bool canProcessExpenses;
  final bool canReceivePayments;
  final bool isActive; // حالة التفعيل

  UserModel({
    this.userID,
    required this.username,
    required this.password,
    required this.role,
    this.roleID,
    this.lastLogin,
    this.canProcessReturns = false,
    this.canProcessExpenses = false,
    this.canReceivePayments = false,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userID: map['UserID'],
      username: map['Username'],
      password: map['Password'],
      role: map['Role'],
      roleID: map['RoleID'],
      lastLogin: map['LastLogin'],
      canProcessReturns: (map['CanProcessReturns'] ?? 0) == 1,
      canProcessExpenses: (map['CanProcessExpenses'] ?? 0) == 1,
      canReceivePayments: (map['CanReceivePayments'] ?? 0) == 1,
      isActive: (map['IsActive'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'UserID': userID,
      'Username': username,
      'Password': password,
      'Role': role,
      'RoleID': roleID,
      'LastLogin': lastLogin,
      'CanProcessReturns': canProcessReturns ? 1 : 0,
      'CanProcessExpenses': canProcessExpenses ? 1 : 0,
      'CanReceivePayments': canReceivePayments ? 1 : 0,
      'IsActive': isActive ? 1 : 0,
    };
  }

  UserModel copyWith({
    int? userID,
    String? username,
    String? password,
    String? role,
    int? roleID,
    String? lastLogin,
    bool? canProcessReturns,
    bool? canProcessExpenses,
    bool? canReceivePayments,
    bool? isActive,
  }) {
    return UserModel(
      userID: userID ?? this.userID,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      roleID: roleID ?? this.roleID,
      lastLogin: lastLogin ?? this.lastLogin,
      canProcessReturns: canProcessReturns ?? this.canProcessReturns,
      canProcessExpenses: canProcessExpenses ?? this.canProcessExpenses,
      canReceivePayments: canReceivePayments ?? this.canReceivePayments,
      isActive: isActive ?? this.isActive,
    );
  }
}
