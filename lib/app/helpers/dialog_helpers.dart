// file: lib/helpers/dialog_helpers.dart
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_dialogs.dart';

/// دالة مساعدة موحدة لمعالجة عمليات الحفظ في النماذج.
Future<void> handleFormSubmission({
  required GlobalKey<FormState> formKey,
  required Future<void> Function() submissionFunction,
  String successTitle = 'تم بنجاح', // <-- عنوان مخصص للنجاح
  required String successMessage,
}) async {
  if (!(formKey.currentState?.validate() ?? false)) {
    return;
  }

  // عرض مؤشر التحميل (لا تغيير هنا)
  Get.dialog(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  try {
    await submissionFunction();

    Get.back(); // إغلاق مؤشر التحميل
    Get.back(); // إغلاق حوار النموذج

    await AppDialogs.showSuccess(successTitle, successMessage);
  } catch (e) {
    print('Form Submission Error: $e');

    Get.back(); // إغلاق مؤشر التحميل

    // عرض رسالة الخطأ الفعلية
    String errorMessage = e.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(11); // إزالة "Exception: "
    }

    await AppDialogs.showError(
      'فشل الحفظ',
      errorMessage,
    );
  }
}

/// دالة مساعدة لبناء قائمة منسدلة مع تصميم موحد
DropdownButtonFormField<String> buildStyledDropdownField({
  required String labelText,
  required String? value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  IconData? prefixIcon,
  bool enabled = true,
  String? Function(String?)? validator,
}) {
  return DropdownButtonFormField<String>(
    value: value,
    decoration: inputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
    ),
    items: items.map((String item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: enabled ? onChanged : null,
    validator: validator,
    isExpanded: true,
  );
}

/// دالة مساعدة لبناء قائمة منسدلة للعملاء
DropdownButtonFormField<int> buildCustomerDropdownField({
  required String labelText,
  required int? value,
  required List<Map<String, dynamic>> customers,
  required ValueChanged<int?> onChanged,
  IconData? prefixIcon,
  bool enabled = true,
  String? Function(int?)? validator,
}) {
  return DropdownButtonFormField<int>(
    value: value,
    decoration: inputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
    ),
    items: customers.map((customer) {
      return DropdownMenuItem<int>(
        value: customer['CustomerID'] as int,
        child: Text(
          '${customer['CustomerName']} ${customer['PhoneNumber'] != null ? '(${customer['PhoneNumber']})' : ''}',
        ),
      );
    }).toList(),
    onChanged: enabled ? onChanged : null,
    validator: validator,
    isExpanded: true,
  );
}

TextFormField buildStyledTextFormField({
  required TextEditingController controller,
  required String labelText,
  IconData? prefixIcon,
  TextInputType? keyboardType,
  bool isReadOnly = false,
  VoidCallback? onTap,
  ValueChanged<String>? onChanged,
  String? suffixText,
  int? maxLines = 1,
  bool obscureText = false, // <--- أضف هذا السطر
  bool enabled = true,

  ValidationType validationType = ValidationType.notEmpty,
  String? customValidationMessage,
  String? Function(String?)? customValidator,
}) {
  return TextFormField(
    controller: controller,
    decoration: inputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
    ),
    keyboardType: keyboardType,
    readOnly: isReadOnly,
    onTap: onTap,
    onChanged: onChanged,
    maxLines: maxLines,
    obscureText: obscureText, // <--- وقم بتمرير القيمة هنا
    enabled: enabled,
    // =============> منطق التحقق الذكي <=============
    validator: (value) {
      // ١. إذا تم تمرير دالة تحقق مخصصة، استخدمها دائمًا.
      if (customValidator != null) {
        return customValidator(value);
      }

      final text = value?.trim() ?? '';

      // ٢. إذا لم يتم تمرير دالة مخصصة، استخدم validationType.
      switch (validationType) {
        case ValidationType.notEmpty:
          if (text.isEmpty) {
            return customValidationMessage ?? 'هذا الحقل مطلوب';
          }
          break;

        case ValidationType.number:
          if (text.isEmpty) {
            return customValidationMessage ?? 'الرجاء إدخال رقم';
          }
          final n = int.tryParse(text);
          if (n == null || n <= 0) {
            return customValidationMessage ??
                'الرجاء إدخال رقم صحيح أكبر من صفر';
          }
          break;

        case ValidationType.decimal:
          if (text.isEmpty) {
            return customValidationMessage ?? 'الرجاء إدخال قيمة';
          }
          final d = double.tryParse(text);
          if (d == null || d < 0) {
            return customValidationMessage ?? 'الرجاء إدخال رقم موجب';
          }
          break;

        case ValidationType.email:
          if (text.isEmpty) {
            return customValidationMessage ?? 'البريد الإلكتروني مطلوب';
          }
          // مثال بسيط على التحقق من البريد الإلكتروني
          if (!GetUtils.isEmail(text)) {
            return customValidationMessage ??
                'صيغة البريد الإلكتروني غير صحيحة';
          }
          break;

        case ValidationType.phone:
          if (text.isEmpty) {
            return customValidationMessage ?? 'رقم الهاتف مطلوب';
          }
          if (!GetUtils.isPhoneNumber(text)) {
            return customValidationMessage ?? 'صيغة رقم الهاتف غير صحيحة';
          }
          break;

        case ValidationType.none:
          // لا تفعل شيئًا، الحقل اختياري
          break;
      }

      // إذا نجح كل شيء، أعد null
      return null;
    },
  );
}

// =======================================================
// ٢. الدوال المساعدة الأخرى التي يعتمد عليها CustomFormDialog
// =======================================================

/// تصميم موحد لترويسة الحوار.
Widget dialogHeader({
  required IconData icon,
  required Color color,
  required String title,
  String? subtitle,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    ],
  );
}

/// تصميم موحد لـ InputDecoration الخاص بحقول الإدخال.
InputDecoration inputDecoration({
  required String labelText,
  IconData? prefixIcon,
  String? suffixText,
}) {
  return InputDecoration(
    labelText: labelText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    suffixText: suffixText,
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF667EEA), width: 1.5),
    ),
  );
}

// في helpers/dialog_helpers.dart

enum ValidationType {
  none, // لا يوجد تحقق
  notEmpty, // يجب ألا يكون فارغًا (هذا هو الافتراضي)
  email, // يجب أن يكون بريدًا إلكترونيًا صالحًا
  number, // يجب أن يكون رقمًا صحيحًا أكبر من صفر
  decimal, // يجب أن يكون رقمًا عشريًا (يمكن أن يكون صفرًا أو أكبر)
  phone, // يجب أن يكون رقم هاتف صالح (مثال بسيط)
}
