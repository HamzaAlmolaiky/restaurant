// file: models/shift_activity_model.dart (بديل DataTable الخاص بالحركات)
class ShiftActivityModel {
  final int activityID;
  final String activityType; // 'فاتورة', 'سند قبض', 'صرف'
  final String description;
  final DateTime activityDate;
  final double amount;

  ShiftActivityModel(
      {required this.activityID,
      required this.activityType,
      required this.description,
      required this.activityDate,
      required this.amount});

  factory ShiftActivityModel.fromMap(Map<String, dynamic> map) {
    return ShiftActivityModel(
      activityID: map['ActivityID'],
      activityType: map['ActivityType'],
      description: map['Description'],
      activityDate: DateTime.parse(map['ActivityDate']),
      amount: (map['Amount'] as num).toDouble(),
    );
  }
}
