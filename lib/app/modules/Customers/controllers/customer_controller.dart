// file: controllers/customer_controller.dart

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../../../helpers/app_dialogs.dart';

/// Controller لإدارة عمليات العملاء
class CustomerController extends GetxController {
  /// استخدام singleton pattern للخدمة
  final CustomerService _customerService = CustomerService.instance;

  /// المتغيرات التفاعلية (Reactive) باستخدام .obs
  var customers = <CustomerModel>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var selectedFilter = 'الكل'.obs;
  // فلاتر الواجهة
  var typeFilter = 'جميع العملاء'.obs;
  var regionFilter = 'جميع المناطق'.obs; // لا يوجد حقل منطقة حالياً في CustomerModel

  /// جلب العملاء عند بدء تشغيل الـ Controller
  @override
  void onInit() {
    super.onInit();
    fetchAllCustomers();
  }

  /// تطبيق الفلاتر والبحث على قائمة العملاء
  List<CustomerModel> get filteredCustomers {
    List<CustomerModel> list = List.of(customers);

    // 1) فلتر النوع
    switch (typeFilter.value) {
      case 'عملاء VIP':
        // تعريف تقريبي لـ VIP: العملاء ذوو رصيد مطلق أكبر من 1000
        list = list
            .where((c) => c.currentBalance.abs() > 1000)
            .toList();
        break;
      case 'عملاء جدد':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        list = list
            .where((c) => c.registrationDate.isAfter(thirtyDaysAgo))
            .toList();
        break;
      case 'عملاء نشطون':
        list = list.where((c) => c.currentBalance >= 0).toList();
        break;
      case 'جميع العملاء':
      default:
        // لا شيء
        break;
    }

    // 2) فلتر المنطقة (غير مطبق فعلياً لعدم توفر حقل منطقة في CustomerModel)
    // مبدئياً، لن نغير القائمة بناءً على regionFilter

    // 3) تطبيق البحث النصي
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.trim().toLowerCase();
      list = list.where((c) {
        final byName = c.customerName.toLowerCase().contains(q);
        final byPhone = (c.phoneNumber ?? '').contains(q);
        return byName || byPhone;
      }).toList();
    }

