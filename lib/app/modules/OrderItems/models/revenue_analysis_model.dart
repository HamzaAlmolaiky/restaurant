/// نموذج لتحليل الإيرادات
library;
// ignore_for_file: no_leading_underscores_for_local_identifiers

class RevenueAnalysisModel {
  final List<Map<String, dynamic>> dailyRevenue;
  final List<Map<String, dynamic>> paymentMethodAnalysis;
  final List<Map<String, dynamic>> categoryAnalysis;
  final double growthRate;
  final Map<String, dynamic> revenueComparison;
  final double lastMonthRevenue;
  final double currentMonthRevenue;

  RevenueAnalysisModel({
    required this.dailyRevenue,
    required this.paymentMethodAnalysis,
    required this.categoryAnalysis,
    required this.growthRate,
    required this.revenueComparison,
    required this.lastMonthRevenue,
    required this.currentMonthRevenue,
  });

  factory RevenueAnalysisModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> _castList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return <Map<String, dynamic>>[];
    }

    return RevenueAnalysisModel(
      dailyRevenue: _castList(map['dailyRevenue']),
      paymentMethodAnalysis: _castList(map['paymentMethodAnalysis']),
      categoryAnalysis: _castList(map['categoryAnalysis']),
      growthRate: (map['growthRate'] as num?)?.toDouble() ?? 0.0,
      revenueComparison:
          (map['revenueComparison'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          <String, dynamic>{},
      lastMonthRevenue: (map['lastMonthRevenue'] as num?)?.toDouble() ?? 0.0,
      currentMonthRevenue:
          (map['currentMonthRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// تحويل النموذج إلى خريطة
  Map<String, dynamic> toMap() => {
    'dailyRevenue': dailyRevenue,
    'paymentMethodAnalysis': paymentMethodAnalysis,
    'categoryAnalysis': categoryAnalysis,
    'growthRate': growthRate,
    'revenueComparison': revenueComparison,
    'lastMonthRevenue': lastMonthRevenue,
    'currentMonthRevenue': currentMonthRevenue,
  };
}
