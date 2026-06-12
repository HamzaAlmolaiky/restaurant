// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helpers/app_dialogs.dart';
import '../../../widgets/filter_bar.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../controllers/order_controller.dart';

class OrderView extends GetView<OrderController> {
  const OrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'إدارة الطلبات',
            subtitle: 'متابعة وإدارة جميع طلبات المطعم',
            actions: [
              PrimaryButton(
                text: 'طلب جديد',
                onPressed: () => Get.toNamed('/sub-main'),
                icon: Icons.add,
                backgroundColor: const Color(0xFF667EEA),
              ),
            ],
            // تم نقل قسم الإحصائيات إلى هنا ليصبح جزءًا من الترويسة
            bottomChild: Obx(() {
              // نفس منطق حساب الإحصائيات يبقى كما هو
              final filtered = controller.filteredOrders;
              final total = filtered.length;
              final now = DateTime.now();
              final today = filtered
                  .where(
                    (o) =>
                        o.orderDate.year == now.year &&
                        o.orderDate.month == now.month &&
                        o.orderDate.day == now.day,
                  )
                  .length;
              final pending = filtered.where((o) => o.amountDue > 0).length;
              final completed = filtered.where((o) => o.amountDue == 0).length;

              // استخدام StatisticsRow لعرض البطاقات
              return StatisticsRow(
                children: [
                  StatisticsCard(
                    title: 'إجمالي الطلبات',
                    value: '$total',
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFF3B82F6),
                    change: '', // تمرير قيمة فارغة لإخفاء مؤشر التغيير
                  ),
                  StatisticsCard(
                    title: 'طلبات اليوم',
                    value: '$today',
                    icon: Icons.today_outlined,
                    color: const Color(0xFF10B981),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'معلقة',
                    value: '$pending',
                    icon: Icons.schedule_outlined,
                    color: const Color(0xFFF59E0B),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'مكتملة',
                    value: '$completed',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF8B5CF6),
                    change: '',
                  ),
                ],
              );
            }),
          ),

          /// Filters Section
          FilterBar(
            children: [
              SearchTextField(
                hintText: 'البحث في الطلبات...',
                onChanged: controller.setSearchQuery,
                focusedBorderColor: const Color(0xFF667EEA),
              ),

              // ٢. استخدام StyledDropdownFormField للحالة
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الحالة', // <-- إضافة labelText
                  value: controller.statusFilter.value,
                  items: ['جميع الحالات', 'مكتمل', 'معلق', 'نقدي', 'آجل']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setStatusFilter(v);
                  },
                ),
              ),

              // ٣. استخدام StyledDropdownFormField للتاريخ
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'التاريخ', // <-- إضافة labelText
                  value: controller.dateFilter.value,
                  items: ['الكل', 'اليوم', 'أمس', 'هذا الأسبوع', 'هذا الشهر']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setDateFilter(v);
                  },
                ),
              ),

              // ٤. زر الأيقونة مع إطاره المخصص
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                // إضافة padding لجعل ارتفاع الزر متوافقًا مع الحقول الأخرى
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: IconButton(
                  onPressed: () => _showAdvancedFiltersDialog(context),
                  icon: const Icon(Icons.filter_list, color: Color(0xFF667EEA)),
                  tooltip: 'المزيد من الفلاتر',
                ),
              ),
            ],
          ),
          // Orders Table
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'رقم الطلب',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'العميل',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'التاريخ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'المبلغ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'الحالة',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'الإجراءات',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Content (real data)
                  Expanded(
                    child: Obx(() {
                      final orders = controller.filteredOrders;
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (orders.isEmpty) {
                        return const Center(child: Text('لا توجد طلبات'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final o = orders[index];
                          final id = o.orderID != null ? '#${o.orderID}' : '#-';
                          final customerName =
                              o.customer?.customerName ??
                              (o.customerID?.toString() ?? '-');
                          final date = o.orderDate
                              .toIso8601String()
                              .split('T')
                              .first;
                          final amount =
                              '${o.totalAmount.toStringAsFixed(2)} ريال';
                          final status = o.amountDue == 0 ? 'مكتمل' : 'معلق';
                          return _buildOrderRow(
                            id,
                            customerName,
                            date,
                            amount,
                            status,
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(
    String orderNumber,
    String customerName,
    String date,
    String amount,
    String status,
  ) {
    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'مكتمل':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'جاري التحضير':
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        break;
      case 'جاري التوصيل':
        statusColor = const Color(0xFF3B82F6);
        statusBgColor = const Color(0xFF3B82F6).withOpacity(0.1);
        break;
      case 'ملغي':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFEF4444).withOpacity(0.1);
        break;
      default: // جديد
        statusColor = const Color(0xFF6B7280);
        statusBgColor = const Color(0xFF6B7280).withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              orderNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customerName,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showOrderDetails(orderNumber),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  color: const Color(0xFF667EEA),
                  tooltip: 'عرض التفاصيل',
                ),
                IconButton(
                  onPressed: () => _editOrder(orderNumber),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.grey[600],
                  tooltip: 'تعديل',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(String orderNumber) async {
    final id = int.tryParse(orderNumber.replaceAll('#', ''));
    if (id == null) {
      AppDialogs.show('خطأ', 'رقم الطلب غير صالح');
      return;
    }
    await controller.fetchOrderDetails(id);
    final o = controller.selectedOrder.value;
    if (o == null) {
      AppDialogs.show('خطأ', 'تعذر تحميل تفاصيل الطلب');
      return;
    }
    Get.dialog(_OrderDetailsDialog(controller: controller));
  }

  void _showAdvancedFiltersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.filter_alt, color: Color(0xFF667EEA)),
              SizedBox(width: 8),
              Text('خيارات التصفية الإضافية'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'البحث يبحث في: رقم الطلب، اسم العميل، والملاحظات.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'حالة التصفية الحالية:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(() => Text('• البحث الحالي: ${controller.searchQuery.value.isEmpty ? "لا يوجد" : controller.searchQuery.value}')),
              Obx(() => Text('• فلتر الحالة: ${controller.statusFilter.value}')),
              Obx(() => Text('• فلتر التاريخ: ${controller.dateFilter.value}')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.setSearchQuery('');
                controller.setStatusFilter('جميع الحالات');
                controller.setDateFilter('الكل');
                Navigator.of(context).pop();
                AppDialogs.show('تمت العملية', 'تم إعادة تعيين جميع الفلاتر');
              },
              child: const Text('إعادة تعيين الفلاتر', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _editOrder(String orderNumber) async {
    final id = int.tryParse(orderNumber.replaceAll('#', ''));
    if (id == null) {
      AppDialogs.show('خطأ', 'رقم الطلب غير صالح');
      return;
    }
    await controller.fetchOrderDetails(id);
    final o = controller.selectedOrder.value;
    if (o == null) {
      AppDialogs.show('خطأ', 'تعذر تحميل بيانات الطلب للتعديل');
      return;
    }
    Get.dialog(_EditOrderDialog(orderId: id));
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  final OrderController controller;
  const _OrderDetailsDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final o = controller.selectedOrder.value!;
    final items = controller.currentOrderItems;
    final maxH = MediaQuery.of(context).size.height * 0.8;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700, maxHeight: maxH),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تفاصيل الطلب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _kv('رقم الطلب', '#${o.orderID ?? '-'}'),
                    _kv(
                      'العميل',
                      o.customer?.customerName ??
                          (o.customerID?.toString() ?? '-'),
                    ),
                    _kv(
                      'التاريخ',
                      o.orderDate.toIso8601String().split('T').first,
                    ),
                    _kv('طريقة الدفع', o.paymentMethod),
                    _kv('الإجمالي', o.totalAmount.toStringAsFixed(2)),
                    _kv('المدفوع', o.amountPaid.toStringAsFixed(2)),
                    _kv('المستحق', o.amountDue.toStringAsFixed(2)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'العناصر',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Obx(() {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('لا توجد عناصر'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        final qty = it.quantity;
                        final price = it.price;
                        final total = (qty * price);
                        return ListTile(
                          dense: true,
                          title: Text(
                            it.menuItem?.itemsName ?? 'عنصر #${it.menuItemsID}',
                          ),
                          subtitle: Text(
                            'الكمية: $qty  |  السعر: ${price.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            total.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('إغلاق'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.dialog(_EditOrderDialog(orderId: o.orderID ?? 0));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تعديل'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$k: ', style: const TextStyle(color: Colors.grey)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EditOrderDialog extends StatelessWidget {
  final int orderId;
  const _EditOrderDialog({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الطلب'),
      content: const Text('هل تريد فتح الطلب في واجهة نقاط البيع لتعديله؟'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            Get.toNamed('/sub-main', arguments: {'orderId': orderId});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
          ),
          child: const Text('فتح واجهة POS'),
        ),
      ],
    );
  }
}
