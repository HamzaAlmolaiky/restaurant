import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../Auth/services/auth_service.dart';
import '../../Shift/services/shift_service.dart';
import '../../Shift/models/shift_model.dart';
import '../../../helpers/app_dialogs.dart';

class CashDrawerController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var totalAmount = 0.0.obs;
  var isDrawerOpen = false.obs;
  var currentShiftData = Rxn<Map<String, dynamic>>();

  // Denomination controllers
  final notes500Controller = TextEditingController(text: '0');
  final notes200Controller = TextEditingController(text: '0');
  final notes100Controller = TextEditingController(text: '0');
  final notes50Controller = TextEditingController(text: '0');
  final notes10Controller = TextEditingController(text: '0');
  final notes5Controller = TextEditingController(text: '0');
  final notes1Controller = TextEditingController(text: '0');

  final coins2Controller = TextEditingController(text: '0');
  final coins1Controller = TextEditingController(text: '0');
  final coins50Controller = TextEditingController(text: '0');
  final coins25Controller = TextEditingController(text: '0');
  final coins10Controller = TextEditingController(text: '0');
  final coins5Controller = TextEditingController(text: '0');

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  void _setupListeners() {
    // Add listeners to all controllers to calculate total automatically
    final controllers = [
      notes500Controller,
      notes200Controller,
      notes100Controller,
      notes50Controller,
      notes10Controller,
      notes5Controller,
      notes1Controller,
      coins2Controller,
      coins1Controller,
      coins50Controller,
      coins25Controller,
      coins10Controller,
      coins5Controller,
    ];

    for (var controller in controllers) {
      controller.addListener(calculateTotal);
    }
  }

  // Calculate total amount
  void calculateTotal() {
    double total = 0.0;

    // Banknotes
    total += (int.tryParse(notes500Controller.text) ?? 0) * 500;
    total += (int.tryParse(notes200Controller.text) ?? 0) * 200;
    total += (int.tryParse(notes100Controller.text) ?? 0) * 100;
    total += (int.tryParse(notes50Controller.text) ?? 0) * 50;
    total += (int.tryParse(notes10Controller.text) ?? 0) * 10;
    total += (int.tryParse(notes5Controller.text) ?? 0) * 5;
    total += (int.tryParse(notes1Controller.text) ?? 0) * 1;

    // Coins
    total += (int.tryParse(coins2Controller.text) ?? 0) * 2;
    total += (int.tryParse(coins1Controller.text) ?? 0) * 1;
    total += (int.tryParse(coins50Controller.text) ?? 0) * 0.5;
    total += (int.tryParse(coins25Controller.text) ?? 0) * 0.25;
    total += (int.tryParse(coins10Controller.text) ?? 0) * 0.1;
    total += (int.tryParse(coins5Controller.text) ?? 0) * 0.05;

    totalAmount.value = total;
  }

  // Reset all values
  void resetAll() {
    notes500Controller.text = '0';
    notes200Controller.text = '0';
    notes100Controller.text = '0';
    notes50Controller.text = '0';
    notes10Controller.text = '0';
    notes5Controller.text = '0';
    notes1Controller.text = '0';

    coins2Controller.text = '0';
    coins1Controller.text = '0';
    coins50Controller.text = '0';
    coins25Controller.text = '0';
    coins10Controller.text = '0';
    coins5Controller.text = '0';

    calculateTotal();
  }

  // Set preset amounts for quick setup
  void setPresetAmount(double amount) {
    resetAll();

    if (amount == 1000) {
      notes500Controller.text = '2';
    } else if (amount == 2000) {
      notes500Controller.text = '4';
    } else if (amount == 5000) {
      notes500Controller.text = '10';
    } else if (amount == 500) {
      notes100Controller.text = '5';
    }

    calculateTotal();
  }

  // Confirm and save cash drawer setup
  Future<bool> confirmCashDrawerSetup() async {
    try {
      isLoading.value = true;

      final auth = Get.find<AuthService>();
      final shiftService = Get.find<ShiftService>();
      final now = DateTime.now();

      // Create and persist new shift in DB
      final newShift = ShiftModel(
        userID: auth.currentUser.value!.userID!,
        startTime: now,
        openingBalance: totalAmount.value,
        status: 'Open',
      );
      final newId = await shiftService.createNewShift(newShift);

      // Update AuthService with opened shift
      auth.startShift(
        ShiftModel(
          shiftID: newId,
          userID: newShift.userID,
          startTime: newShift.startTime,
          openingBalance: newShift.openingBalance,
          status: newShift.status,
        ),
      );

      // Update local observable summary for UI
      currentShiftData.value = {
        'opening_amount': totalAmount.value,
        'opening_time': now,
        'cashier_id': auth.currentUser.value?.userID,
        'cashier_name': auth.currentUser.value?.username,
        'denominations': {
          'notes_500': int.tryParse(notes500Controller.text) ?? 0,
          'notes_200': int.tryParse(notes200Controller.text) ?? 0,
          'notes_100': int.tryParse(notes100Controller.text) ?? 0,
          'notes_50': int.tryParse(notes50Controller.text) ?? 0,
          'notes_10': int.tryParse(notes10Controller.text) ?? 0,
          'notes_5': int.tryParse(notes5Controller.text) ?? 0,
          'notes_1': int.tryParse(notes1Controller.text) ?? 0,
          'coins_2': int.tryParse(coins2Controller.text) ?? 0,
          'coins_1': int.tryParse(coins1Controller.text) ?? 0,
          'coins_50': int.tryParse(coins50Controller.text) ?? 0,
          'coins_25': int.tryParse(coins25Controller.text) ?? 0,
          'coins_10': int.tryParse(coins10Controller.text) ?? 0,
          'coins_5': int.tryParse(coins5Controller.text) ?? 0,
        },
        'status': 'Open',
      };
      isDrawerOpen.value = true;

      // Show success message
      AppDialogs.show('نجاح', 'تم تسجيل رصيد الصندوق الافتتاحي: ${totalAmount.value.toStringAsFixed(2)} ر.س');

      return true;
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء حفظ البيانات. يرجى المحاولة مرة أخرى.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate to POS after confirmation
  void navigateToPOS() {
    Get.offAllNamed('/sub-main');
  }

  // Get cash drawer summary
  Map<String, dynamic> getCashDrawerSummary() {
    return {
      'opening_amount': currentShiftData.value?['opening_amount'] ?? 0.0,
      'opening_time': currentShiftData.value?['opening_time'] ?? DateTime.now(),
      'cashier_name': currentShiftData.value?['cashier_name'] ?? '',
      'status': currentShiftData.value?['status'] ?? 'closed',
      'current_amount': totalAmount.value,
    };
  }

  // Close cash drawer (end of shift)
  Future<bool> closeCashDrawer() async {
    try {
      isLoading.value = true;

      // Calculate closing amount
      calculateTotal();

      final auth = Get.find<AuthService>();
      final shiftService = Get.find<ShiftService>();
      final shiftId = auth.currentShiftId;
      if (shiftId == null) {
        throw 'لا توجد وردية مفتوحة حالياً.';
      }

      // Close shift in DB and post to main box
      await shiftService.closeShiftAndPostToMainBox(
        shiftId,
        totalAmount.value,
        auth.currentUser.value!.userID!,
      );

      // Update local/UI state
      if (currentShiftData.value != null) {
        currentShiftData.value!['closing_amount'] = totalAmount.value;
        currentShiftData.value!['closing_time'] = DateTime.now();
        currentShiftData.value!['status'] = 'Closed';
      }
      isDrawerOpen.value = false;
      auth.closeShift();

      AppDialogs.show('نجاح', 'تم إغلاق الصندوق بمبلغ: ${totalAmount.value.toStringAsFixed(2)} ر.س');

      return true;
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء إغلاق الصندوق: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get denomination breakdown
  List<Map<String, dynamic>> getDenominationBreakdown() {
    return [
      {
        'type': 'banknote',
        'value': 500,
        'count': int.tryParse(notes500Controller.text) ?? 0,
        'total': (int.tryParse(notes500Controller.text) ?? 0) * 500,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'type': 'banknote',
        'value': 200,
        'count': int.tryParse(notes200Controller.text) ?? 0,
        'total': (int.tryParse(notes200Controller.text) ?? 0) * 200,
        'color': const Color(0xFF06B6D4),
      },
      {
        'type': 'banknote',
        'value': 100,
        'count': int.tryParse(notes100Controller.text) ?? 0,
        'total': (int.tryParse(notes100Controller.text) ?? 0) * 100,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'banknote',
        'value': 50,
        'count': int.tryParse(notes50Controller.text) ?? 0,
        'total': (int.tryParse(notes50Controller.text) ?? 0) * 50,
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'banknote',
        'value': 10,
        'count': int.tryParse(notes10Controller.text) ?? 0,
        'total': (int.tryParse(notes10Controller.text) ?? 0) * 10,
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'banknote',
        'value': 5,
        'count': int.tryParse(notes5Controller.text) ?? 0,
        'total': (int.tryParse(notes5Controller.text) ?? 0) * 5,
        'color': const Color(0xFF84CC16),
      },
      {
        'type': 'banknote',
        'value': 1,
        'count': int.tryParse(notes1Controller.text) ?? 0,
        'total': (int.tryParse(notes1Controller.text) ?? 0) * 1,
        'color': const Color(0xFF6B7280),
      },
      // Coins
      {
        'type': 'coin',
        'value': 2,
        'count': int.tryParse(coins2Controller.text) ?? 0,
        'total': (int.tryParse(coins2Controller.text) ?? 0) * 2,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'type': 'coin',
        'value': 1,
        'count': int.tryParse(coins1Controller.text) ?? 0,
        'total': (int.tryParse(coins1Controller.text) ?? 0) * 1,
        'color': const Color(0xFF06B6D4),
      },
      {
        'type': 'coin',
        'value': 0.5,
        'count': int.tryParse(coins50Controller.text) ?? 0,
        'total': (int.tryParse(coins50Controller.text) ?? 0) * 0.5,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'coin',
        'value': 0.25,
        'count': int.tryParse(coins25Controller.text) ?? 0,
        'total': (int.tryParse(coins25Controller.text) ?? 0) * 0.25,
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'coin',
        'value': 0.1,
        'count': int.tryParse(coins10Controller.text) ?? 0,
        'total': (int.tryParse(coins10Controller.text) ?? 0) * 0.1,
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'coin',
        'value': 0.05,
        'count': int.tryParse(coins5Controller.text) ?? 0,
        'total': (int.tryParse(coins5Controller.text) ?? 0) * 0.05,
        'color': const Color(0xFF84CC16),
      },
    ];
  }

  @override
  void onClose() {
    // Dispose controllers
    notes500Controller.dispose();
    notes200Controller.dispose();
    notes100Controller.dispose();
    notes50Controller.dispose();
    notes10Controller.dispose();
    notes5Controller.dispose();
    notes1Controller.dispose();

    coins2Controller.dispose();
    coins1Controller.dispose();
    coins50Controller.dispose();
    coins25Controller.dispose();
    coins10Controller.dispose();
    coins5Controller.dispose();

    super.onClose();
  }
}
