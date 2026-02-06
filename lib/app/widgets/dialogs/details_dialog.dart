// ignore_for_file: deprecated_member_use, avoid_print

/*/ ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'custom_form_dialog.dart';

class DetailItem {
  final String label;
  final String value;
  final IconData? icon;
  const DetailItem({required this.label, required this.value, this.icon});
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 150, // عرض موحد للعنوان
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// عنصر بيانات لقائمة العناصر التفصيلية (يعرض كـ ListTile موحد)
class DetailListTileData {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final IconData leadingIcon;
  const DetailListTileData({
    required this.title,
    this.subtitle,
    this.trailingText,
    this.leadingIcon = Icons.fastfood,
  });
}

/// عنوان قسم داخلي موحد
class DetailsSectionTitle extends StatelessWidget {
  const DetailsSectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// قائمة عناصر موحدة داخل صندوق مزخرف
class DetailsItemsList extends StatelessWidget {
  const DetailsItemsList({super.key, required this.items});
  final List<DetailListTileData> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('لا توجد عناصر لهذا القسم.'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: items
            .map(
              (it) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(it.leadingIcon, size: 18, color: Colors.grey),
                ),
                title: Text(it.title),
                subtitle: it.subtitle != null ? Text(it.subtitle!) : null,
                trailing: it.trailingText != null
                    ? Text(
                        it.trailingText!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// ويدجت تحميل موحد يستخدم في شاشات التفاصيل
class DetailsLoading extends StatelessWidget {
  const DetailsLoading({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// هذا هو الكلاس العام الجديد والمبسط
class DetailsDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;

  /// قائمة بالويدجتس التي تمثل صفوف التفاصيل.
  /// مرر قائمة من DetailRow هنا.
  final List<Widget>? detailRows;

  /// بديل أسهل: تمرير عناصر تفاصيل مجردة وسيتم بناؤها داخلياً.
  final List<DetailItem>? detailItems;

  /// عنوان اختياري لقسم العناصر
  final String? itemsSectionTitle;

  /// بيانات عناصر تفصيلية تعرض كـ ListTile موحد
  final List<DetailListTileData>? items;

  /// قسم إضافي اختياري في الأسفل (للتوافق أو للاستخدام الحر).
  final Widget? extraSection;

  const DetailsDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.blueAccent,
    this.detailRows,
    this.detailItems,
    this.itemsSectionTitle,
    this.items,
    this.extraSection,
  });

  @override
  Widget build(BuildContext context) {
    // تجهيز محتوى الصفوف
    final List<Widget> rows = [];

    if (detailRows != null && detailRows!.isNotEmpty) {
      rows.addAll(detailRows!);
    } else if (detailItems != null && detailItems!.isNotEmpty) {
      for (var i = 0; i < detailItems!.length; i++) {
        final d = detailItems![i];
        rows.add(DetailRow(label: d.label, value: d.value, icon: d.icon));
      }
    }

    // تجهيز قسم العناصر إن وجد
    if (items != null) {
      rows.add(const Divider(height: 24));
      if (itemsSectionTitle != null && itemsSectionTitle!.isNotEmpty) {
        rows.add(DetailsSectionTitle(itemsSectionTitle!));
      }
      rows.add(DetailsItemsList(items: items!));
    }

    // إضافة extraSection إن وجد
    if (extraSection != null) {
      rows.add(extraSection!);
    }

    return CustomFormDialog(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,

      // نمرر مفتاحًا وهميًا لأننا لا نحتاج للتحقق من الصحة
      formKey: GlobalKey<FormState>(),

      // نجمع كل المحتوى في formFields
      formFields: rows,

      // أهم جزء: نضبط الأزرار لعرض زر "إغلاق" فقط
      showCloseIcon: true,
      cancelButtonText: 'إغلاق',
      onConfirm: null, // <-- تمرير null هنا سيخفي زر الحفظ تلقائيًا
    );
  }
}*

// file: lib/widgets/dialogs/details_dialog.dart
import 'package:flutter/material.dart';
import 'custom_form_dialog.dart';

// -------------------------------------------------------------------
// ١. تعريفات البيانات المجردة (Data Contracts)
// هذه الكلاسات الصغيرة تخبر DetailsDialog "ماذا" يعرض
// -------------------------------------------------------------------

/// يمثل صفًا واحدًا من البيانات (عنوان وقيمة).
class DetailItem {
  final String label;
  final String value;
  final IconData? icon;
  const DetailItem({required this.label, required this.value, this.icon});
}

/// يمثل عنصرًا واحدًا في قائمة تفصيلية (يعرض كـ ListTile).
class DetailListItem {
  final String title;
  final String? subtitle;
  final String? trailingText;
  final IconData? leadingIcon;
  const DetailListItem({
    required this.title,
    this.subtitle,
    this.trailingText,
    this.leadingIcon,
  });
}

// -------------------------------------------------------------------
// ٢. الكلاس العام الرئيسي
// -------------------------------------------------------------------

class DetailsDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;

  /// قائمة بالبيانات الأساسية التي تعرض كـ "عنوان: قيمة".
  final List<DetailItem> detailItems;

  /// عنوان اختياري لقسم القائمة.
  final String? listSectionTitle;

  /// قائمة بالعناصر التي تعرض كـ ListTile.
  final List<DetailListItem>? listItems;

  /// ويدجت إضافي للعرض في الأسفل (للحالات المتقدمة أو التحميل).
  final Widget? extraSection;

  const DetailsDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.blueAccent,
    this.detailItems = const [],
    this.listSectionTitle,
    this.listItems,
    this.extraSection,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFormDialog(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      formKey: GlobalKey<FormState>(),
      width: 600,

      formFields: [
        // بناء صفوف التفاصيل الأساسية
        ...detailItems.map((item) => _DetailRow(item: item)),

        // بناء قسم القائمة إذا كان موجودًا
        if (listItems != null && listItems!.isNotEmpty) ...[
          const Divider(height: 24),
          if (listSectionTitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                listSectionTitle!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _DetailsList(items: listItems!),
        ],

        // إضافة extraSection إن وجد
        if (extraSection != null) extraSection!,
      ],

      showCloseIcon: true,
      cancelButtonText: 'إغلاق',
      onConfirm: null,
    );
  }
}

// -------------------------------------------------------------------
// ٣. الويدجتس المساعدة الخاصة (Private Helper Widgets)
// هذه الويدجتس لا يمكن الوصول إليها إلا من داخل هذا الملف
// -------------------------------------------------------------------

/// ويدجت خاص لرسم صف "عنوان: قيمة".
class _DetailRow extends StatelessWidget {
  final DetailItem item;
  const _DetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${item.label}:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item.value)),
        ],
      ),
    );
  }
}

/// ويدجت خاص لرسم قائمة العناصر (ListTile).
class _DetailsList extends StatelessWidget {
  final List<DetailListItem> items;
  const _DetailsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: items
            .map(
              (it) => ListTile(
                dense: true,
                leading: it.leadingIcon != null
                    ? CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          it.leadingIcon,
                          size: 18,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                title: Text(it.title),
                subtitle: it.subtitle != null ? Text(it.subtitle!) : null,
                trailing: it.trailingText != null
                    ? Text(
                        it.trailingText!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}*/

