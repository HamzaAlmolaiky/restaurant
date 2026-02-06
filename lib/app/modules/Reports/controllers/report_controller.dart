// ignore_for_file: avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/advanced_report_service.dart';
import '../../../helpers/app_dialogs.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

// =========================================================================
//                       CLASS: ReportController
// =========================================================================

class ReportController extends GetxController {
  final ReportService _reportService = ReportService.instance;
  final AdvancedReportService _advancedReportService =
      AdvancedReportService.instance;

  // --- كتالوج التقارير الذكي (مصدر الحقيقة للتقارير) ---
  late final Map<String, List<ReportDefinition>> reportCatalog;

  // ================== متغيرات الحالة التفاعلية (Reactive State) ==================
  var isLoading = false.obs;
  var reportTitle = ''.obs;
  var reportData = <ReportItemModel>[].obs;

  // نطاق التاريخ
  final Rxn<DateTime> fromDate = Rxn<DateTime>();
  final Rxn<DateTime> toDate = Rxn<DateTime>();
  final selectedPeriod = ReportPeriod.monthly.obs;

  // --- متغيرات الحالة للقائمتين المنسدلتين ---
  var selectedCategoryKey = 'المبيعات'.obs; // للتحكم في القائمة الأولى
  var availableSubReports =
      <ReportDefinition>[].obs; // لمحتويات القائمة الثانية
  final Rxn<ReportDefinition> selectedReportDefinition =
      Rxn<ReportDefinition>();

  // إحصائيات عامة
  final todayOrders = 0.obs;
  final todaySales = 0.0.obs;
  final monthOrders = 0.obs;
  final monthSales = 0.0.obs;
  final totalCustomers = 0.obs;
  final availableItems = 0.obs;

  // بيانات الرسوم البيانية
  final monthlySalesData = <Map<String, dynamic>>[].obs;
  final categoryRevenue = <ReportItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeReportCatalog();

    // تهيئة القوائم المنسدلة بالحالة الافتراضية
    updateSubReportsForCategory(selectedCategoryKey.value);

    // التعامل مع التواريخ الممررة كـ arguments
    _handleInitialArguments();

    // تحميل البيانات الأولية
    _loadGeneralStats();

