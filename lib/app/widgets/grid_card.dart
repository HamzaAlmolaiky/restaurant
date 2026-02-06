// file: lib/widgets/grid_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// بطاقة عرض عامة وقابلة لإعادة الاستخدام ضمن شبكة (Grid).
///
/// توفر هذه البطاقة هيكلاً موحدًا (إطار، ظل، حواف دائرية)
/// وقائمة إجراءات منبثقة اختيارية في الزاوية العلوية.
class GridCard extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry<String>>? menuItems;
  final Function(String value)? onMenuItemSelected;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  /// لون أيقونة قائمة الإجراءات (النقاط الثلاث).
  final Color menuIconColor;
  /// ويدجت قائمة بديل بالكامل (مثلاً ActionMenu) يُعرض بنفس الموضع.
  final Widget? menuWidget;

  const GridCard({
    super.key,
    required this.child,
    this.menuItems,
    this.onMenuItemSelected,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.menuIconColor = Colors.grey, // <-- القيمة الافتراضية هنا
    this.menuWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: clipBehavior,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(child: child),
              if (menuWidget != null || (menuItems != null && menuItems!.isNotEmpty))
                Positioned(
                  top: 8,
                  left: 8,
                  child: menuWidget ?? PopupMenuButton<String>(
                    onSelected: onMenuItemSelected,
                    itemBuilder: (BuildContext context) => menuItems!,
                    icon: Icon(Icons.more_vert, color: menuIconColor),
                    tooltip: 'خيارات',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
