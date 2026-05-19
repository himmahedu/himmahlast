import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:himmah_app/models/course.dart';
import 'package:himmah_app/models/lecture.dart';
import 'package:himmah_app/screens/lecture_detail_page.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class LecturesPage extends StatelessWidget {
  final Course course;
  const LecturesPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: course.name,
      actions: [
        // زر Google Meet محسّن
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (course.meetLink.isNotEmpty) {
                launchUrl(Uri.parse(course.meetLink), mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لم يقم الدكتور بإنشاء اجتماع بعد')),
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.video_call, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(course.id)
            .collection('lectures')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('لا توجد محاضرات'));
          final lectures = docs.map((d) => Lecture.fromFirestore(d)).toList();

          if (lectures.isEmpty) return const Center(child: Text('لا توجد محاضرات'));

          return DefaultTabController(
            length: lectures.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFFFF3131),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFFF8C00),
                  tabs: lectures.map<Widget>((l) => Tab(text: l.title)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: lectures.map<Widget>((lecture) {
                      return LectureDetailPage(lecture: lecture, course: course);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}