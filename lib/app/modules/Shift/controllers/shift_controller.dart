// file: controllers/shift_controller.dart
import 'package:get/get.dart';
import '../../Auth/services/auth_service.dart';
import '../models/shift_model.dart';
import '../models/shift_details_model.dart';
import '../services/shift_service.dart';
import '../../../helpers/app_dialogs.dart';

class ShiftController extends GetxController {
  final ShiftService _shiftService;
  final AuthService _authService;
  final Rxn<ShiftDetailsModel> currentShift = Rxn<ShiftDetailsModel>();
  final RxInt totalShifts = 0.obs;
  final RxInt activeEmployeesInShift = 0.obs;
  final RxDouble averageShiftHours = 0.0.obs;
  final RxDouble totalSalesInShift = 0.0.obs;
  ShiftController(this._shiftService, this._authService);

  var currentOpenShift = Rx<ShiftModel?>(null);
  var shiftsHistory = <ShiftDetailsModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // عند تسجيل دخول المستخدم، تحقق من وجود وردية مفتوحة له
    if (_authService.isLoggedIn) {
      findOpenShiftForCurrentUser();
    }
  }

  Future<void> findOpenShiftForCurrentUser() async {
    isLoading.value = true;
    currentOpenShift.value = await _shiftService.findOpenShiftForUser(
      _authService.currentUser.value!.userID!,
    );
    isLoading.value = false;
  }

  Future<void> startNewShift(double openingBalance) async {
    if (openingBalance < 0) {
      AppDialogs.show('خطأ', 'الرصيد الافتتاحي لا يمكن أن يكون بالسالب');
      return;
    }
    try {
      isLoading.value = true;
      final newShift = ShiftModel(
        userID: _authService.currentUser.value!.userID!,
        startTime: DateTime.now(),
        openingBalance: openingBalance,
        status: 'Open',
      );
      final newId = await _shiftService.createNewShift(newShift);
      if (newId > 0) {
        AppDialogs.show('نجاح', 'تم بدء الوردية بنجاح');
        await findOpenShiftForCurrentUser(); // تحديث الحالة
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل بدء الوردية: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> closeCurrentShift(double actualClosingBalance) async {
    if (currentOpenShift.value == null) {
      AppDialogs.show('خطأ', 'لا توجد وردية مفتوحة لإغلاقها');
      return;
    }
    try {
      isLoading.value = true;
      final supervisorId =
          _authService.currentUser.value!.userID!; // افترض أن المشرف هو من يغلق
      final success = await _shiftService.closeShiftAndPostToMainBox(
        currentOpenShift.value!.shiftID!,
        actualClosingBalance,
        supervisorId,
      );
      if (success) {
        AppDialogs.show('نجاح', 'تم إغلاق الوردية وترحيل المبلغ بنجاح');
        currentOpenShift.value = null; // إفراغ الحالة
      }
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل إغلاق الوردية: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchShiftsHistory(
    int userId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      isLoading.value = true;
      shiftsHistory.assignAll(
        await _shiftService.getShiftsHistory(userId, from, to),
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'فشل جلب سجل الورديات');
    } finally {
      isLoading.value = false;
    }
  }
}
