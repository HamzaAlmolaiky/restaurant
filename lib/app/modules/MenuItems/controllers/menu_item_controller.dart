// file: controllers/menu_item_controller.dart

import 'package:get/get.dart';
import '../../MenuCategories/models/menu_category_model.dart';
import '../../MenuCategories/services/menu_category_service.dart';
import '../models/menu_item_model.dart';
import '../services/menu_item_service.dart';
import '../../../helpers/app_dialogs.dart';

class MenuItemController extends GetxController {
  // حقن الخدمات
  final MenuCategoryService _categoryService;
  final MenuItemService _itemService;

  MenuItemController(this._categoryService, this._itemService);

  // --- متغيرات الحالة التفاعلية ---
  var categoriesWithItems = <MenuCategoryModel>[].obs; // للقائمة الرئيسية
  var allCategories = <MenuCategoryModel>[].obs; // قائمة الفئات فقط
  var allItems = <MenuItemModel>[].obs; // قائمة العناصر فقط
  var isLoading = false.obs;

  // --- البحث والفلاتر ---
  // نص البحث
  var searchText = ''.obs;
  // معرف الفئة المختارة (null = جميع الفئات)
  var selectedCategoryId = RxnInt();
  // حالة المنتج (ليست مدعومة في الموديل حالياً، تبقى للواجهة)
  var statusFilter = 'جميع المنتجات'.obs;
  // فلتر السعر
  var priceFilter = 'جميع الأسعار'.obs;
  // العناصر بعد تطبيق الفلاتر
  var filteredItems = <MenuItemModel>[].obs;

  // خيارات القوائم المنسدلة
  List<String> get categoryOptions => [
    'جميع الفئات',
    ...allCategories.map((c) => c.categoryName),
  ];

  String get selectedCategoryLabel {
    final id = selectedCategoryId.value;
    if (id == null) return 'جميع الفئات';
    final cat = _findCategoryByIdOrNull(id);
    return cat?.categoryName ?? 'جميع الفئات';
  }

  final List<String> statusOptions = const [
    'جميع المنتجات',
    'متوفر',
    'غير متوفر',
    'قريباً',
  ];

  final List<String> priceOptions = const [
    'جميع الأسعار',
    'أقل من 20 ريال',
    '20-50 ريال',
    'أكثر من 50 ريال',
  ];

  // تعيينات تفاعلية
  void setSearchText(String value) {
    searchText.value = value;
    applyFilters();
  }

  void setSelectedCategoryByName(String? name) {
    if (name == null || name == 'جميع الفئات') {
      selectedCategoryId.value = null;
    } else {
      final cat = _findCategoryByNameOrNull(name);
      selectedCategoryId.value = cat?.categoryID;
    }
    applyFilters();
  }

  void setSelectedCategoryId(int? id) {
    selectedCategoryId.value = id;
    applyFilters();
  }

  void setStatusFilter(String? value) {
    if (value == null) return;
    statusFilter.value = value;
    applyFilters();
  }

  void setPriceFilter(String? value) {
    if (value == null) return;
    priceFilter.value = value;
    applyFilters();
  }

  void applyFilters() {
    final query = searchText.value.trim();
    final catId = selectedCategoryId.value;
    final price = priceFilter.value;

    Iterable<MenuItemModel> data = allItems;

    // فلتر الفئة
    if (catId != null) {
      data = data.where((item) => item.categoryID == catId);
    }

    // فلتر البحث بالاسم
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      data = data.where(
        (item) => (item.itemsName).toLowerCase().contains(lower),
      );
    }

    // فلتر السعر
    bool inPrice(double p) {
      switch (price) {
        case 'أقل من 20 ريال':
          return p < 20;
        case '20-50 ريال':
          return p >= 20 && p <= 50;
        case 'أكثر من 50 ريال':
          return p > 50;
        default:
          return true;
      }
    }

    data = data.where((item) => inPrice(item.price));

    // ملاحظة: فلتر الحالة غير مطبق لأن الموديل لا يحتوي حالة.

