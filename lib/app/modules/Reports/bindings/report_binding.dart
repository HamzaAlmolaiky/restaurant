// file: bindings/report_binding.dart
import 'package:get/get.dart';
import '../controllers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    // ReportService ليس لها حالة، لذا يمكن إنشاؤها مباشرة في الـ Controller
    // أو تسجيلها هنا إذا كانت ستستخدم في أماكن أخرى
    Get.lazyPut<ReportController>(() => ReportController());
  }
}
