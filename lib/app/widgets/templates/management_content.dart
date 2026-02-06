// file: lib/widgets/templates/management_content.dart
import 'package:flutter/material.dart';

import '../filter_bar.dart';
import '../page_header.dart';
// استورد المكونات التي تحتاجها مثل PageHeader و FilterBar

/// قالب موحد لمحتوى شاشات الإدارة (بدون Scaffold).
///
/// مصمم خصيصًا ليوضع داخل واجهات أخرى مثل لوحة التحكم.
/// يوفر هيكلاً ثابتًا يتكون من:
/// 1. ترويسة الصفحة (PageHeader).
/// 2. شريط الفلاتر (FilterBar).
/// 3. قسم المحتوى الرئيسي (body) الذي يملأ المساحة المتبقية.
class ManagementContent extends StatelessWidget {
  // --- نفس الخصائص الموجودة في ManagementScreenTemplate ---
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? statisticsWidget;
  final List<Widget>? filterWidgets;
  final Widget body;

  const ManagementContent({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.statisticsWidget,
    this.filterWidgets,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    // الفرق الوحيد: نرجع Column مباشرةً بدلاً من Scaffold
    return Column(
      children: [
        // ١. بناء الترويسة
        PageHeader(
          title: title,
          subtitle: subtitle!,
          actions: actions,
          bottomChild: statisticsWidget,
        ),

        // ٢. بناء شريط الفلاتر (فقط إذا تم توفيره)
        if (filterWidgets != null && filterWidgets!.isNotEmpty)
          FilterBar(children: filterWidgets!),

        // ٣. بناء المحتوى الرئيسي (يجب أن يكون Expanded)
        Expanded(
          child: Padding(
            // استخدام padding موحد حول المحتوى
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: body,
          ),
        ),
      ],
    );
  }
}
