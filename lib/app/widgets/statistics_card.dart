// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// بطاقة إحصائيات مرنة وقوية تجمع بين سهولة الاستخدام والتخصيص الكامل.
///
/// يمكنك استخدامها بإحدى طريقتين:
/// 1. **الطريقة السهلة:** عن طريق تمرير `icon`, `color`, و `change`.
///    سيقوم الكلاس ببناء الأيقونة ومؤشر التغيير تلقائيًا بالتصميم الموحد.
///
/// 2. **الطريقة المتقدمة:** عن طريق تمرير أي ويدجت مخصص إلى `leading` و `trailing`
///    لتحقيق أي تصميم تريده.
class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    // --- المجموعة 1: الطريقة السهلة (للتكوين السريع) ---
    this.icon,
    this.color,
    this.change,
    // --- المجموعة 2: الطريقة المتقدمة (للتخصيص الكامل) ---
    this.leading,
    this.trailing,
  }) : // --- شروط للتحقق من أن المطور لا يخلط بين الطريقتين ---
       assert(
         leading == null || icon == null,
         'لا يمكنك توفير ويدجت `leading` و `icon` في نفس الوقت. اختر طريقة واحدة.',
       ),
       assert(
         trailing == null || change == null,
         'لا يمكنك توفير ويدجت `trailing` و `change` في نفس الوقت. اختر طريقة واحدة.',
       ),
       assert(
         icon == null || color != null,
         'يجب توفير `color` إذا كنت تستخدم `icon`.',
       );

  // --- الخصائص الأساسية للبطاقة ---
  final String title;
  final String value;
  final String? subtitle;

  // --- خصائص الطريقة السهلة ---
  final IconData? icon;
  final Color? color;
  final String? change;

  // --- خصائص الطريقة المتقدمة ---
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ١. عرض الويدجت الرائد (Leading)
              //    - إذا قام المستخدم بتمرير ويدجت `leading`، اعرضه.
              //    - وإلا، إذا استخدم `icon`، قم ببناء الأيقونة الافتراضية.
              if (leading != null)
                leading!
              else if (icon != null)
                _buildDefaultLeading(),

              // ٢. عرض الويدجت التابع (Trailing)
              //    - نفس المنطق: أعط الأولوية للطريقة المتقدمة `trailing`.
              //    - وإلا، إذا استخدم `change`، قم ببناء مؤشر التغيير الافتراضي.
              if (trailing != null)
                trailing!
              else if (change != null && change!.isNotEmpty)
                _buildDefaultTrailing(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  // ======> تم نقل منطق الدوال المساعدة إلى هنا وأصبحت خاصة بالكلاس <======

  /// دالة خاصة لبناء الويدجت الرائد الافتراضي (الأيقونة)
  Widget _buildDefaultLeading() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// دالة خاصة لبناء الويدجت التابع الافتراضي (مؤشر التغيير)
  Widget _buildDefaultTrailing() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        change!,
        style: const TextStyle(
          color: Color(0xFF10B981),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
