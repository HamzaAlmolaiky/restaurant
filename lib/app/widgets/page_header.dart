import 'package:flutter/material.dart';

/// ويدجت موحد لترويسة الصفحة يعرض العنوان والأزرار وأي محتوى إضافي.
/// يقوم تلقائيًا بإضافة فواصل بين أزرار الإجراءات.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? bottomChild;

  /// المسافة التي ستوضع بين كل زر والآخر في قائمة الإجراءات.
  final double actionSpacing;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.bottomChild,
    this.actionSpacing = 12.0, // قيمة افتراضية للمسافة
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Subtitle
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Action Buttons (with automatic spacing)
              if (actions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  // استدعاء الدالة الجديدة التي تضيف الفواصل
                  children: _buildSpacedActions(),
                ),
            ],
          ),
          // Optional Bottom Widget (like StatisticsRow)
          if (bottomChild != null) ...[
            const SizedBox(height: 24),
            bottomChild!,
          ],
        ],
      ),
    );
  }

  /// دالة خاصة لبناء قائمة أزرار الإجراءات مع إضافة الفواصل تلقائيًا.
  List<Widget> _buildSpacedActions() {
    // إذا كان هناك زر واحد فقط، لا حاجة للفواصل
    if (actions.length <= 1) {
      return actions;
    }

    final List<Widget> spacedActions = [];
    for (int i = 0; i < actions.length; i++) {
      // أضف الزر
      spacedActions.add(actions[i]);

      // إذا لم يكن هذا هو الزر الأخير، أضف فاصلًا بعده
      if (i < actions.length - 1) {
        spacedActions.add(SizedBox(width: actionSpacing));
      }
    }

    return spacedActions;
  }
}
