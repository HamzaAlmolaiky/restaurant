// file: lib/helpers/ui_helpers.dart
import 'dart:io';
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

/// دالة مساعدة لعرض الصورة سواء كانت رابط إنترنت، أصل (Asset)، أو ملف محلي من الجهاز.
Widget buildAppImage(
  String? path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.fill,
  Widget? placeholder,
}) {
  final fallback = placeholder ?? const Icon(Icons.image, size: 40, color: Colors.grey);
  if (path == null || path.trim().isEmpty) {
    return fallback;
  }
  final cleanPath = path.trim();
  if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
    return Image.network(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red),
    );
  }
  if (cleanPath.startsWith('assets/')) {
    return Image.asset(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red),
    );
  }
  try {
    return Image.file(
      File(cleanPath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.red),
    );
  } catch (e) {
    return const Icon(Icons.broken_image, size: 40, color: Colors.red);
  }
}
