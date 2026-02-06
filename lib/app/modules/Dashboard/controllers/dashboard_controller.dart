// ignore_for_file: avoid_print

import 'dart:async';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/CustomerPayments/views/customer_payment_view.dart';
import 'package:restaurant/app/modules/Expenses/views/expense_view.dart';
import 'package:restaurant/app/modules/Settings/views/settings_view.dart';
import 'package:restaurant/app/modules/Shift/views/shift_view.dart';

// Import Services
import '../../Customers/services/customer_service.dart';
import '../../Employees/services/employee_service.dart';
import '../../MainBox/services/main_box_service.dart';
import '../../OrderItems/views/order_item_view.dart';
import '../../Orders/services/order_service.dart';
// Import Models
import '../../Orders/models/order_model.dart';

// Import Views
import '../../Customers/views/customer_view.dart';
import '../../Employees/views/employee_view.dart';
import '../../MainBox/views/main_box_transaction_view.dart';
import '../../MenuCategories/views/menu_category_view.dart';
import '../../MenuItems/views/menu_item_view.dart';
import '../../Orders/views/order_view.dart';
import '../../Reports/views/advanced_report_view.dart';
// import '../../Reports/views/report_view.dart';
import '../../Return/views/return_view.dart';
import '../../Suppliers/views/supplier_view.dart';
import '../../Users/views/user_view.dart';

import '../../../helpers/app_dialogs.dart';

class DashboardController extends GetxController {
  // Services
  final OrderService _orderService = Get.find<OrderService>();
  final CustomerService _customerService = CustomerService.instance;
  final EmployeeService _employeeService = EmployeeService.instance;
  final MainBoxService _mainBoxService = MainBoxService.instance;

  // Observable variables for statistics
  var isLoading = false.obs;
  var totalSales = 0.0.obs;
  var totalOrders = 0.obs;
  var newCustomers = 0.obs;
  var averageOrderValue = 0.0.obs;
  var mainBoxBalance = 0.0.obs;
  var activeEmployees = 0.obs;
  var recentOrders = <OrderModel>[].obs;
  var selectedIndex = 0.obs;

