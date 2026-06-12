// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/styled_text_form_field.dart';
import '../../Users/models/user_model.dart';
import '../controllers/auth_controller.dart';
import '../../Settings/controllers/settings_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final selectedUser = ''.obs;
    final isPasswordVisible = false.obs;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
          child: Card(
            elevation: 20,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.withOpacity(0.05)],
                ),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and Title
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: settings.restaurantNameController,
                        builder: (context, value, child) {
                          final title = value.text.isEmpty
                              ? 'اسم المطعم'
                              : value.text;
                          return Text(
                            title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'نظام إدارة المطعم',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      /// User Selection Dropdown
                      StyledInputContainer(
                        child: Obx(
                          () => DropdownButtonFormField<String>(
                            value: selectedUser.value.isEmpty
                                ? null
                                : selectedUser.value,
                            // ١. استخدام الدالة المساعدة لإنشاء التصميم الداخلي الموحد
                            items: controller.allUsers.map((UserModel user) {
                              return DropdownMenuItem<String>(
                                value: user.username,
                                child: buildUserDropdownItem(user),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedUser.value = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى اختيار المستخدم';
                              }
                              return null;
                            },
                            // ٢. التنسيقات الموحدة للقائمة نفسها
                            decoration: const InputDecoration(
                              labelText: 'اختر المستخدم',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color(0xFF3B82F6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            hint: const Text('اختر اسم المستخدم'),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// Password Field
                      StyledInputContainer(
                        child: Obx(
                          () => TextFormField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible.value,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color(0xFF3B82F6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  isPasswordVisible.value =
                                      !isPasswordVisible.value;
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              if (value.length < 4) {
                                return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      await controller.login(
                                        selectedUser.value,
                                        passwordController.text,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading.value
                                ? const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // User Info (role preview)
                      Obx(
                        () => selectedUser.value.isNotEmpty
                            ? _buildUserInfo(selectedUser.value)
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),

                      // Footer
                      Text(
                        'جميع الحقوق محفوظة © 2024',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// عرض معلومات المستخدم المختار
  Widget _buildUserInfo(String username) {
    final UserModel? user = controller.allUsers
        .cast<UserModel>()
        .firstWhereOrNull((u) => u.username == username);
    if (user == null) return const SizedBox.shrink();

    final bool isAdmin = user.role.toLowerCase() == 'مشرف';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isAdmin ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isAdmin ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.point_of_sale,
            color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الصلاحية: ${isAdmin ? 'مشرف' : 'كاشير'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
