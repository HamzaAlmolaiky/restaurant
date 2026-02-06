// ignore_for_file: avoid_print, unused_local_variable

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../Customers/models/customer_model.dart';
import '../../Customers/services/customer_service.dart';
import '../../CustomerPayments/services/customer_payment_service.dart';
import '../../MenuCategories/models/menu_category_model.dart';
import '../../MenuCategories/services/menu_category_service.dart';
import '../../MenuItems/models/menu_item_model.dart';
import '../../MenuItems/services/menu_item_service.dart';
import '../../Orders/models/order_model.dart';
import '../../Orders/services/order_service.dart';
import '../../OrderItems/models/order_item_model.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../../Auth/services/auth_service.dart';
import '../../../helpers/app_dialogs.dart';

class SubMainController extends GetxController {
  /// Services
  late final OrderService _orderService;
  final MenuItemService _menuItemService = MenuItemService.instance;
  final MenuCategoryService _categoryService = MenuCategoryService.instance;
  final CustomerService _customerService = CustomerService.instance;

  /// Observable variables
  var isLoading = false.obs;
  var currentInvoiceIndex = 0.obs;
  var selectedOrderType = 'محلي'.obs;
  final List<String> orderTypes = const ['محلي', 'سفري'];

  var selectedPaymentType = 'نقد'.obs;

  var selectedCategory = 'الأطباق الرئيسية'.obs;
  var selectedCategoryIndex = 0.obs;
  var selectedPaymentMethod = 'نقد'.obs;
  var activeInvoiceIndex = 0.obs;

  /// Observable lists
  var categories = <MenuCategoryModel>[].obs;
  var products = <MenuItemModel>[].obs;
  var customers = <CustomerModel>[].obs;
  var invoices = <Invoice>[].obs;

  /// Scroll controllers for grids
  final ScrollController categoriesScrollController = ScrollController();
  final ScrollController productsScrollController = ScrollController();

  /// بحث المنتجات داخل الفئة الحالية
  final RxString productSearchQuery = ''.obs;

  final List<String> paymentMethods = const ['نقد', 'آجل'];

  bool get isCredit => selectedPaymentMethod.value == 'آجل';

  /// إعدادات الطابعة الحرارية (قابلة للتعديل من الإعدادات لاحقًا)
  final RxString printerIp = '192.168.0.100'.obs; // TDO: اربطها مع Settings
  final RxInt printerPort = 9100.obs;

  @override
  void onInit() {
    super.onInit();
    _orderService = OrderService(
      _customerService,
      CustomerPaymentService.instance,
    );
    _initializeData();
  }

  @override
  void onClose() {
    categoriesScrollController.dispose();
    productsScrollController.dispose();
    super.onClose();
  }

  /// دالة التحميل
  void _initializeData() async {
    await fetchCategories();
    await fetchProducts();
    await fetchCustomers();

    /// إضافة فاتورة جديدة عند بدء التطبيق
    addNewInvoice();
  }

  /// جلب الفئات
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final result = await _categoryService.getAllCategories();
      categories.assignAll(result);

