// file: lib/widgets/data_table_row.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'data_table_header.dart'; // نحتاج هذا الملف للوصول إلى تعريف DataTableColumn

/// ويدجت متخصص لبناء صف بيانات داخل جدول، مع ضمان محاذاته مع الترويسة.
///
/// يأخذ قائمة بتعريفات الأعمدة (`columns`) وقائمة بالويدجتس (`cells`) التي
/// تمثل خلايا الصف، ويقوم تلقائيًا بتطبيق معامل التمدد (flex) من كل عمود
/// على الخلية المقابلة له.
class DataTableRow extends StatelessWidget {
  /// قائمة تعريف الأعمدة (مصدر الحقيقة الوحيد للعرض).
  /// يجب أن تكون هذه هي نفس القائمة التي تم تمريرها إلى DataTableHeader.
  final List<DataTableColumn> columns;

  /// قائمة الويدجتس التي تمثل خلايا هذا الصف.
  /// يجب أن يكون عددها مطابقًا تمامًا لعدد الأعمدة.
  final List<Widget> cells;

  /// لون خلفية الصف (اختياري).
  final Color? backgroundColor;

  /// الحشوة الداخلية للصف.
  final EdgeInsetsGeometry padding;

  const DataTableRow({
    super.key,
    required this.columns,
    required this.cells,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20),
  }) : assert(
         columns.length == cells.length,
         'خطأ في بناء الجدول: عدد الأعمدة (${columns.length}) يجب أن يتطابق تمامًا مع عدد الخلايا (${cells.length}).',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          // فاصل سفلي موحد لكل الصفوف
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // لمحاذاة العناصر عموديًا
        children: List.generate(cells.length, (index) {
          // لكل خلية، نأخذ الـ flex من قائمة الأعمدة المقابلة
          final columnDefinition = columns[index];
          final cellWidget = cells[index];

          // نلف كل خلية بـ Expanded ونعطيها الـ flex الصحيح
          return Expanded(flex: columnDefinition.flex, child: cellWidget);
        }),
      ),
    );
  }
}
