// file: lib/widgets/dialogs/custom_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/dialog_helpers.dart';

class CustomFormDialog extends StatelessWidget {
  // --- الخصائص الأساسية (كانت موجودة) ---
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final GlobalKey<FormState> formKey;
  final List<Widget> formFields;
  final String confirmButtonText;
  final VoidCallback? onConfirm;
  final Widget? footer;

  // --- الخصائص الإضافية التي طلبتها (تمت إضافتها الآن) ---
  final AutovalidateMode? autovalidateMode;
  final double width;
  final bool showCloseIcon;
  final String cancelButtonText;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  final Widget? optionsSection;
  final bool isLoading;

  const CustomFormDialog({
    super.key,
    // --- الخصائص الأساسية ---
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.formKey,
    required this.formFields,
    this.confirmButtonText = 'حفظ',
    this.onConfirm,
    this.footer,

    // --- الخصائص الإضافية ---
    this.autovalidateMode,
    this.width = 480.0, // العرض الافتراضي
    this.showCloseIcon = true,
    this.cancelButtonText = 'إلغاء',
    this.onCancel,
    this.confirmButtonColor,
    this.optionsSection,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ١. الترويسة (تستخدم الآن showCloseIcon و onCancel)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: dialogHeader(
                    icon: icon,
                    color: iconColor,
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (showCloseIcon)
                  IconButton(
                    onPressed: onCancel ?? () => Get.back(),
                    icon: const Icon(Icons.close),
                    splashRadius: 18,
                    tooltip: 'إغلاق',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ٢. المحتوى (يستخدم الآن optionsSection و autovalidateMode)
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: autovalidateMode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._buildFieldsWithSpacers(),
                      if (optionsSection != null) ...[
                        const SizedBox(height: 16),
                        optionsSection!,
                      ],
                      if (footer != null) ...[
                        const SizedBox(height: 16),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ٣. أزرار الإجراءات (تستخدم الآن cancelButtonText و confirmButtonColor)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Get.back(),
                  child: Text(cancelButtonText),
                ),
                if (onConfirm != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // نستخدم true كقيمة افتراضية للتحقق في حالة عدم وجود نموذج فعلي
                      if (formKey.currentState?.validate() ?? true) {
                        onConfirm!(); // نستدعي الدالة (نحن متأكدون أنها ليست null هنا)
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmButtonColor ?? iconColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(confirmButtonText),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// دالة مساعدة لوضع فواصل بين الحقول.
  List<Widget> _buildFieldsWithSpacers() {
    final List<Widget> spacedFields = [];
    for (int i = 0; i < formFields.length; i++) {
      spacedFields.add(formFields[i]);
      if (i < formFields.length - 1) {
        spacedFields.add(const SizedBox(height: 12));
      }
    }
    return spacedFields;
  }
}
