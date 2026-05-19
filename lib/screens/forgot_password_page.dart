import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himmah_app/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _reset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل بريدك الإلكتروني')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط إعادة التعيين')));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.message}')));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسيت كلمة السر')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Color(0xFFFF3131)),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'بريدك الإلكتروني',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _reset,
              child: const Text('إرسال رابط الاستعادة'),
            ),
          ],
        ),
      ),
    );
  }
}