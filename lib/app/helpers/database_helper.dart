// file: services/database_helper.dart
// هذا الملف هو البديل الكامل لكلاس SQLiteConnectionFactory

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// خدمة لإدارة قاعدة البيانات
/// هذه الخدمة توفر وظائف CRUD (إنشاء، قراءة، تحديث، حذف) لقاعدة البيانات.
/// يتم استخدامه لتخزين البيانات المتعلقة بالمطعم.
/// بالإضافة إلى وظائف إضافية مثل الحصول على قاعدة البيانات الحالية.

class DatabaseHelper {
  /// 1. Singleton Pattern: يضمن وجود نسخة واحدة فقط من هذا الكلاس.
  /// هذا هو بديل الكلاس الـ static في C#.
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// متغير داخلي للاحتفاظ باتصال قاعدة البيانات المفتوح.
  static Database? _database;

  /// منشئ خاص لمنع إنشاء نسخ متعددة من الكلاس.
  DatabaseHelper._init();

  /// 2. دالة الوصول إلى قاعدة البيانات (Getter)
  /// هذه هي البديل المباشر لدالة GetOpenConnection().
  Future<Database> get database async {
    /// إذا كانت قاعدة البيانات مهيأة بالفعل، أعدها مباشرة.
    if (_database != null) return _database!;

    /// إذا لم تكن مهيأة، قم بتهيئتها.
    _database = await _initDB('RestaurantDB.db');
    return _database!;
  }

  /// 3. دالة تهيئة قاعدة البيانات (تحدث مرة واحدة فقط)
  /// هذا هو بديل المنشئ الثابت (Static Constructor).
  Future<Database> _initDB(String dbName) async {
    /// الحصول على مسار مجلد قواعد البيانات الافتراضي للتطبيق.
    /// هذا يعادل `AppDomain.CurrentDomain.BaseDirectory` ولكن للتطبيقات.
    Directory documentDirectory = await getApplicationDocumentsDirectory();

    /// استخدام مكتبة `path` لدمج المسار مع اسم قاعدة البيانات.
    /// هذه المكتبة توفر وظائف للتعامل مع المسارات بشكل آمن عبر أنظمة التشغيل
    /// دمج المسار مع اسم الملف للحصول على المسار الكامل.
    final path = join(documentDirectory.path, dbName);

    bool exists = await databaseExists(path);
    if (!exists) {
      ByteData data = await rootBundle.load('assets/db/$dbName');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    /// فتح قاعدة البيانات. إذا لم تكن موجودة، سيتم استدعاء `onCreate`.
    return openDatabase(
      path,
      version: 1,
      onOpen: (db) async {
        // تفعيل قيود العلاقات Foreign Keys في SQLite
        await db.execute('PRAGMA foreign_keys = ON');
        // تأكد من تطابق المخطط مع ما يتوقعه التطبيق
        await _ensureSchema(db);
      },
    );
  }

  /// 4. دالة لجلب كل أسماء الجداول (بديل GetAllTableNames)
  Future<List<String>> getAllTableNames() async {
    final db = await instance.database;
    const query =
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name";
    final result = await db.rawQuery(query);

    return result.map((map) => map['name'] as String).toList();
  }

  /// دالة لإغلاق الاتصال عند الحاجة (نادراً ما تُستخدم في فلاتر)
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ---------------- Schema Utilities ----------------

  Future<List<Map<String, dynamic>>> _pragmaTableInfo(
    Database db,
    String table,
  ) async {
    return await db.rawQuery('PRAGMA table_info($table)');
  }

  Future<bool> _tableExists(Database db, String table) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return res.isNotEmpty;
  }

  bool _hasColumn(List<Map<String, dynamic>> info, String columnName) {
    return info.any(
      (c) => (c['name'] as String).toLowerCase() == columnName.toLowerCase(),
    );
  }

