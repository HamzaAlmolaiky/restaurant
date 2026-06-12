// file: views/customer_payment_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ObxState;
import '../../../widgets/data_table_card.dart';
import '../../../widgets/data_table_header.dart';
import '../../../widgets/obx_state.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../../widgets/templates/management_screen_template.dart';
import '../controllers/customer_payment_controller.dart';

class CustomerPaymentView extends GetView<CustomerPaymentController> {
  const CustomerPaymentView({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    // ١. استخدام القالب الرئيسي للشاشة الذي يجمع كل الأجزاء تلقائيًا
    return ManagementScreenTemplate(
      // --- خصائص الترويسة ---
      title: 'مدفوعات العملاء',
      subtitle: 'إدارة وتتبع جميع مدفوعات العملاء والفواتير',
      actions: [
        PrimaryButton(
          text: 'دفعة جديدة',
          onPressed: () => _showAddPaymentDialog(context),
          icon: Icons.add,
          backgroundColor: const Color(0xFF10B981),
        ),
      ],
      // --- قسم الإحصائيات ---
      statisticsWidget: Obx(() {
        final stats = controller.paymentStats;
        final total = (stats['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final todayTotal = (stats['todayAmount'] as num?)?.toDouble() ?? 0.0;
        final count = (stats['total'] as num?)?.toInt() ?? 0;
        final avg = count > 0 ? (total / count) : 0.0;
        return StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي المدفوعات',
              value: '${total.toStringAsFixed(0)} ريال',
              icon: Icons.payments,
              color: const Color(0xFF10B981),
              subtitle: 'الإجمالي الكلي',
            ),
            StatisticsCard(
              title: 'عدد الدفعات',
              value: '$count دفعة',
              icon: Icons.format_list_numbered,
              color: const Color(0xFFF59E0B),
              subtitle: 'إجمالي العمليات',
            ),
            StatisticsCard(
              title: 'المدفوعات اليوم',
              value: '${todayTotal.toStringAsFixed(0)} ريال',
              icon: Icons.today,
              color: const Color(0xFF3B82F6),
              subtitle: 'إجمالي اليوم',
            ),
            StatisticsCard(
              title: 'متوسط الدفعة',
              value: '${avg.toStringAsFixed(0)} ريال',
              icon: Icons.analytics,
              color: const Color(0xFF8B5CF6),
              subtitle: 'متوسط إجمالي',
            ),
          ],
        );
      }),
      // --- قسم الفلاتر ---
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في المدفوعات...',
          onChanged: controller.searchPayments,
          focusedBorderColor: const Color(0xFF10B981),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'الحالة',
            value: controller.selectedStatus.value,
            items: ['الكل', 'مكتمل', 'معلق', 'مرفوض']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectedStatus.value = value;
            },
          ),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'طريقة الدفع',
            value: controller.selectedMethod.value,
            items: ['الكل', 'نقدي', 'بطاقة', 'تحويل', 'محفظة إلكترونية']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectedMethod.value = value;
            },
          ),
        ),
      ],
      // ٢. استخدام المكون الجديد DataTableCard للمحتوى الرئيسي
      body: DataTableCard(
        header: DataTableHeader(
          columns: const [
            DataTableColumn(title: 'رقم الدفعة', flex: 2),
            DataTableColumn(title: 'العميل', flex: 2),
            DataTableColumn(title: 'رقم الطلب', flex: 2),
            DataTableColumn(title: 'المبلغ', flex: 2),
            DataTableColumn(title: 'طريقة الدفع', flex: 2),
            DataTableColumn(title: 'الحالة', flex: 2),
            DataTableColumn(title: 'التاريخ', flex: 2),
            DataTableColumn(title: 'الإجراءات', flex: 1),
          ],
        ),
        // ٣. استخدام ObxState لإدارة حالات الواجهة (التحميل، الفراغ) تلقائيًا
        body: Obx(
          () => ObxState(
            isLoading: controller.isLoading.value,
            isEmpty:
                controller.filteredPayments.isEmpty &&
                !controller.isLoading.value,
            hasError: false,
            emptyWidget: const Center(
              child: Text(
                'لا توجد مدفوعات مطابقة',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            child: ListView.builder(
              itemCount: controller.filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = controller.filteredPayments[index];
                // هذه الدالة لديك بالفعل وتقوم ببناء كل صف
                return _buildPaymentRow(payment, index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              (payment['payment_number'] ?? '-').toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (payment['customer_name'] ?? '-').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  (payment['phone'] ?? '-').toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (payment['order_number'] ?? '-').toString(),
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${payment['amount'] ?? 0} ريال',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPaymentMethodColor(
                  (payment['payment_method'] ?? '').toString(),
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (payment['payment_method'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getPaymentMethodColor(
                    (payment['payment_method'] ?? '').toString(),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  (payment['status'] ?? '').toString(),
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (payment['status'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor((payment['status'] ?? '').toString()),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ((payment['created_at'] ?? payment['payment_date'] ?? '')
                      .toString()
                      .replaceFirst('T', ' ')
                      .split('.')
                      .first)
                  .toString(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
              onSelected: (String action) =>
                  _handlePaymentAction(action, payment),
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      SizedBox(width: 8),
                      Text('عرض التفاصيل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 8),
                      Text('تعيين مكتمل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('رفض الدفعة'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'حذف',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentAction(
    String action,
    Map<String, dynamic> payment,
  ) {
    final id = payment['id'] ?? payment['PaymentID'] ?? 0;
    switch (action) {
      case 'view':
        Get.dialog(
          AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.payment, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('تفاصيل الدفعة'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('رقم الدفعة',
                      (payment['payment_number'] ?? '-').toString()),
                  _detailRow(
                      'العميل', (payment['customer_name'] ?? '-').toString()),
                  _detailRow(
                      'رقم الطلب', (payment['order_number'] ?? '-').toString()),
                  _detailRow('المبلغ',
                      '${payment['amount'] ?? 0} ريال'),
                  _detailRow('طريقة الدفع',
                      (payment['payment_method'] ?? '-').toString()),
                  _detailRow(
                      'الحالة', (payment['status'] ?? '-').toString()),
                  _detailRow(
                      'التاريخ',
                      (payment['created_at'] ??
                              payment['payment_date'] ??
                              '-')
                          .toString()
                          .split('T')
                          .first),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
        break;
      case 'complete':
        if (id != 0) {
          controller.updatePaymentStatus(id, 'مكتمل');
        }
        break;
      case 'reject':
        if (id != 0) {
          controller.updatePaymentStatus(id, 'مرفوض');
        }
        break;
      case 'delete':
        if (id != 0) {
          Get.dialog(
            AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text(
                  'هل أنت متأكد من حذف هذه الدفعة؟ لا يمكن التراجع.'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.deletePayment(id);
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
        break;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return const Color(0xFF10B981);
      case 'معلق':
      case 'معلقة':
        return const Color(0xFFF59E0B);
      case 'مرفوض':
      case 'مرفوضة':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'نقدي':
        return const Color(0xFF10B981);
      case 'بطاقة':
        return const Color(0xFF3B82F6);
      case 'تحويل':
        return const Color(0xFF8B5CF6);
      case 'محفظة إلكترونية':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final customerNameCtrl = TextEditingController();
    final orderNumberCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final methodNotifier = ValueNotifier<String>('نقدي');
    final statusNotifier = ValueNotifier<String>('مكتمل');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_card, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('إضافة دفعة جديدة'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'اسم العميل مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: orderNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم الطلب (اختياري)',
                      prefixIcon: Icon(Icons.receipt_long),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'المبلغ مطلوب';
                      if (double.tryParse(v.trim()) == null) {
                        return 'أدخل قيمة صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: methodNotifier,
                    builder: (_, method, __) =>
                        DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      items: ['نقدي', 'بطاقة', 'تحويل', 'محفظة إلكترونية']
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => methodNotifier.value = v ?? method,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: statusNotifier,
                    builder: (_, status, __) =>
                        DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: ['مكتمل', 'معلق', 'مرفوض']
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => statusNotifier.value = v ?? status,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('حفظ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final paymentData = {
                'customer_name': customerNameCtrl.text.trim(),
                'order_number': orderNumberCtrl.text.trim().isEmpty
                    ? '-'
                    : orderNumberCtrl.text.trim(),
                'amount': double.parse(amountCtrl.text.trim()),
                'payment_method': methodNotifier.value,
                'status': statusNotifier.value,
                'payment_date': DateTime.now().toIso8601String(),
              };
              controller.addPayment(paymentData);
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
