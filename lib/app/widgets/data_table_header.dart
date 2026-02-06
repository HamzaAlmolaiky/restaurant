// file: lib/widgets/data_table_header.dart
import 'package:flutter/material.dart';

/// ويدجت عام وقابل لإعادة الاستخدام لبناء ترويسة الجداول.
/// يقوم ببناء صف من العناوين ديناميكيًا بناءً على قائمة الأعمدة الممررة.
class DataTableHeader extends StatelessWidget {
  /// قائمة الأعمدة التي سيتم عرضها.
  final List<DataTableColumn> columns;

  const DataTableHeader({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    const headerTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF64748B),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        // استخدام map لتحويل كل كائن DataTableColumn إلى ويدجت Expanded
        children: columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(column.title, style: headerTextStyle),
          );
        }).toList(), // تحويل الناتج إلى قائمة من الويدجتس
      ),
    );
  }
}

/// كلاس مساعد لتعريف خصائص كل عمود في ترويسة الجدول.
class DataTableColumn {
  /// النص الذي سيظهر كعنوان للعمود.
  final String title;

  /// معامل التمدد (flex) لتحديد عرض العمود النسبي.
  final int flex;

  const DataTableColumn({
    required this.title,
    this.flex = 1, // القيمة الافتراضية هي 1 إذا لم يتم تحديدها
  });
}
