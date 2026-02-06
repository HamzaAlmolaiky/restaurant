// ignore_for_file: deprecated_member_use, avoid_print, unused_label, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide ObxState;
import '../../../helpers/app_dialogs.dart';
import '../../../helpers/dialog_helpers.dart';
import '../../../widgets/dialogs/custom_form_dialog.dart';
import '../../../widgets/filter_chips_bar.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/responsive_filter_row.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../../widgets/templates/management_screen_template.dart';
import '../../../widgets/totals_footer.dart';
import '../controllers/supplier_controller.dart';
import '../models/supplier_model.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/action_menu.dart';
import '../../../widgets/reactive_grid_section.dart';

class SupplierView extends GetView<SupplierController> {
  const SupplierView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      // ١. تمرير بيانات الترويسة
      title: 'إدارة الموردين',
      subtitle: 'إدارة شاملة للموردين والشركات الموردة',
      actions: [
        PrimaryButton(
          text: 'مورد جديد',
          onPressed: () => _showAddSupplierDialog(context),
          icon: Icons.add,
          backgroundColor: const Color(0xFF667EEA),
        ),
      ],
      statisticsWidget: Obx(() {
        final s = controller.stats.value;
        final total = s?.total ?? 0;
        final orders = s?.purchaseOrdersCount ?? 0;
        final totalPurchases = s?.totalPurchasesValue ?? 0.0;
        final avgRating = s?.avgRating ?? 0.0;
        return StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي الموردين',
              value: '$total',
              icon: Icons.business,
              color: const Color(0xFF10B981),
              subtitle: 'إجمالي المسجلين',
            ),
            StatisticsCard(
              title: 'طلبات الشراء',
              value: '$orders',
              icon: Icons.shopping_bag,
              color: const Color(0xFF3B82F6),
              subtitle: 'إجمالي الطلبات',
            ),
            StatisticsCard(
              title: 'إجمالي المشتريات',
              value: totalPurchases.toStringAsFixed(2),
              icon: Icons.attach_money,
              color: const Color(0xFF8B5CF6),
              subtitle: 'القيمة الإجمالية',
            ),
            StatisticsCard(
              title: 'متوسط التقييم',
              value: avgRating.toStringAsFixed(1),
              icon: Icons.star,
              color: const Color(0xFFF59E0B),
              subtitle: 'من 5 نجوم',
            ),
          ],
        );
      }),

      // ٢. تمرير قائمة الفلاتر
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في الموردين...',
          onChanged: (v) => controller.searchSuppliers(v),
          focusedBorderColor: const Color(0xFF667EEA),
        ),
        StyledDropdownFormField<String>(
          labelText: 'النوع',
          value: 'جميع الأنواع', // controller.typeFilter.value
          items: ['جميع الأنواع', 'مواد غذائية', 'مشروبات', 'تجهيزات', 'خدمات']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
        StyledDropdownFormField<String>(
          labelText: 'الحالة',
          value: 'جميع الحالات', // controller.statusFilter.value
          items: ['جميع الحالات', 'نشط', 'غير نشط', 'معلق']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
        StyledDropdownFormField<String>(
          labelText: 'التقييم',
          value: 'جميع التقييمات', // controller.ratingFilter.value
          items: ['جميع التقييمات', '5 نجوم', '4+ نجوم', '3+ نجوم', 'أقل من 3']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
      ],

      // ===================================
      // ٣. تمرير المحتوى الرئيسي (الجسم)
      // ===================================
      body: ReactiveGridSection<SupplierModel>(
        // <-- تحديد نوع البيانات
        isLoading: controller.isLoading, // تمرير المتغير التفاعلي مباشرة
        items: controller.suppliers, // تمرير القائمة التفاعلية مباشرة
        emptyText: 'لا توجد بيانات موردين',
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        // تمرير دالة بناء البطاقة مباشرة
        itemBuilder: (context, supplier) => _buildSupplierCard(supplier),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierModel supplier) {
    return InfoCard(
      leadingWidget: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getStatusColor(supplier.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.business,
          color: _getStatusColor(supplier.status),
          size: 24,
        ),
      ),

      // العنوان الرئيسي للبطاقة
      title: supplier.supplierName ?? 'مورد غير معروف',

      // قائمة التفاصيل
      details: [
        InfoCardDetail(icon: Icons.category_outlined, text: supplier.itemsName),
        InfoCardDetail(
          icon: Icons.inventory_2,
          text: 'الكمية: ${supplier.quantity}',
        ),
        InfoCardDetail(
          icon: Icons.attach_money,
          text: 'السعر: ${supplier.price.toStringAsFixed(2)}',
        ),
        InfoCardDetail(
          icon: Icons.check_circle,
          text: 'مدفوع: ${(supplier.amountPaid ?? 0).toStringAsFixed(2)}',
        ),
        InfoCardDetail(
          icon: Icons.pending,
          text: 'متبقي: ${(supplier.amountDue ?? 0).toStringAsFixed(2)}',
        ),
      ],

      // الويدجت السفلي لعرض شريط التقدم والحالة
      bottomWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط التقدم
          Builder(
            builder: (context) {
              final paid = supplier.amountPaid ?? 0.0;
              final due = supplier.amountDue ?? 0.0;
              final total = (paid + due) == 0 ? 1.0 : (paid + due);
              final pct = paid / total;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      supplier.status == 'Paid'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي: ${(paid + due).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% مدفوع',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // الحالة والتاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(supplier.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  supplier.status == 'Paid'
                      ? 'مدفوع'
                      : supplier.status == 'Unpaid'
                      ? 'غير مدفوع'
                      : supplier.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(supplier.status),
                  ),
                ),
              ),
              Text(
                '${supplier.date.year}-${supplier.date.month.toString().padLeft(2, '0')}-${supplier.date.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),

      // ٢. تمرير قائمة الإجراءات عبر ActionMenu مع نفس المظهر
      menuWidget: ActionMenu(
        trigger: const Icon(Icons.more_vert, color: Colors.grey),
        onSelected: (value) => _handleSupplierAction(value, supplier),
        items: const [
          ActionItem(
            value: 'view',
            text: 'عرض التفاصيل',
            icon: Icons.visibility,
            color: Colors.blue,
          ),
          ActionItem(
            value: 'edit',
            text: 'تعديل',
            icon: Icons.edit,
            color: Colors.orange,
          ),
          ActionItem(
            value: 'orders',
            text: 'طلبات الشراء',
            icon: Icons.shopping_bag,
            color: Colors.green,
          ),
          ActionItem(
            value: 'contact',
            text: 'اتصال',
            icon: Icons.phone,
            color: Colors.blue,
          ),
          ActionItem(
            value: 'delete',
            text: 'حذف',
            icon: Icons.delete,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'نشط':
        return const Color(0xFF10B981);
      case 'غير نشط':
        return const Color(0xFFEF4444);
      case 'معلق':
        return const Color(0xFFF59E0B);
      case 'Paid':
        return const Color(0xFF10B981);
      case 'Unpaid':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  void _handleSupplierAction(String action, SupplierModel supplier) {
    switch (action) {
      case 'view':
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(supplier.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.business,
                    color: _getStatusColor(supplier.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    supplier.supplierName ?? 'تفاصيل المورد',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(supplier.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    supplier.status == 'Paid'
                        ? 'مدفوع'
                        : supplier.status == 'Unpaid'
                        ? 'غير مدفوع'
                        : supplier.status,
                    style: TextStyle(
                      color: _getStatusColor(supplier.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text('الصنف: ${supplier.itemsName}')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('الكمية: ${supplier.quantity}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('السعر: ${supplier.price.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final paid = supplier.amountPaid ?? 0.0;
                      final due = supplier.amountDue ?? 0.0;
                      final total = (paid + due) == 0 ? 1.0 : (paid + due);
                      final pct = paid / total;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              supplier.status == 'Paid'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الإجمالي: ${(paid + due).toStringAsFixed(2)}',
                              ),
                              Text('${(pct * 100).toStringAsFixed(0)}% مدفوع'),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إغلاق'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  Get.back();
                  _showEditSupplierDialog(Get.context!, supplier);
                },
                label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
        break;
      case 'edit':
        _showEditSupplierDialog(Get.context!, supplier);
        break;
      case 'orders':
        _showSupplierOrdersDialog(Get.context!, supplier);
        break;
      case 'contact':
        _showContactSupplierDialog(Get.context!, supplier);
        break;
      case 'delete':
        _confirmDeleteSupplier(Get.context!, supplier);
        break;
    }
  }

  void _showAddSupplierDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final itemCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0.00');

    // استخدام ValueNotifier لإدارة الحالة البسيطة
    final statusNotifier = ValueNotifier<String>('Unpaid');
    final totalNotifier = ValueNotifier<double>(0.0);

    // دالة لحساب الإجمالي
    void calculateTotal() {
      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      totalNotifier.value = qty * price;
    }

    // إضافة مستمعين للتحديث التلقائي
    qtyCtrl.addListener(calculateTotal);
    priceCtrl.addListener(calculateTotal);

    final Widget footerWidget = ValueListenableBuilder<double>(
      valueListenable: totalNotifier,
      builder: (context, total, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي المتوقع',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                total.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        );
      },
    );

    Get.dialog(
      CustomFormDialog(
        title: 'إضافة مورد جديد',
        subtitle: 'أدخل بيانات المورد والفاتورة الأولية',
        icon: Icons.business,
        iconColor: const Color(0xFF667EEA),
        formKey: formKey,

        formFields: [
          buildStyledTextFormField(
            controller: nameCtrl,
            labelText: 'اسم المورد',
            prefixIcon: Icons.person_outline,
          ),
          buildStyledTextFormField(
            controller: itemCtrl,
            labelText: 'اسم الصنف/الخدمة',
            prefixIcon: Icons.inventory_2_outlined,
          ),
          // يمكنك بناء Row يدويًا للحقول المتجاورة
          Row(
            children: [
              Expanded(
                child: buildStyledTextFormField(
                  controller: qtyCtrl,
                  labelText: 'الكمية',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  validationType: ValidationType.number,
                  customValidationMessage: 'ادخل كمية صحيحة',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildStyledTextFormField(
                  controller: priceCtrl,
                  labelText: 'السعر',
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validationType: ValidationType.decimal,
                  customValidationMessage: 'ادخل سعر صحيح',
                ),
              ),
            ],
          ),
        ],
        // ٣. تمرير الويدجت السفلي الذي قمنا ببنائه
        footer: footerWidget,

        // ٤. تمرير دالة الحفظ
        onConfirm: () {
          final qty = double.parse(qtyCtrl.text.trim());
          final price = double.parse(priceCtrl.text.trim());
          final total = price * qty;
          final status = statusNotifier.value;
          final model = SupplierModel(
            supplierName: nameCtrl.text.trim(),
            itemsName: itemCtrl.text.trim(),
            quantity: qty,
            price: price,
            status: status,
            amountPaid: status == 'Paid' ? total : 0,
            amountDue: status == 'Unpaid' ? total : 0,
            date: DateTime.now(),
            userID: 1, // مؤقتاً، يجب تغييره حسب المستخدم الحالي
          );
          controller.addSupplier(model);
          Get.back();
        },
      ),
    );
  }

  void _showEditSupplierDialog(BuildContext context, SupplierModel supplier) {
    final controller = Get.find<SupplierController>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: supplier.supplierName ?? '');
    final itemCtrl = TextEditingController(text: supplier.itemsName);
    final qtyCtrl = TextEditingController(
      text: supplier.quantity.toStringAsFixed(0),
    );
    final priceCtrl = TextEditingController(
      text: supplier.price.toStringAsFixed(2),
    );
    final statusNotifier = ValueNotifier<String>(supplier.status);
    final totalNotifier = ValueNotifier<double>(
      supplier.quantity * supplier.price,
    );

    void calculateTotal() {
      final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      totalNotifier.value = qty * price;
    }

    qtyCtrl.addListener(calculateTotal);
    priceCtrl.addListener(calculateTotal);

    Get.dialog(
      CustomFormDialog(
        title: 'تعديل المورد',
        subtitle: 'عدِّل بيانات المورد والفاتورة',
        icon: Icons.edit,
        iconColor: const Color(0xFF667EEA),
        formKey: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        confirmButtonText: 'حفظ التغييرات',

        formFields: [
          buildStyledTextFormField(
            controller: nameCtrl,
            labelText: 'اسم المورد',
            prefixIcon: Icons.person_outline,
            validationType: ValidationType.notEmpty, // <-- إضافة تحقق
          ),
          buildStyledTextFormField(
            controller: itemCtrl,
            labelText: 'اسم الصنف/الخدمة',
            prefixIcon: Icons.inventory_2_outlined,
            validationType: ValidationType.notEmpty, // <-- إضافة تحقق
          ),

          ResponsiveFilterRow(
            items: [
              SpacedRowItem(
                child: buildStyledTextFormField(
                  controller: qtyCtrl,
                  labelText: 'الكمية',
                  prefixIcon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  validationType: ValidationType.number,
                ),
              ),
              SpacedRowItem(
                child: buildStyledTextFormField(
                  controller: priceCtrl,
                  labelText: 'السعر',
                  prefixIcon: Icons.attach_money, // <-- أيقونة مناسبة
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validationType: ValidationType.decimal,
                ),
              ),
            ],
          ),
        ],

        optionsSection: ValueListenableBuilder<String>(
          valueListenable: statusNotifier,
          builder: (context, status, _) => FilterChipsBar(
            options: const [
              FilterChipOption(value: 'Unpaid', label: 'غير مدفوع'),
              FilterChipOption(value: 'Paid', label: 'مدفوع'),
            ],
            selected: status,
            onChanged: (newValue) => statusNotifier.value = newValue,
          ),
        ),

        footer: TotalsFooter(
          title: 'إجمالي الفاتورة',
          valueListenable: totalNotifier,
        ),

        onConfirm: () => handleFormSubmission(
          formKey: formKey,
          successMessage: 'تم تحديث بيانات المورد بنجاح',
          submissionFunction: () {
            final updated = SupplierModel(
              supplierID: supplier.supplierID,
              supplierName: nameCtrl.text.trim(),
              itemsName: itemCtrl.text.trim(),
              quantity: double.parse(qtyCtrl.text.trim()),
              price: double.parse(priceCtrl.text.trim()),
              status: statusNotifier.value,
              amountDue: (totalNotifier.value - (supplier.amountPaid ?? 0.0))
                  .clamp(0, double.infinity),
              amountPaid: supplier.amountPaid,
              date: supplier.date,
              userID: supplier.userID,
            );

            return controller.updateSupplier(updated);
            // تنظيف الموارد
            // qtyCtrl.removeListener(calculateTotal);
            // priceCtrl.removeListener(calculateTotal);

            // Get.back();
          },
        ),
      ),
    );
  }

  void _showSupplierOrdersDialog(BuildContext context, SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'طلبات الشراء - ${supplier.supplierName ?? ''}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: FutureBuilder(
            future: controller.getSupplierHistory(supplier.supplierID ?? -1),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Text('فشل في جلب طلبات الشراء');
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return const Text('لا توجد طلبات شراء لهذا المورد');
              }
              return SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final po = orders[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب #${po.purchaseOrderID}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${po.createdAt.year}-${po.createdAt.month.toString().padLeft(2, '0')}-${po.createdAt.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (po.status == 'Paid'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B))
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            po.status,
                            style: TextStyle(
                              color: po.status == 'Paid'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          po.totalAmount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showContactSupplierDialog(
    BuildContext context,
    SupplierModel supplier,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.phone, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            const Text('الاتصال بالمورد'),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم: ${supplier.supplierName ?? 'غير متوفر'}'),
              const SizedBox(height: 8),
              const Text(
                'لا توجد بيانات اتصال محفوظة في المخطط الحالي (هاتف/بريد).',
              ),
              const SizedBox(height: 12),
              const Text(
                'يمكن إضافة حقول الهاتف والبريد لاحقاً لتفعيل الاتصال المباشر.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              final name = supplier.supplierName ?? '';
              if (name.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: name));
                AppDialogs.show('تم', 'تم نسخ اسم المورد إلى الحافظة');
              }
            },
            child: const Text('نسخ الاسم'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(BuildContext context, SupplierModel supplier) {
    final controller = Get.find<SupplierController>();
    ConfirmDialog.show(
      title: 'تأكيد الحذف',
      message:
          'هل أنت متأكد من حذف المورد "${supplier.supplierName ?? ''}"؟ لا يمكن التراجع عن هذه العملية.',
      confirmText: 'حذف',
      confirmColor: const Color(0xFFEF4444),
      icon: Icons.delete_outline,
      onConfirm: () async {
        if (supplier.supplierID != null) {
          await controller.deleteSupplier(supplier.supplierID!);
        }
      },
    );
  }
}
