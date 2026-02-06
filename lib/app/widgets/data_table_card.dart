// file: lib/widgets/data_table_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// مكون متخصص لعرض البيانات الجدولية داخل بطاقة ذات تصميم موحد.
/// يهتم بالإطار الخارجي وترتيب الترويسة والمحتوى.
class DataTableCard extends StatelessWidget {
  /// الويدجت الذي يمثل صف الترويسة للجدول.
  final Widget header;

  /// الويدجت الذي يمثل محتوى الجدول (عادة ما يكون ListView أو ObxState).
  final Widget body;

  const DataTableCard({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias, // يضمن أن المحتوى لا يتجاوز الحواف الدائرية
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
          // ١. ترويسة الجدول
          header,
          // ٢. فاصل بصري
          const Divider(height: 1, thickness: 1),
          // ٣. محتوى الجدول
          Expanded(child: body),
        ],
      ),
    );
  }
}
