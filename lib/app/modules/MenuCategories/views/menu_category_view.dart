// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:restaurant/app/helpers/app_dialogs.dart';
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
          _showEditCategoryDialog(context, categoryId, name, category.imagePath);
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
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or fallback gradient
                    category.imagePath != null && category.imagePath!.isNotEmpty
                        ? buildAppImage(category.imagePath)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  baseColor.withOpacity(0.8),
                                  baseColor.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(icon, size: 48, color: Colors.white),
                          ),
                    // Dark overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black45,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
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
    final imgTxt = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة فئة جديدة'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم الفئة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: txt,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'مثال: وجبات رئيسية',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('صورة الفئة (رابط أو مسار محلي)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imgTxt,
                            decoration: const InputDecoration(
                              hintText: 'أدخل رابط الصورة أو اختر من جهازك',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null && result.files.single.path != null) {
                              imgTxt.text = result.files.single.path!;
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'تصفح من جهازك',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imgTxt.text.trim().isNotEmpty) ...[
                      const Text('معاينة الصورة:'),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildAppImage(imgTxt.text.trim()),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = txt.text.trim();
                final image = imgTxt.text.trim();
                if (name.isEmpty) {
                  AppDialogs.show('تنبيه', 'اسم الفئة مطلوب');
                  return;
                }
                Navigator.of(ctx).pop();
                await controller.addCategoryWithValidation(
                  name,
                  image.isEmpty ? null : image,
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    int categoryId,
    String categoryName,
    String? categoryImagePath,
  ) {
    final txt = TextEditingController(text: categoryName);
    final imgTxt = TextEditingController(text: categoryImagePath ?? '');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل الفئة'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم الفئة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: txt,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('صورة الفئة (رابط أو مسار محلي)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imgTxt,
                            decoration: const InputDecoration(
                              hintText: 'أدخل رابط الصورة أو اختر من جهازك',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null && result.files.single.path != null) {
                              imgTxt.text = result.files.single.path!;
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'تصفح من جهازك',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imgTxt.text.trim().isNotEmpty) ...[
                      const Text('معاينة الصورة:'),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildAppImage(imgTxt.text.trim()),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = txt.text.trim();
                final image = imgTxt.text.trim();
                if (name.isEmpty) {
                  AppDialogs.show('تنبيه', 'اسم الفئة مطلوب');
                  return;
                }
                Navigator.of(ctx).pop();
                await controller.updateCategoryWithValidation(
                  categoryId,
                  name,
                  image.isEmpty ? null : image,
                );
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }
}
