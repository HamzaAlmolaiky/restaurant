// file: lib/widgets/filter_bar.dart
import 'package:flutter/material.dart';

/// ويدجت متخصص لبناء شريط الفلاتر القياسي في التطبيق.
/// يقوم تلقائيًا بترتيب العناصر في صف وتوزيع المساحة بينها بالتساوي.
class FilterBar extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;

  const FilterBar({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildChildrenWithSpacers(),
      ),
    );
  }

  /// دالة داخلية لبناء العناصر مع الفواصل وتطبيق Expanded على جميع العناصر.
  List<Widget> _buildChildrenWithSpacers() {
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      final child = children[i];

      // ==================> التعديل الرئيسي هنا <==================
      // قم دائمًا بلف كل عنصر داخل Expanded.
      // هذا هو الحل الأكثر أمانًا لضمان عدم حدوث أخطاء "unbounded width".
      widgets.add(Expanded(child: child));
      // ==================> نهاية التعديل <==================

      // أضف فاصلًا إذا لم يكن هذا هو العنصر الأخير
      if (i < children.length - 1) {
        widgets.add(SizedBox(width: spacing));
      }
    }
    return widgets;
  }
}
