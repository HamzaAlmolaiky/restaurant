import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// كلاس بسيط لتمرير بيانات البطاقة بشكل منظم.
class StatisticsCardData {
  final String title;

  /// المتغير التفاعلي نفسه من الكونترولر (e.g., controller.todayRevenue).
  final Rx<num> reactiveValue;

  final IconData icon;
  final Color color;
  final String? subtitle;

  /// نص يضاف بعد القيمة (e.g., " ريال" أو " معاملة").
  final String? valueSuffix;

  StatisticsCardData({
    required this.title,
    required this.reactiveValue,
    required this.icon,
    required this.color,
    this.subtitle,
    this.valueSuffix = '', // قيمة افتراضية فارغة
  });
}
