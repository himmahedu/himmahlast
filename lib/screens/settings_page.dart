import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:himmah_app/theme_provider.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/screens/admin_dashboard_page.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  final _user = FirebaseAuth.instance.currentUser;
  bool _loading = true;
  String _specialty = '';
  String _year = '';
  String _university = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (_user != null) {
        final doc = await _authService.getUserData(_user!.uid);
        if (doc.exists) {
          _nameCtrl.text = doc.get('username') ?? '';
          _specialty = doc.get('specialty') ?? '';
          _year = doc.get('year') ?? '';
          _university = doc.get('university') ?? '';
          _role = doc.get('role') ?? 'student';
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل بيانات المستخدم: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    if (_user != null) {
      await _authService.updateUserProfile(uid: _user!.uid, username: _nameCtrl.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    }
  }

  Future<void> _changePassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('املأ كلا الحقلين')));
      return;
    }
    try {
      await _authService.reauthenticate(_oldPassCtrl.text);
      await _authService.changePassword(_newPassCtrl.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور')));
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_loading) {
      return const MainLayout(title: 'الإعدادات', body: Center(child: CircularProgressIndicator()));
    }
    return MainLayout(
      title: 'الإعدادات',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المظهر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('الوضع الداكن'),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            const Divider(height: 30),
            const Text('الحساب الشخصي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _saveName, child: const Text('حفظ الاسم')),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReadOnlyField('التخصص', _specialty),
                    _buildReadOnlyField('السنة الدراسية', _year),
                    _buildReadOnlyField('الجامعة', _university),
                    const SizedBox(height: 8),
                    Text(
                      _role == 'admin' ? 'يمكنك تعديل هذه البيانات من لوحة الإدارة' : 'يمكن للمدير فقط تعديل هذه البيانات',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (_role == 'admin')
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardPage()));
                        },
                        child: const Text('الذهاب إلى لوحة الإدارة'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: _oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور القديمة')),
            const SizedBox(height: 12),
            TextFormField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _changePassword, child: const Text('تغيير كلمة المرور')),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF3131))),
          Expanded(child: Text(value.isEmpty ? 'غير محدد' : value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}