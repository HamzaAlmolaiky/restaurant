// ignore_for_file: deprecated_member_use

import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

import '../../SubMain/models/invoice.dart';
import '../../SubMain/models/invoice_item.dart';
import '../../../helpers/app_dialogs.dart';

class PrintController extends GetxController {
  var isLoading = false.obs;
  var printData = Rx<Invoice?>(null);

  Invoice? _tryParseInvoice(dynamic inv) {
    try {
      if (inv is Invoice) return inv;
      if (inv is Map) {
        // محاولة بناء Invoice من خريطة، مع قيم افتراضية آمنة للعرض
        final items = <InvoiceItem>[];
        final rawItems = inv['items'];
        if (rawItems is List) {
          for (final it in rawItems) {
            try {
              if (it is Map) {
                final item = InvoiceItem(
                  productId:
                      (it['productId'] ??
                              it['menuItemsID'] ??
                              it['ItemsID'] ??
                              0)
                          .toString(),
                  name: (it['name'] ?? it['ItemsName'] ?? 'منتج').toString(),
                  price: ((it['price'] ?? it['Price'] ?? 0.0) as num)
                      .toDouble(),
                  quantity: ((it['quantity'] ?? it['Quantity'] ?? 1) as num)
                      .toInt(),
                  note: (it['note'] ?? '').toString(),
                );
                item.calculateTotal();
                items.add(item);
              }
            } catch (_) {
              // تجاهل العناصر غير القابلة للتحويل
            }
          }
        }

        final invoice = Invoice(
          id: (inv['id'] ?? '').toString(),
          number: (inv['number'] ?? '').toString(),
          orderType: (inv['orderType'] ?? 'محلي').toString(),
          paymentType: (inv['paymentType'] ?? 'نقد').toString(),
          customerName: (inv['customerName'] ?? '').toString(),
          tableNumber: (inv['tableNumber'] ?? '').toString(),
          items: items,
          createdAt: () {
            final v = inv['createdAt'];
            if (v is String) {
              return DateTime.tryParse(v) ?? DateTime.now();
            } else if (v is DateTime) {
              return v;
            }
            return DateTime.now();
          }(),
          paidAt: null,
          status: InvoiceStatus.values.firstWhere(
            (s) => s.toString().split('.').last == (inv['status'] ?? ''),
            orElse: () => InvoiceStatus.draft,
          ),
          subtotal: ((inv['subtotal'] ?? 0.0) as num).toDouble(),
          taxAmount: ((inv['taxAmount'] ?? 0.0) as num).toDouble(),
          serviceAmount: ((inv['serviceAmount'] ?? 0.0) as num).toDouble(),
          total: ((inv['total'] ?? 0.0) as num).toDouble(),
          serviceCharge: ((inv['serviceCharge'] ?? 0.0) as num).toDouble(),
        );
        if (invoice.total == 0 && invoice.items.isNotEmpty) {
          invoice.calculateTotals();
        }
        return invoice;
      }
    } catch (e) {
      // ignore: avoid_print
      print('فشل تحويل بيانات الفاتورة من Map: $e');
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();

    // Get invoice data from arguments
    final arguments = Get.arguments;
    bool autoPrint = false;
    // ignore: avoid_print
    print('DEBUG PrintController args type: ${arguments.runtimeType}');
    if (arguments is Map) {
      // ignore: avoid_print
      print('DEBUG PrintController args keys: ${arguments.keys.toList()}');
    }
    if (arguments is Invoice) {
      printData.value = arguments;
      // ignore: avoid_print
      print('DEBUG PrintController: received Invoice object directly.');
    } else if (arguments is Map) {
      final inv = arguments['invoice'] ?? arguments['data'] ?? arguments;
      // ignore: avoid_print
      print('DEBUG PrintController invoice candidate type: ${inv.runtimeType}');
      if (inv is Map) {
        // ignore: avoid_print
        print('DEBUG invoice map keys: ${inv.keys.toList()}');
      }
      final parsed = _tryParseInvoice(inv);
      if (parsed != null) {
        printData.value = parsed;
        // ignore: avoid_print
        print(
          'DEBUG PrintController: invoice parsed. items=${parsed.items.length}, total=${parsed.total}',
        );
      } else {
        // Fallback: حاول إنشاء فاتورة مبسطة لضمان عدم بقاء القيمة null
        if (inv is Map) {
          try {
            final fallback = Invoice(
              id: (inv['id'] ?? '').toString(),
              number: (inv['number'] ?? '').toString(),
              orderType: (inv['orderType'] ?? 'محلي').toString(),
              paymentType: (inv['paymentType'] ?? 'نقد').toString(),
              customerName: (inv['customerName'] ?? '').toString(),
              tableNumber: (inv['tableNumber'] ?? '').toString(),
              items: <InvoiceItem>[],
              createdAt: DateTime.now(),
              status: InvoiceStatus.draft,
              subtotal: ((inv['subtotal'] ?? 0.0) as num).toDouble(),
              taxAmount: ((inv['taxAmount'] ?? 0.0) as num).toDouble(),
              serviceAmount: ((inv['serviceAmount'] ?? 0.0) as num).toDouble(),
              total: ((inv['total'] ?? 0.0) as num).toDouble(),
              serviceCharge: ((inv['serviceCharge'] ?? 0.0) as num).toDouble(),
            );
            printData.value = fallback;
            // ignore: avoid_print
            print('DEBUG PrintController: fallback invoice applied.');
          } catch (e) {
            // ignore: avoid_print
            print('DEBUG PrintController: fallback failed: $e');
          }
        }
      }
      autoPrint = (arguments['autoPrint'] == true);
      // ignore: avoid_print
      print('DEBUG PrintController autoPrint: $autoPrint');
    }

    if (printData.value == null) {
      Future.microtask(() {
        if (Get.context != null) {
          AppDialogs.show(
            'تنبيه',
            'لم يتم تمرير بيانات الفاتورة لصفحة الطباعة',
          );
        } else {
          // Fallback to a simple log if there is no context/overlay yet
          // ignore: avoid_print
          print('تحذير: لم يتم تمرير بيانات الفاتورة إلى صفحة الطباعة');
        }
      });
    }

    // Trigger auto print (deferred to next microtask to ensure overlays are ready)
    if (autoPrint && printData.value != null) {
      Future.microtask(() => printInvoice());
    }
  }

  @override
  void onReady() {
    super.onReady();
    // إعادة المحاولة بعد بناء الواجهة لضمان وجود الوسائط
    if (printData.value == null) {
      final args = Get.arguments;
      // ignore: avoid_print
      print('DEBUG onReady: re-check args type: ${args.runtimeType}');
      if (args is Map) {
        final inv = args['invoice'] ?? args['data'] ?? args;
        final parsed = _tryParseInvoice(inv);
        if (parsed != null) {
          printData.value = parsed;
          // ignore: avoid_print
          print('DEBUG onReady: invoice parsed on retry.');
          final autoPrint = (args['autoPrint'] == true);
          if (autoPrint) Future.microtask(() => printInvoice());
        }
      }
    }
  }

  // Print invoice
  Future<void> printInvoice() async {
    try {
      if (isLoading.value) return; // guard re-entrancy
      isLoading.value = true;

      if (printData.value == null) {
        AppDialogs.show(
          'لا توجد فاتورة',
          'لم يتم العثور على بيانات فاتورة للطباعة',
        );
        return;
      }

      final invoice = printData.value!;

      // توليد ملف PDF
      final pdfBytes = await _generateInvoicePdf(invoice);

      // حفظ الملف
      final savedFile = await _savePdfToDisk(
        pdfBytes,
        fileName:
            'invoice_${(invoice.number.isNotEmpty ? invoice.number : invoice.id)}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // فتح مربع طباعة النظام
      // await Printing.layoutPdf(
      //   onLayout: (PdfPageFormat format) async => pdfBytes,
      // );

      AppDialogs.show('نجاح', 'تم حفظ الفاتورة في: ${savedFile.path}');
    } catch (e) {
      AppDialogs.show('خطأ في الطباعة', 'حدث خطأ أثناء طباعة/حفظ الفاتورة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // بناء ملف PDF للفـاتورة
  Future<Uint8List> _generateInvoicePdf(Invoice invoice) async {
    final doc = pw.Document();

    // ملاحظة: لعرض العربية بشكل صحيح يفضل تضمين خط عربي في الأصول لاحقاً
    final baseTextStyle = pw.TextStyle(fontSize: 11);

    pw.Widget header() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'فاتورة مبيعات',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          invoice.number.isEmpty ? 'بدون رقم' : invoice.number,
          style: baseTextStyle,
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );

    pw.Widget info() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('العميل: ${invoice.customerName}', style: baseTextStyle),
        pw.Text('الطاولة: ${invoice.tableNumber}', style: baseTextStyle),
        pw.Text(
          'نوع الطلب: ${invoice.orderType} | طريقة الدفع: ${invoice.paymentType}',
          style: baseTextStyle,
        ),
        pw.Text('التاريخ: ${invoice.createdAt}'),
        pw.SizedBox(height: 8),
      ],
    );

    pw.Widget itemsTable() {
      final headers = ['#', 'الصنف', 'الكمية', 'السعر', 'الإجمالي'];
      final data = <List<String>>[];
      for (int i = 0; i < invoice.items.length; i++) {
        final it = invoice.items[i];
        data.add([
          '${i + 1}',
          it.name,
          '${it.quantity}',
          it.price.toStringAsFixed(2),
          (it.total).toStringAsFixed(2),
        ]);
      }
      return pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: baseTextStyle,
        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        columnWidths: {
          0: const pw.FixedColumnWidth(20),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
        },
      );
    }

    pw.Widget totals() => pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(height: 8),
          _row('الإجمالي الفرعي', invoice.subtotal),
          _row('الضريبة', invoice.taxAmount),
          _row('الخدمة', invoice.serviceAmount),
          pw.Divider(),
          _row('الإجمالي', invoice.total, bold: true),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [header(), info(), itemsTable(), totals()],
      ),
    );

