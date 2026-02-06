import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'statistics_card.dart';
import 'statistics_card_data.dart';

class StatisticsRow extends StatelessWidget {
  /// قائمة من بطاقات الإحصاءات التي سيتم عرضها في الصف.
  final List<StatisticsCard> children;

  /// المسافة الأفقية بين كل بطاقة والأخرى.
  final double spacing;

  const StatisticsRow({
    super.key,
    required this.children,
    this.spacing = 16.0, // القيمة الافتراضية هي 16
  });

  @override
  Widget build(BuildContext context) {
    // سيقوم هذا الويدجت ببناء الصف تلقائيًا
    return Row(children: _buildChildrenWithSpacers());
  }

  /// دالة خاصة لبناء قائمة الويدجتات مع الفواصل بينها.
  List<Widget> _buildChildrenWithSpacers() {
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      // ١. أضف البطاقة داخل ويدجت Expanded
      widgets.add(Expanded(child: children[i]));

      // ٢. إذا لم تكن هذه هي البطاقة الأخيرة، أضف فاصلًا بعدها
      if (i < children.length - 1) {
        widgets.add(SizedBox(width: spacing));
      }
    }

    return widgets;
  }
}

/// ويدجت يعرض صفًا من بطاقات الإحصاءات التي يتم تحديثها تلقائيًا
/// باستخدام متغيرات GetX التفاعلية.
class ReactiveStatisticsRow extends StatelessWidget {
  final List<StatisticsCardData> cards;
  final double spacing;

  const ReactiveStatisticsRow({
    super.key,
    required this.cards,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: _buildCardsWithSpacers());
  }

  List<Widget> _buildCardsWithSpacers() {
    final List<Widget> widgets = [];
    for (int i = 0; i < cards.length; i++) {
      final cardData = cards[i];

      // ١. نضع Expanded و Obx هنا مرة واحدة فقط
      widgets.add(
        Expanded(
          child: Obx(() {
            // ٢. نقوم بتهيئة القيمة داخل Obx لتتحدث تلقائيًا
            String formattedValue;
            // التحقق إذا كانت القيمة عشرية لتهيئتها بشكل صحيح
            if (cardData.reactiveValue.value is double) {
              formattedValue = cardData.reactiveValue.value.toStringAsFixed(2);
            } else {
              formattedValue = cardData.reactiveValue.value.toString();
            }

            // ٣. نمرر البيانات النهائية إلى StatisticsCard
            return StatisticsCard(
              title: cardData.title,
              value: '$formattedValue ${cardData.valueSuffix ?? ''}'.trim(),
              icon: cardData.icon,
              color: cardData.color,
              subtitle: cardData.subtitle,
            );
          }),
        ),
      );

      // ٤. نضيف الفاصل بين البطاقات
      if (i < cards.length - 1) {
        widgets.add(SizedBox(width: spacing));
      }
    }
    return widgets;
  }
}
