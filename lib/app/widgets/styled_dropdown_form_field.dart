// file: lib/widgets/styled_dropdown_form_field.dart
import 'package:flutter/material.dart';

/// هذا المكون مخصص للقوائم المنسدلة التي تكون جزءًا من نموذج (Form) ولها تصميم خاص (مثل التي في شاشة التقارير)
class StyledDropdownFormField<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isExpanded;
  final double? width; // عرض اختياري للمكون بالكامل
  final BoxConstraints? constraints; // قيود اختيارية (عرض/ارتفاع أدنى/أقصى)

  const StyledDropdownFormField({
    super.key,
    required this.labelText,
    this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.width,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: isExpanded,
      borderRadius: BorderRadius.circular(20),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );

    if (constraints != null) {
      field = ConstrainedBox(constraints: constraints!, child: field);
    }
    if (width != null) {
      field = SizedBox(width: width, child: field);
    }

    return field;
  }
}
