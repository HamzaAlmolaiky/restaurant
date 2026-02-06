// file: bindings/user_management_binding.dart
// ignore_for_file: avoid_print

import 'package:get/get.dart';

// ============ Database ============
// ============ Services ============
// Core Services
import '../modules/Auth/services/auth_service.dart';
import '../modules/CustomerPayments/services/customer_payment_service.dart';
import '../modules/Expenses/controllers/expense_controller.dart';
import '../modules/Expenses/services/expense_service.dart';
import '../modules/MainBox/controllers/main_box_transaction_controller.dart';
import '../modules/MenuCategories/services/menu_category_service.dart';
import '../modules/Return/services/return_service.dart';
import '../modules/Shift/controllers/shift_controller.dart';
import '../modules/Users/services/user_service.dart';
import '../modules/Customers/services/customer_service.dart';
import '../modules/Orders/services/order_service.dart';

// Menu Services
import '../modules/MenuItems/services/menu_item_service.dart';
import '../modules/OrderItems/services/order_item_service.dart';

// Business Services
import '../modules/Employees/services/employee_service.dart';
import '../modules/Suppliers/services/supplier_service.dart';
import '../modules/Suppliers/controllers/supplier_controller.dart';

// System Services
import '../modules/MainBox/services/main_box_service.dart';
import '../modules/Shift/services/shift_service.dart';
import '../modules/Reports/services/advanced_report_service.dart';
import '../modules/Reports/services/report_scheduler_service.dart';
// import '../modules/Settings/services/settings_service.dart';

// ============ Controllers ============
// Core Controllers
import '../modules/Auth/controllers/auth_controller.dart';
import '../modules/Dashboard/controllers/dashboard_controller.dart';
import '../modules/Users/controllers/user_management_controller.dart';
import '../modules/Customers/controllers/customer_controller.dart';
import '../modules/Orders/controllers/order_controller.dart';

// Menu Controllers
import '../modules/MenuCategories/controllers/menu_category_controller.dart';
import '../modules/MenuItems/controllers/menu_item_controller.dart';
import '../modules/OrderItems/controllers/order_item_controller.dart';

// Business Controllers
import '../modules/Employees/controllers/employee_controller.dart';
import '../modules/Return/controllers/return_controller.dart';
import '../modules/CustomerPayments/controllers/customer_payment_controller.dart';

// System Controllers
import '../modules/Reports/controllers/report_controller.dart';
import '../modules/Settings/controllers/settings_controller.dart';
import '../modules/CashDrawer/controllers/cash_drawer_controller.dart';
import '../modules/SubMain/controllers/sub_main_controller.dart';

/// ملف الربط الرئيسي للتطبيق
/// يحتوي على جميع الخدمات والكونترولرات المطلوبة
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============ Database Initialization ============

    // ============ Core Services Registration ============

    // User & Auth Services
    Get.put<UserService>(UserService(), permanent: true);
    Get.put<CustomerService>(CustomerService.instance, permanent: true);
    Get.put<CustomerPaymentService>(
      CustomerPaymentService.instance,
      permanent: true,
    );
    Get.put<OrderService>(
      OrderService(
        Get.find<CustomerService>(),
        Get.find<CustomerPaymentService>(),
      ),
      permanent: true,
    );
    Get.put<OrderController>(OrderController(Get.find()), permanent: true);
    Get.put(AuthService());

    // Order Services
    Get.put<SupplierService>(SupplierService.instance, permanent: true);
    Get.put<SupplierController>(
      SupplierController(Get.find()),
      permanent: true,
    );
    Get.put<OrderItemService>(OrderItemService.instance, permanent: true);
    Get.lazyPut<CustomerService>(() => CustomerService.instance);
    Get.lazyPut<ExpenseService>(() => ExpenseService.instance);
    // AuthService يجب أن يكون مسجلاً كـ permanent في مكان آخر (مثل AuthBinding)

    // تسجيل خدمة المرتجعات
    Get.lazyPut<ReturnService>(() => ReturnService(Get.find(), Get.find()));

    // ============ Menu Services Registration ============
    Get.put<MenuCategoryService>(MenuCategoryService.instance, permanent: true);
    Get.put<MenuItemService>(MenuItemService.instance, permanent: true);

    // ============ POS Services Registration ============
    // سيتم تسجيل خدمة الصندوق الرئيسي بشكل دائم أدناه
    Get.lazyPut<MainBoxTransactionController>(
      () => MainBoxTransactionController(Get.find()),
    );

    // توحيد خدمة المصادقة باستخدام AuthService فقط

    // ============ Business Services Registration ============
    Get.put<EmployeeService>(EmployeeService.instance, permanent: true);

    // ============ System Services Registration ============
    Get.put<MainBoxService>(MainBoxService.instance, permanent: true);
    Get.put<ShiftService>(
      ShiftService(Get.find<MainBoxService>()),
      permanent: true,
    );
    Get.put<AdvancedReportService>(
      AdvancedReportService.instance,
      permanent: true,
    );
    Get.put<ReportSchedulerService>(
      ReportSchedulerService.instance,
      permanent: true,
    );
    Get.lazyPut<ShiftController>(
      () => ShiftController(Get.find(), Get.find<AuthService>()),
    );

    // Expenses Services
    Get.lazyPut<ExpenseService>(() => ExpenseService.instance);
    Get.lazyPut<ExpenseController>(() => ExpenseController(Get.find()));

    // ============ Core Controllers Registration ============

    // Auth & User Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<UserManagementController>(
      UserManagementController(),
      permanent: true,
    );

    // Shift Controller
    // تمت إزالة التسجيل المكرر لـ ShiftService

    // Dashboard Controller
    Get.put<DashboardController>(DashboardController(), permanent: true);

    // Customer & Order Controllers
    Get.put<CustomerController>(CustomerController(), permanent: true);
    Get.put<OrderItemController>(OrderItemController(), permanent: true);

    // ============ Menu Controllers Registration ============
    Get.put<MenuCategoryController>(MenuCategoryController(), permanent: true);
    Get.put<MenuItemController>(
      MenuItemController(
        Get.find<MenuCategoryService>(),
        Get.find<MenuItemService>(),
      ),
      permanent: true,
    );

    // ============ Business Controllers Registration ============
    Get.put<EmployeeController>(EmployeeController(), permanent: true);
    Get.put<ReturnController>(ReturnController(), permanent: true);
    Get.put<CustomerPaymentController>(
      CustomerPaymentController(),
      permanent: true,
    );

    // ============ System Controllers Registration ============
    Get.put<ReportController>(ReportController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);

    // ============ POS Controllers Registration ============
    Get.put<CashDrawerController>(CashDrawerController(), permanent: true);
    Get.put<SubMainController>(SubMainController(), permanent: true);
  }
}
