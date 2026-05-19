import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  String _selectedTeacher = '';
  final AuthService _authService = AuthService();

  Future<void> _addCourse() async {
    await _authService.addCourse({
      'name': _nameCtrl.text,
      'imageUrl': _imageCtrl.text,
      'specialty': _specialtyCtrl.text,
      'year': '',
      'meetLink': '',
      'teacher': _selectedTeacher,
    });
    _nameCtrl.clear();
    _imageCtrl.clear();
    _specialtyCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'إدارة المواد',
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم المادة')),
            SizedBox(height: 8.h),
            TextField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة')),
            SizedBox(height: 8.h),
            TextField(controller: _specialtyCtrl, decoration: const InputDecoration(labelText: 'التخصص')),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _addCourse, child: const Text('إضافة مادة')),
            SizedBox(height: 24.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _authService.getAllCourses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final courses = snapshot.data!.docs;
                  if (courses.isEmpty) return const Text('لا توجد مواد');
                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final data = courses[index].data() as Map<String, dynamic>;
                      final docId = courses[index].id;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['specialty'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _authService.deleteCourse(docId);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}