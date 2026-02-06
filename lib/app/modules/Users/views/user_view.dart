// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ObxState;
import 'package:restaurant/app/widgets/info_row.dart';

import '../../../helpers/app_dialogs.dart';
import '../../../helpers/dialog_helpers.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/reactive_form_fields.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../../../widgets/templates/management_screen_template.dart';
import '../controllers/user_management_controller.dart';
import '../models/user_model.dart';
import '../../../widgets/action_menu.dart';
import '../../../widgets/reactive_grid_section.dart';
import '../../../widgets/dialogs/custom_form_dialog.dart';

class UserView extends GetView<UserManagementController> {
  const UserView({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagementScreenTemplate(
      title: 'إدارة المستخدمين',
      subtitle: 'إدارة حسابات المستخدمين والصلاحيات',
      actions: [
        PrimaryButton(
          text: 'مستخدم جديد',
          onPressed: () => _showAddUserDialog(),
          icon: Icons.person_add,
          backgroundColor: const Color(0xFF8B5CF6),
        ),
      ],
      statisticsWidget: Obx(
        () => StatisticsRow(
          children: [
            StatisticsCard(
              title: 'إجمالي المستخدمين',
              value: controller.totalUsers.value.toString(),
              icon: Icons.people,
              color: const Color(0xFF8B5CF6),
              subtitle: 'مستخدم مسجل',
            ),
            StatisticsCard(
              title: 'المستخدمين النشطين',
              value: controller.activeUsersCount.value.toString(),
              icon: Icons.person_outline,
              color: const Color(0xFF10B981),
              subtitle: 'نشط حالياً',
            ),
            StatisticsCard(
              title: 'المديرين',
              value: controller.adminCount.value.toString(),
              icon: Icons.admin_panel_settings,
              color: const Color(0xFFEF4444),
              subtitle: 'صلاحيات كاملة',
            ),
            StatisticsCard(
              title: 'آخر تسجيل دخول',
              value: controller.lastLoginText.value,
              icon: Icons.access_time,
              color: const Color(0xFF3B82F6),
              subtitle: '—',
            ),
          ],
        ),
      ),
      filterWidgets: [
        SearchTextField(
          hintText: 'البحث في المستخدمين...',
          onChanged: controller.searchUsers,
          focusedBorderColor: const Color(0xFF8B5CF6),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'الدور',
            value: controller.selectedRole.value,
            items: controller.roles
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (val) => controller.updateRoleFilter(val!),
          ),
        ),
        Obx(
          () => StyledDropdownFormField<String>(
            labelText: 'الحالة',
            value: controller.selectedStatus.value,
            items: controller.statuses
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (val) => controller.updateStatusFilter(val!),
          ),
        ),
      ],

      // ٣. تمرير المحتوى الرئيسي (الجسم)
      body: ReactiveGridSection<UserModel>(
        // <-- حدد نوع البيانات هنا
        isLoading: controller.isLoading, // مرر المتغير التفاعلي مباشرة
        items: controller.filteredUsers, // مرر القائمة التفاعلية مباشرة
        emptyText: 'لا توجد بيانات لعرضها',
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        // مرر دالة بناء البطاقة مباشرة
        itemBuilder: (context, user) => _buildUserCard(user),
      ),
    );
  }