    filteredItems.assignAll(data.toList());
  }

  // الإحصاءات (تعتمد على العناصر بعد الفلترة لتتماشى مع اختيارات المستخدم)
  int get totalProducts => filteredItems.length;

  double get totalValue =>
      filteredItems.fold<double>(0, (sum, item) => sum + (item.price));

  double get avgPrice => totalProducts == 0 ? 0 : totalValue / totalProducts;

  double get minPrice => filteredItems.isEmpty
      ? 0
      : (filteredItems.map((e) => e.price).reduce((a, b) => a < b ? a : b));

  double get maxPrice => filteredItems.isEmpty
      ? 0
      : (filteredItems.map((e) => e.price).reduce((a, b) => a > b ? a : b));

  int get totalCategories => allCategories.length;

  // مساعدين داخليين للعثور على الفئة
  MenuCategoryModel? _findCategoryByNameOrNull(String name) {
    try {
      return allCategories.firstWhere((c) => c.categoryName == name);
    } catch (_) {
      return null;
    }
  }

  MenuCategoryModel? _findCategoryByIdOrNull(int id) {
    try {
      return allCategories.firstWhere((c) => c.categoryID == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات الرئيسية عند بدء التشغيل
    fetchCategoriesWithItems();
    fetchAllCategories();
    fetchAllItems();
  }

  // --- دوال جلب البيانات ---
  /// جلب الفئات مع العناصر التابعة لها
  /// هذه الدالة تعيد قائمة من الفئات مع العناصر التابعة لها
  /// يتم استخدام هذه الدالة لعرض الفئات في الواجهة الرئيسية
  Future<void> fetchCategoriesWithItems() async {
    try {
      isLoading.value = true;
      categoriesWithItems.assignAll(
        await _categoryService.getCategoriesWithItems(),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب القائمة الكاملة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب جميع الفئات
  Future<void> fetchAllCategories() async {
    try {
      isLoading.value = true;
      allCategories.assignAll(await _categoryService.getAllCategories());
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب الفئات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب جميع العناصر
  Future<void> fetchAllItems() async {
    try {
      isLoading.value = true;
      allItems.assignAll(await _itemService.getAllMenuItems());
      // تحديث العناصر المفلترة بعد الجلب
      applyFilters();
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب عناصر القائمة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // --- دوال إدارة الفئات (Categories) ---

  Future<void> addCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) {
      AppDialogs.show('خطأ', 'اسم الفئة مطلوب');
      return;
    }
    // منع التكرار
    final exists = await _categoryService.categoryExists(categoryName.trim());
    if (exists) {
      AppDialogs.show('تنبيه', 'هذه الفئة موجودة مسبقاً');
      return;
    }
    await _performDbOperation(() async {
      await _categoryService.addCategory(
        MenuCategoryModel(categoryName: categoryName),
      );
      AppDialogs.show('نجاح', 'تمت إضافة الفئة');
    });
  }

  Future<void> updateCategory(int categoryId, String categoryName) async {
    if (categoryId <= 0 || categoryName.trim().isEmpty) {
      AppDialogs.show('خطأ', 'بيانات غير صالحة');
      return;
    }
    // منع التكرار مع استثناء نفس الفئة
    final existingByName = await _categoryService.getCategoryByName(
      categoryName.trim(),
    );
    if (existingByName != null && existingByName.categoryID != categoryId) {
      AppDialogs.show('تنبيه', 'يوجد فئة أخرى بنفس الاسم');
      return;
    }
    await _performDbOperation(() async {
      await _categoryService.updateCategory(
        MenuCategoryModel(categoryID: categoryId, categoryName: categoryName),
      );
      AppDialogs.show('نجاح', 'تم تحديث الفئة');
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    if (categoryId <= 0) {
      AppDialogs.show('خطأ', 'معرف الفئة غير صالح');
      return;
    }
    await _performDbOperation(() async {
      // سياسة حذف آمنة: إعادة إسناد العناصر إلى فئة "غير مصنف" إذا وُجدت عناصر مرتبطة
      final count = await _itemService.countItemsInCategory(categoryId);
      int reassigned = 0;
      if (count > 0) {
        // احصل على فئة "غير مصنف" أو أنشئها
        const String uncategorizedName = 'غير مصنف';
        var defaultCat = await _categoryService.getCategoryByName(
          uncategorizedName,
        );
        if (defaultCat == null) {
          final newId = await _categoryService.addCategory(
            MenuCategoryModel(categoryName: uncategorizedName),
          );
          defaultCat = await _categoryService.getCategoryById(newId);
        }
        if (defaultCat?.categoryID == null) {
          throw Exception('تعذر تجهيز فئة غير مصنف لإعادة الإسناد');
        }
        reassigned = await _itemService.reassignItemsCategory(
          categoryId,
          defaultCat!.categoryID!,
        );
      }
      // حذف الفئة بعد المعالجة
      await _categoryService.deleteCategory(categoryId);
      final msg = count > 0
          ? 'تم حذف الفئة وإعادة إسناد $reassigned عنصر إلى "غير مصنف"'
          : 'تم حذف الفئة';
      AppDialogs.show('نجاح', msg);
    });
  }

  // --- دوال إدارة العناصر (Items) ---

  Future<void> addMenuItem(MenuItemModel menuItem) async {
    // التحقق من المدخلات
    if (menuItem.itemsName.trim().isEmpty ||
        menuItem.price <= 0 ||
        menuItem.categoryID <= 0) {
      AppDialogs.show('خطأ', 'بيانات عنصر القائمة غير مكتملة أو غير صالحة');
      return;
    }
    await _performDbOperation(() async {
      await _itemService.addMenuItem(menuItem);
      AppDialogs.show('نجاح', 'تمت إضافة عنصر القائمة');
    });
  }

  Future<void> updateMenuItem(MenuItemModel menuItem) async {
    // التحقق من المدخلات
    if (menuItem.menuItemsID == null || menuItem.menuItemsID! <= 0) {
      AppDialogs.show('خطأ', 'معرف العنصر غير صالح');
      return;
    }
    await _performDbOperation(() async {
      await _itemService.updateMenuItem(menuItem);
      AppDialogs.show('نجاح', 'تم تحديث عنصر القائمة');
    });
  }

  Future<void> deleteMenuItem(int menuItemId) async {
    if (menuItemId <= 0) {
      AppDialogs.show('خطأ', 'معرف العنصر غير صالح');
      return;
    }
    await _performDbOperation(() async {
      await _itemService.deleteMenuItem(menuItemId);
      AppDialogs.show('نجاح', 'تم حذف عنصر القائمة');
    });
  }

  // --- دالة مساعدة لتجنب تكرار الكود ---
  Future<void> _performDbOperation(Future<void> Function() operation) async {
    try {
      isLoading.value = true;
      await operation();
      // إعادة تحميل كل البيانات بعد أي تغيير لضمان التناسق
      await Future.wait([
        fetchCategoriesWithItems(),
        fetchAllCategories(),
        fetchAllItems(),
      ]);
    } catch (e) {
      AppDialogs.show('خطأ في العملية', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
