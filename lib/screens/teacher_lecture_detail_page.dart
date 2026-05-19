import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:himmah_app/screens/chat_page.dart';
import 'package:himmah_app/screens/teacher_quiz_editor_page.dart';
import 'package:himmah_app/screens/teacher_students_list_page.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class TeacherLectureDetailPage extends StatefulWidget {
  final String courseId;
  final String courseName;
  const TeacherLectureDetailPage({super.key, required this.courseId, required this.courseName});

  @override
  State<TeacherLectureDetailPage> createState() => _TeacherLectureDetailPageState();
}

class _TeacherLectureDetailPageState extends State<TeacherLectureDetailPage> {
  final _titleCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _pdfCtrl = TextEditingController();
  final _meetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeetLink();
  }

  Future<void> _loadMeetLink() async {
    final doc = await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).get();
    if (doc.exists) {
      _meetCtrl.text = doc.get('meetLink') ?? '';
    }
  }

  Future<void> _addLecture() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('lectures').add({
      'title': _titleCtrl.text.trim(),
      'videoUrl': _videoCtrl.text.trim(),
      'pdfUrl': _pdfCtrl.text.trim(),
    });
    _titleCtrl.clear();
    _videoCtrl.clear();
    _pdfCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المحاضرة')));
  }

  Future<void> _updateMeetLink() async {
    await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
      'meetLink': _meetCtrl.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث رابط الاجتماع')));
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.courseName,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // رابط Google Meet
            TextField(controller: _meetCtrl, decoration: const InputDecoration(labelText: 'رابط Google Meet')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _updateMeetLink, child: const Text('حفظ رابط الاجتماع')),
            const Divider(height: 30),
            // إضافة محاضرة
            const Text('إضافة محاضرة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المحاضرة')),
            const SizedBox(height: 8),
            TextField(controller: _videoCtrl, decoration: const InputDecoration(labelText: 'رابط الفيديو')),
            const SizedBox(height: 8),
            TextField(controller: _pdfCtrl, decoration: const InputDecoration(labelText: 'رابط PDF')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _addLecture, child: const Text('إضافة المحاضرة')),
            const Divider(height: 30),
            // قائمة المحاضرات
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('lectures').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final lectures = snapshot.data!.docs;
                return Column(
                  children: lectures.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.quiz, color: Color(0xFFFFDE59)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TeacherQuizEditorPage(lectureId: doc.id),
                                ));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.people, color: Color(0xFFFF8C00)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TeacherStudentsListPage(lectureId: doc.id),
                                ));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: Color(0xFFFF3131)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ChatPage(courseId: widget.courseId, courseName: widget.courseName),
                                ));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('lectures').doc(doc.id).delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 30),
            // قسم نتائج الكويزات للمادة
            const Text('نتائج الكويزات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF3131))),
            const SizedBox(height: 10),
            _buildQuizResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResultsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizResults').where('courseId', isEqualTo: widget.courseId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final results = snapshot.data!.docs;
        if (results.isEmpty) return const Text('لا توجد نتائج بعد');
        return Column(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return FutureBuilder(
              future: FirebaseFirestore.instance.collection('users').doc(data['studentId']).get(),
              builder: (context, userSnapshot) {
                final username = userSnapshot.data?.get('username') ?? 'طالب';
                return Card(
                  child: ListTile(
                    title: Text(username),
                    subtitle: Text('النتيجة: ${data['score']} / ${data['totalQuestions']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.restart_alt, color: Colors.orange),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('quizResults').doc(doc.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة تعيين الكويز للطالب')));
                      },
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}