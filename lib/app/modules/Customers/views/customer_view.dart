// file: views/customer_screen.dart

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helpers/dialog_helpers.dart';
import '../../../helpers/ui_helpers.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/filter_chips_bar.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/dialogs/custom_form_dialog.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../../widgets/templates/management_screen_template.dart';
import '../../../widgets/totals_footer.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

class CustomerView extends GetView<CustomerController> {
  const CustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      // ١. تمرير بيانات الترويسة مباشرةً
      title: 'إدارة العملاء',
      subtitle: 'متابعة وإدارة بيانات العملاء وتاريخ طلباتهم',
      actions: [
        PrimaryButton(
          text: 'كشف حساب',
          onPressed: () => _showCustomerDetails, // يجب أن تكون دالة
          icon: Icons.receipt_long, // أيقونة أنسب
        ),
        PrimaryButton(
          text: 'عميل جديد',
          onPressed: () => _showAddCustomerDialog(context),
          icon: Icons.person_add,
        ),
        IconButton(
          onPressed: () => controller.fetchAllCustomers(),
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
      // ٢. تمرير ويدجت الإحصائيات كما هو
      statisticsWidget: Obx(
        () => StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي العملاء',
              value: '${controller.customers.length}',
              icon: Icons.people_outline,
              color: const Color(0xFF3B82F6),
              change: '+18%',
            ),
            StatisticsCard(
              title: 'عملاء جدد',
              value: '${controller.getNewCustomersCount()}',
              icon: Icons.person_add_outlined,
              color: const Color(0xFF10B981),
              change: '${controller.getAverageNewCustomers()}%',
            ),
            StatisticsCard(
              title: 'عملاء نشطون',
              value: '${controller.getActiveCustomersCount()}',
              icon: Icons.trending_up_outlined,
              color: const Color(0xFF8B5CF6),
              change: '${controller.getAverageActiveCustomers()}%',
            ),
            StatisticsCard(
              title: 'متوسط الطلبات',
              value: controller.getAverageOrdersPerCustomer().toStringAsFixed(
                1,
              ),
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFFF59E0B),
              change: '${controller.getAverageOrdersPerCustomer()}%',
            ),
          ],
        ),
      ),

      // ٣. تمرير قائمة ويدجتات الفلاتر
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث عن عميل...',
          onChanged: (value) => controller.searchQuery.value = value,
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'النوع',
            value: controller.typeFilter.value,
            items: ['جميع العملاء', 'عملاء VIP', 'عملاء جدد', 'عملاء نشطون']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (v) => controller.typeFilter.value = v!,
          ),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'المنطقة',
            value: controller.regionFilter.value,
            items: ['جميع المناطق', 'الرياض', 'جدة', 'الدمام', 'مكة']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (v) => controller.regionFilter.value = v!,
          ),
        ),
      ],

      // ٤. عرض الشبكة بشكل تفاعلي (filteredCustomers هي getter عادي يحتاج Obx)
      body: Obx(() {
        final items = controller.filteredCustomers;
        if (controller.isLoading.value && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Center(
            child: Text('لا يوجد عملاء لعرضهم حاليًا. ابدأ بإضافة عميل جديد.'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildCustomerCard(items[index]),
        );
      }),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    final bool isPositiveBalance = customer.currentBalance >= 0;

    return InfoCard(
      // ١. تمرير البيانات الخام فقط
      avatarLetter: customer.customerName.isNotEmpty
          ? customer.customerName[0]
          : 'ع',
      avatarColor: const Color(0xFF667EEA),
      title: customer.customerName,

      // قائمة من بيانات التفاصيل
      details: [
        if (customer.phoneNumber != null && customer.phoneNumber!.isNotEmpty)
          InfoCardDetail(icon: Icons.phone, text: customer.phoneNumber!),
        InfoCardDetail(
          icon: Icons.calendar_today,
          text: 'انضم: ${_formatDate(customer.registrationDate)}',
        ),
      ],
      notes: customer.notes,

      // بيانات الجزء السفلي
      bottomTitle1: 'الرصيد',
      bottomValue1: '${customer.currentBalance.toStringAsFixed(2)} ريال',
      bottomValue1Color: isPositiveBalance
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444),
      bottomTitle2: 'الحالة',
      bottomValue2: Container(
        // <-- مثال على تمرير ويدجت مخصص
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isPositiveBalance
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isPositiveBalance ? 'نشط' : 'مدين',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // ٢. تمرير الإجراءات
      menuItems: [
        buildPopupMenuItem(
          value: 'view',
          icon: Icons.visibility_outlined,
          text: 'عرض',
          color: const Color(0xFF10B981),
        ),
        buildPopupMenuItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          text: 'تعديل',
        ),
        buildPopupMenuItem(
          value: 'delete',
          icon: Icons.delete_outline,
          text: 'حذف',
          isDestructive: true,
        ),
      ],
      onMenuItemSelected: (value) => _handleCustomerAction(value, customer),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleCustomerAction(String action, CustomerModel customer) {
    switch (action) {
      case 'view':
        _showCustomerDetails(customer);
        break;
      case 'edit':
        _showEditCustomerDialog(customer);
        break;
      case 'delete':
        _showDeleteConfirmation(customer);
        break;
    }
  }

  void _showCustomerDetails(CustomerModel customer) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            const Text('تفاصيل العميل'),
            const Spacer(),
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('الاسم', customer.customerName),
              _buildDetailRow('رقم الهاتف', customer.phoneNumber ?? 'غير محدد'),
              _buildDetailRow(
                'الرصيد الحالي',
                '${customer.currentBalance.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'تاريخ التسجيل',
                _formatDate(customer.registrationDate),
              ),
              if (customer.notes != null && customer.notes!.isNotEmpty)
                _buildDetailRow('ملاحظات', customer.notes!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(CustomerModel customer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.customerName);
    final phoneController = TextEditingController(
      text: customer.phoneNumber ?? '',
    );
    final balanceController = TextEditingController(
      text: customer.currentBalance.toStringAsFixed(2),
    );
    final notesController = TextEditingController(text: customer.notes ?? '');

    Get.dialog(
      CustomFormDialog(
        title: 'تعديل بيانات العميل',
        subtitle: 'يمكنك تحديث معلومات العميل هنا',
        icon: Icons.edit,
        iconColor: const Color(0xFF3B82F6),
        formKey: formKey, // <-- إضافة مفتاح النموذج
        autovalidateMode: AutovalidateMode.onUserInteraction,
        confirmButtonText: 'حفظ التعديلات',

        formFields: [
          buildStyledTextFormField(
            controller: nameController,
            labelText: 'اسم العميل',
            prefixIcon: Icons.person_outlined,
            validationType: ValidationType.notEmpty, // <-- إضافة التحقق
          ),
          buildStyledTextFormField(
            controller: phoneController,
            labelText: 'رقم الهاتف (اختياري)',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validationType: ValidationType.none, // <-- حقل اختياري
          ),
          buildStyledTextFormField(
            controller: balanceController,
            labelText: 'الرصيد الحالي',
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            validationType: ValidationType.decimal, // <-- إضافة التحقق
          ),
          buildStyledTextFormField(
            controller: notesController,
            labelText: 'ملاحظات (اختياري)',
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
            validationType: ValidationType.none, // <-- حقل اختياري
          ),
        ],

        // ٤. نقل منطق الحفظ إلى onConfirm (سيتم تشغيله فقط بعد نجاح التحقق)
        onConfirm: () {
          final updatedCustomer = CustomerModel(
            customerID: customer.customerID,
            customerName: nameController.text.trim(),
            phoneNumber: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            currentBalance:
                double.tryParse(balanceController.text.trim()) ??
                customer.currentBalance,
            registrationDate: customer.registrationDate,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
          );
          controller.updateCustomer(updatedCustomer);
          Get.back();
        },
      ),
    );
  }

  void _showDeleteConfirmation(CustomerModel customer) {
    ConfirmDialog.show(
      title: 'تأكيد الحذف',
      message:
          'هل أنت متأكد من حذف العميل "${customer.customerName}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف',
      onConfirm: () {
        controller.deleteCustomer(customer.customerID!);
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    // استخدام ValueNotifier لإدارة الحالة بشكل تفاعلي
    final balanceTypeNotifier = ValueNotifier<String>('دائن');
    final previewNotifier = ValueNotifier<double>(0.0);

    /// --- ٢. دالة مركزية لتحديث قيمة المعاينة ---
    /// هذه الدالة ستقوم بحساب القيمة النهائية وعرضها في الفوتر
    void updatePreview() {
      final raw = double.tryParse(balanceCtrl.text.trim()) ?? 0.0;
      previewNotifier.value = balanceTypeNotifier.value == 'مدين'
          ? -raw.abs()
          : raw.abs();
    }

    // --- ٣. ربط المستمعات ---
    // استمع لأي تغيير في حقل الرصيد أو نوع الرصيد لتحديث المعاينة تلقائيًا
    balanceCtrl.addListener(updatePreview);
    balanceTypeNotifier.addListener(updatePreview);

    Get.dialog(
      CustomFormDialog(
        title: 'إضافة عميل جديد',
        subtitle: 'أدخل بيانات العميل الأساسية',
        icon: Icons.person_add,
        iconColor: const Color(0xFF667EEA),
        formKey: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        confirmButtonText: 'إضافة',

        formFields: [
          buildStyledTextFormField(
            controller: nameCtrl,
            labelText: 'اسم العميل',
            prefixIcon: Icons.person_outlined,
            validationType: ValidationType.notEmpty, // استخدام النوع المدمج
          ),
          buildStyledTextFormField(
            controller: phoneCtrl,
            labelText: 'رقم الهاتف (اختياري)',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validationType: ValidationType.none, // حقل اختياري
          ),
          buildStyledTextFormField(
            controller: balanceCtrl,
            labelText: 'الرصيد الافتتاحي',
            prefixIcon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            validationType: ValidationType.decimal, // تأكد أنه رقم صالح
          ),
          buildStyledTextFormField(
            controller: notesCtrl,
            labelText: 'ملاحظات (اختياري)',
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
            validationType: ValidationType.none, // حقل اختياري
          ),
        ],

        optionsSection: ValueListenableBuilder<String>(
          valueListenable: balanceTypeNotifier,
          builder: (context, selectedValue, _) => FilterChipsBar(
            options: const [
              FilterChipOption(label: 'دائن (موجب)', value: 'دائن'),
              FilterChipOption(label: 'مدين (سالب)', value: 'مدين'),
            ],
            selected: selectedValue,
            onChanged: (newValue) => balanceTypeNotifier.value = newValue,
          ),
        ),

        footer: TotalsFooter(
          title: 'الرصيد النهائي المحدد',
          valueListenable: previewNotifier,
        ),

        onConfirm: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;

          final finalBalance = previewNotifier.value;

          final model = CustomerModel(
            customerName: nameCtrl.text.trim(),
            phoneNumber: phoneCtrl.text.trim().isEmpty
                ? null
                : phoneCtrl.text.trim(),
            currentBalance: finalBalance,
            registrationDate: DateTime.now(),
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );

          await controller.addCustomer(model);

          // --- ٦. تنظيف الموارد (ممارسة جيدة لتجنب تسريب الذاكرة) ---
          balanceCtrl.removeListener(updatePreview);
          balanceTypeNotifier.removeListener(updatePreview);
          // يمكنك أيضًا عمل dispose() لكل المتحكمات هنا

          Get.back();
        },
      ),
    );
  }
}