// file: lib/widgets/dialogs/details_section.dart
import 'package:flutter/material.dart';
import 'package:restaurant/app/helpers/app_dialogs.dart';

/// ويدجت عام ومتخصص لعرض قسم تفصيلي داخل حوار.
///
/// يقوم بإدارة دورة حياة جلب البيانات من `Future` ويعرض الحالات المختلفة
/// (تحميل، خطأ، بيانات فارغة، نجاح)، ثم يستخدم دالة `itemBuilder`
/// لبناء الواجهة لكل عنصر في القائمة.
class DetailsSection<T> extends StatelessWidget {
  /// العنوان الذي يظهر فوق القسم.
  final String title;

  /// الـ Future الذي سيقوم بجلب قائمة البيانات.
  final Future<List<T>> future;

  /// دالة يتم استدعاؤها لبناء ويدجت لكل عنصر في القائمة بعد وصول البيانات.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// ويدجت يتم عرضه عند عدم وجود بيانات.
  final Widget? emptyWidget;

  const DetailsSection({
    super.key,
    required this.title,
    required this.future,
    required this.itemBuilder,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, thickness: 1),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        FutureBuilder<List<T>>(
          future: future,
          builder: (context, snapshot) {
            // ١. حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              );
            }

            // ٢. حالة الخطأ
            if (snapshot.hasError) {
              print('Error in DetailsSection: ${snapshot.error}');
              AppDialogs.showError(
                'خطأ',
                'حدث خطأ أثناء جلب البيانات:\n${snapshot.error}',
              );
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'حدث خطأ في تحميل البيانات',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];

            // ٣. حالة عدم وجود بيانات
            if (items.isEmpty) {
              return emptyWidget ??
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('لا توجد بيانات لعرضها.')),
                  );
            }

            // ٤. حالة النجاح: بناء قائمة العناصر
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                // نستخدم itemBuilder لبناء كل صف
                children: items
                    .map((item) => itemBuilder(context, item))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
