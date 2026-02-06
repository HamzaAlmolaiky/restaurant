// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modules/Shift/models/shift_details_model.dart';

class ShiftCard extends StatelessWidget {
  final ShiftDetailsModel shift;
  // دالة رد اتصال (callback) لإعلام الويدجت الأب بالإجراء المطلوب
  final Function(String action, ShiftDetailsModel shift)? onActionSelected;

  const ShiftCard({super.key, required this.shift, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
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
          // Shift Header
          _buildHeader(),
          // Shift Details
          _buildDetails(context),
        ],
      ),
    );
  }

  // --- ويدجتات مساعدة داخلية لتقسيم الكود ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(shift.status).withOpacity(0.08),
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
              color: _getStatusColor(shift.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وردية ${shift.userName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  _formatShiftTimeRange(shift.startTime, shift.endTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(shift.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(shift.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _mapStatusText(shift.status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(shift.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildDetailItem('المسؤول', shift.userName),
              _buildDetailItem(
                'الإيرادات',
                '${shift.totalReceipts.toStringAsFixed(2)} ريال',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                'المبيعات',
                '${shift.totalSales.toStringAsFixed(2)} ريال',
                valueColor: const Color(0xFF059669),
              ),
              // القائمة المنبثقة
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                onSelected: (String value) {
                  // استدعاء دالة رد الاتصال عند اختيار عنصر
                  onActionSelected?.call(value, shift);
                },
                itemBuilder: (BuildContext context) => [
                  _buildPopupMenuItem(
                    'view',
                    Icons.visibility,
                    'عرض التفاصيل',
                    const Color(0xFF3B82F6),
                  ),
                  _buildPopupMenuItem(
                    'edit',
                    Icons.edit,
                    'تعديل',
                    const Color(0xFF10B981),
                  ),
                  _buildPopupMenuItem(
                    'report',
                    Icons.assessment,
                    'تقرير الوردية',
                    const Color(0xFF8B5CF6),
                  ),
                  _buildPopupMenuItem(
                    'close',
                    Icons.close,
                    'إغلاق الوردية',
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- دوال مساعدة داخلية خاصة بالكلاس ---

  Expanded _buildDetailItem(String title, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF10B981);
      case 'Closed':
        return const Color(0xFF3B82F6);
      case 'Canceled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _mapStatusText(String status) {
    switch (status) {
      case 'Open':
        return 'نشطة';
      case 'Closed':
        return 'مكتملة';
      case 'Canceled':
        return 'ملغية';
      default:
        return status;
    }
  }

  String _formatShiftTimeRange(DateTime start, DateTime? end) {
    final startStr = DateFormat.jm().format(start);
    final endStr = end != null ? DateFormat.jm().format(end) : '...';
    return '$startStr - $endStr';
  }
}
