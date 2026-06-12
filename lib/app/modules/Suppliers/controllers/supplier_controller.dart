// file: controllers/supplier_controller.dart
import 'package:get/get.dart';
import '../models/supplier_model.dart';
import '../models/supplier_stats_model.dart';
import '../services/supplier_service.dart';
import '../../../helpers/app_dialogs.dart';

class SupplierController extends GetxController {
  final SupplierService _supplierService;
  SupplierController(this._supplierService);

  var suppliers = <SupplierModel>[].obs;
  var isLoading = false.obs;
  final stats = Rx<SupplierStatsModel?>(null);

  // متغيرات الفلترة
  var searchQuery = ''.obs;
  var typeFilter = 'جميع الأنواع'.obs;
  var statusFilter = 'جميع الحالات'.obs;
  var ratingFilter = 'جميع التقييمات'.obs;

  /// القائمة المفلترة
  List<SupplierModel> get filteredSuppliers {
    final q = searchQuery.value.trim().toLowerCase();
    final status = statusFilter.value;
    return suppliers.where((s) {
      final matchSearch = q.isEmpty ||
          (s.supplierName ?? '').toLowerCase().contains(q) ||
          s.itemsName.toLowerCase().contains(q);
      final matchStatus = status == 'جميع الحالات' ||
          (status == 'نشط' && s.status == 'Unpaid') ||
          (status == 'غير نشط' && s.status == 'Paid') ||
          s.status == status;
      return matchSearch && matchStatus;
    }).toList();
  }

  // Snackbar helpers for unified UX
  void _showSuccess(String message) {
    AppDialogs.showSuccess('', message);
  }

  void _showError(String message) {
    AppDialogs.showError('', message);
  }

  @override
  void onInit() {
    super.onInit();
    fetchAllSuppliers();
    fetchStats();
  }

  Future<void> fetchAllSuppliers() async {
    try {
      isLoading.value = true;
      suppliers.assignAll(await _supplierService.getAllSuppliers());
    } catch (e) {
      _showError('فشل في جلب بيانات الموردين');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats() async {
    try {
      stats.value = await _supplierService.getSupplierStats();
    } catch (e) {
      AppDialogs.showError('خطاء في جلب الإحصائيات', e.toString());
    }
  }

  /// إرجاع تاريخ طلبات الشراء لمورد محدد عبر الخدمة
  Future<List<dynamic>> getSupplierHistory(int supplierId) {
    return _supplierService.getSupplierHistory(supplierId);
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    if (supplier.supplierName == null ||
        supplier.supplierName!.trim().isEmpty) {
      _showError('اسم المورد مطلوب');
      return;
    }

    await _performDbOperation(() async {
      await _supplierService.addSupplier(supplier);
      _showSuccess('تمت إضافة المورد بنجاح');
    });
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (supplier.supplierID == null || supplier.supplierID! <= 0) {
      _showError('مُعرّف المورد غير صالح');
      return;
    }
    await _performDbOperation(() async {
      await _supplierService.updateSupplier(supplier);
      _showSuccess('تم تحديث بيانات المورد بنجاح');
    });
  }

  Future<void> deleteSupplier(int supplierId) async {
    if (supplierId <= 0) {
      _showError('مُعرّف المورد غير صالح');
      return;
    }
    await _performDbOperation(() async {
      await _supplierService.deleteSupplier(supplierId);
      _showSuccess('تم حذف المورد بنجاح');
    });
  }

  Future<void> searchSuppliers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      await fetchAllSuppliers();
      return;
    }
    try {
      isLoading.value = true;
      suppliers.assignAll(await _supplierService.searchSuppliers(searchTerm));
    } finally {
      isLoading.value = false;
    }
  }

  /// **منطق العمل الخاص بدفع مبلغ للمورد**
  Future<void> makePaymentToSupplier(int supplierId, double amount) async {
    if (supplierId <= 0 || amount <= 0) {
      _showError('بيانات الدفع غير صالحة');
      return;
    }

    await _performDbOperation(() async {
      // 1. جلب بيانات المورد الحالية
      final supplier = await _supplierService.getSupplierById(supplierId);
      if (supplier == null) throw Exception('المورد غير موجود');

      // 2. حساب القيم الجديدة
      final newAmountPaid = (supplier.amountPaid ?? 0) + amount;
      final newAmountDue = (supplier.amountDue ?? 0) - amount;

      // 3. إنشاء كائن جديد بالبيانات المحدثة
      final updatedSupplier = SupplierModel(
        supplierID: supplier.supplierID,
        supplierName: supplier.supplierName,
        itemsName: supplier.itemsName,
        quantity: supplier.quantity,
        price: supplier.price,
        status: newAmountDue <= 0
            ? 'Paid'
            : supplier.status, // تحديث الحالة إذا تم الدفع بالكامل
        amountPaid: newAmountPaid,
        amountDue: newAmountDue,
        date: supplier.date,
        userID: supplier.userID,
      );

      // 4. تحديث البيانات في قاعدة البيانات
      await _supplierService.updateSupplier(updatedSupplier);
      _showSuccess('تم تسجيل الدفعة بنجاح');
    });
  }

  /// دالة مساعدة لتجنب تكرار الكود
  Future<void> _performDbOperation(Future<void> Function() operation) async {
    try {
      isLoading.value = true;
      await operation();
      await fetchAllSuppliers(); // تحديث القائمة بعد أي عملية
      await fetchStats(); // تحديث الإحصاءات أيضاً
    } catch (e) {
      _showError('فشلت العملية: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
