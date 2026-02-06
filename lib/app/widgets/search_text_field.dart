// file: lib/widgets/search_text_field.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final Color? focusedBorderColor;

  const SearchTextField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    // اللون الافتراضي للإطار عند التركيز
    final focusColor = focusedBorderColor ?? Theme.of(context).primaryColor;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        // التنسيقات الموحدة للإطار والألوان
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