    return list;
  }

  /// جلب كل العملاء
  Future<void> fetchAllCustomers() async {
    try {
      isLoading.value = true;
      final result = await _customerService.getAllCustomers();
      customers.assignAll(
        result.map((item) => CustomerModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب العملاء: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// إضافة عميل جديد
  Future<void> addCustomer(CustomerModel customer) async {
    if (customer.customerName.trim().isEmpty) {
      AppDialogs.show('خطأ', 'اسم العميل مطلوب');
      return;
    }

    try {
      isLoading.value = true;
      final newCustomerId = await _customerService.createCustomer(
        customer.toMap(),
      );
      if (newCustomerId > 0) {
        AppDialogs.show('نجاح', 'تمت إضافة العميل بنجاح');
        await fetchAllCustomers();
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية الإضافة');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات عميل
  Future<void> updateCustomer(CustomerModel customer) async {
    if (customer.customerID == null || customer.customerID! <= 0) {
      AppDialogs.show('خطأ', 'معرف العميل غير صالح');
      return;
    }

    if (customer.customerName.trim().isEmpty) {
      AppDialogs.show('خطأ', 'اسم العميل مطلوب');
      return;
    }

    try {
      isLoading.value = true;
      final success = await _customerService.updateCustomer(
        customer.customerID!,
        customer.toMap(),
      );
      if (success > 0) {
        AppDialogs.show('نجاح', 'تم تحديث بيانات العميل بنجاح');

        // تحديث العنصر في القائمة الحالية مباشرة
        int index = customers.indexWhere(
          (c) => c.customerID == customer.customerID,
        );
        if (index != -1) {
          customers[index] = customer;
        }
      } else {
        AppDialogs.show('خطأ', 'فشلت عملية التحديث');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// حذف عميل
  Future<void> deleteCustomer(int customerId) async {
    try {
      isLoading.value = true;
      final success = await _customerService.deleteCustomer(customerId);

      if (success > 0) {
        // إزالة العميل من القائمة المحلية
        customers.removeWhere((customer) => customer.customerID == customerId);
        AppDialogs.show('نجاح', 'تم حذف العميل بنجاح');
      } else {
        AppDialogs.show('خطأ', 'فشل في حذف العميل');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حذف العميل: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// البحث عن عملاء
  Future<void> searchCustomers(String searchTerm) async {
    searchQuery.value = searchTerm;

    if (searchTerm.trim().isEmpty) {
      await fetchAllCustomers();
      return;
    }

    try {
      isLoading.value = true;
      final result = await _customerService.searchCustomers(searchTerm);
      customers.assignAll(
        result.map((item) => CustomerModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل البحث: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب عدد العملاء الجدد (خلال آخر 30 يوم)
  int getNewCustomersCount() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return customers.where((customer) {
      return customer.registrationDate.isAfter(thirtyDaysAgo);
    }).length;
  }

  /// جلب عدد العملاء النشطين (الذين لديهم رصيد موجب)
  int getActiveCustomersCount() {
    return customers.where((customer) {
      return customer.currentBalance >= 0;
    }).length;
  }

  /// جلب متوسط الرصيد للعملاء
  double getAverageBalance() {
    if (customers.isEmpty) return 0.0;

    double totalBalance = 0.0;
    for (var customer in customers) {
      totalBalance += customer.currentBalance;
    }

    return totalBalance / customers.length;
  }

  /// البحث المحلي في العملاء
  List<CustomerModel> searchCustomersLocal(String query) {
    if (query.isEmpty) return customers;

    return customers.where((customer) {
      return customer.customerName.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          (customer.phoneNumber?.contains(query) ?? false);
    }).toList();
  }

  /// فلترة العملاء حسب الحالة
  List<CustomerModel> filterCustomersByStatus(String status) {
    if (status == 'الكل') return customers;

    return customers.where((customer) {
      switch (status) {
        case 'نشط':
          return customer.currentBalance >= 0;
        case 'مدين':
          return customer.currentBalance < 0;
        default:
          return true;
      }
    }).toList();
  }

  /// فلترة العملاء حسب فترة التسجيل
  List<CustomerModel> filterCustomersByPeriod(String period) {
    if (period == 'الكل') return customers;

    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'اليوم':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'هذا الأسبوع':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'هذا الشهر':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'آخر 30 يوم':
        startDate = now.subtract(const Duration(days: 30));
        break;
      default:
        return customers;
    }

    return customers.where((customer) {
      return customer.registrationDate.isAfter(startDate);
    }).toList();
  }

  /// إحصائيات العملاء
  Map<String, dynamic> getCustomersStatistics() {
    final totalCustomers = customers.length;
    final activeCustomers = getActiveCustomersCount();
    final newCustomers = getNewCustomersCount();
    final averageBalance = getAverageBalance();

    return {
      'total': totalCustomers,
      'active': activeCustomers,
      'new': newCustomers,
      'averageBalance': averageBalance,
      'debtors': totalCustomers - activeCustomers,
    };
  }

  /// جلب متوسط عدد الطلبات لكل عميل
  double getAverageOrdersPerCustomer() {
    if (customers.isEmpty) return 0.0;

    // نحتاج لجلب عدد الطلبات لكل عميل من OrderService
    // هذا مثال مبسط - يمكن تحسينه لاحقاً بربطه مع OrderService
    try {
      // حساب تقريبي بناءً على البيانات المتاحة
      // يمكن تحسينه لاحقاً بجلب البيانات الحقيقية من قاعدة البيانات
      final activeCustomersCount = getActiveCustomersCount();
      if (activeCustomersCount == 0) return 0.0;

      // افتراض أن كل عميل نشط لديه طلبات (يمكن تحسينه)
      return activeCustomersCount > 0
          ? (activeCustomersCount * 2.5) / customers.length
          : 0.0;
    } catch (e) {
      print('خطأ في حساب متوسط الطلبات: $e');
      return 0.0;
    }
  }

  /// جلب إجمالي قيمة المبيعات للعملاء
  double getTotalCustomerSales() {
    double totalSales = 0.0;
    for (var customer in customers) {
      // حساب المبيعات بناءً على الرصيد الحالي
      // الرصيد السالب يعني أن العميل اشترى بأكثر مما دفع
      if (customer.currentBalance < 0) {
        totalSales += customer.currentBalance.abs();
      }
    }
    return totalSales;
  }

  /// جلب عدد العملاء المدينين
  int getDebtorCustomersCount() {
    return customers.where((customer) => customer.currentBalance < 0).length;
  }

  /// جلب إجمالي الديون
  double getTotalDebts() {
    double totalDebts = 0.0;
    for (var customer in customers) {
      if (customer.currentBalance < 0) {
        totalDebts += customer.currentBalance.abs();
      }
    }
    return totalDebts;
  }

  /// جلب العملاء الأكثر شراءً (بناءً على الرصيد السالب)
  List<CustomerModel> getTopCustomersByPurchases({int limit = 5}) {
    final debtorCustomers = customers
        .where((customer) => customer.currentBalance < 0)
        .toList();

    // ترتيب حسب أكبر دين (أكثر شراءً)
    debtorCustomers.sort(
      (a, b) => a.currentBalance.compareTo(b.currentBalance),
    );

    return debtorCustomers.take(limit).toList();
  }

  /// جلب العملاء الجدد خلال فترة معينة
  List<CustomerModel> getCustomersByRegistrationPeriod(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return customers.where((customer) {
      return customer.registrationDate.isAfter(startDate);
    }).toList();
  }

  /// متوسط العملاء الجدد
  double getAverageNewCustomers() {
    final newCustomers = getNewCustomersCount();
    final totalCustomers = customers.length;
    return totalCustomers > 0 ? newCustomers / totalCustomers : 0.0;
  }

  /// متوسط العملاء النشيطون
  double getAverageActiveCustomers() {
    final activeCustomers = getActiveCustomersCount();
    final totalCustomers = customers.length;
    return totalCustomers > 0 ? activeCustomers / totalCustomers : 0.0;
  }

  /// إحصائيات شاملة للعملاء
  Map<String, dynamic> getDetailedCustomerStatistics() {
    final totalCustomers = customers.length;
    final activeCustomers = getActiveCustomersCount();
    final debtorCustomers = getDebtorCustomersCount();
    final newCustomers = getNewCustomersCount();
    final averageBalance = getAverageBalance();
    final totalDebts = getTotalDebts();
    final totalSales = getTotalCustomerSales();
    final averageOrdersPerCustomer = getAverageOrdersPerCustomer();

    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'debtorCustomers': debtorCustomers,
      'newCustomers': newCustomers,
      'averageBalance': averageBalance,
      'totalDebts': totalDebts,
      'totalSales': totalSales,
      'averageOrdersPerCustomer': averageOrdersPerCustomer,
      'customerGrowthRate': totalCustomers > 0
          ? (newCustomers / totalCustomers * 100)
          : 0.0,
      'debtorPercentage': totalCustomers > 0
          ? (debtorCustomers / totalCustomers * 100)
          : 0.0,
    };
  }

  /// تحديث البيانات
  Future<void> refreshData() async {
    await fetchAllCustomers();
  }

  /// إنشاء عميل جديد بالبيانات الأساسية
  CustomerModel createNewCustomer({
    required String name,
    String? phone,
    double balance = 0.0,
    String? notes,
  }) {
    return CustomerModel(
      customerName: name,
      phoneNumber: phone,
      currentBalance: balance,
      registrationDate: DateTime.now(),
      notes: notes,
    );
  }

  /// التحقق من صحة بيانات العميل
  bool validateCustomerData(CustomerModel customer) {
    if (customer.customerName.trim().isEmpty) {
      AppDialogs.show('خطأ في البيانات', 'اسم العميل مطلوب');
      return false;
    }

    if (customer.phoneNumber != null &&
        customer.phoneNumber!.isNotEmpty &&
        customer.phoneNumber!.length < 10) {
      AppDialogs.show('خطأ في البيانات', 'رقم الهاتف غير صحيح');
      return false;
    }

    return true;
  }
}
