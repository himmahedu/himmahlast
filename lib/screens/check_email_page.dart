import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himmah_app/screens/login_page.dart';

class CheckEmailPage extends StatefulWidget {
  final String email;
  const CheckEmailPage({super.key, required this.email});

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  bool _isSending = false;

  Future<void> _resendEmail() async {
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إعادة إرسال رابط التفعيل')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
    setState(() => _isSending = false);
  }

  Future<void> _checkVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم التحقق بعد. تحقق من بريدك الإلكتروني.')),
        );
      }
    }
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
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_unread, size: 80.sp, color: Colors.white),
                  SizedBox(height: 24.h),
                  Text(
                    'تحقق من بريدك الإلكتروني',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'تم إرسال رابط التفعيل إلى ${widget.email}',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'قد تجد الرسالة في مجلد السبام أو البريد غير المرغوب فيه',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFDE59),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      onPressed: _isSending ? null : _resendEmail,
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إعادة إرسال رابط التفعيل', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      onPressed: _checkVerified,
                      child: const Text('تم التحقق، تابع', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}