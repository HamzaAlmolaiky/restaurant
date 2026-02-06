import 'package:get/get.dart';
import '../controllers/cash_drawer_controller.dart';

class CashDrawerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CashDrawerController>(
      () => CashDrawerController(),
    );
  }
}
