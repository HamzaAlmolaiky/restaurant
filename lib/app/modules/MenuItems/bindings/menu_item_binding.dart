// file: bindings/menu_binding.dart

import 'package:get/get.dart';
import '../../MenuCategories/services/menu_category_service.dart';
import '../controllers/menu_item_controller.dart';
import '../services/menu_item_service.dart';

class MenuItemBinding extends Bindings {
  @override
  void dependencies() {
    // تسجيل الخدمات
    Get.lazyPut<MenuCategoryService>(() => MenuCategoryService.instance);
    Get.lazyPut<MenuItemService>(() => MenuItemService.instance);

    // تسجيل الـ Controller وحقن الخدمات فيه
    Get.lazyPut<MenuItemController>(() => MenuItemController(
          Get.find<MenuCategoryService>(),
          Get.find<MenuItemService>(),
        ));
  }
}