  final pages = [
    const MainBoxTransactionView(), // 1: الصناديق
    const MenuCategoryView(), // 2: الفئات
    const MenuItemView(), // 3: المنتجات
    const OrderView(), // 4: الطلبات
    OrderItemView(), // 5: أصناف الطلبات
    const CustomerView(), // 6: العملاء
    const EmployeeView(), // 7: الموظفين
    const SupplierView(), // 8: الموردين
    const ReturnView(), // 9: المرتجعات
    // const ReportView(), // 10: التقارير
    const AdvancedReportView(), // 10: التقارير المتقدمة
    const UserView(), // 11: المستخدمين
    SettingsView(), // 12: الاعدادات
    CustomerPaymentView(), // 13: دفعات العملاء
    ShiftView(), // 14: الورديات
    ExpenseView(), // 15: المصروفات
  ].obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  // جلب بيانات لوحة التحكم
  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        fetchTotalSales(),
        fetchTotalOrders(),
        fetchNewCustomers(),
        fetchAverageOrderValue(),
        fetchMainBoxBalance(),
        fetchActiveEmployees(),
        fetchRecentOrders(),
      ]);
    } catch (e) {
      AppDialogs.show(
        'خطأ',
        'فشل في تحميل بيانات لوحة التحكم: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // جلب إجمالي المبيعات
  Future<void> fetchTotalSales() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      final orders = ordersData
          .map((data) => OrderModel.fromMap(data))
          .toList();
      double total = 0.0;
      for (var order in orders) {
        total += order.totalAmount;
      }
      totalSales.value = total;
    } catch (e) {
      print('خطأ في جلب إجمالي المبيعات: $e');
      totalSales.value = 0.0;
    }
  }

  // جلب إجمالي الطلبات
  Future<void> fetchTotalOrders() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      totalOrders.value = ordersData.length;
    } catch (e) {
      print('خطأ في جلب إجمالي الطلبات: $e');
      totalOrders.value = 0;
    }
  }

  /// جلب العملاء الجدد - استخدام الحقل الصحيح RegistrationDate
  Future<void> fetchNewCustomers() async {
    try {
      final customersData = await _customerService.getAllCustomers();
      final today = DateTime.now();
      int newCount = 0;

      for (var customerData in customersData) {
        if (customerData['RegistrationDate'] != null) {
          try {
            final registrationDate = DateTime.parse(
              customerData['RegistrationDate'],
            );
            if (registrationDate.year == today.year &&
                registrationDate.month == today.month &&
                registrationDate.day == today.day) {
              newCount++;
            }
          } catch (e) {
            print('خطأ في تحليل تاريخ التسجيل: $e');
          }
        }
      }
      newCustomers.value = newCount;
    } catch (e) {
      print('خطأ في جلب العملاء الجدد: $e');
      newCustomers.value = 0;
    }
  }

  // جلب متوسط قيمة الطلب
  Future<void> fetchAverageOrderValue() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      if (ordersData.isNotEmpty) {
        final orders = ordersData
            .map((data) => OrderModel.fromMap(data))
            .toList();
        double total = 0.0;
        for (var order in orders) {
          total += order.totalAmount;
        }
        averageOrderValue.value = total / orders.length;
      } else {
        averageOrderValue.value = 0.0;
      }
    } catch (e) {
      print('خطأ في جلب متوسط قيمة الطلب: $e');
      averageOrderValue.value = 0.0;
    }
  }

  // جلب رصيد الصندوق الرئيسي
  Future<void> fetchMainBoxBalance() async {
    try {
      final balance = await _mainBoxService.getCurrentBalance();
      mainBoxBalance.value = balance;
    } catch (e) {
      print('خطأ في جلب رصيد الصندوق: $e');
      mainBoxBalance.value = 0.0;
    }
  }

  // جلب الطلبات الحديثة (آخر 5 طلبات)
  Future<void> fetchRecentOrders() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      final orders = ordersData
          .map((data) => OrderModel.fromMap(data))
          .toList();

      // ترتيب الطلبات حسب التاريخ (الأحدث أولاً) وأخذ آخر 5
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      recentOrders.assignAll(orders.take(5).toList());
    } catch (e) {
      print('خطأ في جلب الطلبات الحديثة: $e');
      recentOrders.clear();
    }
  }

  // جلب الموظفين النشطين - استخدام الحقول الصحيحة
  Future<void> fetchActiveEmployees() async {
    try {
      final employeesData = await _employeeService.getAllEmployees();
      int activeCount = 0;

      for (var employeeData in employeesData) {
        // التحقق من حالة الموظف - استخدام الحقول المتاحة
        final status = employeeData['Status'] ?? employeeData['status'];
        if (status == 'نشط' || status == 'حاضر' || status == 'Active') {
          activeCount++;
        }
      }
      activeEmployees.value = activeCount;
    } catch (e) {
      print('خطأ في جلب الموظفين النشطين: $e');
      activeEmployees.value = 0;
    }
  }

  // تحديث البيانات
  Future<void> refreshData() async {
    await fetchDashboardData();
  }

  // دوال إضافية للإحصائيات المتقدمة

  // جلب عدد الطلبات اليوم
  Future<int> getTodayOrdersCount() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      final orders = ordersData
          .map((data) => OrderModel.fromMap(data))
          .toList();
      final today = DateTime.now();

      return orders.where((order) {
        final DateTime orderDate = order.orderDate; // already DateTime
        return orderDate.year == today.year &&
            orderDate.month == today.month &&
            orderDate.day == today.day;
      }).length;
    } catch (e) {
      print('خطأ في جلب طلبات اليوم: $e');
      return 0;
    }
  }

  // جلب مبيعات اليوم
  Future<double> getTodaySales() async {
    try {
      final ordersData = await _orderService.getAllOrders();
      final orders = ordersData
          .map((data) => OrderModel.fromMap(data))
          .toList();
      final today = DateTime.now();
      double todaySales = 0.0;

      for (var order in orders) {
        final DateTime orderDate = order.orderDate; // already DateTime
        if (orderDate.year == today.year &&
            orderDate.month == today.month &&
            orderDate.day == today.day) {
          todaySales += order.totalAmount;
        }
      }

      return todaySales;
    } catch (e) {
      print('خطأ في جلب مبيعات اليوم: $e');
      return 0.0;
    }
  }

  // جلب عدد العملاء النشطين
  Future<int> getActiveCustomersCount() async {
    try {
      return await _customerService.getActiveCustomersCount();
    } catch (e) {
      print('خطأ في جلب العملاء النشطين: $e');
      return 0;
    }
  }

  // جلب إجمالي عدد العملاء
  Future<int> getTotalCustomersCount() async {
    try {
      return await _customerService.getTotalCustomersCount();
    } catch (e) {
      print('خطأ في جلب إجمالي العملاء: $e');
      return 0;
    }
  }

  // إنشاء بيانات افتراضية للاختبار
  Future<void> createDefaultData() async {
    try {
      isLoading.value = true;

      // إنشاء عملاء افتراضيين
      await _customerService.createDefaultCustomers();

      // إنشاء موظفين افتراضيين
      await _employeeService.createDefaultEmployees();

      // إنشاء طلبات افتراضية
      await _orderService.createDefaultOrders();

      // تحديث البيانات بعد إنشاء البيانات الافتراضية
      await fetchDashboardData();

      AppDialogs.show('نجاح', 'تم إنشاء جميع البيانات الافتراضية بنجاح');
    } catch (e) {
      AppDialogs.show(
        'خطأ',
        'فشل في إنشاء البيانات الافتراضية: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // دوال إضافية للإحصائيات المتقدمة من الخدمات المحدثة

  // جلب إحصائيات شاملة للعملاء
  Future<Map<String, dynamic>> getCustomersStatistics() async {
    try {
      return await _customerService.getCustomersStatistics();
    } catch (e) {
      print('خطأ في جلب إحصائيات العملاء: $e');
      return {
        'totalCustomers': 0,
        'activeCustomers': 0,
        'newCustomers': 0,
        'averageBalance': 0.0,
      };
    }
  }

  // جلب إحصائيات شاملة للموظفين
  Future<Map<String, dynamic>> getEmployeesStatistics() async {
    try {
      return await _employeeService.getEmployeesStatistics();
    } catch (e) {
      print('خطأ في جلب إحصائيات الموظفين: $e');
      return {
        'totalEmployees': 0,
        'activeEmployees': 0,
        'presentEmployees': 0,
        'absentEmployees': 0,
        'positionCounts': <String, int>{},
      };
    }
  }

  // جلب إحصائيات شاملة للطلبات
  Future<Map<String, dynamic>> getOrdersStatistics() async {
    try {
      return await _orderService.getOrdersStatistics();
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات: $e');
      return {
        'totalOrders': 0,
        'todayOrders': 0,
        'totalSales': 0.0,
        'todaySales': 0.0,
        'averageOrderValue': 0.0,
        'cashOrders': 0,
        'creditOrders': 0,
      };
    }
  }

  // جلب تقرير شامل للداشبورد
  Future<Map<String, dynamic>> getDashboardReport() async {
    try {
      final customerStats = await getCustomersStatistics();
      final employeeStats = await getEmployeesStatistics();
      final orderStats = await getOrdersStatistics();

      return {
        'customers': customerStats,
        'employees': employeeStats,
        'orders': orderStats,
        'mainBoxBalance': mainBoxBalance.value,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('خطأ في جلب تقرير الداشبورد: $e');
      return {};
    }
  }

  // تصدير البيانات للتقارير
  Future<String> exportDashboardData() async {
    try {
      final report = await getDashboardReport();
      // يمكن تحويل البيانات إلى JSON أو CSV حسب الحاجة
      return report.toString();
    } catch (e) {
      print('خطأ في تصدير البيانات: $e');
      return 'فشل في تصدير البيانات';
    }
  }

  // إعادة تعيين جميع البيانات (للاختبار فقط)
  Future<void> resetAllData() async {
    try {
      isLoading.value = true;

      // إعادة تعيين المتغيرات التفاعلية
      totalSales.value = 0.0;
      totalOrders.value = 0;
      newCustomers.value = 0;
      averageOrderValue.value = 0.0;
      mainBoxBalance.value = 0.0;
      activeEmployees.value = 0;
      recentOrders.clear();

      AppDialogs.show('نجاح', 'تم إعادة تعيين جميع البيانات');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إعادة تعيين البيانات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // دالة مساعدة لتحديث إحصائية واحدة
  Future<void> updateSingleStat(String statType) async {
    try {
      switch (statType) {
        case 'sales':
          await fetchTotalSales();
          break;
        case 'orders':
          await fetchTotalOrders();
          break;
        case 'customers':
          await fetchNewCustomers();
          break;
        case 'average':
          await fetchAverageOrderValue();
          break;
        case 'balance':
          await fetchMainBoxBalance();
          break;
        case 'employees':
          await fetchActiveEmployees();
          break;
        case 'recent':
          await fetchRecentOrders();
          break;
        default:
          await fetchDashboardData();
      }
    } catch (e) {
      print('خطأ في تحديث الإحصائية $statType: $e');
    }
  }

  // جلب البيانات بشكل دوري (كل دقيقة)
  void startPeriodicDataRefresh() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!isLoading.value) {
        fetchDashboardData();
      }
    });
  }

  // إيقاف التحديث الدوري
  void stopPeriodicDataRefresh() {
    // يمكن إضافة منطق إيقاف Timer هنا إذا لزم الأمر
  }

  @override
  void onClose() {
    stopPeriodicDataRefresh();
    super.onClose();
  }
}