  /// دالة لاظهار بطاقة المستخدم
  Widget _buildUserCard(UserModel user) {
    return InfoCard(
      avatarLetter: user.username.isNotEmpty ? user.username[0] : 'م',
      avatarColor: _getRoleColor(user.role),
      title: user.username,

      // قائمة التفاصيل (في هذه الحالة، هو الدور فقط)
      details: [
        InfoCardDetail(
          icon: _getRoleIcon(user.role), // أيقونة مناسبة للدور
          text: user.role,
        ),
      ],

      // الجزء السفلي من البطاقة لعرض حالة المستخدم (نشط/غير نشط)
      bottomWidget: Container(
        // استخدام unconstrained إضافي لضمان أن الحاوية تأخذ حجمها الطبيعي
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                (user.isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444))
                    .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.isActive ? 'نشط' : 'غير نشط',
            style: TextStyle(
              color: user.isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // ٢. تمرير قائمة الإجراءات
      menuWidget: ActionMenu(
        onSelected: (value) => _handleUserAction(value, user),
        trigger: const Icon(Icons.more_vert, color: Colors.grey),
        items: [
          const ActionItem(
            value: 'view',
            text: 'عرض التفاصيل',
            icon: Icons.visibility,
            color: Colors.blue,
          ),
          const ActionItem(
            value: 'edit',
            text: 'تعديل',
            icon: Icons.edit,
            color: Colors.orange,
          ),
          if (_canManageRoles())
            const ActionItem(
              value: 'permissions',
              text: 'الصلاحيات',
              icon: Icons.security,
              color: Colors.purple,
            ),
          const ActionItem(
            value: 'reset_password',
            text: 'إعادة تعيين كلمة المرور',
            icon: Icons.lock_reset,
            color: Colors.green,
          ),
          ActionItem(
            value: user.isActive ? 'deactivate' : 'activate',
            text: user.isActive ? 'إلغاء التفعيل' : 'تفعيل المستخدم',
            icon: user.isActive ? Icons.block : Icons.check_circle,
            isDestructive: user.isActive,
          ),
        ],
      ),
    );
  }

  /// دالة لاظهار نافذة تفاصيل المستخدم
  void _handleUserAction(String value, UserModel user) {
    switch (value) {
      case 'view':
        _showUserDetailsDialog(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'permissions':
        _showPermissionsDialog(user);
        break;
      case 'reset_password':
        _showResetPasswordDialog(user);
        break;
      case 'deactivate':
        controller.toggleUserStatus(user.userID!, !user.isActive);
        break;
      case 'activate':
        controller.toggleUserStatus(user.userID!, !user.isActive);
        break;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'مشرف':
        return const Color(0xFF8B5CF6);
      case 'كاشير':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'مشرف':
        return Icons.verified_user;
      case 'كاشير':
        return Icons.point_of_sale;
      default:
        return Icons.person_outline;
    }
  }
}

/// دالة لاظهار نافذة تفاصيل المستخدم
void _showUserDetailsDialog(UserModel user) {
  Get.dialog(
    CustomFormDialog(
      title: 'تفاصيل المستخدم',
      subtitle: 'عرض المعلومات الأساسية للمستخدم "${user.username}"',
      icon: Icons.info_outline,
      iconColor: Colors.blueAccent,

      // ٢. بما أننا لا نحتاج لنموذج، نمرر مفتاحًا وهميًا
      formKey: GlobalKey<FormState>(),

      formFields: [
        InfoRow(label: 'المعرّف الرقمي (ID)', value: '${user.userID ?? '-'}'),
        InfoRow(label: 'اسم المستخدم', value: user.username),
        InfoRow(label: 'الدور (الصلاحية)', value: user.role),
        InfoRow(label: 'الحالة', value: user.isActive ? 'نشط' : 'غير نشط'),
      ],

      showCloseIcon: true, // يظهر أيقونة X في الأعلى
      cancelButtonText: 'إغلاق', // تغيير نص زر الإلغاء
      onConfirm: null,
    ),
  );
}

/// دالة لاظهار نافذة تعديل المستخدم
void _showEditUserDialog(UserModel user) {
  final formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController(text: user.username);
  final roles = Get.find<UserManagementController>().roles;
  final roleNotifier = ValueNotifier<String>(user.role);
  final activeNotifier = ValueNotifier<bool>(user.isActive);

  Get.dialog(
    CustomFormDialog(
      title: 'تعديل المستخدم',
      subtitle: 'قم بتحديث بيانات المستخدم واحفظ التغييرات',
      icon: Icons.edit,
      iconColor: Colors.teal,
      formKey: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      confirmButtonText: 'حفظ',
      formFields: [
        buildStyledTextFormField(
          controller: usernameCtrl,
          labelText: 'اسم المستخدم',
          prefixIcon: Icons.person_outline,
        ),
        ValueListenableBuilder<String>(
          valueListenable: roleNotifier,
          builder: (context, value, _) => DropdownButtonFormField<String>(
            value: value,
            items: roles
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => roleNotifier.value = v ?? value,
            decoration: const InputDecoration(
              labelText: 'الدور',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'اختر الدور' : null,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: activeNotifier,
          builder: (context, value, _) => SwitchListTile(
            value: value,
            onChanged: (v) => activeNotifier.value = v,
            contentPadding: EdgeInsets.zero,
            title: const Text('نشط'),
          ),
        ),
      ],
      onConfirm: () async {
        if (!(formKey.currentState?.validate() ?? false)) return;
        final updated = user.copyWith(
          username: usernameCtrl.text.trim(),
          role: roleNotifier.value,
          isActive: activeNotifier.value,
        );
        await Get.find<UserManagementController>().updateUser(updated);
        Get.back();
      },
    ),
  );
}

/// دالة لاظهار نافذة الصلاحيات
void _showPermissionsDialog(UserModel user) {
  if (!_canManageRoles()) {
    AppDialogs.show('غير مسموح', 'ليس لديك صلاحية لتعديل الأدوار');
    return;
  }

  final formKey = GlobalKey<FormState>();
  final roleNotifier = ValueNotifier<String>(user.role);

  Get.dialog(
    CustomFormDialog(
      title: 'إدارة الصلاحيات (الدور)',
      subtitle: 'حدد دوراً مناسباً للمستخدم "${user.username}"',
      icon: Icons.security,
      iconColor: Colors.deepPurple,
      formKey: formKey,
      confirmButtonText: 'حفظ الدور',
      confirmButtonColor: Colors.deepPurple,

      formFields: [
        ValueListenableDropdown<String>(
          valueNotifier: roleNotifier,
          labelText: 'الدور المحدد',
          prefixIcon: Icons.admin_panel_settings_outlined,
          // الحصول على قائمة الأدوار من الكنترولر
          items: Get.find<UserManagementController>().roles
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يجب اختيار دور للمستخدم';
            }
            return null;
          },
        ),
      ],

      onConfirm: () => handleFormSubmission(
        formKey: formKey,
        successMessage: 'تم تحديث دور المستخدم "${user.username}" بنجاح.',
        submissionFunction: () {
          final updatedUser = user.copyWith(role: roleNotifier.value);
          return Get.find<UserManagementController>().updateUser(updatedUser);
        },
      ),
    ),
  );
}

/// دالة لاظهار نافذة تغيير كلمة المرور
void _showResetPasswordDialog(UserModel user) {
  final formKey = GlobalKey<FormState>();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  Get.dialog(
    CustomFormDialog(
      title: 'إعادة تعيين كلمة المرور',
      subtitle: 'أدخل كلمة المرور الجديدة للمستخدم "${user.username}"',
      icon: Icons.lock_reset,
      iconColor: Colors.deepOrange,
      formKey: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      confirmButtonText: 'حفظ كلمة المرور',
      confirmButtonColor: Colors.deepOrange, // لتخصيص لون الزر

      formFields: [
        buildStyledTextFormField(
          controller: passCtrl,
          labelText: 'كلمة المرور الجديدة',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          // استخدام التحقق المخصص للحالات المعقدة
          customValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'كلمة المرور الجديدة مطلوبة';
            }
            if (value.length < 6) {
              return 'يجب أن تكون 6 أحرف/أرقام على الأقل';
            }
            return null;
          },
        ),
        buildStyledTextFormField(
          controller: pass2Ctrl,
          labelText: 'تأكيد كلمة المرور',
          prefixIcon: Icons.lock_person_outlined,
          obscureText: true,
          customValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'تأكيد كلمة المرور مطلوب';
            }
            // التحقق من المطابقة مع الحقل الأول
            if (value != passCtrl.text) {
              return 'كلمتا المرور غير متطابقتين';
            }
            return null;
          },
        ),
      ],

