// file: lib/widgets/responsive_filter_row.dart
import 'package:flutter/material.dart';

/// كلاس مساعد لتمرير ويدجت مع معامل التمدد (flex) الخاص به.
class SpacedRowItem {
  final Widget child;
  final int flex;

  const SpacedRowItem({
    required this.child,
    this.flex = 1, // القيمة الافتراضية هي 1
  });
}

/// ويدجت متخصص لبناء صف من العناصر القابلة للتمدد (Expanded)
/// مع إضافة فواصل (SizedBox) بينها تلقائيًا.
class ResponsiveFilterRow extends StatelessWidget {
  /// قائمة العناصر التي سيتم عرضها.
  final List<SpacedRowItem> items;

  /// المسافة بين كل عنصر والآخر.
  final double spacing;

  const ResponsiveFilterRow({
    super.key,
    required this.items,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    // المرور على قائمة العناصر لبناء الواجهة
    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // لا تقم بإضافة العناصر الفارغة (SizedBox.shrink) إلى الصف
      if (item.child is SizedBox && (item.child as SizedBox).width == 0.0) {
        continue;
      }

      // أضف العنصر داخل Expanded مع الـ flex الخاص به
      children.add(Expanded(flex: item.flex, child: item.child));

      // أضف فاصلًا إذا لم يكن هذا هو العنصر الأخير الظاهر في القائمة
      if (i < items.length - 1) {
        // تحقق مما إذا كان العنصر التالي ليس فارغًا أيضًا قبل إضافة الفاصل
        final nextItemVisible =
            !(items[i + 1].child is SizedBox &&
                (items[i + 1].child as SizedBox).width == 0.0);
        if (nextItemVisible) {
          children.add(SizedBox(width: spacing));
        }
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
