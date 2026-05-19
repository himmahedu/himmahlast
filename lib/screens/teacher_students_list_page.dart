import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherStudentsListPage extends StatelessWidget {
  final String lectureId;
  const TeacherStudentsListPage({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نتائج الطلاب')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final students = snapshot.data!.docs;
          return FutureBuilder<Map<String, int>>(
            future: _getAllQuizResults(students),
            builder: (context, resultsSnapshot) {
              if (!resultsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final results = resultsSnapshot.data!;
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final data = students[index].data() as Map<String, dynamic>;
                  final uid = students[index].id;
                  return ListTile(
                    title: Text(data['username'] ?? ''),
                    subtitle: Text('النقاط في هذا الكويز: ${results[uid] ?? 0}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getAllQuizResults(List<QueryDocumentSnapshot> students) async {
    final Map<String, int> results = {};
    for (var student in students) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(student.id)
          .collection('quizResults')
          .doc(lectureId)
          .get();
      if (doc.exists) {
        results[student.id] = doc.get('score') ?? 0;
      }
    }
    return results;
  }
}