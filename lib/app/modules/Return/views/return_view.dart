// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';

import 'package:get/get.dart' hide ObxState;
import '../../../helpers/dialog_helpers.dart';
import '../../../widgets/data_table_card.dart';
import '../../../widgets/data_table_header.dart';
import '../../../widgets/data_table_row.dart';
import '../../../widgets/dialogs/custom_form_dialog.dart';
import '../../../widgets/dialogs/details_dialog.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/obx_state.dart';
import '../../../widgets/templates/management_screen_template.dart';

import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../controllers/return_controller.dart';
import '../models/order_return_model.dart';

class ReturnView extends GetView<ReturnController> {
  const ReturnView({super.key});

  // ١. تعريف الأعمدة مرة واحدة كمصدر للحقيقة
  static const List<DataTableColumn> _columns = [
    DataTableColumn(title: 'رقم المرتجع', flex: 2),
    DataTableColumn(title: 'رقم الطلب', flex: 2),
    DataTableColumn(title: 'العميل', flex: 3),
    DataTableColumn(title: 'السبب', flex: 3),
    DataTableColumn(title: 'القيمة', flex: 2),
    DataTableColumn(title: 'التاريخ', flex: 2),
    DataTableColumn(title: 'الإجراءات', flex: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      title: 'إدارة المرتجعات',
      subtitle: 'متابعة وإدارة مرتجعات الطلبات والمنتجات',
      actions: [
        PrimaryButton(
          text: 'مرتجع جديد',
          onPressed: () => _showAddReturnDialog(context),
          icon: Icons.keyboard_return,
          backgroundColor: const Color(0xFFEF4444),
        ),
      ],
      // --- تمرير ويدجت الإحصائيات ---
      statisticsWidget: Obx(
        () => StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي المرتجعات',
              value: '${controller.returnStats['totalReturns'] ?? 0}',
              icon: Icons.keyboard_return,
              color: const Color(0xFFEF4444),
              subtitle: 'إجمالي',
            ),
            StatisticsCard(
              title: 'قيمة المرتجعات',
              value:
                  '${(controller.returnStats['totalValue'] ?? 0.0).toStringAsFixed(0)} ريال',
              icon: Icons.money_off,
              color: const Color(0xFFF59E0B),
              subtitle: 'إجمالي القيمة',
            ),
            StatisticsCard(
              title: 'معدل المرتجعات',
              value:
                  '${(controller.returnStats['returnRate'] ?? 0.0).toStringAsFixed(1)}%',
              icon: Icons.trending_down,
              color: const Color(0xFF8B5CF6),
              subtitle: 'من إجمالي الطلبات',
            ),
            StatisticsCard(
              title: 'مرتجعات اليوم',
              value: '${controller.returnStats['todayReturns'] ?? 0}',
              icon: Icons.today,
              color: const Color(0xFF3B82F6),
              subtitle: 'اليوم',
            ),
          ],
        ),
      ),

      // --- تمرير قائمة الفلاتر ---
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في المرتجعات...',
          onChanged: controller.searchReturns,
          focusedBorderColor: const Color(0xFFEF4444),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'الحالة',
            value: controller.selectedStatus.value,
            items: controller.statuses
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (v) => controller.updateStatusFilter(v!),
          ),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'السبب',
            value: controller.selectedReason.value,
            items: controller.reasons
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (v) => controller.updateReasonFilter(v!),
          ),
        ),
        // فلتر التاريخ
        ElevatedButton.icon(
          onPressed: () => _showDateRangeDialog(),
          icon: const Icon(Icons.date_range),
          label: const Text('فلتر التاريخ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
        ),
        // زر مرتجعات اليوم
        ElevatedButton.icon(
          onPressed: () => controller.fetchTodayReturns(),
          icon: const Icon(Icons.today),
          label: const Text('مرتجعات اليوم'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
        ),
      ],

      // --- تمرير محتوى الجدول ---
      body: DataTableCard(
        header: const DataTableHeader(columns: _columns),
        body: Obx(
          () => ObxState(
            isLoading: controller.isLoading.value,
            isEmpty:
                controller.filteredReturns.isEmpty &&
                !controller.isLoading.value,
            hasError: false,
            child: ListView.builder(
              itemCount: controller.filteredReturns.length,
              itemBuilder: (context, index) {
                final returnModel = controller.filteredReturns[index];
                return _buildReturnRow(returnModel);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ٣. دالة بناء الصف تتعامل الآن مع موديل منظم وتضمن المحاذاة
  Widget _buildReturnRow(OrderReturnModel returnModel) {
    // ملاحظة: ستحتاج إلى إضافة customerName و customerPhone إلى الموديل كما شرحنا سابقًا
    // للحصول عليها من استعلام JOIN في الخدمة.
    final customerName = returnModel.customerName ?? 'غير معروف';
    final customerPhone = returnModel.customerPhone ?? '';

    return DataTableRow(
      columns: _columns,
      cells: [
        // رقم المرتجع
        Text(
          'RT-${returnModel.returnID ?? '-'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // رقم الطلب
        Text('#${returnModel.originalOrderID}'),
        // العميل
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (customerPhone.isNotEmpty)
              Text(
                customerPhone,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        // السبب
        Text(returnModel.returnReason),
        // القيمة
        Text(
          '${returnModel.totalReturnAmount.toStringAsFixed(2)} ريال',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
        // التاريخ
        Text(_formatDate(returnModel.returnDate.toIso8601String())),
        // الإجراءات
        SizedBox(
          width: 120, // تحديد عرض ثابت
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              // زر عرض التفاصيل
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.visibility, color: Color(0xFF3B82F6)),
                  onPressed: () => _viewReturnDetails(returnModel),
                  tooltip: 'عرض التفاصيل',
                ),
              ),
              // زر التحديث
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                  onPressed: () => _showUpdateReturnDialog(returnModel),
                  tooltip: 'تحديث',
                ),
              ),
              // زر الحذف
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                  onPressed: () =>
                      controller.deleteReturn(returnModel.returnID!),
                  tooltip: 'حذف',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showAddReturnDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final orderIdCtrl = TextEditingController();
    final totalAmountCtrl = TextEditingController();

    controller.resetNewReturnForm();

    Get.dialog(
      CustomFormDialog(
        title: 'إضافة مرتجع جديد',
        subtitle: 'أدخل تفاصيل الطلب والعناصر المرتجعة',
        icon: Icons.keyboard_return,
        iconColor: const Color(0xFFEF4444),
        formKey: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        confirmButtonText: 'حفظ المرتجع',

        formFields: [
          // الحقول النصية لا تحتاج إلى Obx
          buildStyledTextFormField(
            controller: orderIdCtrl,
            labelText: 'رقم الطلب الأصلي',
            prefixIcon: Icons.receipt_long,
            keyboardType: TextInputType.number,
            validationType: ValidationType.number,
          ),

          // ٤. تغليف كل قائمة منسدلة بـ Obx الخاص بها
          Obx(
            () => StyledDropdownFormField<String>(
              // استخدام المكون القياسي
              labelText: 'العميل (اختياري)',
              value: (() {
                final v = controller.newReturnCustomerId.value;
                if (v == null) return null;
                final exists = controller.customers.any(
                  (c) => (c['CustomerID']).toString() == v.toString(),
                );
                return exists ? v.toString() : null;
              })(),
              items: controller.customers
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: (c['CustomerID']).toString(),
                      child:
                          Text((c['CustomerName']?.toString() ?? 'بدون اسم')),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                controller.newReturnCustomerId.value =
                    int.tryParse(value ?? '');
              },
            ),
          ),

          Obx(
            () => StyledDropdownFormField<String>(
              // استخدام المكون القياسي
              labelText: 'حالة المرتجع',
              value: controller.newReturnStatus.value,
              items: controller.statuses
                  .where((s) => s != 'الكل')
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => controller.newReturnStatus.value =
                  value ?? controller.statuses[1],
              // يمكنك إضافة prefixIcon هنا إذا كان مكونك يدعمها
            ),
          ),

          Obx(
            () => StyledDropdownFormField<String>(
              labelText: 'سبب الإرجاع',
              value: controller.newReturnReason.value,
              items: controller.reasons
                  .where((r) => r != 'الكل')
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => controller.newReturnReason.value =
                  value ?? controller.reasons[1],
            ),
          ),

          buildStyledTextFormField(
            controller: totalAmountCtrl,
            labelText: 'إجمالي مبلغ المرتجع',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validationType: ValidationType.decimal,
          ),
        ],

        // ٥. استخدام الدالة المساعدة لمعالجة الحفظ بأمان
        onConfirm: () => handleFormSubmission(
          formKey: formKey,
          successMessage: 'تم تسجيل المرتجع بنجاح.',
          submissionFunction: () {
            final returnModel = OrderReturnModel(
              originalOrderID: int.parse(orderIdCtrl.text),
              returnReason: controller.newReturnReason.value,
              totalReturnAmount: double.parse(totalAmountCtrl.text),
              returnDate: DateTime.now(),
              shiftID: 1,
              userID: 1,
              customerID: controller.newReturnCustomerId.value == 0
                  ? null
                  : controller.newReturnCustomerId.value,
              returnStatus: controller.newReturnStatus.value,
              returnItems: [],
            );

            return controller.addReturn(returnModel);
          },
        ),
      ),
    );
  }

  void _viewReturnDetails(OrderReturnModel returnModel) {
    Get.dialog(
      CustomFormDialog(
        title: 'تفاصيل المرتجع RT-${returnModel.returnID ?? '-'}',
        icon: Icons.keyboard_return,
        iconColor: const Color(0xFFEF4444),
        width: 600,
        formKey: GlobalKey<FormState>(),

        formFields: [
          // --- القسم الأول: التفاصيل الأساسية (باستخدام InfoRow) ---
          InfoRow(
            label: 'رقم الطلب الأصلي',
            value: '#${returnModel.originalOrderID}',
            icon: Icons.receipt_long,
          ),
          InfoRow(
            label: 'العميل',
            value: [
              returnModel.customerName ?? 'غير معروف',
              if ((returnModel.customerPhone ?? '').isNotEmpty)
                returnModel.customerPhone!,
            ].join(' - '),
            icon: Icons.person,
          ),
          InfoRow(
            label: 'السبب',
            value: returnModel.returnReason,
            icon: Icons.comment_outlined,
          ),
          InfoRow(
            label: 'المبلغ الإجمالي',
            value: '${returnModel.totalReturnAmount.toStringAsFixed(2)} ريال',
            icon: Icons.attach_money,
          ),
          InfoRow(
            label: 'التاريخ',
            value: _formatDate(returnModel.returnDate.toIso8601String()),
            icon: Icons.calendar_today,
          ),
          InfoRow(
            label: 'تم بواسطة',
            value:
                (returnModel.userName != null &&
                    returnModel.userName!.trim().isNotEmpty)
                ? returnModel.userName!
                : 'غير معروف',
            icon: Icons.admin_panel_settings,
          ),

          // --- القسم الثاني: عناصر المرتجع (باستخدام المكون العام الجديد) ---
          DetailsSection<OrderItemModel>(
            title: 'العناصر المرتجعة',
            future: controller.getOriginalOrderItems(
              returnModel.originalOrderID,
            ),
            emptyWidget: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('لا توجد عناصر لهذا المرتجع.')),
            ),
            // دالة itemBuilder هي المسؤولة فقط عن رسم الصف الواحد
            itemBuilder: (context, item) {
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(
                    Icons.fastfood,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                title: Text('صنف #${item.menuItem!.itemsName}'),
                subtitle: Text(
                  'الكمية: ${item.quantity} × السعر: ${item.price.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  '${(item.quantity * item.price).toStringAsFixed(2)} ريال',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],

        showCloseIcon: true,
        cancelButtonText: 'إغلاق',
        onConfirm: null,
      ),
    );
  }

  void _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.fetchReturnsByDateRange(picked.start, picked.end);
    }
  }

  void _showUpdateReturnDialog(OrderReturnModel returnModel) {
    final formKey = GlobalKey<FormState>();
    final reasonCtrl = TextEditingController(text: returnModel.returnReason);
    final amountCtrl = TextEditingController(
      text: returnModel.totalReturnAmount.toString(),
    );

    // تأكيد أن سبب الإرجاع الحالي موجود ضمن العناصر لتجنب خطأ Dropdown
    final validReasons = controller.reasons.where((r) => r != 'الكل').toList();
    if (!validReasons.contains(reasonCtrl.text)) {
      reasonCtrl.text = validReasons.isNotEmpty ? validReasons.first : '';
    }

    Get.dialog(
      CustomFormDialog(
        title: 'تحديث المرتجع',
        subtitle: 'تعديل تفاصيل المرتجع رقم RT-${returnModel.returnID}',
        icon: Icons.edit,
        iconColor: const Color(0xFF3B82F6),
        formKey: formKey,
        confirmButtonText: 'حفظ التحديث',
        formFields: [
          Obx(
            () => StyledDropdownFormField<String>(
              labelText: 'سبب الإرجاع',
              value: reasonCtrl.text,
              items: controller.reasons
                  .where((r) => r != 'الكل')
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                reasonCtrl.text = value ?? '';
              },
            ),
          ),
          buildStyledTextFormField(
            controller: amountCtrl,
            labelText: 'مبلغ المرتجع',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validationType: ValidationType.decimal,
          ),
        ],
        onConfirm: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;

          try {
            final updatedReturn = OrderReturnModel(
              returnID: returnModel.returnID,
              originalOrderID: returnModel.originalOrderID,
              returnReason: reasonCtrl.text,
              totalReturnAmount: double.parse(amountCtrl.text),
              returnDate: returnModel.returnDate,
              shiftID: returnModel.shiftID,
              userID: returnModel.userID,
              returnItems: returnModel.returnItems,
            );

            await controller.updateReturn(returnModel.returnID!, updatedReturn);
            Get.back();
          } catch (e) {
            String errorMessage = e.toString();
            if (errorMessage.startsWith('Exception: ')) {
              errorMessage = errorMessage.substring(11);
            }
            Get.dialog(
              AlertDialog(
                title: const Text('خطأ'),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('موافق'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // ignore: unused_element
  void _showProcessReturnDialog(OrderReturnModel returnModel) {
    Get.dialog(
      AlertDialog(
        title: const Text('معالجة المرتجع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد معالجة المرتجع رقم RT-${returnModel.returnID}؟'),
            const SizedBox(height: 16),
            Text('المبلغ: ${returnModel.totalReturnAmount} ريال'),
            Text('السبب: ${returnModel.returnReason}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.processReturn(returnModel);
                Get.back();
              } catch (e) {
                String errorMessage = e.toString();
                if (errorMessage.startsWith('Exception: ')) {
                  errorMessage = errorMessage.substring(11);
                }
                Get.back();
                Get.dialog(
                  AlertDialog(
                    title: const Text('خطأ'),
                    content: Text(errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('موافق'),
                      ),
                    ],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            child: const Text('معالجة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
