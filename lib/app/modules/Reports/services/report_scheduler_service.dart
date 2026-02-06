// file: services/report_scheduler_service.dart

import 'dart:async';
import 'dart:convert';
import '../../../helpers/database_helper.dart';
import '../models/report_model.dart';
import 'advanced_report_service.dart';
import 'report_service.dart';

/// خدمة جدولة التقارير التلقائية
class ReportSchedulerService {
  static final ReportSchedulerService instance = ReportSchedulerService._init();
  ReportSchedulerService._init();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ReportService _reportService = ReportService.instance;
  final AdvancedReportService _advancedReportService = AdvancedReportService.instance;
  
  Timer? _schedulerTimer;
  final List<ScheduledReport> _scheduledReports = [];

  /// بدء خدمة الجدولة
  void startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkAndExecuteScheduledReports();
    });
    _loadScheduledReports();
  }

  /// إيقاف خدمة الجدولة
  void stopScheduler() {
    _schedulerTimer?.cancel();
  }

  /// إضافة تقرير مجدول
  Future<void> scheduleReport(ScheduledReport report) async {
    final db = await _db.database;
    
    await db.insert('Scheduled_Reports', {
      'ReportName': report.reportName,
      'ReportType': report.reportType,
      'Frequency': report.frequency.name,
      'NextRunTime': report.nextRunTime.toIso8601String(),
      'Recipients': jsonEncode(report.recipients),
      'Parameters': jsonEncode(report.parameters),
      'IsActive': report.isActive ? 1 : 0,
      'CreatedAt': DateTime.now().toIso8601String(),
    });

    _scheduledReports.add(report);
  }

  /// تحديث تقرير مجدول
  Future<void> updateScheduledReport(int reportId, ScheduledReport report) async {
    final db = await _db.database;
    
    await db.update(
      'Scheduled_Reports',
      {
        'ReportName': report.reportName,
        'ReportType': report.reportType,
        'Frequency': report.frequency.name,
        'NextRunTime': report.nextRunTime.toIso8601String(),
        'Recipients': jsonEncode(report.recipients),
        'Parameters': jsonEncode(report.parameters),
        'IsActive': report.isActive ? 1 : 0,
        'UpdatedAt': DateTime.now().toIso8601String(),
      },
      where: 'ScheduleID = ?',
      whereArgs: [reportId],
    );

    final index = _scheduledReports.indexWhere((r) => r.scheduleId == reportId);
    if (index != -1) {
      _scheduledReports[index] = report.copyWith(scheduleId: reportId);
    }
  }

  /// حذف تقرير مجدول
  Future<void> deleteScheduledReport(int reportId) async {
    final db = await _db.database;
    
    await db.delete(
      'Scheduled_Reports',
      where: 'ScheduleID = ?',
      whereArgs: [reportId],
    );

    _scheduledReports.removeWhere((r) => r.scheduleId == reportId);
  }

  /// الحصول على جميع التقارير المجدولة
  Future<List<ScheduledReport>> getScheduledReports() async {
    final db = await _db.database;
    
    final result = await db.query(
      'Scheduled_Reports',
      orderBy: 'NextRunTime ASC',
    );

    return result.map((row) => ScheduledReport.fromMap(row)).toList();
  }

  /// تحميل التقارير المجدولة من قاعدة البيانات
  Future<void> _loadScheduledReports() async {
    _scheduledReports.clear();
    final reports = await getScheduledReports();
    _scheduledReports.addAll(reports.where((r) => r.isActive));
  }

  /// فحص وتنفيذ التقارير المجدولة
  Future<void> _checkAndExecuteScheduledReports() async {
    final now = DateTime.now();
    
    for (final report in _scheduledReports) {
      if (report.isActive && now.isAfter(report.nextRunTime)) {
        await _executeScheduledReport(report);
        await _updateNextRunTime(report);
      }
    }
  }

  /// تنفيذ تقرير مجدول
  Future<void> _executeScheduledReport(ScheduledReport report) async {
    try {
      final reportData = await _generateReportData(report);
      await _sendReport(report, reportData);
      await _logReportExecution(report, true);
    } catch (e) {
      await _logReportExecution(report, false, error: e.toString());
    }
  }

  /// توليد بيانات التقرير
  Future<List<ReportItemModel>> _generateReportData(ScheduledReport report) async {
    final params = report.parameters;
    final fromDate = DateTime.parse(params['fromDate'] ?? DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
    final toDate = DateTime.parse(params['toDate'] ?? DateTime.now().toIso8601String());

    switch (report.reportType) {
      case 'sales_summary':
        return await _reportService.getSalesSummary(fromDate, toDate);
      case 'profit_loss':
        return await _advancedReportService.getProfitLossAsReportItems(fromDate, toDate);
      case 'cash_flow':
        return await _advancedReportService.getCashFlowAsReportItems(fromDate, toDate);
      case 'inventory':
        final inventory = await _advancedReportService.getInventoryReport();
        return inventory.map((item) => ReportItemModel(
          label: '${item.itemName} (${item.category})',
          value: item.currentStock,
          secondaryValue: item.totalValue,
        )).toList();
      case 'customer_loyalty':
        final loyalty = await _advancedReportService.getCustomerLoyaltyReport();
        return loyalty.map((customer) => ReportItemModel(
          label: '${customer.customerName} (${customer.loyaltyTier})',
          value: customer.totalSpent,
          secondaryValue: customer.loyaltyScore,
        )).toList();
      default:
        return [];
    }
  }

  /// إرسال التقرير
  Future<void> _sendReport(ScheduledReport report, List<ReportItemModel> data) async {
    // تحويل البيانات إلى CSV
    final csvData = _convertToCsv(data);
    
    // في التطبيق الحقيقي، يمكن إرسال التقرير عبر البريد الإلكتروني
    // أو حفظه في مجلد معين أو إرساله عبر API
    
    // حفظ التقرير في قاعدة البيانات كسجل
    await _saveReportHistory(report, csvData);
  }

  /// تحويل البيانات إلى CSV
  String _convertToCsv(List<ReportItemModel> data) {
    final buffer = StringBuffer('البيان,القيمة,القيمة الثانوية\n');
    for (final item in data) {
      final safeLabel = '"${item.label.replaceAll('"', '""')}"';
      buffer.writeln('$safeLabel,${item.value},${item.secondaryValue ?? ''}');
    }
    return buffer.toString();
  }

  /// حفظ سجل التقرير
  Future<void> _saveReportHistory(ScheduledReport report, String csvData) async {
    final db = await _db.database;
    
    await db.insert('Report_History', {
      'ScheduleID': report.scheduleId,
      'ReportName': report.reportName,
      'GeneratedAt': DateTime.now().toIso8601String(),
      'DataSize': csvData.length,
      'Recipients': jsonEncode(report.recipients),
      'Status': 'مرسل',
    });
  }

  /// تحديث وقت التشغيل التالي
  Future<void> _updateNextRunTime(ScheduledReport report) async {
    final nextRun = _calculateNextRunTime(report.nextRunTime, report.frequency);
    
    final db = await _db.database;
    await db.update(
      'Scheduled_Reports',
      {'NextRunTime': nextRun.toIso8601String()},
      where: 'ScheduleID = ?',
      whereArgs: [report.scheduleId],
    );

    // تحديث الكائن في الذاكرة
    final index = _scheduledReports.indexWhere((r) => r.scheduleId == report.scheduleId);
    if (index != -1) {
      _scheduledReports[index] = report.copyWith(nextRunTime: nextRun);
    }
  }

  /// حساب وقت التشغيل التالي
  DateTime _calculateNextRunTime(DateTime currentTime, ReportFrequency frequency) {
    switch (frequency) {
      case ReportFrequency.daily:
        return currentTime.add(const Duration(days: 1));
      case ReportFrequency.weekly:
        return currentTime.add(const Duration(days: 7));
      case ReportFrequency.monthly:
        return DateTime(currentTime.year, currentTime.month + 1, currentTime.day);
      case ReportFrequency.quarterly:
        return DateTime(currentTime.year, currentTime.month + 3, currentTime.day);
      case ReportFrequency.yearly:
        return DateTime(currentTime.year + 1, currentTime.month, currentTime.day);
    }
  }

  /// تسجيل تنفيذ التقرير
  Future<void> _logReportExecution(ScheduledReport report, bool success, {String? error}) async {
    final db = await _db.database;
    
    await db.insert('Report_Execution_Log', {
      'ScheduleID': report.scheduleId,
      'ExecutedAt': DateTime.now().toIso8601String(),
      'Success': success ? 1 : 0,
      'ErrorMessage': error,
    });
  }

  /// الحصول على سجل تنفيذ التقارير
  Future<List<Map<String, dynamic>>> getExecutionHistory(int scheduleId) async {
    final db = await _db.database;
    
    return await db.query(
      'Report_Execution_Log',
      where: 'ScheduleID = ?',
      whereArgs: [scheduleId],
      orderBy: 'ExecutedAt DESC',
      limit: 50,
    );
  }

  /// إنشاء الجداول المطلوبة
  Future<void> createSchedulerTables() async {
    final db = await _db.database;
    
    // جدول التقارير المجدولة
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Scheduled_Reports (
        ScheduleID INTEGER PRIMARY KEY AUTOINCREMENT,
        ReportName TEXT NOT NULL,
        ReportType TEXT NOT NULL,
        Frequency TEXT NOT NULL,
        NextRunTime TEXT NOT NULL,
        Recipients TEXT NOT NULL,
        Parameters TEXT,
        IsActive INTEGER DEFAULT 1,
        CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        UpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول سجل التقارير
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Report_History (
        HistoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        ScheduleID INTEGER,
        ReportName TEXT NOT NULL,
        GeneratedAt TEXT NOT NULL,
        DataSize INTEGER DEFAULT 0,
        Recipients TEXT,
        Status TEXT DEFAULT 'مرسل',
        FOREIGN KEY (ScheduleID) REFERENCES Scheduled_Reports(ScheduleID)
      )
    ''');

    // جدول سجل تنفيذ التقارير
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Report_Execution_Log (
        LogID INTEGER PRIMARY KEY AUTOINCREMENT,
        ScheduleID INTEGER,
        ExecutedAt TEXT NOT NULL,
        Success INTEGER DEFAULT 1,
        ErrorMessage TEXT,
        FOREIGN KEY (ScheduleID) REFERENCES Scheduled_Reports(ScheduleID)
      )
    ''');
  }
}

