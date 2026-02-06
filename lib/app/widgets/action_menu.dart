import 'package:flutter/material.dart';

class ActionItem {
  final String value;
  final String text;
  final IconData icon;
  final Color? color;
  final bool isDestructive;
  const ActionItem({
    required this.value,
    required this.text,
    required this.icon,
    this.color,
    this.isDestructive = false,
  });
}

class ActionMenu extends StatelessWidget {
  final List<ActionItem> items;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;
  final Widget? trigger; // يسمح باستخدام أيقونة عارية لضمان تطابق المظهر 1:1

  const ActionMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.trigger,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (context) {
          return items.map((item) {
            final color = item.color ??
                (item.isDestructive ? const Color(0xFFEF4444) : const Color(0xFF2D3748));
            return PopupMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    item.text,
                    style: TextStyle(
                      color: color,
                      fontWeight: item.isDestructive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        child: trigger ?? Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F4F6),
          ),
          child: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
