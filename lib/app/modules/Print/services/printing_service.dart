// ignore_for_file: deprecated_member_use

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../OrderItems/models/order_item_model.dart';
import '../../Orders/models/order_model.dart';
import '../../SubMain/models/invoice.dart';

class PrintingService {
  PrintingService._();
  static final PrintingService instance = PrintingService._();

  Future<void> printInvoiceTicket(
    Invoice invoice, {
    required String ip,
    int port = 9100,
    PaperSize paper = PaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(ip, port: port);
    if (res != PosPrintResult.success) {
      throw Exception('فشل الاتصال بالطابعة: ${describeEnum(res)}');
    }

    try {
      // Header
      printer.text(
        'فاتورة مبيعات',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      printer.text(
        invoice.number.isNotEmpty ? invoice.number : 'بدون رقم',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.hr();

      // Info
      printer.text(
        'العميل: ${invoice.customerName}',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.text(
        'الطاولة: ${invoice.tableNumber}',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.text(
        'نوع الطلب: ${invoice.orderType} | الدفع: ${invoice.paymentType}',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.text(
        'التاريخ: ${invoice.createdAt.toString().substring(0, 16)}',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.hr();

      // Table header
      printer.row([
        PosColumn(
          text: 'الإجمالي',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'السعر',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'الكمية',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'الصنف',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      for (final item in invoice.items) {
        final total = (item.total);
        printer.row([
          PosColumn(
            text: total.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.price.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.quantity.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.name,
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        if ((item.note).toString().trim().isNotEmpty) {
          printer.text(
            'ملاحظة: ${item.note}',
            styles: const PosStyles(align: PosAlign.right),
          );
        }
      }

      printer.hr();

      // Totals
      void totalRow(String label, double value, {bool bold = false}) {
        printer.row([
          PosColumn(
            text: value.toStringAsFixed(2),
            width: 6,
            styles: PosStyles(bold: bold),
          ),
          PosColumn(
            text: label,
            width: 6,
            styles: PosStyles(bold: bold, align: PosAlign.right),
          ),
        ]);
      }

      totalRow('الإجمالي الفرعي', invoice.subtotal);
      totalRow('الضريبة', invoice.taxAmount);
      totalRow('الخدمة', invoice.serviceAmount);
      printer.hr();
      totalRow('الإجمالي', invoice.total, bold: true);

      printer.feed(2);
      printer.text(
        'شكراً لزيارتكم!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.cut();
    } finally {
      printer.disconnect();
    }
  }

  Future<void> printOrderTicket(
    OrderModel order,
    List<OrderItemModel> items, {
    required String ip,
    int port = 9100,
    PaperSize paper = PaperSize.mm80,
    int? orderId,
  }) async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(ip, port: port);
    if (res != PosPrintResult.success) {
      throw Exception('فشل الاتصال بالطابعة: ${describeEnum(res)}');
    }

    try {
      // Header
      printer.text(
        'فاتورة مبيعات',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      final oid = order.orderID ?? orderId;
      printer.text(
        'رقم: ${oid ?? ''}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.hr();

      // Info
      final customerName = order.customer?.customerName ?? 'زبون نقدي';
      final payment = order.paymentMethod;
      printer.text(
        'العميل: $customerName',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.text(
        'الدفع: $payment',
        styles: const PosStyles(align: PosAlign.right),
      );
      printer.text(
        'التاريخ: ${order.orderDate.toString().substring(0, 16)}',
        styles: const PosStyles(align: PosAlign.right),
      );
      if ((order.notes ?? '').trim().isNotEmpty) {
        printer.text(
          'ملاحظة: ${order.notes}',
          styles: const PosStyles(align: PosAlign.right),
        );
      }
      printer.hr();

      // Table header
      printer.row([
        PosColumn(
          text: 'الإجمالي',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'السعر',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'الكمية',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'الصنف',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      for (final it in items) {
        final total = (it.quantity * it.price);
        final name = it.menuItem?.itemsName ?? 'صنف';
        printer.row([
          PosColumn(
            text: total.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: it.price.toStringAsFixed(2),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: it.quantity.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: name,
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      printer.hr();

      void totalRow(String label, double value, {bool bold = false}) {
        printer.row([
          PosColumn(
            text: value.toStringAsFixed(2),
            width: 6,
            styles: PosStyles(bold: bold),
          ),
          PosColumn(
            text: label,
            width: 6,
            styles: PosStyles(bold: bold, align: PosAlign.right),
          ),
        ]);
      }

      totalRow('الإجمالي', order.totalAmount, bold: true);
      totalRow('المدفوع', order.amountPaid);
      totalRow('المتبقي', order.amountDue);

      printer.feed(2);
      printer.text(
        'شكراً لزيارتكم!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      printer.cut();
    } finally {
      printer.disconnect();
    }
  }

  Future<File> saveOrderPdf(
    OrderModel order,
    List<OrderItemModel> items, {
    String? fileName,
    int? orderId,
  }) async {
    // تحميل خطوط عربية لدعم RTL وتشكيل الحروف
    final fontRegData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final fontBoldData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    );
    final arabicFont = pw.Font.ttf(fontRegData);
    final arabicBold = pw.Font.ttf(fontBoldData);
    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicBold);

    final doc = pw.Document(theme: theme);

    final base = pw.TextStyle(fontSize: 10);

    pw.Widget header() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'فاتورة مبيعات',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text('رقم: ${(order.orderID ?? orderId) ?? ''}', style: base),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );

    final customerName = order.customer?.customerName ?? 'زبون نقدي';
    pw.Widget info() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('العميل: $customerName', style: base),
        pw.Text('الدفع: ${order.paymentMethod}', style: base),
        pw.Text(
          'التاريخ: ${order.orderDate.toString().substring(0, 16)}',
          style: base,
        ),
        if ((order.notes ?? '').trim().isNotEmpty)
          pw.Text('ملاحظة: ${order.notes}', style: base),
        pw.SizedBox(height: 6),
      ],
    );

    pw.Widget itemsTable() {
      final headers = ['#', 'الصنف', 'الكمية', 'السعر', 'الإجمالي'];
      final data = <List<String>>[];
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final name = it.menuItem?.itemsName ?? 'صنف';
        final total = (it.quantity * it.price);
        data.add([
          '${i + 1}',
          name,
          it.quantity.toString(),
          it.price.toStringAsFixed(2),
          total.toStringAsFixed(2),
        ]);
      }
      return pw.Table.fromTextArray(
        headers: headers,
        data: data,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: base,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        columnWidths: {
          0: const pw.FixedColumnWidth(18),
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
          _pdfRow('الإجمالي', order.totalAmount, bold: true),
          _pdfRow('المدفوع', order.amountPaid),
          _pdfRow('المتبقي', order.amountDue),
        ],
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [header(), info(), itemsTable(), totals()],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    final name =
        fileName ??
        'order_${(order.orderID ?? orderId) ?? DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  pw.Widget _pdfRow(String label, double value, {bool bold = false}) {
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
}
