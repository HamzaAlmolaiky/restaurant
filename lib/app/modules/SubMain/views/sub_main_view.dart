// ignore_for_file: deprecated_member_use, unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/invoice_item.dart';
import '../controllers/sub_main_controller.dart';

class SubMainView extends GetView<SubMainController> {
  const SubMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Right Side - Products and Categories
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  /// المنتجات
                  const SizedBox(height: 8),
                  _buildPaymentAndOrderControls(),
                  const SizedBox(height: 8),
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildProductSearchBar(),
                          const SizedBox(height: 8),
                          Expanded(child: _buildProductsGrid()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// الفئات
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: _buildCategoriesGrid(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// الطلب
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Invoice Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'الطلب الحالي',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              Obx(
                                () => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    controller.currentInvoice.number.isEmpty
                                        ? 'طلب'
                                        : 'طلب ${controller.currentInvoice.number}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Obx(
                                    () => Column(
                                      children: [
                                        Text(
                                          'العميل',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          controller
                                                  .currentInvoice
                                                  .customerName
                                                  .isEmpty
                                              ? '—'
                                              : controller
                                                    .currentInvoice
                                                    .customerName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Obx(
                                    () => Column(
                                      children: [
                                        Text(
                                          'الطاولة',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          controller
                                                  .currentInvoice
                                                  .tableNumber
                                                  .isEmpty
                                              ? '—'
                                              : controller
                                                    .currentInvoice
                                                    .tableNumber,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// فاتورة المنتجات
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'المنتج',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'الكمية',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'السعر',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 40),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: Obx(
                                () => ListView.builder(
                                  itemCount:
                                      controller.currentInvoice.items.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        controller.currentInvoice.items[index];
                                    return _buildOrderItem(item, index);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// الخصائص
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'المجموع الفرعي',
                            '${controller.currentInvoice.subtotal.toStringAsFixed(2)} ر.س',
                          ),
                          _buildSummaryRow(
                            'الضريبة (15%)',
                            '${controller.currentInvoice.taxAmount.toStringAsFixed(2)} ر.س',
                          ),
                          _buildSummaryRow(
                            'رسوم الخدمة (10%)',
                            '${controller.currentInvoice.serviceAmount.toStringAsFixed(2)} ر.س',
                          ),
                          const Divider(thickness: 2),
                          _buildSummaryRow(
                            'المجموع الكلي',
                            '${controller.currentInvoice.total.toStringAsFixed(2)} ر.س',
                            isTotal: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                /// زر حفظ الطلب
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    controller.saveInvoice();
                                  },
                                  icon: const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'حفظ الطلب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B7280),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                /// زر الدفع
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    controller.payInvoice();
                                  },
                                  icon: const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'دفع الطلب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : controller.categories.isEmpty
          ? const Center(
              child: Text(
                'لا توجد فئات متاحة',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Scrollbar(
              controller: controller.categoriesScrollController,
              thumbVisibility: true,
              child: GridView.builder(
                controller: controller.categoriesScrollController,
                primary: false,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final category = controller.categories[index];

                  /// زر اختيار الفئة
                  return GestureDetector(
                    onTap: () => controller.selectCategoryByIndex(index),
                    child: Obx(() {
                      final isSelected =
                          controller.selectedCategoryIndex.value == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(category.categoryName),
                              size: 32,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'الأطباق الرئيسية':
        return Icons.restaurant;
      case 'المقبلات':
        return Icons.local_dining;
      case 'المشروبات':
        return Icons.local_drink;
      case 'الحلويات':
        return Icons.cake;
      case 'السلطات':
        return Icons.eco;
      case 'المشاوي':
        return Icons.outdoor_grill;
      default:
        return Icons.fastfood;
    }
  }

  /// بناء واجهة المنتجات
  /// مع البحث داخل الفئة المحددة
  /// وعرض المنتجات بشكل شبكة
  /// مع زر اضافة كل منتج الى الفاتورة
  /// وعرض الايقونة المناسبة لكل منتج
  /// حسب اسمه
  /// مع عرض عدد المنتجات في الفئة المحددة
  /// وعرض اسم الفئة المحددة في الاعلى
  /// مع عرض ايقونة الفئة المناسبة
  Widget _buildProductsGrid() {
    return Obx(() {
      final products = controller.getFilteredProductsForSelectedCategory();

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (products.isEmpty) {
        return const Center(
          child: Text(
            'لا توجد منتجات مطابقة في هذه الفئة',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return Scrollbar(
        controller: controller.productsScrollController,
        thumbVisibility: true,
        child: GridView.builder(
          controller: controller.productsScrollController,
          primary: false,
          physics: const ClampingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            /// زر اضافة منتج الى الفاتورة
            return GestureDetector(
              onTap: () => controller.addProductToInvoice(product),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getProductIcon(product.itemsName),
                      size: 32,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        product.itemsName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  IconData _getProductIcon(String productName) {
    if (productName.contains('كبسة') ||
        productName.contains('برياني') ||
        productName.contains('مقلوبة')) {
      return Icons.rice_bowl;
    } else if (productName.contains('مندي') ||
        productName.contains('مضغوط') ||
        productName.contains('حنيذ') ||
        productName.contains('مظبي')) {
      return Icons.restaurant;
    } else if (productName.contains('عصير') ||
        productName.contains('شاي') ||
        productName.contains('قهوة')) {
      return Icons.local_drink;
    } else if (productName.contains('حمص') ||
        productName.contains('متبل') ||
        productName.contains('تبولة') ||
        productName.contains('فتوش')) {
      return Icons.local_dining;
    } else {
      return Icons.fastfood;
    }
  }

  Widget _buildSelectedCategoryHeader() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _getCategoryIcon(controller.selectedCategory.value),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'فئة: ${controller.selectedCategory.value}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${controller.getFilteredProductsForSelectedCategory().length} منتج',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(InvoiceItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (item.note.isNotEmpty)
                  Text(
                    item.note,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () =>
                      controller.updateItemQuantity(index, item.quantity - 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      controller.updateItemQuantity(index, item.quantity + 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.total.toStringAsFixed(2)} ر.س',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          InkWell(
            onTap: () => controller.removeItem(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.delete,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF1F2937) : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal
                  ? const Color(0xFF10B981)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearchBar() {
    return Obx(
      () => TextField(
        onChanged: (v) => controller.productSearchQuery.value = v,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج... (داخل الفئة)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.productSearchQuery.value.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => controller.productSearchQuery.value = '',
                ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAndOrderControls() {
    return Obx(() {
      final isCredit = controller.isCredit;
      return Row(
        children: [
          // نوع الطلب
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'نوع الطلب',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedOrderType.value,
                  items: controller.orderTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setOrderType(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // طريقة الدفع
          Expanded(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'طريقة الدفع',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedPaymentMethod.value,
                  items: controller.paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.setPaymentMethod(v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // اختيار العميل عند آجل
          if (isCredit)
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'العميل (للدفع الآجل)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.currentInvoice.customerName.isEmpty
                        ? null
                        : controller.currentInvoice.customerName,
                    hint: const Text('اختر العميل'),
                    items: controller.customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.customerName,
                            child: Text(c.customerName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      controller.currentInvoice.customerName = v ?? '';
                      controller.invoices.refresh();
                    },
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