    return doc.save();
  }

  pw.Widget _row(String label, double value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          value.toStringAsFixed(2),
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<File> _savePdfToDisk(
    Uint8List bytes, {
    required String fileName,
  }) async {
    Directory? dir;
    try {
      // أولوية الحفظ في مجلد التنزيلات على سطح المكتب إن توفر
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // Share invoice as image or PDF
  Future<void> shareInvoice() async {
    try {
      isLoading.value = true;

      // Simulate sharing process
      await Future.delayed(const Duration(seconds: 1));

      AppDialogs.show('نجاح', 'تم مشاركة الفاتورة بنجاح');
    } catch (e) {
      AppDialogs.show('خطأ', 'حدث خطأ أثناء مشاركة الفاتورة');
    } finally {
      isLoading.value = false;
    }
  }

  // Copy invoice details to clipboard
  Future<void> copyInvoiceDetails() async {
    if (printData.value == null) return;

    final invoice = printData.value!;
    final details =
        '''
فاتورة ${invoice.number}
التاريخ: ${_formatDate(invoice.createdAt)}
العميل: ${invoice.customerName}
الطاولة: ${invoice.tableNumber}
نوع الطلب: ${invoice.orderType}
طريقة الدفع: ${invoice.paymentType}

المنتجات:
${invoice.items.map((item) => '${item.name} × ${item.quantity} = ${item.total.toStringAsFixed(2)} ر.س').join('\n')}

المجموع الفرعي: ${invoice.subtotal.toStringAsFixed(2)} ر.س
الضريبة (15%): ${invoice.taxAmount.toStringAsFixed(2)} ر.س
رسوم الخدمة (10%): ${invoice.serviceAmount.toStringAsFixed(2)} ر.س
المجموع الكلي: ${invoice.total.toStringAsFixed(2)} ر.س
''';

    await Clipboard.setData(ClipboardData(text: details));

    AppDialogs.show('نجاح', 'تم نسخ تفاصيل الفاتورة إلى الحافظة');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ignore: unused_element
  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get restaurant info (should come from settings)
  Map<String, String> getRestaurantInfo() {
    return {
      'name': 'مطعم دار النظامي',
      'subtitle': 'للمشويات التركية والأكلات الشعبية',
      'address': 'الرياض - حي النخيل - شارع الملك فهد',
      'phone': '+966 11 234 5678',
      'email': 'info@daralnazami.com',
      'website': 'www.daralnazami.com',
      'vatNumber': '123456789012345',
    };
  }
}
