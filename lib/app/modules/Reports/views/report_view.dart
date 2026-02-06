// ignore_for_file: deprecated_member_use, avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../helpers/app_dialogs.dart';

import '../../../widgets/date_range_field.dart';
import '../../../widgets/filter_panel.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/responsive_filter_row.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../controllers/report_controller.dart';
import '../models/diagram_model.dart';
import '../models/report_model.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'التقارير والإحصائيات',
            subtitle: 'تقارير شاملة عن المبيعات والأداء المالي',
            actions: [
              PrimaryButton(
                text: 'تصدير البيانات',
                onPressed: () => _showExportDialog(context),
                icon: Icons.file_download_outlined,
                backgroundColor: const Color(0xFF10B981),
              ),
            ],
          ),

          /// Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernFilters(context),
                  const SizedBox(height: 24),
                  Obx(
                    () => controller.isLoading.value
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8B5CF6),
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildModernStatsGrid(),
                  const SizedBox(height: 32),
                  _buildModernChartsSection(),
                  const SizedBox(height: 32),
                  _buildModernReportData(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت الفلاتر الحديثة باستخدام مكونات معيارية قابلة لإعادة الاستخدام.
  Widget _buildModernFilters(BuildContext context) {
    return FilterPanel(
      child: Obx(() {
        // العنصر الأول: الفئة الرئيسية (دائمًا ظاهر)
        final mainCategoryFilter = SpacedRowItem(
          flex: 2,
          child: StyledDropdownFormField<String>(
            labelText: 'فئة التقرير',
            value: controller.selectedCategoryKey.value,
            items: controller.reportCatalog.keys.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: controller.changeMainCategory,
          ),
        );

        // العنصر الثاني: التقرير الفرعي (دائمًا ظاهر)
        final subReportFilter = SpacedRowItem(
          flex: 3,
          child: StyledDropdownFormField<ReportDefinition>(
            labelText: 'التقرير المحدد',
            value: controller.selectedReportDefinition.value,
            isExpanded: true,
            items: controller.availableSubReports.map((
              ReportDefinition reportDef,
            ) {
              return DropdownMenuItem<ReportDefinition>(
                value: reportDef,
                child: Text(
                  reportDef.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) controller.changeAndBuildReport(val);
            },
          ),
        );

        // العنصر الثالث: الفترة الزمنية (يتم بناؤه بشكل شرطي)
        final periodFilter = SpacedRowItem(
          flex: 2,
          child:
              (controller.selectedReportDefinition.value?.isTimeBound ?? true)
              ? StyledDropdownFormField<ReportPeriod>(
                  labelText: 'الفترة الزمنية',
                  value: controller.selectedPeriod.value,
                  items: const [
                    DropdownMenuItem(
                      value: ReportPeriod.daily,
                      child: Text('يومي'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriod.weekly,
                      child: Text('أسبوعي'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriod.monthly,
                      child: Text('شهري'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriod.yearly,
                      child: Text('سنوي'),
                    ),
                    DropdownMenuItem(
                      value: ReportPeriod.custom,
                      child: Text('مخصص'),
                    ),
                  ],
                  onChanged: (p) async {
                    if (p == null) return;
                    controller.applyPeriodAndRebuild(p);
                    if (p == ReportPeriod.custom) {
                      final picked = await _showCustomDateRangePicker(
                        context,
                        initialStartDate: controller.fromDate.value,
                        initialEndDate: controller.toDate.value,
                      );
                      if (picked != null) {
                        controller.applyDateFilter(picked.start, picked.end);
                      }
                    }
                  },
                )
              : const SizedBox.shrink(), // <-- يعيد ويدجت فارغ إذا كان مخفيًا
        );

        // العنصر الرابع: نطاق التاريخ (يتم بناؤه بشكل شرطي)
        final dateRangeFilter = SpacedRowItem(
          flex: 3,
          child:
              ((controller.selectedReportDefinition.value?.isTimeBound ??
                      true) &&
                  controller.selectedPeriod.value == ReportPeriod.custom)
              ? DateRangeField(
                  labelText: 'نطاق التاريخ',
                  rangeLabel: () {
                    final from = controller.fromDate.value;
                    final to = controller.toDate.value;
                    if (from != null && to != null) {
                      String fmt(DateTime d) =>
                          DateFormat('yyyy/MM/dd').format(d);
                      return '${fmt(from)} - ${fmt(to)}';
                    }
                    return 'اختر نطاق التاريخ';
                  }(),
                  onTap: () async {
                    final picked = await _showCustomDateRangePicker(
                      context,
                      initialStartDate: controller.fromDate.value,
                      initialEndDate: controller.toDate.value,
                    );
                    if (picked != null) {
                      controller.applyDateFilter(picked.start, picked.end);
                    }
                  },
                )
              : const SizedBox.shrink(), // <-- يعيد ويدجت فارغ إذا كان مخفيًا
        );

        // ====================================================================
        // ٢. تمرير قائمة "الوصفات" إلى ResponsiveFilterRow ليقوم ببناء الواجهة
        // ====================================================================
        return ResponsiveFilterRow(
          items: [
            mainCategoryFilter,
            subReportFilter,
            periodFilter,
            dateRangeFilter,
          ],
        );
      }),
    );
  }

  Future<DateTimeRange?> _showCustomDateRangePicker(
    BuildContext context, {
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) async {
    // ##### تم التعديل لاستخدام الويدجت الجديد #####
    return Get.dialog<DateTimeRange>(
      CustomDateRangePickerGetX(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
  }

  Widget _buildModernStatsGrid() {
    return Obx(
      () => StatisticsRow(
        children: [
          StatisticsCard(
            title: 'مبيعات اليوم',
            value: _formatCurrency(controller.todaySales.value),
            icon: Icons.attach_money,
            color: const Color(0xFF10B981),
          ),
          StatisticsCard(
            title: 'طلبات اليوم',
            value: controller.todayOrders.value.toString(),
            icon: Icons.shopping_cart,
            color: const Color(0xFF3B82F6),
          ),
          StatisticsCard(
            title: 'متوسط الطلب (اليوم)',
            value: _formatCurrency(
              controller.todayOrders.value > 0
                  ? controller.todaySales.value / controller.todayOrders.value
                  : 0,
            ),
            icon: Icons.trending_up,
            color: const Color(0xFF8B5CF6),
          ),
          StatisticsCard(
            title: 'إجمالي العملاء',
            value: controller.totalCustomers.value.toString(),
            icon: Icons.people,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChartsSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المبيعات خلال الفترة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildSalesChart()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توزيع الإيراد حسب الفئة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildCategoryPieChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernReportData() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(
              'بيانات تقرير: ${controller.reportTitle.value}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final data = controller.reportData;
            if (data.isEmpty) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد بيانات لعرضها',
                      style: TextStyle(color: Color(0xFF1F2937), fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختر نوع تقرير ونطاق زمني لعرض البيانات',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'البند',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'القيمة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'القيمة الثانوية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: index.isEven
                            ? Colors.white
                            : const Color(0xFFFDFDFD),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  color: Color(0xFF2D3748),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatCurrency(item.value),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.secondaryValue != null
                                    ? _formatCurrency(item.secondaryValue!)
                                    : '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF2D3748),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return Obx(() {
      final data = controller.monthlySalesData;
      if (data.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد بيانات مبيعات',
            style: TextStyle(color: Color(0xFF1F2937)),
          ),
        );
      }
      final points = [
        for (var item in data)
          Point(
            (item['date'] as String).substring(5),
            (item['total_sales'] as num? ?? 0).toDouble(),
          ),
      ];
      return SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          axisLine: AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: const TextStyle(color: Color(0xFF1F2937), fontSize: 10),
          majorGridLines: const MajorGridLines(width: 1, color: Colors.grey),
          axisLine: const AxisLine(width: 0),
          minimum: 0,
        ),
        series: <ColumnSeries<Point, String>>[
          ColumnSeries<Point, String>(
            dataSource: points,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            width: 0.6,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.y'),
        enableAxisAnimation: true,
        plotAreaBorderWidth: 0,
      );
    });
  }

  Widget _buildCategoryPieChart() {
    return Obx(() {
      final items = controller.categoryRevenue;
      if (items.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد بيانات للفئات',
            style: TextStyle(color: Color(0xFF1F2937)),
          ),
        );
      }
      final data = [for (final e in items) Pie(e.label, e.value)];
      return SfCircularChart(
        legend: const Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(color: Color(0xFF1F2937)),
          position: LegendPosition.bottom,
        ),
        series: <PieSeries<Pie, String>>[
          PieSeries<Pie, String>(
            dataSource: data,
            xValueMapper: (d, _) => d.category,
            yValueMapper: (d, _) => d.value,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            explode: false,
            radius: '90%',
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x : point.y',
        ),
      );
    });
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.download, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text('تصدير التقرير'),
            ],
          ),
          content: const SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سيتم نسخ بيانات التقرير الحالي بصيغة CSV إلى الحافظة.'),
                SizedBox(height: 8),
                Text('يمكنك لصقها في Excel أو أي محرر CSV.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final csv = controller.exportCurrentReportToCsv();
                if (csv.isEmpty) {
                  AppDialogs.showInfo('تنبيه', 'لا توجد بيانات لتصديرها');
                  return;
                }
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  AppDialogs.showSuccess('نجاح', 'تم نسخ CSV إلى الحافظة');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('نسخ CSV'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(num v) => '${v.toStringAsFixed(2)} ريال';
}

// ####################################################################
// ###### ويدجت + كنترولر جديدين لإدارة الواجهة المخصصة باستخدام GetX ######
// ####################################################################

/// Controller لإدارة حالة منتقي التاريخ
class CustomDateRangePickerController extends GetxController {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  CustomDateRangePickerController({this.initialStartDate, this.initialEndDate});

  @override
  void onInit() {
    super.onInit();
    startDate.value = initialStartDate;
    endDate.value = initialEndDate;
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStartDate ? startDate.value : endDate.value) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStartDate) {
        startDate.value = picked;
      } else {
        endDate.value = picked;
      }
    }
  }

  void confirm() {
    if (startDate.value != null && endDate.value != null) {
      if (startDate.value!.isAfter(endDate.value!)) {
        Get.snackbar(
          'خطأ',
          'تاريخ البدء يجب أن يكون قبل تاريخ الانتهاء.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      Get.back(
        result: DateTimeRange(start: startDate.value!, end: endDate.value!),
      );
    }
  }
}

/// Widget لعرض الواجهة المخصصة لاختيار التاريخ (Stateless)
class CustomDateRangePickerGetX extends StatelessWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CustomDateRangePickerGetX({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام Get.put لإنشاء وحقن الـ controller
    final controller = Get.put(
      CustomDateRangePickerController(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
    final DateFormat formatter = DateFormat('MM/dd/yyyy');

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'اختر النطاق الزمني',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // استخدام Obx لمراقبة التغيرات في التواريخ وإعادة بناء الواجهة
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDateField(
                    context,
                    controller: controller,
                    label: 'End Date',
                    date: controller.endDate.value,
                    formatter: formatter,
                    onTap: () => controller.selectDate(context, false),
                    isSelected: false,
                  ),
                  const SizedBox(width: 16),
                  _buildDateField(
                    context,
                    controller: controller,
                    label: 'Start Date',
                    date: controller.startDate.value,
                    formatter: formatter,
                    onTap: () => controller.selectDate(context, true),
                    isSelected: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: controller.confirm,
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required CustomDateRangePickerController controller,
    required String label,
    required DateTime? date,
    required DateFormat formatter,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD9CCEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 68, 67, 67),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date != null ? formatter.format(date) : '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
