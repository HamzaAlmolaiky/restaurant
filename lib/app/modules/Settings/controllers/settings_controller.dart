// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../helpers/app_dialogs.dart';

class SettingsController extends GetxController {
  // Observable variables for settings
  var isLoading = false.obs;
  var isDirty = false.obs;

  // General Settings
  final restaurantNameController = TextEditingController(text: 'مطاعم المليكي');
  final addressController = TextEditingController(
    text: 'شارع الملك فهد، الرياض، المملكة العربية السعودية',
  );
  final phoneController = TextEditingController(text: '+966 11 234 5678');
  final emailController = TextEditingController(text: 'info@restaurant.com');

  // Sales Settings
  var vatRate = 15.0.obs;
  var serviceChargeRate = 10.0.obs;
  var enableVat = true.obs;
  var enableServiceCharge = true.obs;

  // System Settings
  var selectedLanguage = 'ar'.obs;
  var selectedTimezone = 'Asia/Riyadh'.obs;
  var selectedCurrency = 'SAR'.obs;
  var selectedDateFormat = 'dd/MM/yyyy'.obs;

  // Print Settings
  var autoPrint = true.obs;
  var paperSize = 'A4'.obs;
  var printLogo = true.obs;
  var thankYouMessage = 'شكراً لزيارتكم مطعمنا'.obs;

  // Security Settings
  var twoFactorAuth = false.obs;
  var sessionTimeout = 30.obs;
  var auditLog = true.obs;
  var autoBackup = true.obs;
  var backupFrequency = 'daily'.obs;

  // Notification Settings
  var newOrderNotifications = true.obs;
  var lowStockNotifications = true.obs;
  var paymentNotifications = true.obs;
  var dailyReportNotifications = true.obs;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  void _setupListeners() {
    // Add listeners to text controllers to mark as dirty
    restaurantNameController.addListener(_markDirty);
    addressController.addListener(_markDirty);
    phoneController.addListener(_markDirty);
    emailController.addListener(_markDirty);
  }

  void _markDirty() {
    isDirty.value = true;
  }

  // Save all settings
  Future<bool> saveSettings() async {
    try {
      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Create settings data
      final settingsData = {
        'general': {
          'restaurant_name': restaurantNameController.text,
          'address': addressController.text,
          'phone': phoneController.text,
          'email': emailController.text,
        },
        'sales': {
          'vat_rate': vatRate.value,
          'service_charge_rate': serviceChargeRate.value,
          'enable_vat': enableVat.value,
          'enable_service_charge': enableServiceCharge.value,
        },
        'system': {
          'language': selectedLanguage.value,
          'timezone': selectedTimezone.value,
          'currency': selectedCurrency.value,
          'date_format': selectedDateFormat.value,
        },
        'print': {
          'auto_print': autoPrint.value,
          'paper_size': paperSize.value,
          'print_logo': printLogo.value,
          'thank_you_message': thankYouMessage.value,
        },
        'security': {
          'two_factor_auth': twoFactorAuth.value,
          'session_timeout': sessionTimeout.value,
          'audit_log': auditLog.value,
          'auto_backup': autoBackup.value,
          'backup_frequency': backupFrequency.value,
        },
        'notifications': {
          'new_orders': newOrderNotifications.value,
          'low_stock': lowStockNotifications.value,
          'payments': paymentNotifications.value,
          'daily_reports': dailyReportNotifications.value,
        },
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save settings (in real app, save to database/API)
      print('Settings saved: $settingsData');

      isDirty.value = false;

      AppDialogs.show('نجاح', 'تم حفظ جميع الإعدادات بنجاح');

      return true;
    } catch (e) {
      AppDialogs.show(
        'خطأ',
        'حدث خطأ أثناء حفظ الإعدادات. يرجى المحاولة مرة أخرى.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reset to default settings
  void resetToDefaults() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
            SizedBox(width: 12),
            Text('إعادة تعيين الإعدادات'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إعادة تعيين جميع الإعدادات للقيم الافتراضية؟\nسيتم فقدان جميع التخصيصات الحالية.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'إعادة تعيين',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _performReset() {
    // Reset general settings
    restaurantNameController.text = 'مطعم الذوق الأصيل';
    addressController.text = 'شارع الملك فهد، الرياض، المملكة العربية السعودية';
    phoneController.text = '+966 11 234 5678';
    emailController.text = 'info@restaurant.com';

    // Reset sales settings
    vatRate.value = 15.0;
    serviceChargeRate.value = 10.0;
    enableVat.value = true;
    enableServiceCharge.value = true;

    // Reset system settings
    selectedLanguage.value = 'ar';
    selectedTimezone.value = 'Asia/Riyadh';
    selectedCurrency.value = 'SAR';
    selectedDateFormat.value = 'dd/MM/yyyy';

    // Reset print settings
    autoPrint.value = true;
    paperSize.value = 'A4';
    printLogo.value = true;
    thankYouMessage.value = 'شكراً لزيارتكم مطعمنا';

    // Reset security settings
    twoFactorAuth.value = false;
    sessionTimeout.value = 30;
    auditLog.value = true;
    autoBackup.value = true;
    backupFrequency.value = 'daily';

    // Reset notification settings
    newOrderNotifications.value = true;
    lowStockNotifications.value = true;
    paymentNotifications.value = true;
    dailyReportNotifications.value = true;

    isDirty.value = true;

    AppDialogs.show('نجاح', 'تم إعادة تعيين جميع الإعدادات للقيم الافتراضية');
  }

  // Backup settings
  Future<void> createBackup() async {
    try {
      isLoading.value = true;

      // Simulate backup creation
      await Future.delayed(const Duration(seconds: 3));

      AppDialogs.show('نجاح', 'تم إنشاء نسخة احتياطية من الإعدادات بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء إنشاء النسخة الاحتياطية');
    } finally {
      isLoading.value = false;
    }
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'en', 'name': 'English'},
    ];
  }

  // Get available timezones
  List<Map<String, String>> getAvailableTimezones() {
    return [
      {'code': 'Asia/Riyadh', 'name': 'الرياض (GMT+3)'},
      {'code': 'Asia/Dubai', 'name': 'دبي (GMT+4)'},
      {'code': 'UTC', 'name': 'UTC (GMT+0)'},
    ];
  }

  // Get available currencies
  List<Map<String, String>> getAvailableCurrencies() {
    return [
      {'code': 'SAR', 'name': 'ريال سعودي'},
      {'code': 'AED', 'name': 'درهم إماراتي'},
      {'code': 'USD', 'name': 'دولار أمريكي'},
    ];
  }

  // Get available date formats
  List<Map<String, String>> getAvailableDateFormats() {
    return [
      {'code': 'dd/MM/yyyy', 'name': 'يوم/شهر/سنة'},
      {'code': 'MM/dd/yyyy', 'name': 'شهر/يوم/سنة'},
      {'code': 'yyyy-MM-dd', 'name': 'سنة-شهر-يوم'},
    ];
  }

  // Get available paper sizes
  List<String> getAvailablePaperSizes() {
    return ['A4', 'A5', '80mm', '58mm'];
  }

  // Get available backup frequencies
  List<Map<String, String>> getBackupFrequencies() {
    return [
      {'code': 'daily', 'name': 'يومياً'},
      {'code': 'weekly', 'name': 'أسبوعياً'},
      {'code': 'monthly', 'name': 'شهرياً'},
    ];
  }

  @override
  void onClose() {
    restaurantNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
