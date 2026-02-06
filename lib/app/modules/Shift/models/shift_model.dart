// file: models/shift_model.dart

class ShiftModel {
  final int? shiftID;
  final int userID;
  final DateTime startTime;
  final DateTime? endTime;
  final double openingBalance;
  final double? closingBalance;
  final String status; // 'Open', 'Closed'

  ShiftModel(
      {this.shiftID,
      required this.userID,
      required this.startTime,
      this.endTime,
      required this.openingBalance,
      this.closingBalance,
      required this.status});

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      shiftID: map['ShiftID'],
      userID: map['UserID'],
      startTime: DateTime.parse(map['StartTime']),
      endTime: map['EndTime'] != null ? DateTime.parse(map['EndTime']) : null,
      openingBalance: (map['OpeningBalance'] as num).toDouble(),
      closingBalance: map['ClosingBalance'] != null
          ? (map['ClosingBalance'] as num).toDouble()
          : null,
      status: map['Status'],
    );
  }

  Map<String, dynamic> toMap() => {
        'UserID': userID,
        'StartTime': startTime.toIso8601String(),
        'EndTime': endTime?.toIso8601String(),
        'OpeningBalance': openingBalance,
        'ClosingBalance': closingBalance,
        'Status': status,
      };
}
