// ignore_for_file: deprecated_member_use, use_build_context_synchronously

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
import '../controllers/menu_category_controller.dart';
import '../../MenuItems/controllers/menu_item_controller.dart';
import '../models/menu_category_model.dart';

class MenuCategoryView extends GetView<MenuCategoryController> {
  const MenuCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // للحصول على عدادات المنتجات عبر كونترولر العناصر إن كان مسجلاً
    final hasItemsController = Get.isRegistered<MenuItemController>();
    final itemsController = hasItemsController
        ? Get.find<MenuItemController>()
        : null;
    // ضمان تسجيل MenuCategoryController لتفادي أخطاء الربط بعد Hot Reload
    if (!Get.isRegistered<MenuCategoryController>()) {
      Get.put(MenuCategoryController());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'فئات القائمة',
            subtitle: 'إدارة وتنظيم فئات الأطعمة والمشروبات',
            actions: [
              PrimaryButton(
                text: 'فئة جديدة',
                onPressed: () => _showAddCategoryDialog(context),
                icon: Icons.add,
                backgroundColor: const Color(0xFF667EEA),
              ),
            ],
            // تم دمج قسم الإحصائيات هنا ليصبح جزءًا من الترويسة
            bottomChild: Obx(() {
              // كل منطق حساب الإحصائيات الديناميكي يبقى كما هو
              final hasItems = Get.isRegistered<MenuItemController>();
              final itemsCtrl = hasItems
                  ? Get.find<MenuItemController>()
                  : null;
              final q = controller.searchQuery.value.trim();
              final status = controller.statusFilter.value;
              final sort = controller.sortOption.value;
              final allCats = controller.categories.toList();
              List<MenuCategoryModel> filtered = allCats.where((c) {
                final matchText =
                    q.isEmpty ||
                    c.categoryName.toLowerCase().contains(q.toLowerCase());
                if (!matchText) return false;
                if (status == 'جميع الحالات') return true;
                final cnt =
                    itemsCtrl?.allItems
                        .where((it) => it.categoryID == c.categoryID)
                        .length ??
                    0;
                return status == 'نشطة' ? cnt > 0 : cnt == 0;
              }).toList();
              filtered.sort((a, b) {
                final aCount =
                    itemsCtrl?.allItems
                        .where((it) => it.categoryID == a.categoryID)
                        .length ??
                    0;
                final bCount =
                    itemsCtrl?.allItems
                        .where((it) => it.categoryID == b.categoryID)
                        .length ??
                    0;
                switch (sort) {
                  case 'الأقدم':
                    return (a.categoryID ?? 0).compareTo(b.categoryID ?? 0);
                  case 'الأكثر منتجات':
                    return bCount.compareTo(aCount);
                  case 'الأقل منتجات':
                    return aCount.compareTo(bCount);
                  case 'الأحدث':
                  default:
                    return (b.categoryID ?? 0).compareTo(a.categoryID ?? 0);
                }
              });
              final totalCats = filtered.length;
              int totalItems = 0;
              int maxCount = 0;
              String topCategory = totalCats == 0
                  ? '-'
                  : filtered.first.categoryName;
              for (final c in filtered) {
                final cnt =
                    itemsCtrl?.allItems
                        .where((it) => it.categoryID == c.categoryID)
                        .length ??
                    0;
                totalItems += cnt;
                if (cnt > maxCount) {
                  maxCount = cnt;
                  topCategory = c.categoryName;
                }
              }
              final avgPerCat = totalCats == 0 ? 0 : (totalItems / totalCats);

              // استخدام StatisticsRow لعرض البطاقات بالبيانات المحسوبة
              return StatisticsRow(
                children: [
                  StatisticsCard(
                    title: 'إجمالي الفئات',
                    value: '$totalCats',
                    icon: Icons.category,
                    color: const Color(0xFF667EEA),
                    subtitle: 'عدد الفئات',
                  ),
                  StatisticsCard(
                    title: 'إجمالي المنتجات',
                    value: '$totalItems',
                    icon: Icons.restaurant_menu,
                    color: const Color(0xFF10B981),
                    subtitle: 'منتج ضمن النتائج',
                  ),
                  StatisticsCard(
                    title: 'أكبر فئة (عناصر)',
                    value: topCategory,
                    icon: Icons.trending_up,
                    color: const Color(0xFFF59E0B),
                    subtitle: maxCount > 0 ? '$maxCount منتج' : '-',
                  ),
                  StatisticsCard(
                    title: 'متوسط المنتجات/فئة',
                    value: avgPerCat.toStringAsFixed(1),
                    icon: Icons.analytics,
                    color: const Color(0xFF8B5CF6),
                    subtitle: 'متوسط ضمن النتائج',
                  ),
                ],
              );
            }),
          ),

