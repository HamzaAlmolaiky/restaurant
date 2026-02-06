// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDialogs {
  AppDialogs._();

  /// Generic entry: decides which dialog to show based on title keywords
  /// Error if title contains: 'خطأ', 'فشل', 'error', 'fail'
  /// Success if title contains: 'تم', 'نجاح', 'success', 'done'
  /// Otherwise Info
  static Future<void> show(String title, String message) {
    final t = title.toLowerCase();
    final isError =
        t.contains('خطأ') ||
        t.contains('فشل') ||
        t.contains('error') ||
        t.contains('fail');
    final isSuccess =
        t.contains('تم') ||
        t.contains('نجاح') ||
        t.contains('success') ||
        t.contains('done');
    if (isError) return showError(title, message);
    if (isSuccess) return showSuccess(title, message);
    return showInfo(title, message);
  }

  static Future<void> showSuccess(String title, String message) {
    return _show(
      icon: Icons.check_circle,
      headerColor: const Color(0xFF10B981),
      iconColor: Colors.white,
      title: title.isEmpty ? 'نجاح' : title,
      message: message,
      positiveText: 'حسناً',
    );
  }

  static Future<void> showError(String title, String message) {
    return _show(
      icon: Icons.error_outline,
      headerColor: const Color(0xFFEF4444),
      iconColor: Colors.white,
      title: title.isEmpty ? 'حدث خطأ' : title,
      message: message,
      positiveText: 'إغلاق',
    );
  }

  static Future<void> showInfo(String title, String message) {
    return _show(
      icon: Icons.info_outline,
      headerColor: const Color(0xFF3B82F6),
      iconColor: Colors.white,
      title: title.isEmpty ? 'معلومة' : title,
      message: message,
      positiveText: 'حسناً',
    );
  }

  static Future<void> _show({
    required IconData icon,
    required Color headerColor,
    required Color iconColor,
    required String title,
    required String message,
    required String positiveText,
  }) {
    return Get.dialog(
      barrierColor: Colors.transparent,
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: headerColor, width: 1),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(message, style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
            // Actions
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: headerColor, width: 1.5),
                  ),
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(foregroundColor: headerColor),
                    child: Text(positiveText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }
}
