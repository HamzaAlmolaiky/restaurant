import 'package:flutter/material.dart';

class ObxState extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final bool isEmpty;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const ObxState({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.isEmpty,
    required this.child,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
    }
    if (hasError) {
      return errorWidget ?? const Center(child: Text('حدث خطأ غير متوقع'));
    }
    if (isEmpty) {
      return emptyWidget ?? const Center(child: Text('لا توجد بيانات للعرض'));
    }
    return child;
  }
}
