import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDialog {
  static Future<void> show({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color confirmColor = const Color(0xFFEF4444),
    IconData icon = Icons.warning,
    Color iconColor = const Color(0xFFEF4444),
    VoidCallback? onConfirm,
  }) async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(cancelText)),
          ElevatedButton(
            onPressed: () {
              if (onConfirm != null) onConfirm();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
