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
      statisticsWidget: StatisticsRow(
        children: [
          StatisticsCard(
            title: 'إجمالي المدفوعات',
            value: '89,340 ريال',
            icon: Icons.payments,
            color: const Color(0xFF10B981),
            subtitle: 'هذا الشهر',
          ),
          StatisticsCard(
            title: 'المدفوعات المعلقة',
            value: '12,450 ريال',
            icon: Icons.pending,
            color: const Color(0xFFF59E0B),
            subtitle: '23 فاتورة',
          ),
          StatisticsCard(
            title: 'المدفوعات اليوم',
            value: '5,680 ريال',
            icon: Icons.today,
            color: const Color(0xFF3B82F6),
            subtitle: '14 عملية',
          ),
          StatisticsCard(
            title: 'متوسط الدفعة',
            value: '245 ريال',
            icon: Icons.analytics,
            color: const Color(0xFF8B5CF6),
            subtitle: 'آخر 30 يوم',
          ),
        ],
      ),
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
              onSelected: (String value) {
                // Handle action
              },
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
                  value: 'receipt',
                  child: Row(
                    children: [
                      Icon(Icons.receipt, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('طباعة الإيصال'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refund',
                  child: Row(
                    children: [
                      Icon(Icons.undo, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('استرداد'),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة دفعة جديدة'),
          content: const SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'العميل',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'رقم الطلب',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
