// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'إعدادات النظام',
            subtitle: 'تحديد وتخصيص إعدادات تطبيق المطعم',
            actions: [
              PrimaryButton(
                text: 'نسخ احتياطي',
                icon: Icons.backup,
                onPressed: () => c.createBackup(),
                backgroundColor: const Color(0xFF10B981),
              ),
              PrimaryButton(
                text: 'إعادة تعيين',
                icon: Icons.refresh,
                onPressed: () => c.resetToDefaults(),
                backgroundColor: const Color(0xFFEF4444),
              ),
              PrimaryButton(
                text: 'حفظ الاعدادات',
                icon: Icons.lock,
                onPressed: () => c.saveSettings(),
                backgroundColor: const Color(0xFF3B82F6),
              ),
            ],
          ),

          /// Settings Content
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Column 1 - General + Sales
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSettingsSection(
                              title: 'الإعدادات العامة',
                              icon: Icons.settings,
                              color: const Color(0xFF3B82F6),
                              children: [
                                _buildSettingItem(
                                  title: 'اسم المطعم',
                                  subtitle: c.restaurantNameController.text,
                                  icon: Icons.restaurant,
                                  onTap: () => _showTextControllerDialog(
                                    context,
                                    'اسم المطعم',
                                    c.restaurantNameController,
                                  ),
                                ),
                                _buildSettingItem(
                                  title: 'العنوان',
                                  subtitle: c.addressController.text,
                                  icon: Icons.location_on,
                                  onTap: () => _showTextControllerDialog(
                                    context,
                                    'العنوان',
                                    c.addressController,
                                  ),
                                ),
                                _buildSettingItem(
                                  title: 'رقم الهاتف',
                                  subtitle: c.phoneController.text,
                                  icon: Icons.phone,
                                  onTap: () => _showTextControllerDialog(
                                    context,
                                    'رقم الهاتف',
                                    c.phoneController,
                                  ),
                                ),
                                _buildSettingItem(
                                  title: 'البريد الإلكتروني',
                                  subtitle: c.emailController.text,
                                  icon: Icons.email,
                                  onTap: () => _showTextControllerDialog(
                                    context,
                                    'البريد الإلكتروني',
                                    c.emailController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSettingsSection(
                              title: 'إعدادات المبيعات',
                              icon: Icons.point_of_sale,
                              color: const Color(0xFF10B981),
                              children: [
                                _buildSwitchItem(
                                  title: 'الضريبة المضافة',
                                  subtitle: 'تطبيق ضريبة القيمة المضافة 15%',
                                  value: c.enableVat.value,
                                  onChanged: (value) =>
                                      c.enableVat.value = value,
                                ),
                                _buildSettingItem(
                                  title: 'نسبة الضريبة',
                                  subtitle:
                                      '${c.vatRate.value.toStringAsFixed(0)}%',
                                  icon: Icons.percent,
                                  onTap: () => _showNumberEditDialog(
                                    context,
                                    'نسبة الضريبة',
                                    c.vatRate.value,
                                    (v) => c.vatRate.value = v,
                                  ),
                                ),
                                _buildSwitchItem(
                                  title: 'رسوم الخدمة',
                                  subtitle: 'إضافة رسوم خدمة تلقائية',
                                  value: c.enableServiceCharge.value,
                                  onChanged: (value) =>
                                      c.enableServiceCharge.value = value,
                                ),
                                _buildSettingItem(
                                  title: 'نسبة رسوم الخدمة',
                                  subtitle:
                                      '${c.serviceChargeRate.value.toStringAsFixed(0)}%',
                                  icon: Icons.room_service,
                                  onTap: () => _showNumberEditDialog(
                                    context,
                                    'نسبة رسوم الخدمة',
                                    c.serviceChargeRate.value,
                                    (v) => c.serviceChargeRate.value = v,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Column 2 - System + Printing
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSettingsSection(
                              title: 'إعدادات النظام',
                              icon: Icons.computer,
                              color: const Color(0xFF8B5CF6),
                              children: [
                                _buildDropdownItem(
                                  title: 'اللغة',
                                  subtitle: c.selectedLanguage.value == 'ar'
                                      ? 'العربية'
                                      : 'English',
                                  icon: Icons.language,
                                  items: const ['العربية', 'English'],
                                  selectedValue:
                                      c.selectedLanguage.value == 'ar'
                                      ? 'العربية'
                                      : 'English',
                                  onChanged: (value) {
                                    if (value == null) return;
                                    c.selectedLanguage.value =
                                        value == 'العربية' ? 'ar' : 'en';
                                  },
                                ),
                                _buildDropdownItem(
                                  title: 'المنطقة الزمنية',
                                  subtitle:
                                      c.selectedTimezone.value == 'Asia/Riyadh'
                                      ? 'الرياض (GMT+3)'
                                      : c.selectedTimezone.value,
                                  icon: Icons.access_time,
                                  items: const [
                                    'الرياض (GMT+3)',
                                    'Asia/Dubai',
                                    'UTC',
                                  ],
                                  selectedValue:
                                      c.selectedTimezone.value == 'Asia/Riyadh'
                                      ? 'الرياض (GMT+3)'
                                      : c.selectedTimezone.value,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    c.selectedTimezone.value =
                                        (value == 'الرياض (GMT+3)')
                                        ? 'Asia/Riyadh'
                                        : value;
                                  },
                                ),
                                _buildDropdownItem(
                                  title: 'العملة',
                                  subtitle: c.selectedCurrency.value,
                                  icon: Icons.attach_money,
                                  items: const ['SAR', 'AED', 'USD'],
                                  selectedValue: c.selectedCurrency.value,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    c.selectedCurrency.value = value;
                                  },
                                ),
                                _buildDropdownItem(
                                  title: 'تنسيق التاريخ',
                                  subtitle: c.selectedDateFormat.value,
                                  icon: Icons.calendar_today,
                                  items: const [
                                    'dd/MM/yyyy',
                                    'MM/dd/yyyy',
                                    'yyyy-MM-dd',
                                  ],
                                  selectedValue: c.selectedDateFormat.value,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    c.selectedDateFormat.value = value;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSettingsSection(
                              title: 'إعدادات الطباعة',
                              icon: Icons.print,
                              color: const Color(0xFFF59E0B),
                              children: [
                                _buildSwitchItem(
                                  title: 'طباعة تلقائية للفواتير',
                                  subtitle: 'طباعة الفاتورة عند إتمام الطلب',
                                  value: c.autoPrint.value,
                                  onChanged: (value) =>
                                      c.autoPrint.value = value,
                                ),
                                _buildDropdownItem(
                                  title: 'حجم الورق',
                                  subtitle: c.paperSize.value,
                                  icon: Icons.description,
                                  items: c.getAvailablePaperSizes(),
                                  selectedValue: c.paperSize.value,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    c.paperSize.value = value;
                                  },
                                ),
                                _buildSwitchItem(
                                  title: 'طباعة شعار المطعم',
                                  subtitle: 'إضافة الشعار في الفواتير',
                                  value: c.printLogo.value,
                                  onChanged: (value) =>
                                      c.printLogo.value = value,
                                ),
                                _buildSettingItem(
                                  title: 'رسالة الشكر',
                                  subtitle: c.thankYouMessage.value,
                                  icon: Icons.message,
                                  onTap: () => _showStringEditDialog(
                                    context,
                                    'رسالة الشكر',
                                    c.thankYouMessage.value,
                                    (v) => c.thankYouMessage.value = v,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Column 3 - Security + Notifications
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSettingsSection(
                              title: 'الأمان والحماية',
                              icon: Icons.security,
                              color: const Color(0xFFEF4444),
                              children: [
                                _buildSwitchItem(
                                  title: 'تسجيل الدخول الثنائي',
                                  subtitle: 'حماية إضافية للحسابات',
                                  value: c.twoFactorAuth.value,
                                  onChanged: (value) =>
                                      c.twoFactorAuth.value = value,
                                ),
                                _buildSettingItem(
                                  title: 'مدة انتهاء الجلسة',
                                  subtitle: '${c.sessionTimeout.value} دقيقة',
                                  icon: Icons.timer,
                                  onTap: () => _showIntEditDialog(
                                    context,
                                    'مدة انتهاء الجلسة (بالدقائق)',
                                    c.sessionTimeout.value,
                                    (v) => c.sessionTimeout.value = v,
                                  ),
                                ),
                                _buildSwitchItem(
                                  title: 'سجل العمليات',
                                  subtitle: 'تسجيل جميع العمليات المهمة',
                                  value: c.auditLog.value,
                                  onChanged: (value) =>
                                      c.auditLog.value = value,
                                ),
                                _buildSettingItem(
                                  title: 'النسخ الاحتياطي التلقائي',
                                  subtitle: c.autoBackup.value
                                      ? 'مفعل'
                                      : 'غير مفعل',
                                  icon: Icons.backup,
                                  onTap: () => _showBoolToggleDialog(
                                    context,
                                    'النسخ الاحتياطي التلقائي',
                                    c.autoBackup.value,
                                    (v) => c.autoBackup.value = v,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSettingsSection(
                              title: 'الإشعارات',
                              icon: Icons.notifications,
                              color: const Color(0xFF06B6D4),
                              children: [
                                _buildSwitchItem(
                                  title: 'إشعارات الطلبات الجديدة',
                                  subtitle: 'تنبيه عند وصول طلب جديد',
                                  value: c.newOrderNotifications.value,
                                  onChanged: (value) =>
                                      c.newOrderNotifications.value = value,
                                ),
                                _buildSwitchItem(
                                  title: 'إشعارات انتهاء المخزون',
                                  subtitle: 'تنبيه عند نفاد المنتجات',
                                  value: c.lowStockNotifications.value,
                                  onChanged: (value) =>
                                      c.lowStockNotifications.value = value,
                                ),
                                _buildSwitchItem(
                                  title: 'إشعارات المدفوعات',
                                  subtitle: 'تنبيه عند استلام مدفوعات',
                                  value: c.paymentNotifications.value,
                                  onChanged: (value) =>
                                      c.paymentNotifications.value = value,
                                ),
                                _buildSwitchItem(
                                  title: 'تقارير يومية',
                                  subtitle: 'إرسال تقرير يومي بالإيميل',
                                  value: c.dailyReportNotifications.value,
                                  onChanged: (value) =>
                                      c.dailyReportNotifications.value = value,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
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
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7280), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: onChanged,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTextControllerDialog(
    BuildContext context,
    String title,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل $title'),
          content: SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                labelText: title,
                border: const OutlineInputBorder(),
              ),
              controller: controller,
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

  void _showStringEditDialog(
    BuildContext context,
    String title,
    String current,
    ValueChanged<String> onSaved,
  ) {
    final text = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل $title'),
          content: SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                labelText: title,
                border: const OutlineInputBorder(),
              ),
              controller: text,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                onSaved(text.text);
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showNumberEditDialog(
    BuildContext context,
    String title,
    double current,
    ValueChanged<double> onSaved,
  ) {
    final text = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعديل $title'),
          content: SizedBox(
            width: 400,
            child: TextField(
              decoration: InputDecoration(
                labelText: title,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: text,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(text.text);
                if (v != null) onSaved(v);
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showIntEditDialog(
    BuildContext context,
    String title,
    int current,
    ValueChanged<int> onSaved,
  ) {
    final text = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,
            child: TextField(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: text,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = int.tryParse(text.text);
                if (v != null) onSaved(v);
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showBoolToggleDialog(
    BuildContext context,
    String title,
    bool current,
    ValueChanged<bool> onSaved,
  ) {
    var temp = current;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              const Text('إيقاف/تشغيل'),
              const SizedBox(width: 12),
              StatefulBuilder(
                builder: (context, setState) => Switch(
                  value: temp,
                  onChanged: (v) => setState(() => temp = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                onSaved(temp);
                Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
