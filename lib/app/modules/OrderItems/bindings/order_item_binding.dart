import 'package:get/get.dart';

import '../controllers/order_item_controller.dart';

class OrderItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderItemController>(
      () => OrderItemController(),
    );
  }
}
