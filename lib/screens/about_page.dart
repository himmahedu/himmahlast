import 'package:flutter/material.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'حول التطبيق',
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info, size: 80, color: Color(0xFFFF3131)),
              SizedBox(height: 20),
              Text(
                'أكاديمية همة التعليمية',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'تطبيق تعليمي متكامل يهدف إلى تسهيل العملية التعليمية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'المدير التنفيذي: محمد نور الهدى النعسان',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00)),
              ),
              SizedBox(height: 40),
              Text(
                'حقوق التطبيق محفوظة لصالح أكاديمية همة التعليمية',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}