      /// Set first category as selected if available
      if (categories.isNotEmpty) {
        selectedCategory.value = categories.first.categoryName;
        selectedCategoryIndex.value = 0;
      }
    } catch (e) {
      AppDialogs.show('خطاء في جلب الفئات', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب المنتجات
  Future<void> fetchProducts() async {
    try {
      final result = await _menuItemService.getAllMenuItems();
      products.assignAll(result);
    } catch (e) {
      AppDialogs.show('خطاء في جلب المنتجات', e.toString());
    }
  }

  /// جلب العملاء
  Future<void> fetchCustomers() async {
    try {
      final result = await _customerService.getAllCustomers();
      customers.assignAll(
        result.map((item) => CustomerModel.fromMap(item)).toList(),
      );
    } catch (e) {
      AppDialogs.show('خطاء في جلب العملاء', e.toString());
    }
  }

  /// جلب المنتجات حسب الفئة المحددة
  List<MenuItemModel> getProductsForSelectedCategory() {
    if (categories.isEmpty) return [];

    final selectedCat = categories.firstWhereOrNull(
      (cat) => cat.categoryName == selectedCategory.value,
    );

    if (selectedCat == null) return [];

    return products
        .where((product) => product.categoryID == selectedCat.categoryID)
        .toList();
  }

  /// المنتجات المفلترة حسب نص البحث داخل الفئة المحددة
  List<MenuItemModel> getFilteredProductsForSelectedCategory() {
    final base = getProductsForSelectedCategory();
    final q = productSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((p) => p.itemsName.toLowerCase().contains(q)).toList();
  }

  /// إضافة فاتورة جديدة
  /// هذه الدالة تضيف فاتورة جديدة إلى القائمة وتقوم بتحديث الفاتورة الحالية
  /// لتكون الفاتورة الجديدة هي الفاتورة النشطة
  /// يمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "إضافة فاتورة
  /// أو عند الانتهاء من الفاتورة
  /// أو عند الانتقال إلى فاتورة أخرى
  /// أو عند إغلاق التطبيق
  /// أو عند الحاجة إلى إدارة الفواتير المفتوحة
  void addNewInvoice() {
    final newInvoice = Invoice(
      id: 'INV${DateTime.now().millisecondsSinceEpoch}',
      number: '',
      orderType: selectedOrderType.value,
      paymentType: selectedPaymentMethod.value,
      customerName: '',
      tableNumber: '',
      items: [],
      createdAt: DateTime.now(),
    );

    invoices.add(newInvoice);
    currentInvoiceIndex.value = invoices.length - 1;
  }

  /// إدارة الفواتير
  /// هذه الدالة تسمح بالتبديل بين الفواتير المفتوحة
  /// وتحديث الفاتورة الحالية بناءً على الفهرس المحدد
  /// كما تسمح بإغلاق الفواتير المفتوحة
  /// إذا كان هناك أكثر من فاتورة مفتوحة
  /// وتحديث الفهرس الحالي إذا كان خارج النطاق
  void switchToInvoice(int index) {
    if (index >= 0 && index < invoices.length) {
      currentInvoiceIndex.value = index;
      // مزامنة طريقة الدفع مع الفاتورة الحالية
      selectedPaymentMethod.value = currentInvoice.paymentType;
      // مزامنة نوع الطلب مع الفاتورة الحالية
      selectedOrderType.value = currentInvoice.orderType;
    }
  }

  /// إغلاق فاتورة
  /// هذه الدالة تسمح بإغلاق فاتورة مفتوحة
  /// إذا كان هناك أكثر من فاتورة مفتوحة
  /// وتحديث الفهرس الحالي إذا كان خارج النطاق
  /// لا يتم حذف الفاتورة بل يتم إزالتها من القائمة
  /// ويمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "إغلاق فاتورة
  /// أو عند الانتهاء من الفاتورة
  /// أو عند الانتقال إلى فاتورة أخرى
  /// أو عند إغلاق التطبيق
  /// أو عند الحاجة إلى إدارة الفواتير المفتوحة
  /// ملاحظة: لا يتم حذف الفاتورة من قاعدة البيانات بل تبقى محفوظة
  /// ويمكن استرجاعها لاحقاً إذا لزم الأمر
  /// يمكن تعديل هذه الدالة لتناسب احتياجات التطبيق
  /// مثل إضافة تأكيد قبل الإغلاق أو حفظ الفاتورة قبل الإغلاق
  /// أو إضافة خيارات أخرى مثل حفظ الفاتورة كمسودة
  /// أو حفظ الفاتورة كفاتورة مدفوعة
  /// أو حفظ الفاتورة كفاتورة ملغاة
  /// أو حفظ الفاتورة كفاتورة مؤجلة
  /// أو حفظ الفاتورة كفاتورة مؤجلة الدفع
  /// أو حفظ الفاتورة كفاتورة مؤجلة التسليم
  /// أو حفظ الفاتورة كفاتورة مؤجلة الإرجاع
  /// أو حفظ الفاتورة كفاتورة مؤجلة التعديل
  /// أو حفظ الفاتورة كفاتورة مؤجلة التحديث
  void closeInvoice(int index) {
    if (invoices.length > 1 && index >= 0 && index < invoices.length) {
      invoices.removeAt(index);
      if (currentInvoiceIndex.value >= invoices.length) {
        currentInvoiceIndex.value = invoices.length - 1;
      }
    }
  }

  Invoice get currentInvoice => invoices[currentInvoiceIndex.value];

  /// دالة إدارة نوع الطلب
  /// هذه الدالة تسمح بتعيين نوع الطلب الحالي
  /// مثل "محلي" أو "سفري"
  /// وتحديث الفاتورة الحالية بناءً على النوع المحدد
  /// يمكن استدعاؤها عند الحاجة مثل عند اختيار نوع الطلب من قائمة
  /// أو عند تغيير نوع الطلب في واجهة المستخدم
  void setOrderType(String type) {
    selectedOrderType.value = type;
    currentInvoice.orderType = type;
    invoices.refresh();
  }

  /// دالة إدارة نوع الدفع
  /// هذه الدالة تسمح بتعيين نوع الدفع الحالي
  /// مثل "نقد" أو "آجل"
  /// وتحديث الفاتورة الحالية بناءً على النوع المحدد
  /// يمكن استدعاؤها عند الحاجة مثل عند اختيار نوع الدفع من قائمة
  /// أو عند تغيير نوع الدفع في واجهة المستخدم
  void setPaymentType(String type) {
    selectedPaymentType.value = type;
    currentInvoice.paymentType = type;
    invoices.refresh();
  }

  /// دالة إدارة الفئة المحددة
  /// هذه الدالة تسمح بتعيين الفئة المحددة الحالية
  /// مثل "الأطباق الرئيسية" أو "المشروبات"
  /// وتحديث الفاتورة الحالية بناءً على الفئة المحددة
  /// يمكن استدعاؤها عند الحاجة مثل عند اختيار فئة من قائمة
  void selectCategory(String category) {
    selectedCategory.value = category;
    final index = categories.indexWhere((cat) => cat.categoryName == category);
    if (index != -1) {
      selectedCategoryIndex.value = index;
    }
  }

  /// دالة إدارة الفئة المحددة حسب الفهرس
  /// هذه الدالة تسمح بتعيين الفئة المحددة الحالية بناءً على الفهرس
  /// مثل اختيار الفئة الأولى أو الثانية من القائمة
  /// وتحديث الفاتورة الحالية بناءً على الفئة المحددة
  /// يمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "الفئة التالية"
  /// أو عند الضغط على زر "الفئة السابقة"
  void selectCategoryByIndex(int index) {
    if (index >= 0 && index < categories.length) {
      selectedCategoryIndex.value = index;
      selectedCategory.value = categories[index].categoryName;
    }
  }

  /// دالة إضافة منتج إلى فاتورة
  /// هذه الدالة تسمح بإضافة منتج إلى الفاتورة الحالية
  /// بناءً على المنتج المحدد
  /// وتحديث الفاتورة الحالية بناءً على المنتج المضاف
  /// يمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "إضافة منتج"
  /// أو عند اختيار منتج من قائمة
  /// أو عند إضافة منتج من واجهة المستخدم
  /// أو عند إضافة منتج من قائمة المنتجات
  void addProductToInvoice(MenuItemModel product) {
    final int? menuId = product.menuItemsID;
    if (menuId == null || menuId <= 0) {
      AppDialogs.show('تنبيه', 'لا يمكن إضافة منتج بدون معرف صالح.');
      return;
    }
    final String productKey = menuId.toString();
    final existingItemIndex = currentInvoice.items.indexWhere(
      (item) => item.productId == productKey,
    );

    if (existingItemIndex != -1) {
      /// اضافة الكمية للمنتج
      currentInvoice.items[existingItemIndex].quantity++;
      currentInvoice.items[existingItemIndex].calculateTotal();
    } else {
      /// إضافة منتج جديد
      final newItem = InvoiceItem(
        productId: productKey,
        name: product.itemsName,
        price: product.price,
        quantity: 1,
        note: '',
      );
      currentInvoice.items.add(newItem);
    }

    currentInvoice.calculateTotals();
    invoices.refresh();
  }

  /// دالة تحديث كمية عنصر في الفاتورة
  /// هذه الدالة تسمح بتحديث كمية عنصر في الفاتورة الحالية
  /// بناءً على الفهرس المحدد
  /// وتحديث الفاتورة الحالية بناءً على الكمية الجديدة
  /// يمكن استدعاؤها عند الحاجة مثل عند تغيير الكمية في واجهة المستخدم
  /// أو عند تعديل الكمية في الفاتورة
  /// أو عند تحديث الكمية في قائمة العناصر
  /// أو عند تعديل الكمية في قائمة الطلبات
  /// أو عند تعديل الكمية في قائمة الفواتير
  /// أو عند تعديل الكمية في قائمة المبيعات
  /// أو عند تعديل الكمية في قائمة المشتريات
  /// أو عند تعديل الكمية في قائمة المخزون
  /// أو عند تعديل الكمية في قائمة المنتجات
  /// أو عند تعديل الكمية في قائمة الأصناف
  void updateItemQuantity(int itemIndex, int newQuantity) {
    if (itemIndex >= 0 && itemIndex < currentInvoice.items.length) {
      if (newQuantity <= 0) {
        currentInvoice.items.removeAt(itemIndex);
      } else {
        currentInvoice.items[itemIndex].quantity = newQuantity;
        currentInvoice.items[itemIndex].calculateTotal();
      }
      currentInvoice.calculateTotals();
      invoices.refresh();
    }
  }

  /// دالة إزالة عنصر من الفاتورة
  /// هذه الدالة تسمح بإزالة عنصر من الفاتورة الحالية
  /// بناءً على الفهرس المحدد
  void removeItem(int itemIndex) {
    if (itemIndex >= 0 && itemIndex < currentInvoice.items.length) {
      currentInvoice.items.removeAt(itemIndex);
      currentInvoice.calculateTotals();
      invoices.refresh();
    }
  }

  /// حفظ الفاتورة
  /// هذه الدالة تسمح بحفظ الفاتورة الحالية في قاعدة البيانات
  /// وتحديث حالة الفاتورة إلى "محفوظة"
  /// يمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "حفظ الفاتورة"
  /// أو عند الانتهاء من الفاتورة
  /// أو عند الانتقال إلى فاتورة أخرى
  /// أو عند إغلاق التطبيق
  /// أو عند الحاجة إلى حفظ الفاتورة في قاعدة البيانات
  Future<void> saveInvoice() async {
    try {
      isLoading.value = true;

      /// تأكيد تحديث المجاميع قبل الحفظ
      currentInvoice.calculateTotals();

      /// تحقق: في حال الدفع آجل يجب اختيار عميل
      if (currentInvoice.paymentType == 'آجل' &&
          (currentInvoice.customerName.isEmpty)) {
        AppDialogs.show('تنبيه', 'عند اختيار الدفع (آجل) يجب تحديد العميل أولاً');
        isLoading.value = false;
        return;
      }

      /// تحقق: يجب أن تحتوي الفاتورة على عنصر واحد على الأقل
      if (currentInvoice.items.isEmpty) {
        AppDialogs.show('تنبيه', 'لا يمكن حفظ فاتورة بدون عناصر. أضف عنصرًا واحدًا على الأقل.');
        isLoading.value = false;
        return;
      }

      /// تحقق من العناصر: يجب أن تملك معرف منتج صالح
      final invalidItems = currentInvoice.items
          .where(
            (it) =>
                int.tryParse(it.productId) == null ||
                (int.tryParse(it.productId) ?? 0) <= 0,
          )
          .toList();
      if (invalidItems.isNotEmpty) {
        final names = invalidItems.map((e) => e.name).join('، ');
        AppDialogs.show('تنبيه', 'هناك عناصر لا تملك معرف صالح في جدول الأصناف: $names');
        isLoading.value = false;
        return;
      }

      /// تحويل طريقة الدفع إلى الصيغة المعتمدة في قاعدة البيانات
      final bool isCredit = currentInvoice.paymentType == 'آجل';
      final String paymentMethod = isCredit ? 'Credit' : 'Cash';

      /// تحديد مبالغ الدفع
      final double totalAmount = currentInvoice.total;
      final double amountPaid = isCredit ? 0.0 : totalAmount;
      final double amountDue = isCredit ? totalAmount : 0.0;

      /// الحصول على رقم العميل عند الآجل
      int? customerId;
      if (isCredit) {
        customerId = _resolveCustomerIdByName(currentInvoice.customerName);
        if (customerId == null) {
          AppDialogs.show('تنبيه', 'تعذر تحديد العميل المختار. يرجى إعادة اختيار العميل.');
          isLoading.value = false;
          return;
        }
      }

      /// الحصول على المستخدم والوردية من AuthService بشكل ديناميكي
      int? resolvedUserId;
      int? resolvedShiftId;
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        resolvedUserId = auth.currentUser.value?.userID;
        resolvedShiftId = auth.currentShiftId;
      }
      if (resolvedUserId == null || resolvedShiftId == null) {
        AppDialogs.show('تنبيه', 'لا يمكن الحفظ: تأكد من تسجيل الدخول وفتح وردية حالية.');
        isLoading.value = false;
        return;
      }

      /// تحويل عناصر الفاتورة إلى عناصر طلب
      final orderItems = currentInvoice.items
          .map(
            (it) => OrderItemModel(
              orderID: 0, // سيتم تعيينه في المعاملة داخل OrderService
              menuItemsID: int.parse(it.productId),
              quantity: it.quantity.toDouble(),
              price: it.price,
            ),
          )
          .toList();

      /// ملاحظة: استبدل القيم الافتراضية للمستخدم والوردية بالقيم الفعلية في نظامك
      final orderModel = OrderModel(
        orderDate: DateTime.now(),
        totalAmount: totalAmount,
        taxAmount: currentInvoice.taxAmount,
        serviceCharge: currentInvoice.serviceAmount,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        amountDue: amountDue,
        customerID: customerId,
        userID: resolvedUserId,
        shiftID: resolvedShiftId,
        notes: 'فاتورة من نقاط البيع - ${currentInvoice.orderType}',
        orderItems: orderItems,
      );

      // تشخيص: طباعة الحمولة قبل الحفظ
      print(
        'DEBUG saveInvoice -> PaymentMethod=$paymentMethod, total=$totalAmount, items=${orderItems.length}, customerID=$customerId, userID=$resolvedUserId, shiftID=$resolvedShiftId',
      );

      int orderId;
      try {
        orderId = await _orderService.createOrderAndPrint(
          orderModel,
          printerIp: printerIp.value,
          printerPort: printerPort.value,
          savePdf: true,
        );
      } on DatabaseException catch (dbErr) {
        final msg = dbErr.toString();
        if (msg.contains('FOREIGN KEY constraint failed')) {
          AppDialogs.show('خطأ في الحفظ', 'فشل قيد المفاتيح الخارجية. تأكد من وجود UserID و ShiftID صالحين${isCredit ? ' وكذلك CustomerID' : ''}.');
        } else {
          AppDialogs.show('خطأ في الحفظ', 'فشل قاعدة البيانات: $msg');
        }
        rethrow;
      }

      /// تعيين رقم الفاتورة بعد الحفظ
      currentInvoice.number = 'INV$orderId';

      /// تحديث الحالة
      currentInvoice.status = InvoiceStatus.saved;
      invoices.refresh();

      /// تم الاستغناء عن الانتقال إلى شاشة الطباعة - الطباعة أصبحت مباشرة عند الحفظ
      AppDialogs.show('تم الحفظ والطباعة', 'رقم الطلب: $orderId\nتم إرسال التذكرة للطابعة وحفظ PDF.');
    } catch (e) {
      print('حفظ الفاتورة فشل: $e');
      AppDialogs.show('خطأ', 'حدث خطأ أثناء حفظ الفاتورة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// مساعد: إيجاد رقم العميل بالاسم من القائمة المحمّلة
  int? _resolveCustomerIdByName(String name) {
    try {
      final match = customers.firstWhere(
        (c) => (c.customerName).trim() == name.trim(),
      );
      return match.customerID;
    } catch (_) {
      return null;
    }
  }

  /// طباعة الفاتورة
  /// هذه الدالة تسمح بفتح صفحة الطباعة للفاتورة الحالية
  /// ويمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "طباعة الفاتورة"
  /// أو عند الانتهاء من الفاتورة
  /// أو عند الانتقال إلى فاتورة أخرى
  /// أو عند إغلاق التطبيق
  /// أو عند الحاجة إلى طباعة الفاتورة
  /// أو عند الحاجة إلى طباعة الفاتورة في قائمة الطلبات
  Future<void> printInvoice() async {
    try {
      isLoading.value = true;

      /// تأكيد تحديث المجاميع قبل الطباعة
      currentInvoice.calculateTotals();

      /// فتح صفحة الطباعة
      final invoiceMap = {
        'id': currentInvoice.id,
        'number': currentInvoice.number,
        'orderType': currentInvoice.orderType,
        'paymentType': currentInvoice.paymentType,
        'customerName': currentInvoice.customerName,
        'tableNumber': currentInvoice.tableNumber,
        'createdAt': currentInvoice.createdAt.toIso8601String(),
        'status': currentInvoice.status.toString().split('.').last,
        'subtotal': currentInvoice.subtotal,
        'taxAmount': currentInvoice.taxAmount,
        'serviceAmount': currentInvoice.serviceAmount,
        'total': currentInvoice.total,
        'serviceCharge': currentInvoice.serviceCharge,
        'items': currentInvoice.items
            .map(
              (it) => {
                'productId': it.productId,
                'name': it.name,
                'price': it.price,
                'quantity': it.quantity,
                'note': it.note,
              },
            )
            .toList(),
      };
      await Get.toNamed(
        '/print',
        arguments: {'invoice': invoiceMap, 'autoPrint': false},
      );
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء فتح صفحة الطباعة');
    } finally {
      isLoading.value = false;
    }
  }

  /// دفع الفاتورة
  /// هذه الدالة تسمح بدفع الفاتورة الحالية بواسطة محاكاة عملية الدفع
  /// وتحديث حالة الفاتورة إلى "مدفوعة"
  /// يمكن استدعاؤها عند الحاجة مثل عند الضغط على زر "دفع الفاتورة"
  /// أو عند الانتهاء من الفاتورة
  Future<void> payInvoice() async {
    try {
      isLoading.value = true;

      /// حفظ الفاتورة اذا كانت جديدة
      if (currentInvoice.status == InvoiceStatus.draft) {
        await saveInvoice();
      }

      /// محاكاة عملية الدفع
      await Future.delayed(const Duration(seconds: 2));

      currentInvoice.status = InvoiceStatus.paid;
      currentInvoice.paidAt = DateTime.now();
      invoices.refresh();

      AppDialogs.show('تم الدفع', 'تم دفع الفاتورة ${currentInvoice.number} بنجاح - المبلغ: ${currentInvoice.total.toStringAsFixed(2)} ر.س');
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء معالجة الدفع: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تعيين نوع الدفع الحالي (نقد / آجل) وتحديث الفاتورة النشطة
  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    currentInvoice.paymentType = method;
    // إذا تحول إلى نقد، نفرغ اسم العميل
    if (method == 'نقد') {
      currentInvoice.customerName = '';
    }
    invoices.refresh();
  }
}
