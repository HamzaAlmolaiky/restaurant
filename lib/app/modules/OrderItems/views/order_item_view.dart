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
import '../controllers/order_item_controller.dart';

class OrderItemView extends GetView<OrderItemController> {
  const OrderItemView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      title: 'عناصر الطلبات',
      subtitle: 'إدارة وتتبع تفاصيل عناصر جميع الطلبات',
      actions: [
        PrimaryButton(
          text: 'عنصر جديد',
          onPressed: () => _showAddItemDialog(context),
          icon: Icons.add,
          backgroundColor: const Color(0xFF3B82F6),
        ),
      ],
      statisticsWidget: Obx(() {
        final stats = controller.orderItemStats;
        String formatNum(num? n, {int fraction = 0}) =>
            n == null ? '0' : n.toStringAsFixed(fraction);
        final top = (stats['topProducts'] as List?)?.cast<Map>() ?? [];
        final topName = top.isNotEmpty
            ? (top.first['itemName']?.toString() ?? 'غير متوفر')
            : 'غير متوفر';
        final topQty = top.isNotEmpty
            ? ((top.first['totalQuantity'] as num?) ?? 0)
            : 0;
        return StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي العناصر',
              value: formatNum(
                (stats['totalItems'] as num?) ??
                    (stats['totalQuantity'] as num?),
              ),
              icon: Icons.inventory,
              color: const Color(0xFF3B82F6),
              subtitle: 'عنصر',
            ),
            StatisticsCard(
              title: 'قيمة العناصر',
              value:
                  '${formatNum((stats['totalRevenue'] as num?) ?? (stats['totalValue'] as num?), fraction: 2)} ريال',
              icon: Icons.attach_money,
              color: const Color(0xFF10B981),
              subtitle: 'إجمالي المبيعات',
            ),
            StatisticsCard(
              title: 'متوسط سعر العنصر',
              value:
                  '${formatNum((stats['avgPrice'] as num?) ?? (stats['averageOrderValue'] as num?), fraction: 2)} ريال',
              icon: Icons.analytics,
              color: const Color(0xFF8B5CF6),
              subtitle: 'متوسط السعر',
            ),
            StatisticsCard(
              title: 'الأكثر مبيعاً',
              value: topName,
              icon: Icons.trending_up,
              color: const Color(0xFFF59E0B),
              subtitle: '${formatNum(topQty)} مرة',
            ),
          ],
        );
      }),

      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في عناصر الطلبات...',
          onChanged: controller.updateSearchQuery,
          focusedBorderColor: const Color(0xFF3B82F6),
        ),
        StyledDropdownFormField<String>(
          labelText: 'الفئة',
          value: 'جميع الفئات',
          items: ['جميع الفئات', 'أطباق رئيسية', 'مقبلات', 'مشروبات', 'حلويات']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {},
        ),
        StyledDropdownFormField<String>(
          labelText: 'حالة الطلب',
          value: 'جميع الحالات',
          items: ['جميع الحالات', 'جديد', 'جاري التحضير', 'جاهز', 'مكتمل']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {},
        ),
        StyledDropdownFormField<String>(
          labelText: 'التاريخ',
          value: 'جميع التواريخ',
          items: ['جميع التواريخ', 'اليوم', 'أمس', 'آخر 7 أيام', 'آخر 30 يوم']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {},
        ),
      ],

      // --- ٣. تمرير محتوى الجدول ---
      body: DataTableCard(
        header: DataTableHeader(
          columns: const [
            DataTableColumn(title: 'رقم العنصر', flex: 1),
            DataTableColumn(title: 'رقم الطلب', flex: 1),
            DataTableColumn(title: 'اسم الصنف', flex: 3),
            DataTableColumn(title: 'الكمية', flex: 1),
            DataTableColumn(title: 'السعر', flex: 1),
            DataTableColumn(title: 'الإجمالي', flex: 1),
            DataTableColumn(title: 'الإجراءات', flex: 1),
          ],
        ),
        body: Obx(
          () => ObxState(
            isLoading: controller.isLoading.value,
            hasError: false, // تأكد من وجوده في الكنترولر
            isEmpty:
                controller.filteredOrderItems.isEmpty &&
                !controller.isLoading.value,
            emptyWidget: const Center(child: Text('لا توجد عناصر طلبات للعرض')),
            child: ListView.builder(
              itemCount: controller.filteredOrderItems.length,
              itemBuilder: (context, index) {
                final item = controller.filteredOrderItems[index];
                return _buildOrderItemRow(item.toMapWithJoins(), index);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Dialog: Add new order item (simple placeholder)
  Future<void> _showAddItemDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عنصر طلب'),
        content: const Text(
          'سيتم تفعيل نموذج إضافة عنصر لاحقاً. هذا حوار تمهيدي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // UI: Order item row
  Widget _buildOrderItemRow(Map<String, dynamic> item, int index) {
    final String name =
        (item['itemName'] ?? item['MenuItemName'] ?? 'غير معروف').toString();
    final String category =
        (item['categoryName'] ?? item['CategoryName'] ?? '—').toString();
    final num qty = (item['quantity'] ?? item['Quantity'] ?? 0) as num;
    final num price =
        (item['price'] ?? item['UnitPrice'] ?? item['Price'] ?? 0) as num;
    final num total = (item['total'] ?? item['Total'] ?? (qty * price)) as num;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('${index + 1}', textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(category, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${qty.toString()} × ${price.toStringAsFixed(2)}'),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${total.toStringAsFixed(2)} ريال',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
