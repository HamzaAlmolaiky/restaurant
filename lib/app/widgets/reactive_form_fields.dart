// file: lib/widgets/reactive_form_fields.dart
import 'package:flutter/material.dart';
import '../helpers/dialog_helpers.dart'; // تأكد من صحة هذا المسار

/// مكون متخصص يربط DropdownButtonFormField مع ValueNotifier تلقائيًا.
class ValueListenableDropdown<T> extends StatelessWidget {
  final ValueNotifier<T> valueNotifier;
  final String labelText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final String? Function(T?)? validator;

  const ValueListenableDropdown({
    super.key,
    required this.valueNotifier,
    required this.labelText,
    this.prefixIcon,
    required this.items,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام ValueListenableBuilder داخليًا لإخفاء التعقيد
    return ValueListenableBuilder<T>(
      valueListenable: valueNotifier,
      builder: (context, value, _) {
        return DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: (newValue) {
            if (newValue != null) {
              valueNotifier.value = newValue;
            }
          },
          // استخدام دالة التصميم الموحدة من helpers
          decoration: inputDecoration(
            labelText: labelText,
            prefixIcon: prefixIcon,
          ),
          validator: validator,
        );
      },
    );
  }
}

/// مكون متخصص يربط SwitchListTile مع ValueNotifier تلقائيًا.
class ValueListenableSwitchTile extends StatelessWidget {
  final ValueNotifier<bool> valueNotifier;
  final String title;
  final Color? activeColor;

  const ValueListenableSwitchTile({
    super.key,
    required this.valueNotifier,
    required this.title,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام ValueListenableBuilder داخليًا
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (context, value, _) {
        return SwitchListTile(
          value: value,
          onChanged: (newValue) => valueNotifier.value = newValue,
          title: Text(title),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: activeColor,
        );
      },
    );
  }
}
