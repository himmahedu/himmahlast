import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/models/course.dart';
import 'package:himmah_app/screens/lectures_page.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class StudentHomePage extends StatelessWidget {
  final String specialty;
  final String year;
  const StudentHomePage({super.key, required this.specialty, required this.year});

  @override
  Widget build(BuildContext context) {
    print('=== StudentHomePage ===');
    print('specialty: [$specialty]');
    print('year: [$year]');

    return MainLayout(
      title: 'المواد الدراسية',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('specialty', isEqualTo: specialty)
            .where('year', isEqualTo: year)
            .snapshots(),
        builder: (context, snapshot) {
          print('StreamBuilder state: ${snapshot.connectionState}');
          print('Has data: ${snapshot.hasData}');
          print('Has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          final docs = snapshot.data!.docs;
          print('Number of courses found: ${docs.length}');

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('لا توجد مواد للتخصص: $specialty, السنة: $year'),
                  const SizedBox(height: 10),
                  const Text('تأكد من وجود مواد في Firestore بنفس التخصص والسنة'),
                ],
              ),
            );
          }

          final courses = docs.map((d) => Course.fromFirestore(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LecturesPage(course: course))),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Color(0xFFFF3131)),
                    title: Text(course.name),
                    subtitle: Text('${course.specialty} - ${course.year}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
