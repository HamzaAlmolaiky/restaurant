// file: helpers/database_init.dart

import '../modules/Reports/services/report_scheduler_service.dart';

/// مساعد لتهيئة قاعدة البيانات وإنشاء الجداول المطلوبة
class DatabaseInitializer {
  static Future<void> initializeDatabase() async {
    // إنشاء جداول نظام جدولة التقارير
    final schedulerService = ReportSchedulerService.instance;
    await schedulerService.createSchedulerTables();
    
    // بدء خدمة الجدولة
    schedulerService.startScheduler();
  }
}
