import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherQuizEditorPage extends StatefulWidget {
  final String lectureId;
  const TeacherQuizEditorPage({super.key, required this.lectureId});

  @override
  State<TeacherQuizEditorPage> createState() => _TeacherQuizEditorPageState();
}

class _TeacherQuizEditorPageState extends State<TeacherQuizEditorPage> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [];
  int _correctIndex = 0;
  int _optionCount = 2;

  @override
  void initState() {
    super.initState();
    _addOptionControllers();
  }

  void _addOptionControllers() {
    while (_optionCtrls.length < _optionCount) {
      _optionCtrls.add(TextEditingController());
    }
  }

  Future<void> _addQuestion() async {
    if (_questionCtrl.text.trim().isEmpty) return;
    final options = _optionCtrls.take(_optionCount).map((c) => c.text).toList();
    await FirebaseFirestore.instance
        .collection('lectures')
        .doc(widget.lectureId)
        .collection('quizzes')
        .add({
      'question': _questionCtrl.text.trim(),
      'options': options,
      'correctIndex': _correctIndex,
    });
    _questionCtrl.clear();
    for (var c in _optionCtrls) c.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة السؤال')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محرر الكويز')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // إضافة سؤال جديد
            TextField(controller: _questionCtrl, decoration: const InputDecoration(labelText: 'نص السؤال')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('عدد الخيارات:'),
                DropdownButton<int>(
                  value: _optionCount,
                  items: [2, 3, 4, 5, 6].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _optionCount = v!;
                      _addOptionControllers();
                    });
                  },
                ),
              ],
            ),
            ...List.generate(_optionCount, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v!),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionCtrls[i],
                        decoration: InputDecoration(labelText: 'الخيار ${i + 1}'),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _addQuestion, child: const Text('إضافة السؤال')),
            const Divider(height: 30),
            // قائمة الأسئلة الموجودة
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lectures')
                  .doc(widget.lectureId)
                  .collection('quizzes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final questions = snapshot.data!.docs;
                return Column(
                  children: questions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['question'] ?? ''),
                      subtitle: Text('الإجابة الصحيحة: ${data['correctIndex']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}