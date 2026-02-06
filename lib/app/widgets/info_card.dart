// file: lib/widgets/info_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'grid_card.dart'; // تأكد من أن هذا المسار صحيح

// كلاس مساعد لتمرير بيانات كل صف تفصيلي بشكل منظم
class InfoCardDetail {
  final IconData icon;
  final String text;

  InfoCardDetail({required this.icon, required this.text});
}

/// بطاقة عرض عامة ومتخصصة لعرض معلومات غنية (للعملاء، الموظفين، إلخ).
///
/// تحتوي هذه البطاقة على كل منطق التنسيق الداخلي، وتحتاج فقط إلى البيانات الخام لعرضها.
class InfoCard extends StatelessWidget {
  // --- بيانات المحتوى ---
  final String? avatarLetter;
  final Color? avatarColor;
  final Widget? leadingWidget; // <-- لإضافة أيقونة مخصصة
  final String title;
  final List<InfoCardDetail> details;
  final String? notes;

  // --- بيانات الجزء السفلي (اختياري) ---
  final String? bottomTitle1;
  final String? bottomValue1;
  final Color? bottomValue1Color;
  final String? bottomTitle2;
  final Widget? bottomValue2;
  final Widget? bottomWidget;

  // --- خصائص الإجراءات ---
  final List<PopupMenuEntry<String>>? menuItems;
  final Function(String value)? onMenuItemSelected;
  final Widget? menuWidget; // ويدجت قائمة بديل (ActionMenu)

  const InfoCard({
    super.key,
    this.avatarLetter,
    this.avatarColor,
    this.leadingWidget,
    required this.title,
    this.details = const [],
    this.notes,
    this.bottomTitle1,
    this.bottomValue1,
    this.bottomValue1Color,
    this.bottomTitle2,
    this.bottomValue2,
    this.bottomWidget,
    this.menuItems,
    this.onMenuItemSelected,
    this.menuWidget,
  }) : assert(
         leadingWidget == null || (avatarLetter == null && avatarColor == null),
         'لا يمكنك توفير leadingWidget و avatarLetter/avatarColor في نفس الوقت.',
       );

  @override
  Widget build(BuildContext context) {
    return GridCard(
      menuItems: menuWidget == null ? menuItems : null,
      onMenuItemSelected: menuWidget == null ? onMenuItemSelected : null,
      menuWidget: menuWidget,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // <-- للتحكم في التوزيع
          children: [
            // ===================================
            // ١. الجزء العلوي والأوسط
            // ===================================
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ليأخذ أقل مساحة ممكنة
              children: [
                if (leadingWidget != null)
                  leadingWidget!
                else if (avatarLetter != null && avatarColor != null)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor!.withOpacity(0.1),
                    child: Text(
                      avatarLetter!.toUpperCase(),
                      style: TextStyle(
                        color: avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ...details.map(
                  (detail) =>
                      _buildDetailRow(icon: detail.icon, text: detail.text),
                ),
                if (notes != null && notes!.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.note,
                    text: notes!,
                    isExpanded: true,
                  ),
              ],
            ),

            // ===================================
            // ٢. الجزء السفلي
            // ===================================
            if (bottomWidget != null)
              bottomWidget!
            else if (bottomValue1 != null)
              _buildDefaultBottomWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF718096)),
          const SizedBox(width: 8),
          isExpanded
              ? Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }

  Widget _buildDefaultBottomWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (bottomTitle1 != null && bottomValue1 != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bottomTitle1!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0)),
              ),
              const SizedBox(height: 4),
              Text(
                bottomValue1!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bottomValue1Color ?? const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        if (bottomTitle2 != null && bottomValue2 != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bottomTitle2!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0)),
              ),
              const SizedBox(height: 4),
              bottomValue2!,
            ],
          ),
      ],
    );
  }
}
