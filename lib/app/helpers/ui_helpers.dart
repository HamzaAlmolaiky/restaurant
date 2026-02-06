// file: lib/helpers/ui_helpers.dart
import 'package:flutter/material.dart';

/// دالة مساعدة لبناء عنصر قياسي في قائمة منبثقة (PopupMenuEntry).
PopupMenuItem<String> buildPopupMenuItem({
  required String value,
  required IconData icon,
  required String text,
  Color? color,
  bool isDestructive = false, // للخيار "حذف"
}) {
  final itemColor = isDestructive ? Colors.red : color;

  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 16, color: itemColor),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: itemColor)),
      ],
    ),
  );
}
