// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// زر أساسي موحد للتطبيق، يدعم الأيقونات وحالات التحميل.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // اللون الافتراضي إذا لم يتم توفيره
    final color = backgroundColor ?? const Color(0xFF3B82F6);

    // بناء الزر بناءً على وجود أيقونة أم لا
    return icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: _buildIcon(),
            label: _buildLabel(),
            style: _buildStyle(color),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: _buildStyle(color),
            child: _buildLabel(),
          );
  }

  /// دالة خاصة لبناء محتوى الزر (نص أو مؤشر تحميل)
  Widget _buildLabel() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  /// دالة خاصة لبناء الأيقونة (تختفي أثناء التحميل)
  Widget _buildIcon() {
    if (isLoading) {
      // إرجاع حاوية فارغة للحفاظ على التنسيق
      return const SizedBox(width: 24);
    }
    return Icon(icon, color: Colors.white);
  }

  /// دالة خاصة لبناء تنسيق الزر الموحد
  ButtonStyle _buildStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      // تغيير لون الزر عند تعطيله
      disabledBackgroundColor: color.withOpacity(0.5),
    );
  }
}
