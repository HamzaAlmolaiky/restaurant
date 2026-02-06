import 'package:flutter/material.dart';

class FilterChipOption {
  final String label;
  final String value;
  const FilterChipOption({required this.label, required this.value});
}

class FilterChipsBar extends StatelessWidget {
  final List<FilterChipOption> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double runSpacing;

  const FilterChipsBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(vertical: 0),
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: padding,
        child: Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: options.map((opt) {
            final bool isSelected = opt.value == selected;
            // ألوان متوافقة مع النمط المستخدم حالياً (أخضر للفعال، أحمر لغيره عند الحاجة)
            final selectedColor = isSelected ? const Color(0xFFECFDF5) : null;
            final textColor = isSelected ? const Color(0xFF10B981) : const Color(0xFF2D3748);
            return ChoiceChip(
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (_) => onChanged(opt.value),
              selectedColor: selectedColor,
              labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
    );
  }
}