  Future<void> _ensureSchema(Database db) async {
    // المرحلة الأولى من الترقية: إضافة الجداول الأساسية

    // جدول الأدوار (Roles)
    final rolesExists = await _tableExists(db, 'Roles');
    if (!rolesExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Roles (
          RoleID INTEGER PRIMARY KEY AUTOINCREMENT,
          RoleName TEXT NOT NULL UNIQUE,
          Description TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1
        )
      ''');

      // إدراج الأدوار الافتراضية
      await db.execute('''
        INSERT INTO Roles (RoleName, Description) VALUES 
        ('مشرف', 'مشرف النظام - صلاحيات كاملة'),
        ('كاشير', 'موظف نقاط البيع'),
        ('مدير', 'مدير المطعم'),
        ('طباخ', 'طباخ المطعم'),
        ('خدمة عملاء', 'موظف خدمة العملاء')
      ''');
    }

    // جدول إعدادات المطعم (Restaurant_Settings)
    final settingsExists = await _tableExists(db, 'Restaurant_Settings');
    if (!settingsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Restaurant_Settings (
          SettingID INTEGER PRIMARY KEY AUTOINCREMENT,
          RestaurantName TEXT NOT NULL DEFAULT 'مطعم الأصالة',
          LogoURL TEXT,
          Address TEXT DEFAULT 'الرياض، المملكة العربية السعودية',
          PhoneNumber TEXT DEFAULT '+966501234567',
          Email TEXT DEFAULT 'info@restaurant.com',
          TaxNumber TEXT DEFAULT '123456789',
          DefaultCurrency TEXT DEFAULT 'SAR',
          TaxRate REAL DEFAULT 0.15,
          ServiceChargeRate REAL DEFAULT 0.10,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          UpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // إدراج الإعدادات الافتراضية
      await db.execute('''
        INSERT INTO Restaurant_Settings (RestaurantName, Address, PhoneNumber, Email) VALUES 
        ('مطعم الأصالة', 'الرياض، المملكة العربية السعودية', '+966501234567', 'info@restaurant.com')
      ''');
    }

    // جدول الطاولات (Tables)
    final tablesExists = await _tableExists(db, 'Tables');
    if (!tablesExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Tables (
          TableID INTEGER PRIMARY KEY AUTOINCREMENT,
          TableName TEXT NOT NULL,
          Section TEXT DEFAULT 'القاعة الرئيسية',
          Capacity INTEGER DEFAULT 4,
          Status TEXT DEFAULT 'متاحة',
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1
        )
      ''');

      // إدراج طاولات افتراضية
      await db.execute('''
        INSERT INTO Tables (TableName, Section, Capacity) VALUES 
        ('طاولة 1', 'القاعة الرئيسية', 4),
        ('طاولة 2', 'القاعة الرئيسية', 4),
        ('طاولة 3', 'القاعة الرئيسية', 6),
        ('طاولة 4', 'القاعة الرئيسية', 2),
        ('طاولة 5', 'القاعة الخارجية', 8),
        ('طاولة 6', 'القاعة الخارجية', 6),
        ('طاولة VIP1', 'القاعة المميزة', 10),
        ('طاولة VIP2', 'القاعة المميزة', 8)
      ''');
    }

