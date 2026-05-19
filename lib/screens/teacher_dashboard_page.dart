import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/widgets/main_layout.dart';
import 'package:himmah_app/screens/teacher_lecture_detail_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  final String teacherId;
  const TeacherDashboardPage({super.key, required this.teacherId});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'لوحة الأستاذ',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final courses = snapshot.data!.docs;
          if (courses.isEmpty) return const Center(child: Text('لا توجد مواد'));
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final data = courses[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.book, color: Color(0xFFFF8C00)),
                title: Text(data['name'] ?? ''),
                subtitle: Text('${data['specialty']} - ${data['year']}'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TeacherLectureDetailPage(courseId: courses[index].id, courseName: data['name'] ?? ''),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}