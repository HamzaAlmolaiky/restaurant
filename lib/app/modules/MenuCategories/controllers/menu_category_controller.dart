import 'package:get/get.dart';

import '../models/menu_category_model.dart';
import '../services/menu_category_service.dart';
import '../../../helpers/app_dialogs.dart';

class MenuCategoryController extends GetxController {
  final MenuCategoryService _categoryService = MenuCategoryService.instance;

  final _categories = <MenuCategoryModel>[].obs;

  // فلاتر وحقول واجهة
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'جميع الحالات'.obs; // [جميع الحالات, نشطة, غير نشطة]
  final RxString sortOption = 'الأحدث'.obs; // [الأحدث, الأقدم, الأكثر منتجات, الأقل منتجات]

  List<MenuCategoryModel> get categories => _categories;

  /// جلب قائمة الفئات
  Future<void> fetchCategories() async {
    try {
      _categories.assignAll(await _categoryService.getAllCategories());
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في جلب قائمة الفئات: ${e.toString()}');
    }
  }

  /// حذف فئة
  Future<void> deleteCategory(int id) async {
    try {
      final ok = await _categoryService.deleteCategory(id);
      if (ok) {
        // إزالة محلية فورية لضمان تحديث الشبكة مباشرة
        _categories.removeWhere((c) => c.categoryID == id);
        // تأكيد التزامن مع قاعدة البيانات
        await fetchCategories();
        AppDialogs.show('تم', 'تم حذف الفئة بنجاح');
      } else {
        AppDialogs.show('تنبيه', 'لم يتم حذف أي سجل');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في حذف الفئة: ${e.toString()}');
    }
  }

  /// تحديث فئة (مع منع التكرار)
  Future<void> updateCategoryWithValidation(int id, String newName, String? imagePath) async {
    try {
      final name = newName.trim();
      if (name.isEmpty) {
        AppDialogs.show('تنبيه', 'اسم الفئة مطلوب');
        return;
      }
      final exists = await _categoryService.getCategoryByName(name);
      if (exists != null && exists.categoryID != id) {
        AppDialogs.show('تنبيه', 'يوجد فئة أخرى بنفس الاسم');
        return;
      }
      final updated = await _categoryService.updateCategory(
        MenuCategoryModel(categoryID: id, categoryName: name, imagePath: imagePath),
      );
      if (updated) {
        await fetchCategories();
        AppDialogs.show('تم', 'تم تحديث الفئة بنجاح');
      } else {
        AppDialogs.show('تنبيه', 'لم يتم تحديث أي سجل');
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في تحديث الفئة: ${e.toString()}');
    }
  }

  /// اضافة فئة (مع منع التكرار)
  Future<void> addCategoryWithValidation(String name, String? imagePath) async {
    try {
      final title = name.trim();
      if (title.isEmpty) {
        AppDialogs.show('تنبيه', 'اسم الفئة مطلوب');
        return;
      }
      final duplicate = await _categoryService.categoryExists(title);
      if (duplicate) {
        AppDialogs.show('تنبيه', 'هذه الفئة موجودة مسبقاً');
        return;
      }
      await _categoryService.addCategory(MenuCategoryModel(categoryName: title, imagePath: imagePath));
      await fetchCategories();
      AppDialogs.show('تم', 'تمت إضافة الفئة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل في إضافة الفئة: ${e.toString()}');
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }
}
