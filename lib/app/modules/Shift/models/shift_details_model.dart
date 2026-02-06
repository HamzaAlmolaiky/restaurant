// file: models/shift_details_model.dart (بديل ViewModel و DataTable)
import 'shift_model.dart';

class ShiftDetailsModel extends ShiftModel {
  final String userName;
  final double totalSales;
  final double totalReturns;
  final double totalExpenses;
  final double totalReceipts;
  final double difference;

  ShiftDetailsModel({
    required int super.shiftID,
    required super.userID,
    required super.startTime,
    super.endTime,
    required super.openingBalance,
    super.closingBalance,
    required super.status,
    required this.userName,
    required this.totalSales,
    required this.totalReturns,
    required this.totalExpenses,
    required this.totalReceipts,
    required this.difference,
  });

  factory ShiftDetailsModel.fromMap(Map<String, dynamic> map) {
    return ShiftDetailsModel(
      shiftID: map['ShiftID'],
      userID: map['UserID'],
      startTime: DateTime.parse(map['StartTime']),
      endTime: map['EndTime'] != null ? DateTime.parse(map['EndTime']) : null,
      openingBalance: (map['OpeningBalance'] as num).toDouble(),
      closingBalance: map['ClosingBalance'] != null
          ? (map['ClosingBalance'] as num).toDouble()
          : null,
      status: map['Status'],
      userName: map['UserName'] ?? 'غير معروف',
      totalSales: (map['TotalSales'] as num).toDouble(),
      totalReturns: (map['TotalReturns'] as num).toDouble(),
      totalExpenses: (map['TotalExpenses'] as num).toDouble(),
      totalReceipts: (map['TotalReceipts'] as num).toDouble(),
      difference: (map['Difference'] as num).toDouble(),
    );
  }
}
