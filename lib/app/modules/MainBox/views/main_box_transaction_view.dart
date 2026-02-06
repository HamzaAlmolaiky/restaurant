// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/statistics_card_data.dart';
import '../../../widgets/statistics_row.dart';
import '../controllers/main_box_transaction_controller.dart';
import '../models/main_box_transaction_model.dart';

class MainBoxTransactionView extends GetView<MainBoxTransactionController> {
  const MainBoxTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'الصندوق الرئيسي',
            subtitle: 'إدارة وتتبع جميع المعاملات المالية والنقدية',
            actions: [
              PrimaryButton(
                text: 'معاملة جديدة',
                onPressed: () => _showAddTransactionDialog(context),
                icon: Icons.add,
                backgroundColor: const Color(0xFF10B981),
              ),
              PrimaryButton(
                text: 'جرد الصندوق',
                onPressed: () => _showCashCountDialog(context),
                icon: Icons.calculate,
                backgroundColor: const Color(0xFF3B82F6),
              ),
            ],
            // تم دمج كل محتوى الترويسة في bottomChild
            bottomChild: Column(
              children: [
                // ١. صف رصيد الصندوق والإحصائيات
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // لمحاذاة العناصر بشكل صحيح
                  children: [
                    // بطاقة رصيد الصندوق (تم تحويلها إلى دالة مساعدة)
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => _buildCashBalanceCard(
                          balance: controller.currentBalance.value,
                          lastUpdate: controller.lastUpdate.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // صف الإحصائيات التفاعلي
                    Expanded(
                      flex: 3,
                      child: ReactiveStatisticsRow(
                        cards: [
                          StatisticsCardData(
                            title: 'إيرادات اليوم',
                            reactiveValue: controller.todayRevenue,
                            icon: Icons.trending_up,
                            color: const Color(0xFF10B981),
                            valueSuffix: 'ريال',
                          ),
                          StatisticsCardData(
                            title: 'مصروفات اليوم',
                            reactiveValue: controller.todayExpenses,
                            icon: Icons.trending_down,
                            color: const Color(0xFFEF4444),
                            valueSuffix: 'ريال',
                          ),
                          StatisticsCardData(
                            title: 'عدد المعاملات',
                            reactiveValue: controller.todayTransactionsCount,
                            icon: Icons.receipt_long,
                            color: const Color(0xFF3B82F6),
                            subtitle: 'معاملة',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ٢. فلتر التاريخ
                _DateRangeFilter(
                  onApply: (from, to) {
                    controller.fetchFilteredTransactions(
                      DateTime(from.year, from.month, from.day),
                      DateTime(to.year, to.month, to.day),
                      transactionType: controller.selectedType.value,
                    );
                  },
                ),
              ],
            ),
          ),
          // Quick Actions
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text(
                  'الإجراءات السريعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                _buildQuickActionButton(
                  'إيداع نقدي',
                  Icons.add_circle,
                  const Color(0xFF10B981),
                  onPressed: () => _showQuickTransactionDialog(
                    context,
                    type: 'إيداع',
                    isDeposit: true,
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  'سحب نقدي',
                  Icons.remove_circle,
                  const Color(0xFFEF4444),
                  onPressed: () => _showQuickTransactionDialog(
                    context,
                    type: 'سحب',
                    isDeposit: false,
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  'تحويل بنكي',
                  Icons.account_balance,
                  const Color(0xFF3B82F6),
                  onPressed: () => _showQuickTransactionDialog(
                    context,
                    type: 'تحويل',
                    // اجعل المستخدم يختار وارد/صادر داخل النافذة
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  'تقرير يومي',
                  Icons.assessment,
                  const Color(0xFF8B5CF6),
                  onPressed: () {
                    final now = DateTime.now();
                    final from = DateTime(now.year, now.month, now.day);
                    final to = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      23,
                      59,
                      59,
                    );
                    Get.toNamed(
                      '/report',
                      arguments: {
                        'preset': 'today',
                        'from': from,
                        'to': to,
                        'source': 'main_box',
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Transactions Table
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'رقم المعاملة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'النوع',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'المبلغ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'الوصف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'الموظف',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'التاريخ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'الإجراءات',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        // Filter buttons
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedType.value == 'الكل'
                                    ? 'جميع المعاملات'
                                    : controller.selectedType.value,
                                items:
                                    [
                                      'جميع المعاملات',
                                      'مبيعات',
                                      'فتح وردية',
                                      'مرتجع',
                                      'مصروف',
                                      'سحب',
                                      'إيداع',
                                      'تحويل',
                                    ].map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(
                                          item,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue == null) return;
                                  final mapped = newValue == 'جميع المعاملات'
                                      ? 'الكل'
                                      : newValue;
                                  controller.changeTypeFilter(mapped);
                                },
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table Body
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = controller.transactions;
                      if (items.isEmpty) {
                        return const Center(child: Text('لا توجد معاملات'));
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final t = items[index];
                          return _buildTransactionRow(t, index);
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

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildTransactionRow(MainBoxTransactionModel transaction, int index) {
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
              transaction.transactionID != null
                  ? '#${transaction.transactionID}'
                  : '#-',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTransactionTypeColor(
                  transaction.transactionType ?? '-',
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTransactionTypeIcon(transaction.transactionType ?? '-'),
                    size: 16,
                    color: _getTransactionTypeColor(
                      transaction.transactionType ?? '-',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.transactionType ?? '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getTransactionTypeColor(
                        transaction.transactionType ?? '-',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.amountOut > 0
                  ? '-${transaction.amountOut.toStringAsFixed(2)} ريال'
                  : '+${transaction.amountIn.toStringAsFixed(2)} ريال',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: (transaction.transactionType ?? '') == 'سحب'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF059669),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              transaction.description ?? '-',
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.userName ?? '-',
              style: const TextStyle(color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              transaction.transactionDate.toLocal().toString().substring(0, 16),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
              onSelected: (String value) async {
                final id = transaction.transactionID;
                if (id == null) return;
                final ctx = Get.context;
                switch (value) {
                  case 'view':
                    if (ctx != null) {
                      _showTransactionDetails(ctx, transaction);
                    } else {
                      Get.snackbar(
                        'تنبيه',
                        'تعذر فتح التفاصيل لعدم توفر السياق',
                      );
                    }
                    break;
                  case 'receipt':
                    // TDO: طباعة الإيصال لهذه الحركة
                    Get.snackbar('قريباً', 'ميزة الطباعة قيد التطوير');
                    break;
                  case 'edit':
                    if (ctx != null) {
                      _showEditTransactionDialog(ctx, transaction);
                    } else {
                      Get.snackbar(
                        'تنبيه',
                        'تعذر فتح نافذة التعديل لعدم توفر السياق',
                      );
                    }
                    break;
                  case 'delete':
                    if (ctx != null) {
                      _confirmDelete(ctx, id);
                    } else {
                      Get.snackbar(
                        'تنبيه',
                        'تعذر فتح تأكيد الحذف لعدم توفر السياق',
                      );
                    }
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
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
                const PopupMenuItem(
                  value: 'receipt',
                  child: Row(
                    children: [
                      Icon(Icons.receipt, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('طباعة إيصال'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text('حذف'),
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

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'إيداع':
        return const Color(0xFF10B981);
      case 'سحب':
        return const Color(0xFFEF4444);
      case 'تحويل':
        return const Color(0xFF3B82F6);
      case 'مبيعات':
        return const Color(0xFF8B5CF6);
      case 'فتح وردية':
        return const Color(0xFFF59E0B);
      case 'مرتجع':
        return const Color(0xFF06B6D4);
      case 'مصروف':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type) {
      case 'إيداع':
        return Icons.add_circle;
      case 'سحب':
        return Icons.remove_circle;
      case 'تحويل':
        return Icons.swap_horiz;
      case 'مبيعات':
        return Icons.point_of_sale;
      case 'فتح وردية':
        return Icons.lock_open;
      case 'مرتجع':
        return Icons.undo;
      case 'مصروف':
        return Icons.money_off;
      default:
        return Icons.receipt;
    }
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة معاملة جديدة'),
          content: const SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'نوع المعاملة',
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
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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

  void _showCashCountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('جرد الصندوق'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => Text(
                    'الرصيد المسجل: ${controller.currentBalance.value.toStringAsFixed(2)} ريال',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'الرصيد الفعلي',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              child: const Text('تأكيد الجرد'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickTransactionDialog(
    BuildContext context, {
    required String type,
    bool? isDeposit,
  }) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    bool isTransferIn = true; // للتحويل: وارد/صادر

    await showDialog(
      context: context,
      builder: (ctx) {
        final isTransfer = type == 'تحويل';
        return AlertDialog(
          title: Text('إضافة $type'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTransfer)
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: isTransferIn,
                          onChanged: (v) {
                            isTransferIn = v ?? true;
                            (ctx as Element).markNeedsBuild();
                          },
                          title: const Text('تحويل وارد'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: isTransferIn,
                          onChanged: (v) {
                            isTransferIn = v ?? false;
                            (ctx as Element).markNeedsBuild();
                          },
                          title: const Text('تحويل صادر'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amount <= 0) return;
                final desc = descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim();

                if (type == 'إيداع' || type == 'سحب') {
                  await controller.createTransaction(
                    transactionType: type,
                    amount: amount,
                    isDeposit: type == 'إيداع',
                    description: desc,
                  );
                } else if (type == 'تحويل') {
                  await controller.createTransaction(
                    transactionType: 'تحويل',
                    amount: amount,
                    isDeposit: isTransferIn,
                    description:
                        desc ?? (isTransferIn ? 'تحويل وارد' : 'تحويل صادر'),
                  );
                }

                // إغلاق النافذة
                Navigator.of(ctx).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    MainBoxTransactionModel t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفاصيل المعاملة'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('رقم', t.transactionID?.toString() ?? '-'),
              _detailRow('النوع', t.transactionType ?? '-'),
              _detailRow('مبلغ وارد', t.amountIn.toStringAsFixed(2)),
              _detailRow('مبلغ منصرف', t.amountOut.toStringAsFixed(2)),
              _detailRow('الرصيد بعد', t.balanceAfter.toStringAsFixed(2)),
              _detailRow('الوصف', t.description ?? '-'),
              _detailRow('الموظف', t.userName ?? '-'),
              _detailRow(
                'التاريخ',
                t.transactionDate.toLocal().toString().substring(0, 16),
              ),
            ],
          ),
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

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(
    BuildContext context,
    MainBoxTransactionModel t,
  ) {
    final descCtrl = TextEditingController(text: t.description ?? '');
    final isDepositInitial = t.amountIn > 0;
    final amountCtrl = TextEditingController(
      text: (isDepositInitial ? t.amountIn : t.amountOut).toStringAsFixed(2),
    );
    String selectedType = t.transactionType ?? 'إيداع';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool isDeposit = isDepositInitial;
          return AlertDialog(
            title: const Text('تعديل المعاملة'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items:
                        const [
                              'مبيعات',
                              'فتح وردية',
                              'مرتجع',
                              'مصروف',
                              'سحب',
                              'إيداع',
                              'تحويل',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedType = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'نوع المعاملة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: isDeposit,
                          onChanged: (v) {
                            setState(() => isDeposit = v ?? true);
                          },
                          title: const Text('وارد'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: isDeposit,
                          onChanged: (v) {
                            setState(() => isDeposit = v ?? false);
                          },
                          title: const Text('منصرف'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final id = t.transactionID;
                  if (id == null) return;
                  final newAmount =
                      double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                  if (newAmount <= 0) return;

                  // تحديث النوع/الوصف
                  await controller.updateTransactionMeta(
                    id: id,
                    description: descCtrl.text.trim(),
                    transactionType: selectedType,
                  );

                  // تحديث المبالغ (نحدّد كلا الحقلين لضمان تصفير الآخر)
                  await controller.updateTransactionAmounts(
                    id: id,
                    amountIn: isDeposit ? newAmount : 0.0,
                    amountOut: isDeposit ? 0.0 : newAmount,
                    description: descCtrl.text.trim(),
                  );

                  Navigator.of(ctx).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف هذه المعاملة؟ لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              await controller.deleteTransaction(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لبناء بطاقة رصيد الصندوق الحالي
  Widget _buildCashBalanceCard({
    required double balance,
    DateTime? lastUpdate,
  }) {
    final lastTxt = lastUpdate != null
        ? 'آخر تحديث: ${lastUpdate.toLocal().toString().substring(0, 16)}'
        : 'لا توجد معاملات بعد';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'رصيد الصندوق الحالي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${balance.toStringAsFixed(2)} ريال',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lastTxt,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DateRangeFilter extends StatefulWidget {
  final void Function(DateTime from, DateTime to) onApply;
  const _DateRangeFilter({required this.onApply});

  @override
  State<_DateRangeFilter> createState() => _DateRangeFilterState();
}

class _DateRangeFilterState extends State<_DateRangeFilter> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.date_range, color: Color(0xFF64748B)),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _pickFrom,
          child: Text(_from.toLocal().toString().substring(0, 10)),
        ),
        const SizedBox(width: 8),
        const Text('إلى'),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _pickTo,
          child: Text(_to.toLocal().toString().substring(0, 10)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => widget.onApply(_from, _to),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('تطبيق'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }
}