    // بناء التقرير الافتراضي بناءً على التواريخ المحددة
    if (fromDate.value != null && toDate.value != null) {
      buildReport(fromDate.value!, toDate.value!);
    }
  }

  /// بناء التقرير بناءً على التقرير المختار حاليًا والنطاق الزمني
  Future<void> buildReport(DateTime fromDate, DateTime toDate) async {
    final definition = selectedReportDefinition.value;
    if (definition == null) {
      AppDialogs.showError('خطأ', 'الرجاء اختيار نوع التقرير أولاً.');
      return;
    }

    try {
      isLoading.value = true;
      reportData.clear();
      reportTitle.value = definition.displayName;

      // استدعاء دالة جلب البيانات مباشرة بدون الحاجة لـ switch
      final data = await definition.fetchData(fromDate, toDate);
      reportData.assignAll(data);

      // تحديث الرسوم البيانية لتطابق النطاق الزمني للتقرير
      await refreshChartsForRange(fromDate, toDate);
    } catch (e) {
      print('فشل في بناء التقرير (${reportTitle.value}): $e');
      AppDialogs.showError('خطأ', 'حدث خطأ أثناء جلب بيانات التقرير.');
    } finally {
      isLoading.value = false;
    }
  }

  // ================== دوال لإدارة الحالة من الواجهة ==================

  /// يتم استدعاؤها من الواجهة عند تغيير الفئة الرئيسية (القائمة المنسدلة الأولى)
  void changeMainCategory(String? newCategoryKey) {
    if (newCategoryKey == null || newCategoryKey == selectedCategoryKey.value) {
      return;
    }
    selectedCategoryKey.value = newCategoryKey;
    updateSubReportsForCategory(newCategoryKey);
    // بعد تغيير الفئة، قم ببناء أول تقرير في القائمة الجديدة تلقائيًا
    if (fromDate.value != null && toDate.value != null) {
      buildReport(fromDate.value!, toDate.value!);
    }
  }

  /// تحديث قائمة التقارير الفرعية بناءً على الفئة الرئيسية المختارة
  void updateSubReportsForCategory(String categoryKey) {
    final subReports = reportCatalog[categoryKey] ?? [];
    availableSubReports.value = subReports;
    // اختر أول تقرير في القائمة الجديدة كقيمة افتراضية
    if (subReports.isNotEmpty) {
      selectedReportDefinition.value = subReports.first;
    } else {
      selectedReportDefinition.value = null;
    }
  }

  /// يتم استدعاؤها من الواجهة عند اختيار تقرير فرعي (القائمة المنسدلة الثانية)
  Future<void> changeAndBuildReport(ReportDefinition? newDefinition) async {
    if (newDefinition == null) return;
    selectedReportDefinition.value = newDefinition;
    if (fromDate.value != null && toDate.value != null) {
      await buildReport(fromDate.value!, toDate.value!);
    }
  }

  /// يطبق الفترة المختارة، يحدث النطاق، ثم يعيد بناء التقرير
  Future<void> applyPeriodAndRebuild(ReportPeriod period) async {
    selectedPeriod.value = period;
    // عند اختيار "مخصص" لا نبني التقرير فوراً؛ ننتظر منتقي النطاق في الواجهة
    if (period == ReportPeriod.custom) {
      return;
    }
    final range = _resolveRange(period);
    fromDate.value = range.start;
    toDate.value = range.end;
    await buildReport(range.start, range.end);
  }

  /// لتحديث النطاق من منتقي التاريخ المخصص
  void applyDateFilter(DateTime from, DateTime to) {
    fromDate.value = from;
    toDate.value = to;
    selectedPeriod.value = ReportPeriod.custom;
    buildReport(from, to);
  }

  // ================== دوال تحميل البيانات والرسوم ==================

  /// تحديث الرسوم البيانية حسب نطاق التاريخ
  Future<void> refreshChartsForRange(DateTime from, DateTime to) async {
    // إذا كانت الفئة المختارة هي "النقدية" فعلّق الرسوم على حركة الخزنة
    if (selectedCategoryKey.value == 'النقدية') {
      await _loadCashCharts(from, to);
      return;
    }
    // خلاف ذلك، قم بتحميل الرسوم حسب التقرير الفرعي المختار
    await _loadChartsForSubReport(from, to);
  }

  Future<void> _loadGeneralStats() async {
    try {
      final stats = await _reportService.getGeneralStats();
      final today = Map<String, dynamic>.from(stats['today'] ?? {});
      final month = Map<String, dynamic>.from(stats['month'] ?? {});
      final general = Map<String, dynamic>.from(stats['general'] ?? {});

      todayOrders.value = (today['orders'] as num? ?? 0).toInt();
      todaySales.value = (today['sales'] as num? ?? 0).toDouble();
      monthOrders.value = (month['orders'] as num? ?? 0).toInt();
      monthSales.value = (month['sales'] as num? ?? 0).toDouble();
      totalCustomers.value = (general['total_customers'] as num? ?? 0).toInt();
      availableItems.value = (general['available_items'] as num? ?? 0).toInt();
    } catch (e) {
      print('فشل في تحميل الإحصائيات العامة: $e');
    }
  }

  Future<void> _loadMonthlySales([DateTime? from, DateTime? to]) async {
    try {
      final range = _resolveRange(selectedPeriod.value);
      final data = await _reportService.getMonthlySalesReport(
        from ?? range.start,
        to ?? range.end,
      );
      monthlySalesData.assignAll(data);
    } catch (e) {
      print('!!!!!!!! FAILED TO LOAD MONTHLY SALES: $e');
      monthlySalesData.clear();
    }
  }

  Future<void> _loadCategoryRevenue([DateTime? start, DateTime? end]) async {
    try {
      final range = _resolveRange(selectedPeriod.value);
      final rows = await _reportService.getCategoryRevenueReport(
        startDate: start ?? range.start,
        endDate: end ?? range.end,
      );
      final items = rows
          .map(
            (r) => ReportItemModel(
              label: (r['category_name'] ?? 'غير محدد').toString(),
              value: (r['total_revenue'] as num? ?? 0).toDouble(),
            ),
          )
          .toList();
      categoryRevenue.assignAll(items);
    } catch (e) {
      print('!!!!!!!! FAILED TO LOAD CATEGORY REVENUE: $e');
      categoryRevenue.clear();
    }
  }

  // ------------------------------------------------------------------
  // تحميل رسوم فئة "النقدية" (الخزنة)
  // - الرسم العمودي (time-series): صافي الحركة اليومية = المقبوض - المدفوع
  //   يلتزم بالشكل الذي تتوقعه الواجهة: { 'date': 'YYYY-MM-DD', 'total_sales': net }
  // - الرسم الدائري: توزيع إجمالي المقبوض مقابل إجمالي المدفوع
  // ------------------------------------------------------------------
  Future<void> _loadCashCharts(DateTime from, DateTime to) async {
    try {
      // 1) الخط/الأعمدة الزمنية: صافي الحركة اليومي
      final daily = await _reportService.getMainBoxTransactionsSummary(
        from,
        to,
      );
      final seriesPoints = daily.map((d) {
        final inVal = d.value;
        final outVal = d.secondaryValue ?? 0;
        final net = inVal - outVal;
        return {
          'date': d.label, // YYYY-MM-DD
          'total_sales': net, // ما تتوقعه الواجهة كمحور Y
        };
      }).toList();
      monthlySalesData.assignAll(seriesPoints);

      // 2) الرسم الدائري: المقبوض والمدفوع
      final summary = await _reportService.getMainBoxSummary(from, to);
      double inTotal = 0, outTotal = 0;
      for (final item in summary) {
        if (item.label.contains('إجمالي المقبوض')) inTotal = item.value;
        if (item.label.contains('إجمالي المدفوع')) outTotal = item.value;
      }
      categoryRevenue.assignAll([
        ReportItemModel(label: 'المقبوض', value: inTotal),
        ReportItemModel(label: 'المدفوع', value: outTotal),
      ]);
    } catch (e) {
      print('!!!!!!!! FAILED TO LOAD CASH CHARTS: $e');
      monthlySalesData.clear();
      categoryRevenue.clear();
    }
  }

  // ------------------------------------------------------------------
  // تحميل الرسوم حسب التقرير الفرعي المختار (لفئات غير "النقدية")
  // - يملأ categoryRevenue بحسب نوع التقرير الفرعي
  // - يملأ monthlySalesData كـ time-series افتراضي من المبيعات،
  //   مع تخصيص للمصروفات عند اختيار تقرير المصروفات
  // ------------------------------------------------------------------
  Future<void> _loadChartsForSubReport(DateTime from, DateTime to) async {
    try {
      final def = selectedReportDefinition.value;
      final name = def?.displayName ?? '';

      // 1) المخطط الدائري: يعتمد على التقرير الفرعي
      switch (name) {
        case 'حسب الدفع':
          categoryRevenue.assignAll(
            await _reportService.getSalesByPaymentMethod(from, to),
          );
          break;
        case 'حسب الموظف':
          categoryRevenue.assignAll(
            await _reportService.getSalesByEmployee(from, to),
          );
          break;
        case 'الأكثر مبيعاً':
          categoryRevenue.assignAll(
            await _reportService.getTopSellingItems(from, to),
          );
          break;
        case 'حسب الفئة':
          final rows = await _reportService.getCategoryRevenueReport(
            startDate: from,
            endDate: to,
          );
          categoryRevenue.assignAll(
            rows.map(
              (r) => ReportItemModel(
                label: (r['category_name'] ?? 'غير محدد').toString(),
                value: (r['total_revenue'] as num? ?? 0).toDouble(),
              ),
            ),
          );
          break;
        case 'حركة مدفوعات':
          categoryRevenue.assignAll(
            await _reportService.getCustomerPaymentsSummary(from, to),
          );
          break;
        case 'الأكثر شراءً':
          categoryRevenue.assignAll(
            await _reportService.getTopCustomersSimple(from, to),
          );
          break;
        case 'تقرير ضريبي':
          categoryRevenue.assignAll(
            await _reportService.getTaxSummary(from, to),
          );
          break;
        case 'الأرباح والخسائر':
          categoryRevenue.assignAll(
            await _reportService.getProfitAndLoss(from, to),
          );
          break;
        case 'تقرير المرتجعات':
          categoryRevenue.assignAll(
            await _reportService.getReturnsSummary(from, to),
          );
          break;
        case 'المرتجعات بالسبب':
          categoryRevenue.assignAll(
            await _reportService.getReturnsByReason(from, to),
          );
          break;
        default:
          // افتراضي: توزيع الإيراد حسب الفئة
          final rows = await _reportService.getCategoryRevenueReport(
            startDate: from,
            endDate: to,
          );
          categoryRevenue.assignAll(
            rows.map(
              (r) => ReportItemModel(
                label: (r['category_name'] ?? 'غير محدد').toString(),
                value: (r['total_revenue'] as num? ?? 0).toDouble(),
              ),
            ),
          );
      }

      // 2) المخطط العمودي: افتراضياً المبيعات اليومية خلال النطاق
      // استثناء خاص لبعض التقارير لتوافق محور الزمن:
      if (name == 'تقرير المصروفات' && selectedCategoryKey.value == 'النقدية') {
        // لن نصل هنا لأن "النقدية" تستخدم _loadCashCharts، لكن نتركها للوضوح
        final dailyExpenses = await _reportService.getExpensesSummary(from, to);
        final series = dailyExpenses
            .map((e) => {'date': e.label, 'total_sales': e.value})
            .toList();
        monthlySalesData.assignAll(series);
      } else {
        final sales = await _reportService.getMonthlySalesReport(from, to);
        // يطابق الشكل المطلوب مباشرة: date, total_sales
        monthlySalesData.assignAll(sales);
      }
    } catch (e) {
      print('!!!!!!!! FAILED TO LOAD SUBREPORT CHARTS: $e');
      // حفاظاً على تجربة المستخدم، نفرغ الرسوم لتظهر رسائل عدم وجود بيانات
      categoryRevenue.clear();
      monthlySalesData.clear();
    }
  }

  // ================== دوال مساعدة داخلية (Private Helpers) ==================

  void _handleInitialArguments() {
    final args = Get.arguments;
    if (args is Map) {
      fromDate.value = args['from'] as DateTime?;
      toDate.value = args['to'] as DateTime?;
    }

    if (fromDate.value == null || toDate.value == null) {
      final range = _resolveRange(selectedPeriod.value);
      fromDate.value = range.start;
      toDate.value = range.end;
    }
  }

  DateTimeRange _resolveRange(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: start);
      case ReportPeriod.weekly:
        final weekday = now.weekday;
        final daysToSubtract = (weekday % 7); // Assuming Sunday is 7
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysToSubtract));
        return DateTimeRange(start: start, end: now);
      case ReportPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.custom:
        final start = fromDate.value ?? DateTime(now.year, now.month, 1);
        final end = toDate.value ?? now;
        return DateTimeRange(start: start, end: end);
    }
  }

  /// تصدير التقرير الحالي إلى CSV
  String exportCurrentReportToCsv() {
    if (reportData.isEmpty) return '';

    final buffer = StringBuffer('label,value,secondaryValue\n');
    for (final item in reportData) {
      final safeLabel = '"${item.label.replaceAll('"', '""')}"';
      buffer.writeln('$safeLabel,${item.value},${item.secondaryValue ?? ''}');
    }
    return buffer.toString();
  }

  // ================== تهيئة كتالوج التقارير ==================

  void _initializeReportCatalog() {
    reportCatalog = {
      'المبيعات': [
        ReportDefinition(
          displayName: 'ملخص المبيعات',
          fetchData: _reportService.getSalesSummary,
        ),
        ReportDefinition(
          displayName: 'ملخص صافي/إجمالي',
          fetchData: _reportService.getSalesSummaryNetGross,
        ),
        ReportDefinition(
          displayName: 'حسب الدفع',
          fetchData: _reportService.getSalesByPaymentMethod,
        ),
        ReportDefinition(
          displayName: 'حسب الموظف',
          fetchData: _reportService.getSalesByEmployee,
        ),
        ReportDefinition(
          displayName: 'حسب الوردية',
          fetchData: _reportService.getSalesByShift,
        ),
        ReportDefinition(
          displayName: 'حسب الفئة',
          fetchData: (from, to) async {
            final rows = await _reportService.getCategoryRevenueReport(
              startDate: from,
              endDate: to,
            );
            return rows
                .map(
                  (r) => ReportItemModel(
                    label: (r['category_name'] ?? 'غير محدد').toString(),
                    value: (r['total_revenue'] as num? ?? 0).toDouble(),
                  ),
                )
                .toList();
          },
        ),
        ReportDefinition(
          displayName: 'الأكثر مبيعاً',
          fetchData: _reportService.getTopSellingItems,
        ),
      ],
      'العملاء': [
        ReportDefinition(
          displayName: 'كشف حساب',
          fetchData: (_, __) => _reportService.getCustomerBalances(),
          isTimeBound: false,
        ),
        ReportDefinition(
          displayName: 'حركة مدفوعات',
          fetchData: _reportService.getCustomerPaymentsSummary,
        ),
        ReportDefinition(
          displayName: 'الأكثر شراءً',
          fetchData: _reportService.getTopCustomersSimple,
        ),
        ReportDefinition(
          displayName: 'ديون العملاء',
          fetchData: (_, __) => _reportService.getCustomerDebts(),
          isTimeBound: false,
        ),
      ],
      'النقدية': [
        ReportDefinition(
          displayName: 'ملخص الورديات',
          fetchData: _reportService.getShiftSummary,
        ),
        ReportDefinition(
          displayName: 'تقرير المصروفات',
          fetchData: _reportService.getExpensesSummary,
        ),
        ReportDefinition(
          displayName: 'حسب النوع',
          fetchData: _reportService.getExpensesByType,
        ),
        ReportDefinition(
          displayName: 'ملخص حركة الخزنة',
          fetchData: _reportService.getMainBoxSummary,
        ),
      ],
      'المرتجعات': [
        ReportDefinition(
          displayName: 'تقرير المرتجعات',
          fetchData: _reportService.getReturnsSummary,
        ),
        ReportDefinition(
          displayName: 'المرتجعات بالسبب',
          fetchData: _reportService.getReturnsByReason,
        ),
        ReportDefinition(
          displayName: 'المرتجعات بالصنف',
          fetchData: (from, to) async {
            AppDialogs.showInfo('معلومة', 'هذا التقرير غير متوفر حاليًا');
            return [];
          },
        ),
      ],
      'الإدارة': [
        ReportDefinition(
          displayName: 'الأرباح والخسائر',
          fetchData: _reportService.getProfitAndLoss,
        ),
        ReportDefinition(
          displayName: 'إحصائيات عامة',
          isTimeBound: false,
          fetchData: (_, __) async {
            final stats = await _reportService.getGeneralStats();
            final today = Map<String, dynamic>.from(stats['today'] ?? {});
            final month = Map<String, dynamic>.from(stats['month'] ?? {});
            final general = Map<String, dynamic>.from(stats['general'] ?? {});
            return [
              ReportItemModel(
                label: 'مبيعات اليوم',
                value: (today['sales'] as num? ?? 0).toDouble(),
              ),
              ReportItemModel(
                label: 'طلبات اليوم',
                value: (today['orders'] as num? ?? 0).toDouble(),
              ),
              ReportItemModel(
                label: 'مبيعات الشهر',
                value: (month['sales'] as num? ?? 0).toDouble(),
              ),
              ReportItemModel(
                label: 'طلبات الشهر',
                value: (month['orders'] as num? ?? 0).toDouble(),
              ),
              ReportItemModel(
                label: 'إجمالي العملاء',
                value: (general['total_customers'] as num? ?? 0).toDouble(),
              ),
              ReportItemModel(
                label: 'الأصناف المتاحة',
                value: (general['available_items'] as num? ?? 0).toDouble(),
              ),
            ];
          },
        ),
        ReportDefinition(
          displayName: 'تقرير ضريبي',
          fetchData: _reportService.getTaxSummary,
        ),
        ReportDefinition(
          displayName: 'تفصيلي ضريبي بالفواتير',
          fetchData: (from, to) async {
            final rows = await _reportService.getTaxDetailByInvoice(from, to);
            return rows
                .map(
                  (r) => ReportItemModel(
                    label:
                        'فاتورة #${r['order_id']} — ${(r['order_date'] ?? '').toString()}',
                    value: (r['tax_amount'] as num? ?? 0).toDouble(),
                    secondaryValue: (r['service_charge'] as num? ?? 0)
                        .toDouble(),
                  ),
                )
                .toList();
          },
        ),
      ],
      'المخزون والموردين': [
        ReportDefinition(
          displayName: 'حركة الأصناف',
          fetchData: _reportService.getItemMovement,
        ),
        ReportDefinition(
          displayName: 'تقرير المخزون المفصل',
          fetchData: (from, to) async {
            final inventory = await _advancedReportService.getInventoryReport();
            return inventory
                .map(
                  (item) => ReportItemModel(
                    label: '${item.itemName} (${item.category})',
                    value: item.currentStock,
                    secondaryValue: item.totalValue,
                  ),
                )
                .toList();
          },
          isTimeBound: false,
        ),
        ReportDefinition(
          displayName: 'تقرير المشتريات',
          fetchData: (from, to) async {
            final purchases = await _advancedReportService.getPurchaseReport(
              from,
              to,
            );
            return purchases
                .map(
                  (purchase) => ReportItemModel(
                    label: '${purchase.supplierName} - ${purchase.orderNumber}',
                    value: purchase.totalAmount,
                    secondaryValue: purchase.itemsCount.toDouble(),
                  ),
                )
                .toList();
          },
        ),
      ],
      'التقارير المالية المتقدمة': [
        ReportDefinition(
          displayName: 'الأرباح والخسائر المفصل',
          fetchData: _advancedReportService.getProfitLossAsReportItems,
        ),
        ReportDefinition(
          displayName: 'التدفق النقدي',
          fetchData: _advancedReportService.getCashFlowAsReportItems,
        ),
        ReportDefinition(
          displayName: 'مقارنة الأداء',
          fetchData: (from, to) async {
            // حساب الفترة السابقة
            final duration = to.difference(from);
            final previousEnd = from.subtract(const Duration(days: 1));
            final previousStart = previousEnd.subtract(duration);

            final comparisons = await _advancedReportService
                .getPerformanceComparison(from, to, previousStart, previousEnd);

            return comparisons
                .map(
                  (comp) => ReportItemModel(
                    label: '${comp.metric} (${comp.trend})',
                    value: comp.currentPeriod,
                    secondaryValue: comp.changePercentage,
                  ),
                )
                .toList();
          },
        ),
      ],
      'تقارير الموظفين': [
        ReportDefinition(
          displayName: 'تقرير الحضور والانصراف',
          fetchData: (from, to) async {
            final attendance = await _advancedReportService.getAttendanceReport(
              from,
              to,
            );
            return attendance
                .map(
                  (att) => ReportItemModel(
                    label:
                        '${att.employeeName} - ${att.date.toString().substring(0, 10)}',
                    value: att.totalHours,
                    secondaryValue: att.overtimeHours,
                  ),
                )
                .toList();
          },
        ),
        ReportDefinition(
          displayName: 'أداء الموظفين',
          fetchData: (from, to) async {
            final performance = await _advancedReportService
                .getEmployeePerformanceReport(from, to);
            return performance
                .map(
                  (perf) => ReportItemModel(
                    label: '${perf.employeeName} (${perf.position})',
                    value: perf.totalSales,
                    secondaryValue: perf.performanceScore,
                  ),
                )
                .toList();
          },
        ),
      ],
      'تقارير العملاء المتقدمة': [
        ReportDefinition(
          displayName: 'كشف حساب',
          fetchData: (_, __) => _reportService.getCustomerBalances(),
          isTimeBound: false,
        ),
        ReportDefinition(
          displayName: 'حركة مدفوعات',
          fetchData: _reportService.getCustomerPaymentsSummary,
        ),
        ReportDefinition(
          displayName: 'الأكثر شراءً',
          fetchData: _reportService.getTopCustomersSimple,
        ),
        ReportDefinition(
          displayName: 'ديون العملاء',
          fetchData: (_, __) => _reportService.getCustomerDebts(),
          isTimeBound: false,
        ),
        ReportDefinition(
          displayName: 'تقرير ولاء العملاء',
          fetchData: (from, to) async {
            final loyalty = await _advancedReportService
                .getCustomerLoyaltyReport();
            return loyalty
                .map(
                  (customer) => ReportItemModel(
                    label: '${customer.customerName} (${customer.loyaltyTier})',
                    value: customer.totalSpent,
                    secondaryValue: customer.loyaltyScore,
                  ),
                )
                .toList();
          },
          isTimeBound: false,
        ),
      ],
    };
  }
}
