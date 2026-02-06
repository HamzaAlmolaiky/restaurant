// file: lib/widgets/async_grid_section.dart (يمكنك إعادة تسميته إلى reactive_grid_section.dart)
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ObxState;
import 'obx_state.dart';

/// ويدجت متخصص لعرض شبكة (Grid) من البيانات التفاعلية (GetX)
/// مع إدارة حالات التحميل والبيانات الفارغة تلقائيًا.
class ReactiveGridSection<T> extends StatelessWidget {
  /// متغير الحالة الذي يشير إلى ما إذا كانت البيانات قيد التحميل.
  final RxBool isLoading;

  /// قائمة البيانات التفاعلية نفسها (RxList) التي سيتم عرضها.
  final RxList<T> items;

  final String emptyText;
  final SliverGridDelegate gridDelegate;

  /// دالة تقوم ببناء ويدجت البطاقة لكل عنصر في القائمة.
  final Widget Function(BuildContext context, T item) itemBuilder;

  const ReactiveGridSection({
    super.key,
    required this.isLoading,
    required this.items,
    required this.emptyText,
    required this.gridDelegate,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // استخدام Obx مرة واحدة فقط لمراقبة كل الحالات
    return Obx(() {
      // استخدام ObxState لإدارة عرض الحالات المختلفة
      return ObxState(
        isLoading:
            isLoading.value &&
            items.isEmpty, // اعرض التحميل فقط إذا كانت القائمة فارغة
        hasError: false, // يمكنك إضافة متغير hasError لاحقًا إذا احتجت إليه
        isEmpty: !isLoading.value && items.isEmpty,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        emptyWidget: Center(child: Text(emptyText)),
        child: GridView.builder(
          gridDelegate: gridDelegate,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            // استدعاء دالة بناء البطاقة مباشرة
            return itemBuilder(context, item);
          },
        ),
      );
    });
  }
}
