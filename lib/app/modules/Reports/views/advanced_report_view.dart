// file: views/advanced_report_view.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controllers/report_controller.dart';
import '../models/report_model.dart';
import '../../../helpers/app_dialogs.dart';

class AdvancedReportView extends GetView<ReportController> {
  const AdvancedReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildAdvancedHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildReportContent()),
                _buildAdvancedFilters(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'التقارير المتقدمة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'تقارير مفصلة وتحليلات متقدمة',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          label: 'تحديث',
          onPressed: () => controller.buildReport(
            controller.fromDate.value!,
            controller.toDate.value!,
          ),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.download,
          label: 'تصدير',
          onPressed: _showExportDialog,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.schedule,
          label: 'جدولة',
          onPressed: _showScheduleDialog,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF475569),
        elevation: 0,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'فلاتر التقارير',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportTypeFilter(),
                  const SizedBox(height: 24),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 24),
                  _buildComparisonFilter(),
                  const SizedBox(height: 24),
                  _buildGroupingFilter(),
                  const SizedBox(height: 24),
                  _buildMetricsFilter(),
                  const SizedBox(height: 24),
                  _buildApplyButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع التقرير',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedCategoryKey.value,
            decoration: _inputDecoration(),
            items: controller.reportCatalog.keys.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.updateSubReportsForCategory(value);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedReportDefinition.value?.displayName,
            decoration: _inputDecoration(hint: 'اختر التقرير الفرعي'),
            items: controller.availableSubReports.map((report) {
              return DropdownMenuItem(
                value: report.displayName,
                child: Text(report.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final report = controller.availableSubReports.firstWhere(
                  (r) => r.displayName == value,
                );
                controller.selectedReportDefinition.value = report;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفترة الزمنية',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => DropdownButtonFormField<ReportPeriod>(
            value: controller.selectedPeriod.value,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(value: ReportPeriod.daily, child: Text('يومي')),
              DropdownMenuItem(
                value: ReportPeriod.weekly,
                child: Text('أسبوعي'),
              ),
              DropdownMenuItem(
                value: ReportPeriod.monthly,
                child: Text('شهري'),
              ),
              DropdownMenuItem(value: ReportPeriod.yearly, child: Text('سنوي')),
              DropdownMenuItem(value: ReportPeriod.custom, child: Text('مخصص')),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.selectedPeriod.value = value;
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.selectedPeriod.value == ReportPeriod.custom) {
            return Column(
              children: [
                TextFormField(
                  decoration: _inputDecoration(hint: 'من تاريخ'),
                  readOnly: true,
                  controller: TextEditingController(
                    text:
                        controller.fromDate.value?.toString().substring(
                          0,
                          10,
                        ) ??
                        '',
                  ),
                  onTap: () => _selectDate(true),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: _inputDecoration(hint: 'إلى تاريخ'),
                  readOnly: true,
                  controller: TextEditingController(
                    text:
                        controller.toDate.value?.toString().substring(0, 10) ??
                        '',
                  ),
                  onTap: () => _selectDate(false),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildComparisonFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المقارنة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('مقارنة مع الفترة السابقة'),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('مقارنة مع نفس الفترة العام الماضي'),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildGroupingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التجميع',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration(),
          items: const [
            DropdownMenuItem(value: 'day', child: Text('يومي')),
            DropdownMenuItem(value: 'week', child: Text('أسبوعي')),
            DropdownMenuItem(value: 'month', child: Text('شهري')),
            DropdownMenuItem(value: 'quarter', child: Text('ربع سنوي')),
            DropdownMenuItem(value: 'year', child: Text('سنوي')),
          ],
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildMetricsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المقاييس',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('إظهار النسب المئوية'),
          value: true,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('إظهار المتوسطات'),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('إظهار الاتجاهات'),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (controller.fromDate.value != null &&
              controller.toDate.value != null) {
            controller.buildReport(
              controller.fromDate.value!,
              controller.toDate.value!,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('تطبيق الفلاتر'),
      ),
    );
  }

  Widget _buildReportContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(),
            const SizedBox(height: 24),
            _buildChartsSection(),
            const SizedBox(height: 24),
            _buildDataTable(),
          ],
        ),
      );
    });
  }

  Widget _buildReportHeader() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.reportTitle.value.isNotEmpty
                  ? controller.reportTitle.value
                  : 'اختر تقريراً لعرضه',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الفترة: ${controller.fromDate.value?.toString().substring(0, 10) ?? ''} - ${controller.toDate.value?.toString().substring(0, 10) ?? ''}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard(
                  'إجمالي العناصر',
                  controller.reportData.length.toString(),
                  Icons.list_alt,
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'إجمالي القيمة',
                  controller.reportData
                      .fold<double>(0, (sum, item) => sum + item.value)
                      .toStringAsFixed(2),
                  Icons.attach_money,
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Obx(() {
      if (controller.reportData.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المخططات البيانية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries<dynamic, dynamic>>[
                  ColumnSeries<ReportItemModel, String>(
                    dataSource: controller.reportData.take(10).toList(),
                    xValueMapper: (data, _) => data.label,
                    yValueMapper: (data, _) => data.value,
                    color: const Color(0xFF667EEA),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDataTable() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'بيانات التقرير',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('البيان')),
                  DataColumn(label: Text('القيمة')),
                  DataColumn(label: Text('القيمة الثانوية')),
                ],
                rows: controller.reportData.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item.label)),
                      DataCell(Text(item.value.toStringAsFixed(2))),
                      DataCell(
                        Text(item.secondaryValue?.toStringAsFixed(2) ?? '-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF667EEA)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  Future<void> _selectDate(bool isFromDate) async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      if (isFromDate) {
        controller.fromDate.value = date;
      } else {
        controller.toDate.value = date;
      }
    }
  }

  void _showExportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تصدير التقرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              onTap: () {
                Get.back();
                _exportToCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Get.back();
                AppDialogs.showInfo('معلومة', 'تصدير PDF قيد التطوير');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_view),
              title: const Text('Excel'),
              onTap: () {
                Get.back();
                AppDialogs.showInfo('معلومة', 'تصدير Excel قيد التطوير');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('جدولة التقرير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر تكرار إرسال التقرير:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('يومي')),
                DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                DropdownMenuItem(value: 'monthly', child: Text('شهري')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: _inputDecoration(hint: 'البريد الإلكتروني'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              AppDialogs.showInfo('معلومة', 'جدولة التقارير قيد التطوير');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _exportToCsv() {
    final csv = controller.exportCurrentReportToCsv();
    if (csv.isNotEmpty) {
      AppDialogs.showSuccess('تم', 'تم تصدير التقرير بنجاح');
    } else {
      AppDialogs.showError('خطأ', 'لا توجد بيانات للتصدير');
    }
  }
}
