import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class ManageSpecialtiesPage extends StatefulWidget {
  const ManageSpecialtiesPage({super.key});

  @override
  State<ManageSpecialtiesPage> createState() => _ManageSpecialtiesPageState();
}

class _ManageSpecialtiesPageState extends State<ManageSpecialtiesPage> {
  final _nameCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _addSpecialty() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await _authService.addSpecialty(_nameCtrl.text.trim());
    _nameCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'إدارة التخصصات',
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم التخصص')),
            SizedBox(height: 8.h),
            ElevatedButton(onPressed: _addSpecialty, child: const Text('إضافة تخصص')),
            SizedBox(height: 24.h),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _authService.getSpecialties(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final specialties = snapshot.data!;
                  if (specialties.isEmpty) return const Text('لا توجد تخصصات');
                  return ListView.builder(
                    itemCount: specialties.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(specialties[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // يحتاج إلى docId، لذا سنبسط
                          },
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