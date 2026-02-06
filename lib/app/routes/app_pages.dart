import 'package:get/get.dart';

import '../modules/Auth/bindings/auth_binding.dart';
import '../modules/Auth/views/login_view.dart';
import '../modules/CashDrawer/bindings/cash_drawer_binding.dart';
import '../modules/CashDrawer/views/cash_drawer_setup_view.dart';
import '../modules/CustomerPayments/bindings/customer_payment_binding.dart';
import '../modules/CustomerPayments/views/customer_payment_view.dart';
import '../modules/Customers/bindings/customer_binding.dart';
import '../modules/Customers/views/customer_view.dart';
import '../modules/Dashboard/bindings/dashboard_binding.dart';
import '../modules/Dashboard/views/dashboard_view.dart';
import '../modules/Employees/bindings/employee_binding.dart';
import '../modules/Employees/views/employee_view.dart';
import '../modules/Expenses/bindings/expense_binding.dart';
import '../modules/Expenses/views/expense_view.dart';
import '../modules/MainBox/bindings/main_box_transaction_binding.dart';
import '../modules/MainBox/views/main_box_transaction_view.dart';
import '../modules/MenuCategories/bindings/menu_category_binding.dart';
import '../modules/MenuCategories/views/menu_category_view.dart';
import '../modules/MenuItems/bindings/menu_item_binding.dart';
import '../modules/MenuItems/views/menu_item_view.dart';
import '../modules/Orders/bindings/order_binding.dart';
import '../modules/Orders/views/order_view.dart';
import '../modules/OrderItems/bindings/order_item_binding.dart';
import '../modules/OrderItems/views/order_item_view.dart';
import '../modules/Reports/bindings/report_binding.dart';
import '../modules/Reports/views/report_view.dart';
import '../modules/Reports/views/advanced_report_view.dart';
import '../modules/Return/bindings/return_binding.dart';
import '../modules/Return/views/return_view.dart';
import '../modules/Settings/bindings/settings_binding.dart';
import '../modules/Settings/views/settings_view.dart';
import '../modules/Shift/bindings/shift_binding.dart';
import '../modules/Shift/views/shift_view.dart';
import '../modules/SubMain/bindings/sub_main_binding.dart';
import '../modules/SubMain/views/sub_main_view.dart';
import '../modules/Suppliers/bindings/supplier_binding.dart';
import '../modules/Suppliers/views/supplier_view.dart';
import '../modules/Users/bindings/user_management_binding.dart';
import '../modules/Users/views/user_view.dart';

// New imports for upgraded database features
// import '../modules/MenuItems/bindings/modifier_binding.dart';
// import '../modules/Orders/bindings/invoice_binding.dart';
// import '../modules/Suppliers/bindings/inventory_binding.dart';
// import '../modules/Employees/bindings/attendance_binding.dart';
// import '../modules/Settings/bindings/restaurant_settings_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // ignore: constant_identifier_names
  static const INITIAL = Routes.AUTH;

  static final routes = [
    GetPage(
      name: _Paths.CUSTOMERS,
      page: () => const CustomerView(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.CASH_DRAWER_SETUP,
      page: () => const CashDrawerSetupView(),
      binding: CashDrawerBinding(),
    ),

    GetPage(
      name: _Paths.EMPLOYEE,
      page: () => const EmployeeView(),
      binding: EmployeeBinding(),
    ),
    GetPage(
      name: _Paths.EXPENSE,
      page: () => const ExpenseView(),
      binding: ExpenseBinding(),
    ),
    GetPage(
      name: _Paths.MAIN_BOX_TRANSACTION,
      page: () => const MainBoxTransactionView(),
      binding: MainBoxTransactionBinding(),
    ),
    GetPage(
      name: _Paths.MENU_CATEGORY,
      page: () => const MenuCategoryView(),
      binding: MenuCategoryBinding(),
    ),
    GetPage(
      name: _Paths.MENU_ITEM,
      page: () => const MenuItemView(),
      binding: MenuItemBinding(),
    ),
    GetPage(
      name: _Paths.SUB_MAIN,
      page: () => const SubMainView(),
      binding: SubMainBinding(),
    ),
    GetPage(
      name: _Paths.ORDER,
      page: () => const OrderView(),
      binding: OrderBinding(),
    ),
    GetPage(
      name: _Paths.ORDER_ITEM,
      page: () => const OrderItemView(),
      binding: OrderItemBinding(),
    ),
    GetPage(
      name: _Paths.REPORT,
      page: () => const ReportView(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: _Paths.RETURN,
      page: () => const ReturnView(),
      binding: ReturnBinding(),
    ),
    GetPage(
      name: _Paths.SHIFT,
      page: () => const ShiftView(),
      binding: ShiftBinding(),
    ),
    // GetPage(
    //   name: _Paths.SHIFT_ADMIN,
    //   page: () => const ShiftAdminView(),
    //   binding: ShiftBinding(),
    // ),
    // GetPage(
    //   name: _Paths.SHIFT_CLOSE,
    //   page: () => const ShiftCloseView(),
    //   binding: ShiftBinding(),
    // ),
    GetPage(
      name: _Paths.SUPPLIER,
      page: () => const SupplierView(),
      binding: SupplierBinding(),
    ),
    GetPage(
      name: _Paths.USER,
      page: () => const UserView(),
      binding: UserManagementBinding(),
    ),
    GetPage(
      name: _Paths.CUSTOMER_PAYMENT,
      page: () => const CustomerPaymentView(),
      binding: CustomerPaymentBinding(),
    ),
    GetPage(
      name: _Paths.ADVANCED_REPORTS,
      page: () => const AdvancedReportView(),
      binding: ReportBinding(),
    ),

    // New routes for upgraded database features
    // Note: Views need to be created for these routes
    // GetPage(
    //   name: _Paths.MODIFIER,
    //   page: () => const ModifierView(),
    //   binding: ModifierBinding(),
    // ),
    // GetPage(
    //   name: _Paths.INVOICE,
    //   page: () => const InvoiceView(),
    //   binding: InvoiceBinding(),
    // ),
    // GetPage(
    //   name: _Paths.INVENTORY,
    //   page: () => const InventoryView(),
    //   binding: InventoryBinding(),
    // ),
    // GetPage(
    //   name: _Paths.ATTENDANCE,
    //   page: () => const AttendanceView(),
    //   binding: AttendanceBinding(),
    // ),
    // GetPage(
    //   name: _Paths.RESTAURANT_SETTINGS,
    //   page: () => const RestaurantSettingsView(),
    //   binding: RestaurantSettingsBinding(),
    // ),
  ];
}