/// تكرار التقرير
enum ReportFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

/// نموذج التقرير المجدول
class ScheduledReport {
  final int? scheduleId;
  final String reportName;
  final String reportType;
  final ReportFrequency frequency;
  final DateTime nextRunTime;
  final List<String> recipients;
  final Map<String, dynamic> parameters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduledReport({
    this.scheduleId,
    required this.reportName,
    required this.reportType,
    required this.frequency,
    required this.nextRunTime,
    required this.recipients,
    required this.parameters,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduledReport.fromMap(Map<String, dynamic> map) {
    return ScheduledReport(
      scheduleId: map['ScheduleID'],
      reportName: map['ReportName'] ?? '',
      reportType: map['ReportType'] ?? '',
      frequency: ReportFrequency.values.firstWhere(
        (f) => f.name == map['Frequency'],
        orElse: () => ReportFrequency.monthly,
      ),
      nextRunTime: DateTime.parse(map['NextRunTime']),
      recipients: List<String>.from(jsonDecode(map['Recipients'] ?? '[]')),
      parameters: Map<String, dynamic>.from(jsonDecode(map['Parameters'] ?? '{}')),
      isActive: (map['IsActive'] ?? 1) == 1,
      createdAt: map['CreatedAt'] != null ? DateTime.parse(map['CreatedAt']) : null,
      updatedAt: map['UpdatedAt'] != null ? DateTime.parse(map['UpdatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ScheduleID': scheduleId,
      'ReportName': reportName,
      'ReportType': reportType,
      'Frequency': frequency.name,
      'NextRunTime': nextRunTime.toIso8601String(),
      'Recipients': jsonEncode(recipients),
      'Parameters': jsonEncode(parameters),
      'IsActive': isActive ? 1 : 0,
      'CreatedAt': createdAt?.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
    };
  }

  ScheduledReport copyWith({
    int? scheduleId,
    String? reportName,
    String? reportType,
    ReportFrequency? frequency,
    DateTime? nextRunTime,
    List<String>? recipients,
    Map<String, dynamic>? parameters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduledReport(
      scheduleId: scheduleId ?? this.scheduleId,
      reportName: reportName ?? this.reportName,
      reportType: reportType ?? this.reportType,
      frequency: frequency ?? this.frequency,
      nextRunTime: nextRunTime ?? this.nextRunTime,
      recipients: recipients ?? this.recipients,
      parameters: parameters ?? this.parameters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
