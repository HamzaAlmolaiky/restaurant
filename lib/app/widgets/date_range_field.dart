// file: lib/widgets/date_range_field.dart
import 'package:flutter/material.dart';

/// هذا المكون مخصص لعرض نطاق التاريخ القابل للنقر في شاشة التقارير
class DateRangeField extends StatelessWidget {
  final String labelText;
  final String rangeLabel;
  final VoidCallback onTap;

  const DateRangeField({
    super.key,
    required this.labelText,
    required this.rangeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rangeLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
