// file: services/employee_service.dart

// ignore_for_file: avoid_print

import '../../../helpers/database_helper.dart';
import '../models/employee_model.dart';

/// Service للموظفين
/// يتحقق من صحة بيانات الموظف قبل الإضافة والتحديث.
/// يستخدم `DatabaseHelper` لتتبع الاتصال بقاعدة البيانات.
/// يستخدم `EmployeeModel` لتحويل البيانات للكائن.
class EmployeeService {
  static final EmployeeService instance = EmployeeService._init();
  EmployeeService._init();

  /// إضافة موظف جديد
  Future<bool> addEmployee(EmployeeModel employee) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final id = await db.insert('Employees', employee.toMap());
      return id > 0;
    } catch (e) {
      print('خطأ في إضافة الموظف: $e');
      return false;
    }
  }

  // ignore: unintended_html_in_doc_comment
  /// جلب جميع الموظفين - إرجاع List<Map<String, dynamic>> للتوافق مع الكونترولر
  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Employees',
      where: 'IsActive = ?',
      whereArgs: [1],
      orderBy: 'FullName',
    );
    return maps;
  }

  /// جلب جميع الموظفين كـ EmployeeModel objects
  Future<List<EmployeeModel>> getAllEmployeeModels() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Employees',
      where: 'IsActive = ?',
      whereArgs: [1],
      orderBy: 'FullName',
    );
    return maps.map((map) => EmployeeModel.fromMap(map)).toList();
  }

  /// جلب موظف حسب المعرف
  Future<Map<String, dynamic>?> getEmployeeById(int employeeId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Employees',
      where: 'EmployeeID = ?',
      whereArgs: [employeeId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// جلب موظف حسب المعرف كـ EmployeeModel
  Future<EmployeeModel?> getEmployeeModelById(int employeeId) async {
    final employeeData = await getEmployeeById(employeeId);
    if (employeeData != null) {
      return EmployeeModel.fromMap(employeeData);
    }
    return null;
  }

  /// تحديث بيانات الموظف
  Future<bool> updateEmployee(
    int employeeId,
    Map<String, dynamic> employeeData,
  ) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // إزالة EmployeeID من البيانات المحدثة لتجنب تعديله
      employeeData.remove('EmployeeID');

      final rowsAffected = await db.update(
        'Employees',
        employeeData,
        where: 'EmployeeID = ?',
        whereArgs: [employeeId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('خطأ في تحديث الموظف: $e');
      return false;
    }
  }

  /// تحديث بيانات الموظف - للتوافق مع الكود القديم
  Future<bool> updateEmployeeModel(EmployeeModel employee) async {
    if (employee.employeeID == null) {
      throw ArgumentError('معرف الموظف مطلوب للتحديث');
    }
    return await updateEmployee(employee.employeeID!, employee.toMap());
  }

  /// الحذف هنا هو "حذف ناعم" (تعطيل)
  Future<bool> deleteEmployee(int employeeId) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rowsAffected = await db.update(
        'Employees',
        {'IsActive': 0}, // فقط تحديث حالة النشاط
        where: 'EmployeeID = ?',
        whereArgs: [employeeId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('خطأ في حذف الموظف: $e');
      return false;
    }
  }

  /// جلب عدد الموظفين النشطين
  Future<int> getActiveEmployeesCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees WHERE IsActive = 1",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب إجمالي عدد الموظفين
  Future<int> getTotalEmployeesCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees",
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// جلب الموظفين حسب الحالة
  Future<List<Map<String, dynamic>>> getEmployeesByStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause;
    List<dynamic> whereArgs;

    switch (status.toLowerCase()) {
      case 'نشط':
      case 'active':
        whereClause = 'IsActive = ? AND Status = ?';
        whereArgs = [1, 'نشط'];
        break;
      case 'حاضر':
      case 'present':
        whereClause = 'IsActive = ? AND Status = ?';
        whereArgs = [1, 'حاضر'];
        break;
      case 'غائب':
      case 'absent':
        whereClause = 'IsActive = ? AND Status = ?';
        whereArgs = [1, 'غائب'];
        break;
      case 'معطل':
      case 'inactive':
        whereClause = 'IsActive = ?';
        whereArgs = [0];
        break;
      default:
        return await getAllEmployees();
    }

    final maps = await db.query(
      'Employees',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'FullName',
    );

    return maps;
  }

  /// البحث في الموظفين
  Future<List<Map<String, dynamic>>> searchEmployees(String searchTerm) async {
    final db = await DatabaseHelper.instance.database;

    if (searchTerm.trim().isEmpty) {
      return await getAllEmployees();
    }

    final maps = await db.query(
      'Employees',
      where: '''
        IsActive = 1 AND (
          FullName LIKE ? OR 
          PhoneNumber LIKE ? OR 
          Position LIKE ? OR
          Email LIKE ?
        )
      ''',
      whereArgs: [
        '%$searchTerm%',
        '%$searchTerm%',
        '%$searchTerm%',
        '%$searchTerm%',
      ],
      orderBy: 'FullName',
    );

    return maps;
  }

  /// جلب الموظفين حسب المنصب
  Future<List<Map<String, dynamic>>> getEmployeesByPosition(
    String position,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Employees',
      where: 'IsActive = 1 AND Position = ?',
      whereArgs: [position],
      orderBy: 'FullName',
    );
    return maps;
  }

  /// جلب إحصائيات الموظفين
  Future<Map<String, dynamic>> getEmployeesStatistics() async {
    final db = await DatabaseHelper.instance.database;

    // إجمالي الموظفين
    final totalResult = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees",
    );
    final totalEmployees = (totalResult.first['count'] as num?)?.toInt() ?? 0;

    // الموظفين النشطين
    final activeResult = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees WHERE IsActive = 1",
    );
    final activeEmployees = (activeResult.first['count'] as num?)?.toInt() ?? 0;

    // الموظفين الحاضرين
    final presentResult = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees WHERE IsActive = 1 AND Status = 'حاضر'",
    );
    final presentEmployees =
        (presentResult.first['count'] as num?)?.toInt() ?? 0;

    // الموظفين الغائبين
    final absentResult = await db.rawQuery(
      "SELECT COUNT(EmployeeID) as count FROM Employees WHERE IsActive = 1 AND Status = 'غائب'",
    );
    final absentEmployees = (absentResult.first['count'] as num?)?.toInt() ?? 0;

    // المناصب المختلفة
    final positionsResult = await db.rawQuery(
      "SELECT Position, COUNT(EmployeeID) as count FROM Employees WHERE IsActive = 1 GROUP BY Position",
    );

    Map<String, int> positionCounts = {};
    for (var row in positionsResult) {
      final position = row['Position'] as String? ?? 'غير محدد';
      final count = (row['count'] as num?)?.toInt() ?? 0;
      positionCounts[position] = count;
    }

    return {
      'totalEmployees': totalEmployees,
      'activeEmployees': activeEmployees,
      'presentEmployees': presentEmployees,
      'absentEmployees': absentEmployees,
      'positionCounts': positionCounts,
    };
  }

  /// تحديث حالة الموظف (حاضر/غائب)
  Future<bool> updateEmployeeStatus(int employeeId, String status) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rowsAffected = await db.update(
        'Employees',
        {'Status': status},
        where: 'EmployeeID = ? AND IsActive = 1',
        whereArgs: [employeeId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('خطأ في تحديث حالة الموظف: $e');
      return false;
    }
  }

  /// التحقق من وجود موظف بالاسم
  Future<bool> employeeExistsByName(String fullName) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Employees',
      where: 'FullName = ? AND IsActive = 1',
      whereArgs: [fullName.trim()],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// التحقق من وجود موظف برقم الهاتف
  Future<bool> employeeExistsByPhone(String phoneNumber) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'Employees',
      where: 'PhoneNumber = ? AND IsActive = 1',
      whereArgs: [phoneNumber.trim()],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// إنشاء موظفين افتراضيين للاختبار
  Future<void> createDefaultEmployees() async {
    final totalEmployees = await getTotalEmployeesCount();

    if (totalEmployees == 0) {
      final defaultEmployees = [
        {
          'FullName': 'أحمد محمد السعيد',
          'PhoneNumber': '0501234567',
          'Email': 'ahmed@restaurant.com',
          'Position': 'مدير',
          'BasicSalary': 8000.0,
          'HireDate': DateTime.now()
              .subtract(const Duration(days: 365))
              .toIso8601String(),
          'Status': 'حاضر',
          'IsActive': 1,
          'Address': 'الرياض، المملكة العربية السعودية',
          'Notes': 'مدير المطعم الرئيسي',
        },
        {
          'FullName': 'فاطمة علي أحمد',
          'PhoneNumber': '0507654321',
          'Email': 'fatima@restaurant.com',
          'Position': 'كاشير',
          'BasicSalary': 4500.0,
          'HireDate': DateTime.now()
              .subtract(const Duration(days: 180))
              .toIso8601String(),
          'Status': 'حاضر',
          'IsActive': 1,
          'Address': 'الرياض، المملكة العربية السعودية',
          'Notes': 'كاشير أول',
        },
        {
          'FullName': 'محمد عبدالله الأحمد',
          'PhoneNumber': '0509876543',
          'Email': 'mohammed@restaurant.com',
          'Position': 'طباخ',
          'BasicSalary': 5000.0,
          'HireDate': DateTime.now()
              .subtract(const Duration(days: 90))
              .toIso8601String(),
          'Status': 'حاضر',
          'IsActive': 1,
          'Address': 'الرياض، المملكة العربية السعودية',
          'Notes': 'طباخ رئيسي',
        },
        {
          'FullName': 'نورا سعد المطيري',
          'PhoneNumber': '0502468135',
          'Email': 'nora@restaurant.com',
          'Position': 'خدمة عملاء',
          'BasicSalary': 3500.0,
          'HireDate': DateTime.now()
              .subtract(const Duration(days: 45))
              .toIso8601String(),
          'Status': 'غائب',
          'IsActive': 1,
          'Address': 'الرياض، المملكة العربية السعودية',
          'Notes': 'موظفة خدمة عملاء',
        },
        {
          'FullName': 'خالد يوسف العتيبي',
          'PhoneNumber': '0508642097',
          'Email': 'khalid@restaurant.com',
          'Position': 'عامل تنظيف',
          'BasicSalary': 2500.0,
          'HireDate': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'Status': 'حاضر',
          'IsActive': 1,
          'Address': 'الرياض، المملكة العربية السعودية',
          'Notes': 'عامل تنظيف وصيانة',
        },
      ];

      final db = await DatabaseHelper.instance.database;
      for (var employeeData in defaultEmployees) {
        try {
          await db.insert('Employees', employeeData);
        } catch (e) {
          print('خطأ في إنشاء الموظف الافتراضي: $e');
        }
      }
    }
  }

  /// إنشاء موظف جديد من البيانات
  Future<int> createEmployee(Map<String, dynamic> employeeData) async {
    final db = await DatabaseHelper.instance.database;

    // التأكد من وجود البيانات المطلوبة
    if (employeeData['FullName'] == null ||
        employeeData['FullName'].toString().trim().isEmpty) {
      throw ArgumentError('اسم الموظف مطلوب');
    }

    // إضافة القيم الافتراضية إذا لم تكن موجودة
    employeeData['IsActive'] ??= 1;
    employeeData['Status'] ??= 'نشط';
    employeeData['HireDate'] ??= DateTime.now().toIso8601String();

    try {
      return await db.insert('Employees', employeeData);
    } catch (e) {
      print('خطأ في إنشاء الموظف: $e');
      throw Exception('فشل في إنشاء الموظف: $e');
    }
  }
}