    // Users table
    if (await _tableExists(db, 'Users')) {
      final info = await _pragmaTableInfo(db, 'Users');
      if (!_hasColumn(info, 'IsActive')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN IsActive INTEGER NOT NULL DEFAULT 1",
        );
      }
      if (!_hasColumn(info, 'LastLogin')) {
        await db.execute("ALTER TABLE Users ADD COLUMN LastLogin TEXT");
      }
      if (!_hasColumn(info, 'CanProcessReturns')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanProcessReturns INTEGER NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'CanProcessExpenses')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanProcessExpenses INTEGER NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'CanReceivePayments')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanReceivePayments INTEGER NOT NULL DEFAULT 0",
        );
      }
      // إضافة عمود RoleID للربط مع جدول الأدوار
      if (!_hasColumn(info, 'RoleID')) {
        await db.execute("ALTER TABLE Users ADD COLUMN RoleID INTEGER");
      }
    }

    // Employees table
    if (await _tableExists(db, 'Employees')) {
      final info = await _pragmaTableInfo(db, 'Employees');
      if (!_hasColumn(info, 'FullName')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN FullName TEXT");
      }
      if (!_hasColumn(info, 'PhoneNumber')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN PhoneNumber TEXT");
      }
      if (!_hasColumn(info, 'Email')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN Email TEXT");
      }
      if (!_hasColumn(info, 'Position')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN Position TEXT");
      }
      if (!_hasColumn(info, 'BasicSalary')) {
        await db.execute(
          "ALTER TABLE Employees ADD COLUMN BasicSalary REAL NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'HireDate')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN HireDate TEXT");
      }
      if (!_hasColumn(info, 'Status')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN Status TEXT");
      }
      if (!_hasColumn(info, 'IsActive')) {
        await db.execute(
          "ALTER TABLE Employees ADD COLUMN IsActive INTEGER NOT NULL DEFAULT 1",
        );
      }
      if (!_hasColumn(info, 'Address')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN Address TEXT");
      }
      if (!_hasColumn(info, 'Notes')) {
        await db.execute("ALTER TABLE Employees ADD COLUMN Notes TEXT");
      }
    }

    // Orders table: تأكيد وجود عمود Status المستخدم في التقارير والخدمات
    if (await _tableExists(db, 'Orders')) {
      final info = await _pragmaTableInfo(db, 'Orders');
      if (!_hasColumn(info, 'Status')) {
        await db.execute("ALTER TABLE Orders ADD COLUMN Status TEXT");
      }
      // ضرائب ورسوم خدمة للطلبات
      if (!_hasColumn(info, 'TaxAmount')) {
        await db.execute(
          "ALTER TABLE Orders ADD COLUMN TaxAmount REAL NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'ServiceCharge')) {
        await db.execute(
          "ALTER TABLE Orders ADD COLUMN ServiceCharge REAL NOT NULL DEFAULT 0",
        );
      }
      // إضافة عمود TableID للربط مع جدول الطاولات
      if (!_hasColumn(info, 'TableID')) {
        await db.execute("ALTER TABLE Orders ADD COLUMN TableID INTEGER");
      }
    }

    // CustomerPayments table
    final customerPaymentsExists = await _tableExists(db, 'CustomerPayments');
    if (!customerPaymentsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS CustomerPayments (
          PaymentID INTEGER PRIMARY KEY AUTOINCREMENT,
          CustomerID INTEGER NOT NULL,
          ShiftID INTEGER NOT NULL,
          UserID INTEGER NOT NULL,
          OrderID INTEGER,
          PaymentDate TEXT NOT NULL,
          AmountReceived REAL NOT NULL DEFAULT 0,
          Notes TEXT
        )
      ''');
    } else {
      final info = await _pragmaTableInfo(db, 'CustomerPayments');
      if (!_hasColumn(info, 'PaymentID') && _hasColumn(info, 'PaymentId')) {
        // لا يمكن إعادة تسمية الأعمدة بسهولة في SQLite بدون جدول وسيط
        // نضمن على الأقل وجود العمود القياسي عبر إنشاء عمود جديد إذا لزم
        await db.execute(
          "ALTER TABLE CustomerPayments ADD COLUMN PaymentID INTEGER",
        );
        // ملاحظة: يمكن لاحقاً ترحيل البيانات و/أو إنشاء View للتوافق
      }
      if (!_hasColumn(info, 'AmountReceived')) {
        await db.execute(
          "ALTER TABLE CustomerPayments ADD COLUMN AmountReceived REAL NOT NULL DEFAULT 0",
        );
      }
    }

    // Returns table
    final returnsExists = await _tableExists(db, 'Returns');
    if (!returnsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Returns (
          ReturnID INTEGER PRIMARY KEY AUTOINCREMENT,
          OrderID INTEGER,
          ReturnDate TEXT NOT NULL,
          Amount REAL NOT NULL DEFAULT 0,
          Notes TEXT
        )
      ''');
    }

    // OrderReturns table: create or upgrade schema
    final orderReturnsExists = await _tableExists(db, 'OrderReturns');
    if (!orderReturnsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS OrderReturns (
          ReturnID INTEGER PRIMARY KEY AUTOINCREMENT,
          OriginalOrderID INTEGER NOT NULL,
          ShiftID INTEGER,
          ReturnDate TEXT NOT NULL,
          ReturnReason TEXT,
          UserID INTEGER,
          TotalReturnAmount REAL NOT NULL DEFAULT 0,
          CustomerID INTEGER,
          ReturnStatus TEXT NOT NULL DEFAULT 'قيد المراجعة',
          FOREIGN KEY (OriginalOrderID) REFERENCES Orders(OrderID),
          FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        )
      ''');
      // فهارس لتحسين الأداء في عمليات البحث/الفلترة
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_OriginalOrderID ON OrderReturns(OriginalOrderID)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_CustomerID ON OrderReturns(CustomerID)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_ReturnDate ON OrderReturns(ReturnDate)',
      );
    } else {
      final info = await _pragmaTableInfo(db, 'OrderReturns');
      if (!_hasColumn(info, 'CustomerID')) {
        await db.execute("ALTER TABLE OrderReturns ADD COLUMN CustomerID INTEGER");
      }
      if (!_hasColumn(info, 'ReturnStatus')) {
        await db.execute(
          "ALTER TABLE OrderReturns ADD COLUMN ReturnStatus TEXT NOT NULL DEFAULT 'قيد المراجعة'",
        );
      }
      if (!_hasColumn(info, 'OriginalOrderID')) {
        await db.execute("ALTER TABLE OrderReturns ADD COLUMN OriginalOrderID INTEGER");
      }
      if (!_hasColumn(info, 'TotalReturnAmount')) {
        await db.execute(
          "ALTER TABLE OrderReturns ADD COLUMN TotalReturnAmount REAL NOT NULL DEFAULT 0",
        );
      }
      // إنشاء الفهارس إن لم تكن موجودة
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_OriginalOrderID ON OrderReturns(OriginalOrderID)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_CustomerID ON OrderReturns(CustomerID)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_OrderReturns_ReturnDate ON OrderReturns(ReturnDate)',
      );
    }

    // جدول الفواتير (Invoices) - منفصل عن الطلبات
    final invoicesExists = await _tableExists(db, 'Invoices');
    if (!invoicesExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Invoices (
          InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
          OrderID INTEGER NOT NULL UNIQUE,
          CustomerID INTEGER,
          TableID INTEGER,
          Subtotal REAL NOT NULL DEFAULT 0,
          TaxAmount REAL NOT NULL DEFAULT 0,
          ServiceCharge REAL NOT NULL DEFAULT 0,
          DiscountAmount REAL DEFAULT 0,
          GrandTotal REAL NOT NULL DEFAULT 0,
          Status TEXT DEFAULT 'غير مدفوعة',
          InvoiceDateTime TEXT NOT NULL,
          CreatedBy INTEGER,
          Notes TEXT,
          FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
          FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
          FOREIGN KEY (TableID) REFERENCES Tables(TableID),
          FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // جدول المدفوعات (Payments) - يدعم مدفوعات متعددة لفاتورة واحدة
    final paymentsExists = await _tableExists(db, 'Payments');
    if (!paymentsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Payments (
          PaymentID INTEGER PRIMARY KEY AUTOINCREMENT,
          InvoiceID INTEGER NOT NULL,
          PaymentMethod TEXT NOT NULL DEFAULT 'نقد',
          Amount REAL NOT NULL,
          PaymentDateTime TEXT NOT NULL,
          ProcessedBy INTEGER,
          TransactionReference TEXT,
          Notes TEXT,
          FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID),
          FOREIGN KEY (ProcessedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // جدول سجل الأنشطة (Activity_Logs)
    final activityLogsExists = await _tableExists(db, 'Activity_Logs');
    if (!activityLogsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Activity_Logs (
          LogID INTEGER PRIMARY KEY AUTOINCREMENT,
          UserID INTEGER,
          Action TEXT NOT NULL,
          TableName TEXT,
          RecordID INTEGER,
          Details TEXT,
          LogDateTime TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          IPAddress TEXT,
          FOREIGN KEY (UserID) REFERENCES Users(UserID)
        )
      ''');
    }

    // Users table upgrade logic already handled earlier in this method (deduplicated)

    // المرحلة الثالثة: نظام التعديلات والإضافات

    // جدول مجموعات التعديلات (Modifier_Groups)
    final modifierGroupsExists = await _tableExists(db, 'Modifier_Groups');
    if (!modifierGroupsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Modifier_Groups (
          GroupID INTEGER PRIMARY KEY AUTOINCREMENT,
          GroupName TEXT NOT NULL,
          SelectionType TEXT NOT NULL DEFAULT 'اختياري-واحد',
          IsRequired INTEGER DEFAULT 0,
          MaxSelections INTEGER DEFAULT 1,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1
        )
      ''');

      // إدراج مجموعات افتراضية
      await db.execute('''
        INSERT INTO Modifier_Groups (GroupName, SelectionType, IsRequired, MaxSelections) VALUES 
        ('درجة الطبخ', 'إجباري', 1, 1),
        ('الإضافات', 'اختياري-متعدد', 0, 5),
        ('المشروبات الباردة', 'اختياري-واحد', 0, 1),
        ('المشروبات الساخنة', 'اختياري-واحد', 0, 1),
        ('الصلصات', 'اختياري-متعدد', 0, 3)
      ''');
    }

    // جدول التعديلات (Modifiers)
    final modifiersExists = await _tableExists(db, 'Modifiers');
    if (!modifiersExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Modifiers (
          ModifierID INTEGER PRIMARY KEY AUTOINCREMENT,
          ModifierName TEXT NOT NULL,
          AdditionalPrice REAL DEFAULT 0,
          GroupID INTEGER,
          DisplayOrder INTEGER DEFAULT 0,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1,
          FOREIGN KEY (GroupID) REFERENCES Modifier_Groups(GroupID)
        )
      ''');

      // إدراج تعديلات افتراضية
      await db.execute('''
        INSERT INTO Modifiers (ModifierName, AdditionalPrice, GroupID, DisplayOrder) VALUES 
        ('نصف استواء', 0, 1, 1),
        ('كامل الاستواء', 0, 1, 2),
        ('مشوي جيداً', 0, 1, 3),
        ('جبن إضافي', 5, 2, 1),
        ('خضار إضافية', 3, 2, 2),
        ('لحم إضافي', 10, 2, 3),
        ('كولا', 0, 3, 1),
        ('عصير برتقال', 2, 3, 2),
        ('ماء', 0, 3, 3),
        ('شاي', 0, 4, 1),
        ('قهوة', 2, 4, 2),
        ('صلصة حارة', 0, 5, 1),
        ('صلصة ثوم', 0, 5, 2),
        ('كاتشب', 0, 5, 3)
      ''');
    }

    // جدول ربط المنتجات بمجموعات التعديلات (MenuItem_ModifierGroups)
    final menuItemModifierGroupsExists = await _tableExists(
      db,
      'MenuItem_ModifierGroups',
    );
    if (!menuItemModifierGroupsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS MenuItem_ModifierGroups (
          ItemID INTEGER,
          GroupID INTEGER,
          PRIMARY KEY (ItemID, GroupID),
          FOREIGN KEY (ItemID) REFERENCES Menu_Items(ItemID),
          FOREIGN KEY (GroupID) REFERENCES Modifier_Groups(GroupID)
        )
      ''');
    }

    // جدول تعديلات عناصر الطلبات (OrderItem_Modifiers)
    final orderItemModifiersExists = await _tableExists(
      db,
      'OrderItem_Modifiers',
    );
    if (!orderItemModifiersExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS OrderItem_Modifiers (
          OrderItemID INTEGER,
          ModifierID INTEGER,
          Quantity INTEGER DEFAULT 1,
          PriceAtTimeOfSale REAL DEFAULT 0,
          PRIMARY KEY (OrderItemID, ModifierID),
          FOREIGN KEY (OrderItemID) REFERENCES Order_Items(OrderItemID),
          FOREIGN KEY (ModifierID) REFERENCES Modifiers(ModifierID)
        )
      ''');
    }

    // المرحلة الرابعة: نظام إدارة المخزون

    // جدول عناصر المخزون (Inventory_Items)
    final inventoryItemsExists = await _tableExists(db, 'Inventory_Items');
    if (!inventoryItemsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Inventory_Items (
          InventoryItemID INTEGER PRIMARY KEY AUTOINCREMENT,
          ItemName TEXT NOT NULL,
          ItemCode TEXT UNIQUE,
          UnitOfMeasure TEXT NOT NULL DEFAULT 'كيلو',
          CurrentStock REAL DEFAULT 0,
          ReorderLevel REAL DEFAULT 0,
          CostPerUnit REAL DEFAULT 0,
          SupplierID INTEGER,
          Category TEXT DEFAULT 'عام',
          ExpiryDate TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1,
          FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
        )
      ''');

      // إدراج عناصر مخزون افتراضية
      await db.execute('''
        INSERT INTO Inventory_Items (ItemName, ItemCode, UnitOfMeasure, CurrentStock, ReorderLevel, CostPerUnit, Category) VALUES 
        ('دقيق أبيض', 'FLOUR001', 'كيس 25 كيلو', 50, 10, 25.50, 'مواد أساسية'),
        ('أرز بسمتي', 'RICE001', 'كيس 20 كيلو', 30, 5, 45.00, 'مواد أساسية'),
        ('لحم بقري', 'BEEF001', 'كيلو', 25, 5, 65.00, 'لحوم'),
        ('دجاج طازج', 'CHICKEN001', 'كيلو', 40, 10, 28.00, 'لحوم'),
        ('طماطم', 'TOMATO001', 'كيلو', 15, 3, 8.50, 'خضروات'),
        ('بصل', 'ONION001', 'كيلو', 20, 5, 6.00, 'خضروات'),
        ('زيت نباتي', 'OIL001', 'لتر', 12, 3, 15.00, 'زيوت'),
        ('ملح', 'SALT001', 'كيلو', 10, 2, 3.50, 'توابل')
      ''');
    }

    // جدول الوصفات (Recipes) - ربط المنتجات بمكونات المخزون
    final recipesExists = await _tableExists(db, 'Recipes');
    if (!recipesExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Recipes (
          RecipeID INTEGER PRIMARY KEY AUTOINCREMENT,
          MenuItemID INTEGER NOT NULL,
          InventoryItemID INTEGER NOT NULL,
          QuantityUsed REAL NOT NULL,
          Unit TEXT DEFAULT 'كيلو',
          Notes TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (MenuItemID) REFERENCES Menu_Items(ItemID),
          FOREIGN KEY (InventoryItemID) REFERENCES Inventory_Items(InventoryItemID)
        )
      ''');
    }

    // جدول أوامر الشراء (Purchase_Orders)
    final purchaseOrdersExists = await _tableExists(db, 'Purchase_Orders');
    if (!purchaseOrdersExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Purchase_Orders (
          PurchaseOrderID INTEGER PRIMARY KEY AUTOINCREMENT,
          OrderNumber TEXT UNIQUE,
          SupplierID INTEGER,
          OrderDate TEXT NOT NULL,
          ExpectedDeliveryDate TEXT,
          Status TEXT DEFAULT 'معلق',
          TotalAmount REAL DEFAULT 0,
          CreatedBy INTEGER,
          ApprovedBy INTEGER,
          Notes TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
          FOREIGN KEY (CreatedBy) REFERENCES Users(UserID),
          FOREIGN KEY (ApprovedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // جدول تفاصيل أوامر الشراء (Purchase_Order_Items)
    final purchaseOrderItemsExists = await _tableExists(
      db,
      'Purchase_Order_Items',
    );
    if (!purchaseOrderItemsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Purchase_Order_Items (
          POItemID INTEGER PRIMARY KEY AUTOINCREMENT,
          PurchaseOrderID INTEGER NOT NULL,
          InventoryItemID INTEGER NOT NULL,
          QuantityOrdered REAL NOT NULL,
          UnitPrice REAL NOT NULL,
          TotalPrice REAL NOT NULL,
          QuantityReceived REAL DEFAULT 0,
          FOREIGN KEY (PurchaseOrderID) REFERENCES Purchase_Orders(PurchaseOrderID),
          FOREIGN KEY (InventoryItemID) REFERENCES Inventory_Items(InventoryItemID)
        )
      ''');
    }

    // جدول معاملات المخزون (Inventory_Transactions)
    final inventoryTransactionsExists = await _tableExists(
      db,
      'Inventory_Transactions',
    );
    if (!inventoryTransactionsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Inventory_Transactions (
          TransactionID INTEGER PRIMARY KEY AUTOINCREMENT,
          InventoryItemID INTEGER NOT NULL,
          TransactionType TEXT NOT NULL,
          Quantity REAL NOT NULL,
          CostPerUnit REAL,
          TotalCost REAL,
          TransactionDate TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          ReferenceID TEXT,
          ReferenceType TEXT,
          UserID INTEGER,
          Notes TEXT,
          FOREIGN KEY (InventoryItemID) REFERENCES Inventory_Items(InventoryItemID),
          FOREIGN KEY (UserID) REFERENCES Users(UserID)
        )
      ''');
    }

    // المرحلة الخامسة: نظام الحضور والرواتب

    // جدول إعدادات الرواتب (Payroll_Settings)
    final payrollSettingsExists = await _tableExists(db, 'Payroll_Settings');
    if (!payrollSettingsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Payroll_Settings (
          SettingID INTEGER PRIMARY KEY AUTOINCREMENT,
          EmployeeID INTEGER NOT NULL,
          BaseSalary REAL DEFAULT 0,
          HourlyRate REAL DEFAULT 0,
          OvertimeRate REAL DEFAULT 0,
          PaymentFrequency TEXT DEFAULT 'شهري',
          BankAccount TEXT,
          TaxRate REAL DEFAULT 0,
          InsuranceDeduction REAL DEFAULT 0,
          EffectiveDate TEXT NOT NULL,
          IsActive INTEGER DEFAULT 1,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
        )
      ''');
    }

    // جدول الحضور (Attendance)
    final attendanceExists = await _tableExists(db, 'Attendance');
    if (!attendanceExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Attendance (
          AttendanceID INTEGER PRIMARY KEY AUTOINCREMENT,
          EmployeeID INTEGER NOT NULL,
          Date TEXT NOT NULL,
          CheckInTime TEXT,
          CheckOutTime TEXT,
          TotalHours REAL DEFAULT 0,
          OvertimeHours REAL DEFAULT 0,
          Status TEXT DEFAULT 'حاضر',
          Notes TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
        )
      ''');
    }

    // جدول سجل الرواتب (Payroll_History)
    final payrollHistoryExists = await _tableExists(db, 'Payroll_History');
    if (!payrollHistoryExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Payroll_History (
          PayrollID INTEGER PRIMARY KEY AUTOINCREMENT,
          EmployeeID INTEGER NOT NULL,
          PayPeriodStart TEXT NOT NULL,
          PayPeriodEnd TEXT NOT NULL,
          RegularHours REAL DEFAULT 0,
          OvertimeHours REAL DEFAULT 0,
          RegularPay REAL DEFAULT 0,
          OvertimePay REAL DEFAULT 0,
          GrossPay REAL DEFAULT 0,
          TaxDeduction REAL DEFAULT 0,
          InsuranceDeduction REAL DEFAULT 0,
          OtherDeductions REAL DEFAULT 0,
          NetPay REAL DEFAULT 0,
          PaymentDate TEXT,
          PaymentMethod TEXT DEFAULT 'نقد',
          Status TEXT DEFAULT 'معلق',
          ProcessedBy INTEGER,
          Notes TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
          FOREIGN KEY (ProcessedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // جدول نقاط البيع (POS_Terminals)
    final posTerminalsExists = await _tableExists(db, 'POS_Terminals');
    if (!posTerminalsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS POS_Terminals (
          TerminalID INTEGER PRIMARY KEY AUTOINCREMENT,
          TerminalName TEXT NOT NULL,
          Location TEXT,
          IPAddress TEXT,
          Status TEXT DEFAULT 'نشط',
          LastActivity TEXT,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          IsActive INTEGER DEFAULT 1
        )
      ''');

      // إدراج محطة افتراضية
      await db.execute('''
        INSERT INTO POS_Terminals (TerminalName, Location, Status) VALUES 
        ('محطة رئيسية', 'الكاشير الرئيسي', 'نشط'),
        ('محطة فرعية 1', 'الكاشير الفرعي', 'نشط')
      ''');
    }

    // جدول منصات التوصيل الخارجي (ThirdParty_Platforms)
    final thirdPartyPlatformsExists = await _tableExists(
      db,
      'ThirdParty_Platforms',
    );
    if (!thirdPartyPlatformsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ThirdParty_Platforms (
          PlatformID INTEGER PRIMARY KEY AUTOINCREMENT,
          PlatformName TEXT NOT NULL,
          CommissionRate REAL DEFAULT 0,
          APIKey TEXT,
          IsActive INTEGER DEFAULT 1,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // إدراج منصات افتراضية
      await db.execute('''
        INSERT INTO ThirdParty_Platforms (PlatformName, CommissionRate) VALUES 
        ('طلبات', 15.0),
        ('هنقرستيشن', 18.0),
        ('أوبر إيتس', 20.0),
        ('كريم ناو', 16.0)
      ''');
    }

    // جدول الضرائب (Taxes)
    final taxesExists = await _tableExists(db, 'Taxes');
    if (!taxesExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Taxes (
          TaxID INTEGER PRIMARY KEY AUTOINCREMENT,
          TaxName TEXT NOT NULL,
          TaxRate REAL NOT NULL DEFAULT 0,
          TaxType TEXT DEFAULT 'نسبة مئوية',
          IsActive INTEGER DEFAULT 1,
          CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // إدراج ضرائب افتراضية
      await db.execute('''
        INSERT INTO Taxes (TaxName, TaxRate, TaxType) VALUES 
        ('ضريبة القيمة المضافة', 15.0, 'نسبة مئوية'),
        ('رسوم الخدمة', 10.0, 'نسبة مئوية'),
        ('ضريبة إضافية', 5.0, 'نسبة مئوية')
      ''');
    }

    // جداول إضافية لإكمال النظام

    // جدول تفاصيل المرتجعات (Return_Items)
    final returnItemsExists = await _tableExists(db, 'Return_Items');
    if (!returnItemsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Return_Items (
          ReturnItemID INTEGER PRIMARY KEY AUTOINCREMENT,
          ReturnID INTEGER NOT NULL,
          OrderItemID INTEGER,
          ItemID INTEGER,
          Quantity REAL NOT NULL,
          UnitPrice REAL NOT NULL,
          TotalAmount REAL NOT NULL,
          Reason TEXT,
          FOREIGN KEY (ReturnID) REFERENCES Returns(ReturnID),
          FOREIGN KEY (OrderItemID) REFERENCES Order_Items(OrderItemID),
          FOREIGN KEY (ItemID) REFERENCES Menu_Items(ItemID)
        )
      ''');
    }

    // جدول الإلغاءات والخصومات (Voids_And_Discounts)
    final voidsAndDiscountsExists = await _tableExists(
      db,
      'Voids_And_Discounts',
    );
    if (!voidsAndDiscountsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Voids_And_Discounts (
          VoidDiscountID INTEGER PRIMARY KEY AUTOINCREMENT,
          OrderID INTEGER,
          OrderItemID INTEGER,
          Type TEXT NOT NULL,
          Amount REAL NOT NULL,
          Percentage REAL,
          Reason TEXT,
          AuthorizedBy INTEGER,
          DateTime TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
          FOREIGN KEY (OrderItemID) REFERENCES Order_Items(OrderItemID),
          FOREIGN KEY (AuthorizedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // جدول معاملات النقد (Cash_Transactions)
    final cashTransactionsExists = await _tableExists(db, 'Cash_Transactions');
    if (!cashTransactionsExists) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Cash_Transactions (
          TransactionID INTEGER PRIMARY KEY AUTOINCREMENT,
          ShiftID INTEGER,
          TransactionType TEXT NOT NULL,
          Amount REAL NOT NULL,
          Description TEXT,
          ReferenceID TEXT,
          ProcessedBy INTEGER,
          DateTime TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (ShiftID) REFERENCES Shifts(ShiftID),
          FOREIGN KEY (ProcessedBy) REFERENCES Users(UserID)
        )
      ''');
    }

    // إنشاء الفهارس لتحسين الأداء
    await _createIndexes(db);

    // Users table
    if (await _tableExists(db, 'Users')) {
      final info = await _pragmaTableInfo(db, 'Users');
      if (!_hasColumn(info, 'IsActive')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN IsActive INTEGER NOT NULL DEFAULT 1",
        );
      }
      if (!_hasColumn(info, 'LastLogin')) {
        await db.execute("ALTER TABLE Users ADD COLUMN LastLogin TEXT");
      }
      if (!_hasColumn(info, 'CanProcessReturns')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanProcessReturns INTEGER NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'CanProcessExpenses')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanProcessExpenses INTEGER NOT NULL DEFAULT 0",
        );
      }
      if (!_hasColumn(info, 'CanReceivePayments')) {
        await db.execute(
          "ALTER TABLE Users ADD COLUMN CanReceivePayments INTEGER NOT NULL DEFAULT 0",
        );
      }
      // إضافة عمود RoleID للربط مع جدول الأدوار
      if (!_hasColumn(info, 'RoleID')) {
        await db.execute("ALTER TABLE Users ADD COLUMN RoleID INTEGER");
      }
    }
  }

  Future<void> _createIndexes(Database db) async {
    // إنشاء فهارس لتحسين الأداء مع التحقق من وجود الأعمدة
    try {
      // فهرس العملاء في الطلبات
      if (await _columnExists(db, 'Orders', 'CustomerID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Orders_CustomerID ON Orders (CustomerID)
        ''');
      }

      // فهرس الطاولات في الطلبات
      if (await _columnExists(db, 'Orders', 'TableID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Orders_TableID ON Orders (TableID)
        ''');
      }

      // فهرس الطلبات في عناصر الطلبات
      if (await _columnExists(db, 'Order_Items', 'OrderID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Order_Items_OrderID ON Order_Items (OrderID)
        ''');
      }

      // فهرس المنتجات في عناصر الطلبات
      if (await _columnExists(db, 'Order_Items', 'ItemID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Order_Items_ItemID ON Order_Items (ItemID)
        ''');
      }

      // فهرس الفئات في المنتجات
      if (await _columnExists(db, 'Menu_Items', 'CategoryID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Menu_Items_CategoryID ON Menu_Items (CategoryID)
        ''');
      }

      // فهرس الموردين في المخزون
      if (await _columnExists(db, 'Inventory_Items', 'SupplierID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Inventory_Items_SupplierID ON Inventory_Items (SupplierID)
        ''');
      }

      // فهرس الموردين في أوامر الشراء
      if (await _columnExists(db, 'Purchase_Orders', 'SupplierID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Purchase_Orders_SupplierID ON Purchase_Orders (SupplierID)
        ''');
      }

      // فهرس أوامر الشراء في تفاصيل الأوامر
      if (await _columnExists(db, 'Purchase_Order_Items', 'PurchaseOrderID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Purchase_Order_Items_PurchaseOrderID ON Purchase_Order_Items (PurchaseOrderID)
        ''');
      }

      // فهرس المخزون في تفاصيل أوامر الشراء
      if (await _columnExists(db, 'Purchase_Order_Items', 'InventoryItemID')) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_Purchase_Order_Items_InventoryItemID ON Purchase_Order_Items (InventoryItemID)
        ''');
      }
    } catch (e) {
      print('خطأ في إنشاء الفهارس: $e');
    }
  }

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    try {
      if (!await _tableExists(db, tableName)) return false;
      final info = await _pragmaTableInfo(db, tableName);
      return _hasColumn(info, columnName);
    } catch (e) {
      return false;
    }
  }
}
