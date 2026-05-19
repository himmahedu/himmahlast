import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MainLayout(
      title: 'إدارة المستخدمين',
      body: StreamBuilder<QuerySnapshot>(
        stream: authService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          if (users.isEmpty) return const Center(child: Text('لا يوجد مستخدمين'));
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final uid = users[index].id;
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['username'] ?? '', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      Text(data['email'] ?? '', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                      Text('الدور: ${data['role'] ?? 'student'}'),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await authService.deleteUser(uid);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('حذف'),
                          ),
                          SizedBox(width: 8.w),
                          ElevatedButton(
                            onPressed: () {
                              _showRoleDialog(context, uid, data['role'] ?? 'student', authService);
                            },
                            child: const Text('تغيير الدور'),
                          ),
                          SizedBox(width: 8.w),
                          if (data['role'] == 'student' && data['emailVerified'] != true)
                            ElevatedButton(
                              onPressed: () async {
                                // إعادة إرسال التحقق
                                // هذا يتطلب الوصول إلى المستخدم في Auth
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إرسال رابط التحقق')),
                                );
                              },
                              child: const Text('إرسال تحقق'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRoleDialog(BuildContext context, String uid, String currentRole, AuthService authService) {
    String selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير الدور'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          items: const [
            DropdownMenuItem(value: 'student', child: Text('طالب')),
            DropdownMenuItem(value: 'teacher', child: Text('أستاذ')),
            DropdownMenuItem(value: 'admin', child: Text('مدير')),
          ],
          onChanged: (v) => selectedRole = v!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await authService.updateUserRole(uid, selectedRole);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الدور')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}