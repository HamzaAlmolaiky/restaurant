// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helpers/app_dialogs.dart';
import '../../../widgets/filter_bar.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/search_text_field.dart';
import '../../../widgets/statistics_card.dart';
import '../../../widgets/statistics_row.dart';
import '../../../widgets/styled_dropdown_form_field.dart';
import '../controllers/employee_controller.dart';
import '../models/employee_model.dart';


class EmployeeView extends GetView<EmployeeController> {
  const EmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          /// Header Section
          PageHeader(
            title: 'إدارة الموظفين',
            subtitle: 'متابعة وإدارة بيانات الموظفين والحضور والأداء',
            actions: [
              PrimaryButton(
                text: 'موظف جديد',
                onPressed: () => _showEmployeeFormDialog(context),
                icon: Icons.person_add,
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              PrimaryButton(
                text: 'تسجيل حضور',
                onPressed: () => _showAttendanceDialog(context),
                icon: Icons.access_time,
                backgroundColor: const Color(0xFF3B82F6),
              ),
            ],
            // تم دمج قسم الإحصائيات هنا ليصبح جزءًا من الترويسة
            bottomChild: Obx(() {
              if (controller.isLoading.value && controller.employees.isEmpty) {
                // عرض التحميل فقط في البداية
                return const Center(child: CircularProgressIndicator());
              }
              return StatisticsRow(
                children: [
                  StatisticsCard(
                    title: 'إجمالي الموظفين',
                    value: controller.totalEmployees.value.toString(),
                    icon: Icons.people_outline,
                    color: const Color(0xFF8B5CF6),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'حاضرون اليوم',
                    value: controller.presentToday.value.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'متأخرون',
                    value: controller.lateCount.value.toString(),
                    icon: Icons.schedule_outlined,
                    color: const Color(0xFFF59E0B),
                    change: '',
                  ),
                  StatisticsCard(
                    title: 'في إجازة',
                    value: controller.onLeaveCount.value.toString(),
                    icon: Icons.beach_access_outlined,
                    color: const Color(0xFF3B82F6),
                    change: '',
                  ),
                ],
              );
            }),
          ),

          /// Search and Filters
          FilterBar(
            children: [
              // ١. حقل البحث - مفعّل
              SearchTextField(
                hintText: 'البحث عن موظف...',
                onChanged: controller.searchEmployees,
              ),

              // ٢. قائمة فلترة القسم - مربوطة بالمتحكم
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'القسم',
                  value: controller.selectedDepartment.value,
                  items:
                      ['الكل', 'المطبخ', 'الخدمة', 'الإدارة', 'التوصيل']
                          .map(
                            (item) =>
                                DropdownMenuItem(value: item, child: Text(item)),
                          )
                          .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) controller.filterByDepartment(newValue);
                  },
                ),
              ),

              // ٣. قائمة فلترة الحالة - مربوطة بالمتحكم
              Obx(
                () => StyledDropdownFormField<String>(
                  labelText: 'الحالة',
                  value: controller.selectedStatus.value,
                  items: ['الكل', 'نشط', 'غير نشط']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) controller.filterByStatus(newValue);
                  },
                ),
              ),

              // ٤. زر تحديث البيانات
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: IconButton(
                  onPressed: controller.loadEmployeesFromDB,
                  icon: const Icon(Icons.refresh, color: Color(0xFF8B5CF6)),
                  tooltip: 'تحديث البيانات',
                ),
              ),
            ],
          ),

          /// Employees Grid
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Obx(() {
                final items = controller.filteredEmployees;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final employee = items[index];
                    return _buildEmployeeCard(employee);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    final String name = employee.name;
    final String position = employee.position;
    final String phone = employee.phoneNumber ?? '';
    final double salary = employee.basicSalary;
    final bool isActive = employee.isActive;
    final String status = isActive ? 'نشط' : 'غير نشط';

    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'نشط':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'غير نشط':
      default:
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFEF4444).withOpacity(0.1);
    }

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'م',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                position,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الراتب:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${salary.toStringAsFixed(0)} ريال',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.visibility_outlined,
                            onTap: () => _viewEmployeeDetails(employee),
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                        const SizedBox(width: 8),
                         Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit_outlined,
                            onTap: () => _editEmployee(Get.context!, employee),
                            color: Colors.grey[600]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone_outlined,
                            onTap: () => _callEmployee(phone),
                            color: const Color(0xFF10B981),
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _showEmployeeFormDialog(BuildContext context, {EmployeeModel? employee}) {
    if (employee != null) {
      controller.fillFormForEdit(employee);
    } else {
      controller.nameController.clear();
      controller.phoneController.clear();
      controller.positionController.clear();
      controller.salaryController.clear();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                employee == null ? Icons.person_add : Icons.edit,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              Text(employee == null ? 'موظف جديد' : 'تعديل موظف'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الموظف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.positionController,
                    decoration: const InputDecoration(
                      labelText: 'المنصب / الوظيفة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.salaryController,
                    decoration: const InputDecoration(
                      labelText: 'الراتب الأساسي',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => controller.saveEmployee(existingEmployee: employee),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(employee == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showAttendanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFF3B82F6)),
              SizedBox(width: 12),
              Text('تسجيل حضور'),
            ],
          ),
          content: const SizedBox(
            width: 400,
            child: Text('سيتم إضافة نموذج تسجيل الحضور هنا'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('تسجيل'),
            ),
          ],
        );
      },
    );
  }

  void _viewEmployeeDetails(EmployeeModel employee) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            const Text('تفاصيل الموظف'),
            const Spacer(),
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الاسم: ${employee.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text('الهاتف: ${employee.phoneNumber ?? "-"}'),
            const SizedBox(height: 8),
            Text('المنصب: ${employee.position}'),
            const SizedBox(height: 8),
            Text('الراتب: ${employee.basicSalary.toStringAsFixed(2)} ريال'),
            const SizedBox(height: 8),
            Text('تاريخ التعيين: ${employee.hireDate.toLocal().toString().substring(0, 10)}'),
            const SizedBox(height: 8),
            Text('الحالة: ${employee.isActive ? "نشط" : "غير نشط"}'),
          ],
        ),
      ),
    );
  }

  void _editEmployee(BuildContext context, EmployeeModel employee) {
    _showEmployeeFormDialog(context, employee: employee);
  }

  void _callEmployee(String phone) {
    AppDialogs.show('الاتصال بالموظف', 'جاري الاتصال بالرقم: $phone');
  }
}
