// file: lib/widgets/styled_text_form_field.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../modules/Users/models/user_model.dart';

/// حاوية موحدة لحقول الإدخال والقوائم المنسدلة في التطبيق.
class StyledInputContainer extends StatelessWidget {
  final Widget child;

  const StyledInputContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

/// ويدجت مساعد لبناء عنصر القائمة المنسدلة للمستخدم
Widget buildUserDropdownItem(UserModel user) {
  final bool isAdmin =
      user.role.toLowerCase() == 'admin' || user.role.toLowerCase() == 'مشرف';
  final Color roleColor = isAdmin
      ? const Color(0xFF10B981)
      : const Color(0xFF3B82F6);
  final IconData roleIcon = isAdmin
      ? Icons.admin_panel_settings
      : Icons.point_of_sale;

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(roleIcon, size: 16, color: roleColor),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Row(
          children: [
            Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            Text(
              isAdmin ? '(مشرف)' : '(كاشير)',
              style: TextStyle(fontSize: 12, color: roleColor),
            ),
          ],
        ),
      ),
    ],
  );
}
