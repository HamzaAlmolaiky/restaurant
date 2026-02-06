// file: views/menu_management_screen.dart

// ignore_for_file: deprecated_member_use, avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helpers/ui_helpers.dart';
import '../../../widgets/filter_bar.dart';
import '../../../widgets/grid_card.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../controllers/menu_item_controller.dart';
import '../models/menu_item_model.dart';
import '../../../helpers/app_dialogs.dart';

class MenuItemView extends GetView<MenuItemController> {
  const MenuItemView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'إدارة القائمة والمنتجات',
            subtitle: 'إدارة فئات ومنتجات المطعم والأسعار والتوفر',
            actions: [
              PrimaryButton(
                text: 'منتج جديد',
                onPressed: () => _showAddProductDialog(context),
                icon: Icons.restaurant_menu,
                backgroundColor: const Color(0xFF10B981),
              ),
            ],
            // تم دمج قسم الإحصائيات هنا ليصبح جزءًا من الترويسة
            bottomChild: Obx(
              () => StatisticsRow(
                children: [
                  StatisticsCard(
                    title: 'إجمالي المنتجات',
                    value: controller.totalProducts.toString(),
                    icon: Icons.restaurant_menu_outlined,
                    color: const Color(0xFF10B981),
                    change: '', // تمرير قيمة فارغة لإخفاء مؤشر التغيير
                  ),
                  StatisticsCard(
                    title: 'متوسط السعر',
                    value: controller.avgPrice.toStringAsFixed(2),
                    icon: Icons.price_change,
                    color: const Color(0xFF8B5CF6),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'القيمة الإجمالية',
                    value: controller.totalValue.toStringAsFixed(2),
                    icon: Icons.summarize,
                    color: const Color(0xFFF59E0B),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'الفئات',
                    value: controller.totalCategories.toString(),
                    icon: Icons.category_outlined,
                    color: const Color(0xFF3B82F6),
                    change: '',
                  ),
                ],
              ),
            ),
          ),

          /// Search and Filters
          FilterBar(
            children: [
              // ١. حقل البحث
              SearchTextField(
                hintText: 'البحث في المنتجات...',
                onChanged: controller.setSearchText,
                // لا حاجة لتحديد لون هنا، سيستخدم اللون الافتراضي
              ),

              // ٢. فلتر الفئات (باستخدام StyledDropdownFormField<int?> المخصص)
              Obx(
                () => StyledDropdownFormField<int?>(
                  labelText: 'الفئة',
                  value: controller.selectedCategoryId.value,
                  // إضافة عنصر "جميع الفئات" يدويًا في بداية القائمة
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null, // القيمة null تمثل "الكل"
                      child: Text('جميع الفئات'),
                    ),
                    ...controller.allCategories.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.categoryID,
                        child: Text(c.categoryName),
                      ),
                    ),
                  ],
                  onChanged: controller.setSelectedCategoryId,
                ),
              ),

              // ٣. فلتر الحالة
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الحالة',
                  value: controller.statusFilter.value,
                  items: controller.statusOptions
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: controller.setStatusFilter,
                ),
              ),

              // ٤. فلتر السعر
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'السعر',
                  value: controller.priceFilter.value,
                  items: controller.priceOptions
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: controller.setPriceFilter,
                ),
              ),
            ],
          ), // Products Grid
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Obx(() {
                if (controller.isLoading.value && controller.allItems.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF667EEA)),
                  );
                }

                if (controller.filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ابدأ بإضافة منتجات جديدة للقائمة',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: controller.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.filteredItems[index];
                    final product = {
                      'id': item.menuItemsID,
                      'name': item.itemsName,
                      'category': item.category?.categoryName ?? 'غير مصنف',
                      'price': item.price,
                      'categoryId': item.categoryID,
                      // حقول افتراضية للحفاظ على الواجهة دون الاعتماد على بيانات تجريبية
                      'status': 'متوفر',
                      'description': '',
                      'isFavorite': false,
                    };
                    return _buildProductCard(context, product);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final String name = product['name'];
    final String category = product['category'];
    final double price = product['price'];
    final String status = product['status'];
    final String description = product['description'];

    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'متوفر':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'غير متوفر':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFEF4444).withOpacity(0.1);
        break;
      default: // قريباً
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
    }
    return GridCard(
      // تمرير قائمة الإجراءات
      menuItems: [
        buildPopupMenuItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          text: 'تعديل',
        ),
        buildPopupMenuItem(
          value: 'duplicate',
          icon: Icons.copy_outlined,
          text: 'نسخ',
        ),
        buildPopupMenuItem(
          value: 'delete',
          icon: Icons.delete_outline,
          text: 'حذف',
          isDestructive: true,
        ),
      ],
      // دالة التعامل مع اختيار عنصر من القائمة
      onMenuItemSelected: (value) =>
          _handleProductAction(context, value, product),

      // المحتوى الداخلي للبطاقة
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleFavorite(product),
                            child: Icon(
                              product['isFavorite']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: product['isFavorite']
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _viewProductDetails(product),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    int? selectedCatId = controller.allCategories.isNotEmpty
        ? controller.allCategories.first.categoryID
        : null;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text('منتج جديد'),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اسم المنتج'),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'مثال: بيتزا مارجريتا',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('السعر'),
                const SizedBox(height: 6),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'مثال: 25.0',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('الفئة'),
                const SizedBox(height: 6),
                StatefulBuilder(
                  builder: (ctx, setState) {
                    final cats = controller.allCategories;
                    return DropdownButtonFormField<int>(
                      value: selectedCatId,
                      items: cats
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.categoryID!,
                              child: Text(c.categoryName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCatId = v),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? -1;
                if (name.isEmpty || price <= 0 || selectedCatId == null) {
                  AppDialogs.show(
                    'تنبيه',
                    'يرجى إدخال اسم صحيح، سعر أكبر من صفر، واختيار فئة',
                  );
                  return;
                }
                Navigator.of(context).pop();
                await controller.addMenuItem(
                  MenuItemModel(
                    itemsName: name,
                    price: price,
                    categoryID: selectedCatId!,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void _handleProductAction(
    BuildContext context,
    String action,
    Map<String, dynamic> product,
  ) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(context, product);
        break;
      case 'duplicate':
        _duplicateProduct(product);
        break;
      case 'delete':
        _confirmDeleteProduct(context, product);
        break;
    }
  }

  void _toggleFavorite(Map<String, dynamic> product) {
    product['isFavorite'] = !product['isFavorite'];
    print('تغيير المفضلة للمنتج: ${product['name']}');
  }

  void _viewProductDetails(Map<String, dynamic> product) {
    print('عرض تفاصيل المنتج: ${product['name']}');
  }

  void _duplicateProduct(Map<String, dynamic> product) async {
    final name = product['name'] as String;
    final price = (product['price'] as num).toDouble();
    final categoryId = product['categoryId'] as int;
    final newItem = MenuItemModel(
      itemsName: '$name (نسخة)',
      price: price,
      categoryID: categoryId,
    );
    await controller.addMenuItem(newItem);
  }

  void _confirmDeleteProduct(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final id = product['id'] as int?;
    if (id == null) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.deleteMenuItem(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final id = product['id'] as int?;
    if (id == null) return;
    final nameController = TextEditingController(
      text: product['name'] as String,
    );
    final priceController = TextEditingController(
      text: (product['price'] as num).toString(),
    );
    int selectedCatId = product['categoryId'] as int;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل المنتج'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الاسم'),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('السعر'),
              const SizedBox(height: 6),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('الفئة'),
              const SizedBox(height: 6),
              Obx(() {
                final cats = controller.allCategories;
                return DropdownButtonFormField<int>(
                  value: selectedCatId,
                  items: cats
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.categoryID!,
                          child: Text(c.categoryName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedCatId = v ?? selectedCatId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? -1;
              if (name.isEmpty || price <= 0) {
                AppDialogs.show(
                  'تنبيه',
                  'يرجى إدخال اسم صحيح وسعر أكبر من صفر',
                );
                return;
              }
              final updated = MenuItemModel(
                menuItemsID: id,
                itemsName: name,
                price: price,
                categoryID: selectedCatId,
              );
              Navigator.of(context).pop();
              await controller.updateMenuItem(updated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
