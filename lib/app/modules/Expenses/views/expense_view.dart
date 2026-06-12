// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/filter_bar.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import '../../Auth/controllers/auth_controller.dart';
import '../../Shift/controllers/shift_controller.dart';
import '../../../helpers/app_dialogs.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'إدارة المصروفات',
            subtitle: 'متابعة وإدارة جميع مصروفات المطعم',
            actions: [
              PrimaryButton(
                text: 'مصروف جديد',
                onPressed: () => _showExpenseFormDialog(context),
                icon: Icons.add_circle,
                backgroundColor: const Color(0xFFF59E0B),
              ),
            ],
            // تم دمج قسم الإحصائيات هنا ليصبح جزءًا من الترويسة
            bottomChild: Obx(
              () => StatisticsRow(
                children: [
                  StatisticsCard(
                    title: 'إجمالي المصروفات',
                    value: '${controller.totalAmount.toStringAsFixed(0)} ريال',
                    icon: Icons.money_off,
                    color: const Color(0xFFEF4444),
                    subtitle: 'بناءً على الفلتر الحالي',
                  ),
                  StatisticsCard(
                    title: 'متوسط يومي',
                    value: '${controller.avgDaily.toStringAsFixed(0)} ريال',
                    icon: Icons.trending_up,
                    color: const Color(0xFF3B82F6),
                    subtitle: 'متوسط المصروفات',
                  ),
                  StatisticsCard(
                    title: 'أكبر مصروف',
                    value: '${controller.maxExpense.toStringAsFixed(0)} ريال',
                    icon: Icons.arrow_upward,
                    color: const Color(0xFFF59E0B),
                    subtitle: 'أعلى مبلغ',
                  ),
                  StatisticsCard(
                    title: 'عدد المصروفات',
                    value: '${controller.filteredExpenses.length}',
                    icon: Icons.receipt_long,
                    color: const Color(0xFF8B5CF6),
                    subtitle: 'نتيجة الفلتر',
                  ),
                ],
              ),
            ),
          ),

          /// Filters Section
          FilterBar(
            children: [
              // ١. حقل البحث - مفعّل
              SearchTextField(
                hintText: 'البحث في المصروفات...',
                onChanged: (value) => controller.searchQuery.value = value,
                focusedBorderColor: const Color(0xFFF59E0B),
              ),

              // ٢. فلتر الفئة - مفعّل
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الفئة',
                  value: controller.categoryFilter.value,
                  items: [
                    'جميع الفئات',
                    'رواتب',
                    'إيجار',
                    'مواد خام',
                    'صيانة',
                    'كهرباء',
                    'أخرى',
                  ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (v) => controller.categoryFilter.value = v ?? 'جميع الفئات',
                ),
              ),

              // ٣. فلتر الحالة - مفعّل
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الحالة',
                  value: controller.statusFilter.value,
                  items: ['جميع الحالات', 'مدفوع', 'معلق', 'مرفوض']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (v) => controller.statusFilter.value = v ?? 'جميع الحالات',
                ),
              ),

              // ٤. فلتر التاريخ - مفعّل
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'التاريخ',
                  value: controller.dateFilter.value,
                  items: ['جميع التواريخ', 'اليوم', 'أمس', 'هذا الأسبوع', 'هذا الشهر']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (v) => controller.dateFilter.value = v ?? 'جميع التواريخ',
                ),
              ),
            ],
          ),

          /// Expenses Table
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
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'رقم المصروف',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'الوصف',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الفئة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'المبلغ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الحالة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'التاريخ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'المسؤول',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الإجراءات',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Body
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value &&
                          controller.expensesForShift.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                          ),
                        );
                      }

                      final expenses = controller.filteredExpenses;
                      if (expenses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد مصروفات',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ابدأ بتسجيل المصروفات للوردية الحالية',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final exp = expenses[index];
                          // تطبيع إلى نفس هيكل الخريطة المستخدمة في الواجهة لتقليل التغييرات
                          final expense = {
                            'id':
                                (exp.expenseID?.toString()) ??
                                'EXP-${index + 1}',
                            'description': exp.description ?? '-',
                            'notes': null,
                            'category': exp.expenseType ?? 'أخرى',
                            'amount': exp.amount,
                            'status':
                                '-', // لا يوجد حقل حالة في النموذج، نعرض قيمة حيادية
                            'date': exp.expenseDate
                                .toIso8601String()
                                .split('T')
                                .first,
                            'responsible':
                                exp.userName ?? exp.recipientName ?? '-',
                          };
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    expense['id'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense['description']?.toString() ??
                                            '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (expense['notes'] != null)
                                        Text(
                                          expense['notes']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                        expense['category'] as String,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      expense['category'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getCategoryColor(
                                          expense['category'] as String,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${expense['amount']} ريال',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        expense['status'].toString(),
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      expense['status'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(
                                          expense['status'].toString(),
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    expense['date'].toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    expense['responsible'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _viewExpenseDetails(expense),
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        tooltip: 'عرض التفاصيل',
                                      ),
                                      IconButton(
                                        onPressed: () => _editExpense(context, expense),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        tooltip: 'تعديل',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteExpense(expense),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        tooltip: 'حذف',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'رواتب':
        return const Color(0xFF3B82F6);
      case 'إيجار':
        return const Color(0xFFEF4444);
      case 'مواد خام':
        return const Color(0xFF10B981);
      case 'صيانة':
        return const Color(0xFFF59E0B);
      case 'كهرباء':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مدفوع':
        return const Color(0xFF10B981);
      case 'معلق':
        return const Color(0xFFF59E0B);
      case 'مرفوض':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  void _viewExpenseDetails(Map<String, dynamic> expense) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            const Text('تفاصيل المصروف'),
            const Spacer(),
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعرّف: ${expense['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('الفئة: ${expense['category']}'),
            const SizedBox(height: 8),
            Text('المبلغ: ${expense['amount']} ريال', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('الوصف: ${expense['description']}'),
            const SizedBox(height: 8),
            Text('التاريخ: ${expense['date']}'),
            const SizedBox(height: 8),
            Text('المسؤول: ${expense['responsible']}'),
          ],
        ),
      ),
    );
  }

  void _editExpense(BuildContext context, Map<String, dynamic> expense) {
    final expenseId = int.tryParse(expense['id'].toString());
    final model = controller.expensesForShift.firstWhereOrNull((e) => e.expenseID == expenseId);
    if (model != null) {
      _showExpenseFormDialog(context, expense: model);
    } else {
      AppDialogs.show('تنبيه', 'تعذر العثور على بيانات المصروف الأصلية للتعديل');
    }
  }

  void _deleteExpense(Map<String, dynamic> expense) {
    final expenseId = int.tryParse(expense['id'].toString());
    if (expenseId == null) {
      AppDialogs.show('خطأ', 'معرف المصروف غير صالح');
      return;
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا المصروف؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              final shiftCtrl = Get.find<ShiftController>();
              final shiftId = shiftCtrl.currentOpenShift.value?.shiftID ?? 1;
              controller.deleteExpense(expenseId, shiftId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showExpenseFormDialog(BuildContext context, {ExpenseModel? expense}) {
    final amountCtrl = TextEditingController(text: expense?.amount.toString() ?? '');
    final typeCtrl = TextEditingController(text: expense?.expenseType ?? '');
    final descCtrl = TextEditingController(text: expense?.description ?? '');
    final recipientCtrl = TextEditingController(text: expense?.recipientName ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                expense == null ? Icons.add_circle : Icons.edit,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              Text(expense == null ? 'إضافة مصروف جديد' : 'تعديل المصروف'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'نوع المصروف / الفئة',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: صيانة، كهرباء، إيجار',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: recipientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المستلم / الجهة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوصف / الملاحظات',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) {
                  AppDialogs.show('خطأ', 'يرجى إدخال مبلغ صالح أكبر من صفر');
                  return;
                }
                if (typeCtrl.text.trim().isEmpty) {
                  AppDialogs.show('خطأ', 'يرجى إدخال نوع المصروف');
                  return;
                }

                Navigator.of(context).pop();

                final shiftCtrl = Get.find<ShiftController>();
                final shiftId = shiftCtrl.currentOpenShift.value?.shiftID ?? 1;
                int userId = 1;
                try {
                  userId = Get.find<AuthController>().currentUser.value?.userID ?? 1;
                } catch (_) {}

                if (expense == null) {
                  final newExpense = ExpenseModel(
                    shiftID: shiftId,
                    userID: userId,
                    amount: amt,
                    expenseDate: DateTime.now(),
                    expenseType: typeCtrl.text.trim(),
                    recipientName: recipientCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                  await controller.addExpense(newExpense, shiftId);
                } else {
                  final updatedExpense = ExpenseModel(
                    expenseID: expense.expenseID,
                    shiftID: expense.shiftID,
                    userID: expense.userID,
                    amount: amt,
                    expenseDate: expense.expenseDate,
                    expenseType: typeCtrl.text.trim(),
                    recipientName: recipientCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    employeeID: expense.employeeID,
                  );
                  await controller.updateExpense(updatedExpense, shiftId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(expense == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }
}
