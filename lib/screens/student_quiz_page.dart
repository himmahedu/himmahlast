import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class StudentQuizPage extends StatefulWidget {
  final String courseId;
  final String lectureId;
  const StudentQuizPage({super.key, required this.courseId, required this.lectureId});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('quizzes')
        .get();
    if (snapshot.docs.isNotEmpty) {
      _questions = snapshot.docs.map((d) => d.data()).toList();
    }
    setState(() => _isLoading = false);
  }

  void _answer(int selected) {
    if (_questions[_current]['correctIndex'] == selected) _score++;
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() => _finished = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'tokens': FieldValue.increment(_score),
        'totalQuizzes': FieldValue.increment(1),
      });
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('quizResults')
          .doc(user.uid)
          .set({
        'score': _score,
        'total': _questions.length,
        'userId': user.uid,
        'userName': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('لا توجد أسئلة')));
    if (_finished) {
      return MainLayout(
        title: 'نتيجة الكويز',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80.sp, color: const Color(0xFFFFDE59)),
              SizedBox(height: 16.h),
              Text('نتيجتك: $_score / ${_questions.length}', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }
    final q = _questions[_current];
    return MainLayout(
      title: 'الكويز - ${_current + 1}/${_questions.length}',
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              color: const Color(0xFFFF3131),
            ),
            SizedBox(height: 24.h),
            Text(q['question'], style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            ...List.generate(
              (q['options'] as List).length,
                  (i) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    backgroundColor: const Color(0xFFFFDE59),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: () => _answer(i),
                  child: Text(q['options'][i], style: TextStyle(fontSize: 16.sp)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}