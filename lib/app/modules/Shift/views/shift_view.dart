// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helpers/ui_helpers.dart';
import '../../../widgets/dialogs/custom_form_dialog.dart';
import '../../../widgets/grid_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/reactive_grid_section.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../../widgets/templates/management_screen_template.dart';
import '../controllers/shift_controller.dart';
import '../models/shift_details_model.dart';

class ShiftView extends GetView<ShiftController> {
  const ShiftView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      // ١. تمرير بيانات الترويسة
      title: 'إدارة الورديات',
      subtitle: 'تنظيم وإدارة ورديات العمل والموظفين',
      actions: [
        PrimaryButton(
          text: 'وردية جديدة',
          onPressed: () => _showAddShiftDialog(context),
          icon: Icons.add,
          backgroundColor: const Color(0xFF8B5CF6),
        ),
        PrimaryButton(
          text: 'الوردية الحالية',
          onPressed: () => _showCurrentShiftDialog(context),
          icon: Icons.access_time,
          backgroundColor: const Color(0xFF10B981),
        ),
      ],
      statisticsWidget: Column(
        children: [
          // عرض حالة الوردية الحالية
          Obx(() {
            if (controller.currentShift.value == null) {
              return _buildNoActiveShiftCard();
            }
            return _buildCurrentShiftStatus(controller.currentShift.value!);
          }),
          const SizedBox(height: 24),

          // عرض الإحصائيات
          Obx(() {
            if (controller.isLoading.value &&
                controller.shiftsHistory.isEmpty) {
              return const SizedBox(height: 85);
            }
            return StatisticsRow(
              children: [
                StatisticsCard(
                  title: 'إجمالي الورديات',
                  value: controller.totalShifts.value.toString(),
                  icon: Icons.schedule,
                  color: const Color(0xFF8B5CF6),
                  subtitle: 'هذا الشهر',
                ),
                StatisticsCard(
                  title: 'الموظفين النشطين',
                  value: controller.activeEmployeesInShift.value.toString(),
                  icon: Icons.people,
                  color: const Color(0xFF10B981),
                  subtitle: 'في الوردية الحالية',
                ),
                StatisticsCard(
                  title: 'متوسط ساعات العمل',
                  value: controller.averageShiftHours.value.toStringAsFixed(1),
                  icon: Icons.access_time,
                  color: const Color(0xFF3B82F6),
                  subtitle: 'ساعة يومياً',
                ),
                StatisticsCard(
                  title: 'إجمالي المبيعات',
                  value:
                      '${controller.totalSalesInShift.value.toStringAsFixed(2)} ريال',
                  icon: Icons.trending_up,
                  color: const Color(0xFFF59E0B),
                  subtitle: 'الوردية الحالية',
                ),
              ],
            );
          }),
        ],
      ),

