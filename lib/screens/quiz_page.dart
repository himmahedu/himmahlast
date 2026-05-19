import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizPage extends StatefulWidget {
  final String lectureId;
  final String courseId;
  const QuizPage({super.key, required this.lectureId, required this.courseId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  bool _loading = true;
  bool _quizCompleted = false;
  bool _alreadyTaken = false;
  int _previousScore = 0;
  int _previousTotal = 0;

  @override
  void initState() {
    super.initState();
    _checkPreviousAttempt();
  }

  Future<void> _checkPreviousAttempt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final resultDoc = await FirebaseFirestore.instance
        .collection('quizResults')
        .where('studentId', isEqualTo: user.uid)
        .where('lectureId', isEqualTo: widget.lectureId)
        .get();
    if (resultDoc.docs.isNotEmpty) {
      final data = resultDoc.docs.first.data();
      _previousScore = data['score'] ?? 0;
      _previousTotal = data['totalQuestions'] ?? 0;
      setState(() {
        _alreadyTaken = true;
        _loading = false;
      });
    } else {
      _fetchQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lectures')
        .doc(widget.lectureId)
        .collection('quizzes')
        .get();
    if (snapshot.docs.isNotEmpty) {
      _questions = snapshot.docs.map((d) => d.data()).toList();
    }
    setState(() => _loading = false);
  }

  void _answer(int selected) {
    if (_questions[_current]['correctIndex'] == selected) {
      _score++;
    }
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // حفظ النتيجة في مجموعة quizResults
      await FirebaseFirestore.instance.collection('quizResults').add({
        'studentId': user.uid,
        'quizId': widget.lectureId, // استخدام lectureId كمُعرِّف للكويز
        'lectureId': widget.lectureId,
        'courseId': widget.courseId,
        'score': _score,
        'totalQuestions': _questions.length,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // تحديث النقاط الإجمالية للطالب
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'tokens': FieldValue.increment(_score),
      });
    }
    setState(() => _quizCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_alreadyTaken) {
      return Scaffold(
        appBar: AppBar(title: const Text('نتيجة الكويز')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Color(0xFFFFDE59)),
              const SizedBox(height: 20),
              Text('لقد أجبت على هذا الكويز مسبقًا ونتيجتك هي $_previousScore من $_previousTotal',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('لا توجد أسئلة بعد')));
    if (_quizCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text('لقد حصلت على $_score من ${_questions.length} نقطة',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_current];
    return Scaffold(
      appBar: AppBar(title: Text('الكويز - ${_current + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_current + 1) / _questions.length),
            const SizedBox(height: 20),
            Text(q['question'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate((q['options'] as List).length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFFFFDE59),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => _answer(i),
                  child: Text(q['options'][i], style: const TextStyle(fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}