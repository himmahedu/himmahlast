import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himmah_app/auth_service.dart';
import 'package:himmah_app/screens/register_page.dart';
import 'package:himmah_app/screens/forgot_password_page.dart';

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
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      setState(() => _loading = false);

      if (uc != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('تم الدخول')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                    const Text('تم تسجيل الدخول بنجاح', style: TextStyle(fontSize: 22)),
                    const SizedBox(height: 10),
                    Text('البريد: ${_emailCtrl.text.trim()}'),
                  ],
                ),
              ),
            ),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      String msg = 'خطأ في تسجيل الدخول';
      if (e.code == 'user-not-found') msg = 'المستخدم غير موجود';
      if (e.code == 'wrong-password') msg = 'كلمة المرور خاطئة';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFF3131), Color(0xFFFF8C00)]),
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
                    CircleAvatar(radius: 50, backgroundColor: Colors.white, child: ClipOval(child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain))),
                    const SizedBox(height: 20),
                    const Text('أكاديمية همة التعليمية', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: 'البريد الإلكتروني', labelStyle: const TextStyle(color: Colors.white70), prefixIcon: const Icon(Icons.email, color: Color(0xFFFFDE59)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDE59), width: 2))),
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: 'كلمة المرور', labelStyle: const TextStyle(color: Colors.white70), prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFDE59)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDE59), width: 2))),
                            validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDE59), foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 16)),
                              onPressed: _loading ? null : _login,
                              child: _loading ? const CircularProgressIndicator(color: Colors.black) : const Text('دخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('ليس لديك حساب؟ سجل الآن', style: TextStyle(color: Colors.white))),
                      const SizedBox(width: 20),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())), child: const Text('نسيت كلمة السر', style: TextStyle(color: Colors.white))),
                    ]),
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
