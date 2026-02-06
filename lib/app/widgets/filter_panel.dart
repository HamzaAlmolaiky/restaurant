// file: lib/widgets/filter_panel.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// هذا المكون يوفر الإطار الخارجي (اللون، الظل، الحواف) لأي لوحة فلات
class FilterPanel extends StatelessWidget {
  final Widget child;

  const FilterPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
