// file: lib/widgets/templates/management_screen_template.dart
import 'package:flutter/material.dart';

// استيراد المكونات العامة التي أنشأناها
import '../page_header.dart';
import '../filter_bar.dart';

/// قالب موحد لجميع شاشات الإدارة في التطبيق.
///
/// يوفر هذا القالب هيكلاً ثابتًا يتكون من:
/// 1. ترويسة الصفحة (PageHeader).
/// 2. شريط الفلاتر (FilterBar).
/// 3. قسم المحتوى الرئيسي (عادة ما يكون GridView أو ListView).
class ManagementScreenTemplate extends StatelessWidget {
  // --- خصائص الترويسة ---
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? statisticsWidget; // الجزء السفلي من الترويسة

  // --- خصائص الفلاتر ---
  final List<Widget>? filterWidgets;

  // --- خصائص المحتوى الرئيسي ---
  final Widget body;

  const ManagementScreenTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.statisticsWidget,
    this.filterWidgets,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ١. بناء الترويسة باستخدام البيانات الممررة
          PageHeader(
            title: title,
            subtitle: subtitle,
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
      ),
    );
  }
}