          /// Filters Section
          FilterBar(
            children: [
              // ١. حقل البحث
              SearchTextField(
                hintText: 'البحث في الفئات...',
                onChanged: (val) => controller.searchQuery.value = val,
                focusedBorderColor: const Color(0xFF667EEA),
              ),

              // ٢. قائمة فلترة الحالة
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الحالة',
                  value: controller.statusFilter.value,
                  items: ['جميع الحالات', 'نشطة', 'غير نشطة']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      controller.statusFilter.value = val ?? 'جميع الحالات',
                ),
              ),

              // ٣. قائمة فلترة الترتيب
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الترتيب',
                  value: controller.sortOption.value,
                  items: ['الأحدث', 'الأقدم', 'الأكثر منتجات', 'الأقل منتجات']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      controller.sortOption.value = val ?? 'الأحدث',
                ),
              ),
            ],
          ),
          // Categories Grid
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Obx(() {
                if (controller.categories.isEmpty) {
                  return const Center(child: Text('لا توجد فئات'));
                }
                // تطبيق الفلترة والترتيب
                final allCats = controller.categories.toList();
                final q = controller.searchQuery.value.trim();
                List<MenuCategoryModel> filtered = allCats.where((c) {
                  final matchText =
                      q.isEmpty ||
                      c.categoryName.toLowerCase().contains(q.toLowerCase());
                  if (!matchText) return false;
                  final status = controller.statusFilter.value;
                  if (status == 'جميع الحالات') return true;
                  final cnt =
                      itemsController?.allItems
                          .where((it) => it.categoryID == c.categoryID)
                          .length ??
                      0;
                  return status == 'نشطة' ? cnt > 0 : cnt == 0;
                }).toList();

                // ترتيب
                final sort = controller.sortOption.value;
                filtered.sort((a, b) {
                  final aCount =
                      itemsController?.allItems
                          .where((it) => it.categoryID == a.categoryID)
                          .length ??
                      0;
                  final bCount =
                      itemsController?.allItems
                          .where((it) => it.categoryID == b.categoryID)
                          .length ??
                      0;
                  switch (sort) {
                    case 'الأقدم':
                      return (a.categoryID ?? 0).compareTo(b.categoryID ?? 0);
                    case 'الأكثر منتجات':
                      return bCount.compareTo(aCount);
                    case 'الأقل منتجات':
                      return aCount.compareTo(bCount);
                    case 'الأحدث':
                    default:
                      return (b.categoryID ?? 0).compareTo(a.categoryID ?? 0);
                  }
                });

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    final itemsCount =
                        itemsController?.allItems
                            .where((it) => it.categoryID == category.categoryID)
                            .length ??
                        0;
                    return _buildCategoryCard(context, category, itemsCount);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    MenuCategoryModel category,
    int itemCount,
  ) {
    // مظهر اختياري ثابت الآن؛ يمكن لاحقاً حفظ اللون/الأيقونة ضمن الفئة
    final Color baseColor = const Color(0xFF667EEA);
    const IconData icon = Icons.category;
    final String name = category.categoryName;
    final int categoryId = category.categoryID ?? 0;
    final String status = itemCount > 0 ? 'نشطة' : 'غير نشطة';
    return GridCard(
      menuIconColor: Colors.white,
      // تمرير قائمة الإجراءات
      menuItems: [
        buildPopupMenuItem(
          value: 'edit',
          icon: Icons.edit,
          text: 'تعديل الفئة',
        ),
        buildPopupMenuItem(
          value: 'delete',
          icon: Icons.delete,
          text: 'حذف الفئة',
          isDestructive: true,
        ),
      ],
      // دالة التعامل مع اختيار عنصر من القائمة
      onMenuItemSelected: (value) {
        if (value == 'edit') {
          _showEditCategoryDialog(context, categoryId, name);
        } else if (value == 'delete') {
          controller.deleteCategory(categoryId);
        }
      },

      // المحتوى الداخلي للبطاقة
      child: Column(
        children: [
          // Category Header with Image/Icon
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    baseColor.withOpacity(0.8),
                    baseColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Category Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // لمحاذاة العناصر بشكل أفضل
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount منتج',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          ),
                        ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'نشطة':
        return const Color(0xFF10B981);
      case 'غير نشطة':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final txt = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('إضافة فئة جديدة'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: txt,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitAdd(ctx, txt.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _submitAdd(ctx, txt.text),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _submitAdd(BuildContext ctx, String name) {
    controller.addCategoryWithValidation(name).then((_) {
      Navigator.of(ctx).pop();
    });
  }

  void _showEditCategoryDialog(
    BuildContext context,
    int categoryId,
    String categoryName,
  ) {
    final txt = TextEditingController(text: categoryName);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('تعديل الفئة'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: txt,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitEdit(ctx, categoryId, txt.text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => _submitEdit(ctx, categoryId, txt.text),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  void _submitEdit(BuildContext ctx, int id, String name) {
    controller.updateCategoryWithValidation(id, name).then((_) {
      Navigator.of(ctx).pop();
    });
  }
}