      // ٢. تمرير قائمة الفلاتر
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في الورديات...',
          onChanged: (value) {
            /* ... */
          },
          focusedBorderColor: const Color(0xFF8B5CF6),
        ),
        StyledDropdownFormField<String>(
          labelText: 'نوع الوردية',
          value: 'جميع الورديات', // controller.typeFilter.value
          items: ['جميع الورديات', 'صباحية', 'مسائية', 'ليلية']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
        StyledDropdownFormField<String>(
          labelText: 'الحالة',
          value: 'جميع الحالات', // controller.statusFilter.value
          items: ['جميع الحالات', 'نشطة', 'مكتملة', 'ملغية']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
        StyledDropdownFormField<String>(
          labelText: 'التاريخ',
          value: 'جميع التواريخ', // controller.dateFilter.value
          items: ['جميع التواريخ', 'اليوم', 'أمس', 'آخر 7 أيام', 'آخر 30 يوم']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (newValue) {
            /* ... */
          },
        ),
      ],

      // ٣. تمرير المحتوى الرئيسي (الجسم)
      body: ReactiveGridSection<ShiftDetailsModel>(
        // <-- تحديد نوع البيانات
        isLoading: controller.isLoading, // تمرير المتغير التفاعلي مباشرة
        items: controller.shiftsHistory, // تمرير القائمة التفاعلية مباشرة
        emptyText: 'لا توجد ورديات للعرض',
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.3,
        ),
        // تمرير دالة بناء البطاقة مباشرة
        itemBuilder: (context, shift) => _buildShiftCard(shift),
      ),
    );
  }

  Widget _buildShiftInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(ShiftDetailsModel shift) {
    return GridCard(
      // تمرير قائمة الإجراءات
      menuItems: [
        buildPopupMenuItem(
          value: 'view',
          icon: Icons.visibility,
          text: 'عرض التفاصيل',
          color: const Color(0xFF3B82F6),
        ),
        buildPopupMenuItem(
          value: 'edit',
          icon: Icons.edit,
          text: 'تعديل',
          color: const Color(0xFF10B981),
        ),
        buildPopupMenuItem(
          value: 'report',
          icon: Icons.assessment,
          text: 'تقرير الوردية',
          color: const Color(0xFF8B5CF6),
        ),
        buildPopupMenuItem(
          value: 'close',
          icon: Icons.close,
          text: 'إغلاق الوردية',
          isDestructive: true,
        ),
      ],
      // دالة التعامل مع اختيار عنصر من القائمة
      onMenuItemSelected: (value) {
        // Handle action based on value
      },

      // المحتوى الداخلي للبطاقة
      child: Column(
        children: [
          // Shift Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getStatusColor(shift.status).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(shift.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وردية ${shift.userName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _formatShiftTimeRange(shift.startTime, shift.endTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(shift.status),
                          fontWeight: FontWeight.w500,
                        ),
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
                    color: _getStatusColor(shift.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _mapStatusText(shift.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(shift.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shift Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildDetailColumn('المسؤول', shift.userName),
                      const SizedBox(width: 16),
                      _buildDetailColumn(
                        'الإيرادات',
                        '${shift.totalReceipts.toStringAsFixed(2)} ريال',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDetailColumn(
                        'المبيعات',
                        '${shift.totalSales.toStringAsFixed(2)} ريال',
                        valueColor: const Color(0xFF059669),
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

  // دالة مساعدة صغيرة لبناء أعمدة التفاصيل داخل البطاقة
  Widget _buildDetailColumn(String title, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF10B981);
      case 'Closed':
        return const Color(0xFF3B82F6);
      case 'Canceled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _mapStatusText(String status) {
    switch (status) {
      case 'Open':
        return 'نشطة';
      case 'Closed':
        return 'مكتملة';
      case 'Canceled':
        return 'ملغية';
      default:
        return status;
    }
  }

  String _formatShiftTimeRange(DateTime start, DateTime? end) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = end != null
        ? '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'
        : '...';
    return '$startStr - $endStr';
  }

  void _showAddShiftDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    int? selectedManagerId; // متغير محلي بسيط لتخزين اختيار المدير
    Get.dialog(
      CustomFormDialog(
        title: 'اضافة وردية جديدة',
        icon: Icons.schedule,
        iconColor: const Color(0xFF8B5CF6),
        formKey: formKey,
        formFields: [],
        onConfirm: () => (),
      ),
    );
  }

  void _showCurrentShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تفاصيل الوردية الحالية'),
          content: const SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الوردية: المسائية',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'المدة: 14:00 - 22:00',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('المدير: أحمد محمد')),
                    Expanded(child: Text('الموظفين: 8 موظفين')),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('المبيعات: 15,680 ريال')),
                    Expanded(child: Text('الطلبات: 47 طلب')),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'الموظفين النشطين:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• أحمد محمد (مدير)\n• فاطمة علي (كاشير)\n• محمد سالم (طباخ)\n• نورا أحمد (نادلة)\n• خالد محمد (مساعد طباخ)\n• سارة علي (نادلة)\n• يوسف أحمد (عامل تنظيف)\n• مريم سالم (كاشير)',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تقرير الوردية'),
            ),
          ],
        );
      },
    );
  }

  /// ويدجت يعرض معلومات الوردية الحالية بناءً على البيانات الحقيقية
  Widget _buildCurrentShiftStatus(ShiftDetailsModel shift) {
    // حساب الوقت المتبقي (هذا مثال، قد تحتاج لتعديله حسب منطقك)
    final remainingTime = shift.endTime?.difference(DateTime.now());
    final remainingHours = remainingTime != null && !remainingTime.isNegative
        ? remainingTime.inHours
        : 0;
    final remainingMinutes = remainingTime != null && !remainingTime.isNegative
        ? remainingTime.inMinutes.remainder(60)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'الوردية الحالية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // استخدام دالة `_formatShiftTimeRange` الموجودة لديك
                Text(
                  _formatShiftTimeRange(shift.startTime, shift.endTime),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  // استخدام Wrap للتأكد من أن العناصر تتناسب مع الشاشات المختلفة
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _buildShiftInfo('المسؤول', shift.userName),
                    // يجب إضافة هذه البيانات إلى موديل ShiftDetailsModel إذا لم تكن موجودة
                    // _buildShiftInfo('الموظفين', '${shift.employeeCount ?? 0} موظفين'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${remainingHours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'ساعات متبقية',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت يظهر عندما لا تكون هناك وردية نشطة
  Widget _buildNoActiveShiftCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            'لا توجد وردية نشطة حاليًا',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