      // ٤. استخدام الدالة المساعدة لمعالجة الحفظ بأمان
      onConfirm: () => handleFormSubmission(
        formKey: formKey,
        successMessage:
            'تم تغيير كلمة المرور للمستخدم "${user.username}" بنجاح.',
        submissionFunction: () {
          return Get.find<UserManagementController>().changePassword(
            user.userID!,
            passCtrl.text.trim(),
          );
        },
      ),
    ),
  );
}

/// دالة لاظهار نافذة اضافة مستخدم
void _showAddUserDialog() {
  final formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final roles = Get.find<UserManagementController>().roles;
  final roleNotifier = ValueNotifier<String>(
    roles.isNotEmpty ? roles.first : '',
  );
  final activeNotifier = ValueNotifier<bool>(true);

  Get.dialog(
    CustomFormDialog(
      title: 'إضافة مستخدم جديد',
      subtitle: 'أدخل البيانات الأساسية للمستخدم',
      icon: Icons.person_add_alt_1,
      iconColor: Colors.indigo,
      formKey: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      confirmButtonText: 'إضافة',

      formFields: [
        // ١. استخدام الدالة المساعدة لحقل اسم المستخدم
        buildStyledTextFormField(
          controller: usernameCtrl,
          labelText: 'اسم المستخدم',
          prefixIcon: Icons.person_outline,
          validationType: ValidationType.notEmpty, // التحقق أصبح أبسط
          customValidationMessage: 'اسم المستخدم مطلوب',
        ),

        buildStyledTextFormField(
          controller: passwordCtrl,
          labelText: 'كلمة المرور',
          prefixIcon: Icons.lock_outline,
          obscureText: true, // <-- خاصية جديدة مقترحة
          customValidator: (v) {
            if (v == null || v.length < 6) {
              return 'كلمة المرور 6 أحرف/أرقام على الأقل';
            }
            return null;
          },
        ),

        ValueListenableDropdown<String>(
          valueNotifier: roleNotifier,
          labelText: 'الدور',
          prefixIcon: Icons.admin_panel_settings,
          items: roles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          validator: (v) => (v == null || v.isEmpty) ? 'اختر الدور' : null,
        ),

        ValueListenableSwitchTile(
          valueNotifier: activeNotifier,
          title: 'نشط',
          activeColor: Colors.indigo,
        ),
      ],

      onConfirm: () async {
        if (!(formKey.currentState?.validate() ?? false)) return;
        final newUser = UserModel(
          username: usernameCtrl.text.trim(),
          password: passwordCtrl.text.trim(),
          role: roleNotifier.value,
          isActive: activeNotifier.value,
        );
        await Get.find<UserManagementController>().addUser(newUser);
        Get.back();
      },
    ),
  );
}

/// دالة للتحقق من صلاحية تعديل الدور
bool _canManageRoles() {
  final roles = Get.find<UserManagementController>().roles;
  if (roles.isEmpty) return false;
  if (roles.length == 1) return true;
  if (roles.contains('مشرف')) return true;
  return true;
}
