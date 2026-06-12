// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/statistics_card_data.dart';
import '../../../widgets/statistics_row.dart';
import '../controllers/dashboard_controller.dart';
import '../../Auth/controllers/auth_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'نظام المطعم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                Expanded(
                  child: Obx(
                    () => ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _buildNavItem(
                          icon: Icons.dashboard_outlined,
                          title: 'لوحة التحكم',
                          index: 0,
                          isSelected: controller.selectedIndex.value == 0,
                        ),
                        _buildNavItem(
                          icon: Icons.inventory_2_outlined,
                          title: 'الصناديق',
                          index: 1,
                          isSelected: controller.selectedIndex.value == 1,
                        ),
                        _buildNavItem(
                          icon: Icons.category_outlined,
                          title: 'الفئات',
                          index: 2,
                          isSelected: controller.selectedIndex.value == 2,
                        ),
                        _buildNavItem(
                          icon: Icons.fastfood_outlined,
                          title: 'المنتجات',
                          index: 3,
                          isSelected: controller.selectedIndex.value == 3,
                        ),
                        _buildNavItem(
                          icon: Icons.shopping_cart_outlined,
                          title: 'الطلبات',
                          index: 4,
                          isSelected: controller.selectedIndex.value == 4,
                        ),
                        _buildNavItem(
                          icon: Icons.list_alt_outlined,
                          title: 'عناصر الطلبات',
                          index: 5,
                          isSelected: controller.selectedIndex.value == 5,
                        ),
                        _buildNavItem(
                          icon: Icons.people_outline,
                          title: 'العملاء',
                          index: 6,
                          isSelected: controller.selectedIndex.value == 6,
                        ),
                        _buildNavItem(
                          icon: Icons.work_outline,
                          title: 'الموظفين',
                          index: 7,
                          isSelected: controller.selectedIndex.value == 7,
                        ),
                        _buildNavItem(
                          icon: Icons.local_shipping_outlined,
                          title: 'الموردين',
                          index: 8,
                          isSelected: controller.selectedIndex.value == 8,
                        ),
                        _buildNavItem(
                          icon: Icons.refresh_outlined,
                          title: 'المرتجعات',
                          index: 9,
                          isSelected: controller.selectedIndex.value == 9,
                        ),
                        _buildNavItem(
                          icon: Icons.bar_chart_outlined,
                          title: 'التقارير',
                          index: 10,
                          isSelected: controller.selectedIndex.value == 10,
                        ),
                        _buildNavItem(
                          icon: Icons.account_circle_outlined,
                          title: 'المستخدمين',
                          index: 11,
                          isSelected: controller.selectedIndex.value == 11,
                        ),
                        _buildNavItem(
                          icon: Icons.payment_outlined,
                          title: 'مدفوعات العملاء',
                          index: 12,
                          isSelected: controller.selectedIndex.value == 12,
                        ),
                        _buildNavItem(
                          icon: Icons.local_atm_outlined,
                          title: 'الورديات',
                          index: 13,
                          isSelected: controller.selectedIndex.value == 13,
                        ),
                        _buildNavItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'المصروفات',
                          index: 14,
                          isSelected: controller.selectedIndex.value == 14,
                        ),
                        _buildNavItem(
                          icon: Icons.settings_outlined,
                          title: 'الاعدادات',
                          index: 15,
                          isSelected: controller.selectedIndex.value == 15,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF667EEA),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GetX<AuthController>(
                          init: Get.find<AuthController>(),
                          builder: (auth) {
                            final username =
                                auth.currentUser.value?.username ?? 'غير مسجل';
                            final role = auth.currentUser.value?.role ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (role.isNotEmpty)
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Obx(
              () => controller.selectedIndex.value == 0
                  ? _buildDashboardContent()
                  : controller.pages[controller.selectedIndex.value - 1],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.changeIndex(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF667EEA).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFF667EEA)
                      : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF667EEA)
                        : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            PageHeader(
              title: 'مرحباً بك في لوحة التحكم',
              subtitle: 'نظرة عامة على أداء المطعم اليوم',
              // تم تحويل عرض التاريخ إلى ويدجت مخصص وتمريره كـ action
              actions: [_buildDateDisplay()],
              // تم دمج قسم الإحصائيات هنا باستخدام ReactiveStatisticsRow
              bottomChild: ReactiveStatisticsRow(
                cards: [
                  StatisticsCardData(
                    title: 'إجمالي المبيعات',
                    reactiveValue: controller.totalSales,
                    icon: Icons.attach_money,
                    color: const Color(0xFF10B981),
                    valueSuffix: ' ريال',
                  ),
                  StatisticsCardData(
                    title: 'الطلبات اليوم',
                    reactiveValue: controller.totalOrders,
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF3B82F6),
                  ),
                  StatisticsCardData(
                    title: 'العملاء الجدد',
                    reactiveValue: controller.newCustomers,
                    icon: Icons.people,
                    color: const Color(0xFF8B5CF6),
                  ),
                  StatisticsCardData(
                    title: 'متوسط الطلب',
                    reactiveValue: controller.averageOrderValue,
                    icon: Icons.trending_up,
                    color: const Color(0xFFF59E0B),
                    valueSuffix: ' ريال',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Recent Activity (fixed height inside scroll view)
            SizedBox(
              height: 420,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildRecentOrdersCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickActionsCard()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الطلبات الحديثة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              TextButton(
                onPressed: () => controller.changeIndex(4),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = controller.recentOrders;
              if (orders.isEmpty) {
                return const Center(child: Text('لا توجد طلبات حديثة'));
              }
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderNumber = 'طلب #${order.orderID ?? ''}';
                  final customerName =
                      order.customer?.customerName ?? 'بدون اسم';
                  final amount = '${order.totalAmount.toStringAsFixed(0)} ريال';
                  final status = order.amountDue > 0 ? 'جديد' : 'مكتمل';
                  return _buildOrderItem(
                    orderNumber,
                    customerName,
                    amount,
                    status,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    String orderNumber,
    String customerName,
    String amount,
    String status,
  ) {
    Color statusColor;
    switch (status) {
      case 'مكتمل':
        statusColor = const Color(0xFF10B981);
        break;
      case 'جاري التحضير':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'جاري التوصيل':
        statusColor = const Color(0xFF3B82F6);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإجراءات السريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Column(
              children: [
                _buildQuickActionItem(
                  icon: Icons.add_shopping_cart,
                  title: 'طلب جديد',
                  color: const Color(0xFF3B82F6),
                  onTap: () => Get.toNamed('/sub-main'),
                ),
                _buildQuickActionItem(
                  icon: Icons.person_add,
                  title: 'عميل جديد',
                  color: const Color(0xFF10B981),
                  onTap: () => controller.changeIndex(6),
                ),
                _buildQuickActionItem(
                  icon: Icons.restaurant_menu,
                  title: 'منتج جديد',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => controller.changeIndex(3),
                ),
                _buildQuickActionItem(
                  icon: Icons.assessment,
                  title: 'تقرير يومي',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    final now = DateTime.now();
                    final from = DateTime(now.year, now.month, now.day);
                    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    Get.toNamed(
                      '/report',
                      arguments: {
                        'from': from,
                        'to': to,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// دالة مساعدة لبناء ويدجت عرض التاريخ في الترويسة
  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            DateTime.now().toString().substring(0, 10),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
