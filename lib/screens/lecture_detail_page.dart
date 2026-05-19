import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:himmah_app/models/lecture.dart';
import 'package:himmah_app/models/course.dart';
import 'package:himmah_app/screens/chat_page.dart';
import 'package:himmah_app/screens/quiz_page.dart';

class LectureDetailPage extends StatelessWidget {
  final Lecture lecture;
  final Course course;
  const LectureDetailPage({super.key, required this.lecture, required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lecture.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('تشغيل الفيديو'),
            onPressed: () {
              if (lecture.videoUrl.isNotEmpty) {
                launchUrl(Uri.parse(lecture.videoUrl));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رابط فيديو')));
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('فتح ملف PDF'),
            onPressed: () {
              if (lecture.pdfUrl.isNotEmpty) {
                launchUrl(Uri.parse(lecture.pdfUrl), mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد ملف PDF بعد')));
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.quiz),
            label: const Text('الكويز'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage(lectureId: lecture.id, courseId: course.id))),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('الدردشة'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(courseId: course.id, courseName: course.name))),
          ),
        ],
      ),
    );
  }
}
