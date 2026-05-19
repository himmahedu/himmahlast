import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/screens/register_page.dart';
import 'package:himmah_app/screens/forgot_password_page.dart';
import 'package:himmah_app/screens/student_home_page.dart';
import 'package:himmah_app/screens/teacher_dashboard_page.dart';
import 'package:himmah_app/screens/admin_dashboard_page.dart';
import 'package:himmah_app/screens/setup_profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uc = await _authService.signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (uc != null) {
        final user = uc.user!;
        final userDoc = await _authService.getUserData(user.uid);

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email ?? '',
            'role': 'student',
            'username': user.email ?? '',
            'specialty': '',
            'year': '',
            'university': '',
            'tokens': 0,
            'disabled': false,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إنشاء بياناتك. الرجاء تسجيل الدخول مجدداً.')),
            );
          }
          setState(() => _loading = false);
          return;
        }

        final role = userDoc.get('role') ?? 'student';
        final disabled = userDoc.get('disabled') ?? false;

        print('=== DEBUG ===');
        print('Role: $role');
        print('Specialty: ${userDoc.get('specialty')}');
        print('Year: ${userDoc.get('year')}');

        if (disabled == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('حسابك معطل. تواصل مع الإدارة.')),
            );
          }
          setState(() => _loading = false);
          return;
        }

        if (role == 'student' && !user.emailVerified) {
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الرجاء تفعيل بريدك الإلكتروني. تم إرسال رابط التفعيل.')),
            );
          }
          setState(() => _loading = false);
          return;
        }

        Widget destination;
        if (role == 'student') {
          final specialty = userDoc.get('specialty') ?? '';
          final year = userDoc.get('year') ?? '';
          if (specialty.isEmpty || year.isEmpty) {
            destination = const SetupProfilePage();
          } else {
            destination = StudentHomePage(specialty: specialty, year: year);
          }
        } else if (role == 'teacher') {
          destination = TeacherDashboardPage(teacherId: user.uid);
        } else {
          destination = const AdminDashboardPage();
        }

        print('Destination: ${destination.runtimeType}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري الانتقال إلى ${destination.runtimeType}... الدور: $role'),
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => destination),
              (route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'خطأ في تسجيل الدخول';
      if (e.code == 'user-not-found') msg = 'المستخدم غير موجود';
      if (e.code == 'wrong-password') msg = 'كلمة المرور خاطئة';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF3131), Color(0xFFFF8C00)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'أكاديمية همة التعليمية',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email, color: Color(0xFFFFDE59)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDE59), width: 2)),
                            ),
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFDE59)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDE59), width: 2)),
                            ),
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFDE59),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                                  : const Text('دخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                          child: const Text('ليس لديك حساب؟ سجل الآن', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                          child: const Text('نسيت كلمة السر', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//ubjhmguyjb  



//oihnkj,nohn



