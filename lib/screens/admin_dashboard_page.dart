import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himmah_app/services/specialties_service.dart';
import 'package:himmah_app/widgets/main_layout.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final List<String> _tabs = [
    'الطلاب',
    'المعلمون',
    'المواد',
    'التخصصات والسنوات',
    'الحسابات',
    'نتائج الكويزات',
    'روابط التواصل'
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'لوحة الإدارة',
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFFFF3131), Color(0xFFFF8C00)])
                          : null,
                      color: isSelected ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const _StudentsManagement(),
                const _TeachersManagement(),
                const _CoursesManagement(),
                const _SpecialtiesAndYearsManagement(),
                const _AccountsManagement(),
                const _QuizResultsManagement(),
                const _SocialLinksManagement(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== إدارة الطلاب ====================
class _StudentsManagement extends StatelessWidget {
  const _StudentsManagement();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!.docs;
        if (students.isEmpty) return const Center(child: Text('لا يوجد طلاب بعد'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            final uid = students[index].id;
            final username = data['username']?.toString() ?? '';
            final firstChar = username.isNotEmpty ? username.substring(0, 1) : 'ط';
            final isActive = data['subscriptionActive'] ?? false;
            final isDisabled = data['disabled'] ?? false;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: isDisabled
                      ? Colors.red
                      : isActive
                      ? Colors.green
                      : const Color(0xFFFFDE59),
                  child: Icon(
                    isDisabled
                        ? Icons.block
                        : isActive
                        ? Icons.check_circle
                        : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  username.isEmpty ? 'بدون اسم' : username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDisabled ? Colors.red : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? 'بدون بريد'),
                    Text('التخصص: ${data['specialty'] ?? '-'} | السنة: ${data['year'] ?? '-'}'),
                    Text(
                      isActive ? '✅ مشترك' : '❌ غير مشترك',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                children: [
                  const Divider(),
                  // تعديل الاسم
                  _EditableField(label: 'الاسم', value: data['username'] ?? '', onSave: (val) {
                    FirebaseFirestore.instance.collection('users').doc(uid).update({'username': val});
                  }),
                  // تعديل البريد
                  _EditableField(label: 'البريد', value: data['email'] ?? '', onSave: (val) {
                    FirebaseFirestore.instance.collection('users').doc(uid).update({'email': val});
                  }),
                  // تعديل الجامعة
                  _EditableField(label: 'الجامعة', value: data['university'] ?? '', onSave: (val) {
                    FirebaseFirestore.instance.collection('users').doc(uid).update({'university': val});
                  }),
                  // اختيار التخصص والسنة
                  _SpecialtyYearSelector(
                    uid: uid,
                    currentSpecialty: data['specialty'] ?? '',
                    currentYear: data['year'] ?? '',
                  ),
                  const SizedBox(height: 8),
                  // أزرار التحكم
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // زر تفعيل/تعطيل الاشتراك
                        ElevatedButton.icon(
                          icon: Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            isActive ? 'تعطيل الاشتراك' : 'تفعيل الاشتراك',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.orange : Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'subscriptionActive': !isActive,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isActive ? 'تم تعطيل الاشتراك' : 'تم تفعيل الاشتراك')),
                            );
                          },
                        ),
                        // زر تفعيل/تعطيل الحساب
                        ElevatedButton.icon(
                          icon: Icon(
                            isDisabled ? Icons.check_circle : Icons.block,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            isDisabled ? 'تفعيل الحساب' : 'تعطيل الحساب',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDisabled ? Colors.green : Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'disabled': !isDisabled,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isDisabled ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب')),
                            );
                          },
                        ),
                        // زر حذف الطالب
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                          label: const Text('حذف الطالب', style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: Text('هل أنت متأكد من حذف الطالب "$username"؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الطالب')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== محدد التخصص والسنة ====================
class _SpecialtyYearSelector extends StatefulWidget {
  final String uid;
  final String currentSpecialty;
  final String currentYear;
  const _SpecialtyYearSelector({required this.uid, required this.currentSpecialty, required this.currentYear});

  @override
  State<_SpecialtyYearSelector> createState() => _SpecialtyYearSelectorState();
}

class _SpecialtyYearSelectorState extends State<_SpecialtyYearSelector> {
  String? _selectedSpecialty;
  String? _selectedYear;
  List<String> _specialties = [];
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.currentSpecialty;
    _selectedYear = widget.currentYear;
    _loadLists();
  }

  Future<void> _loadLists() async {
    final specs = await SpecialtiesService.getSpecialties();
    final yrs = await SpecialtiesService.getYears();
    setState(() {
      _specialties = specs;
      _years = yrs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _specialties.contains(_selectedSpecialty) ? _selectedSpecialty : null,
            decoration: const InputDecoration(
              labelText: 'التخصص',
              hintText: 'اختر التخصص',
              border: OutlineInputBorder(),
            ),
            items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              setState(() => _selectedSpecialty = v);
              FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'specialty': v});
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _years.contains(_selectedYear) ? _selectedYear : null,
            decoration: const InputDecoration(
              labelText: 'السنة',
              hintText: 'اختر السنة',
              border: OutlineInputBorder(),
            ),
            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) {
              setState(() => _selectedYear = v);
              FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'year': v});
            },
          ),
        ],
      ),
    );
  }
}

// ==================== حقل قابل للتعديل ====================
class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onSave;
  const _EditableField({required this.label, required this.value, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onSave(ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ==================== إدارة المعلمين ====================
class _TeachersManagement extends StatelessWidget {
  const _TeachersManagement();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final teachers = snapshot.data!.docs;
        if (teachers.isEmpty) return const Center(child: Text('لا يوجد معلمون بعد'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final data = teachers[index].data() as Map<String, dynamic>;
            final uid = teachers[index].id;
            final username = data['username']?.toString() ?? '';
            final firstChar = username.isNotEmpty ? username.substring(0, 1) : 'م';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF8C00),
                  child: Text(firstChar, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                title: Text(username.isEmpty ? 'بدون اسم' : username),
                subtitle: Text('${data['email']}\nالتخصص: ${data['specialty'] ?? '-'}'),
                children: [
                  _EditableField(label: 'الاسم', value: data['username'] ?? '', onSave: (val) {
                    FirebaseFirestore.instance.collection('users').doc(uid).update({'username': val});
                  }),
                  _EditableField(label: 'البريد', value: data['email'] ?? '', onSave: (val) {
                    FirebaseFirestore.instance.collection('users').doc(uid).update({'email': val});
                  }),
                  _TeacherSpecialtySelector(uid: uid, currentSpecialty: data['specialty'] ?? ''),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text('حذف المعلم'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المعلم')));
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TeacherSpecialtySelector extends StatefulWidget {
  final String uid;
  final String currentSpecialty;
  const _TeacherSpecialtySelector({required this.uid, required this.currentSpecialty});

  @override
  State<_TeacherSpecialtySelector> createState() => _TeacherSpecialtySelectorState();
}

class _TeacherSpecialtySelectorState extends State<_TeacherSpecialtySelector> {
  String? _selectedSpecialty;
  List<String> _specialties = [];

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = widget.currentSpecialty;
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    final specs = await SpecialtiesService.getSpecialties();
    setState(() => _specialties = specs);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: _specialties.contains(_selectedSpecialty) ? _selectedSpecialty : null,
        decoration: const InputDecoration(labelText: 'التخصص', hintText: 'اختر التخصص'),
        items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) {
          setState(() => _selectedSpecialty = v);
          FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'specialty': v});
        },
      ),
    );
  }
}

// ==================== إدارة المواد ====================
class _CoursesManagement extends StatefulWidget {
  const _CoursesManagement();

  @override
  State<_CoursesManagement> createState() => _CoursesManagementState();
}

class _CoursesManagementState extends State<_CoursesManagement> {
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _specialty;
  String? _year;
  List<String> _specialties = [];
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final specs = await SpecialtiesService.getSpecialties();
    final yrs = await SpecialtiesService.getYears();
    setState(() {
      _specialties = specs;
      _years = yrs;
      if (specs.isNotEmpty) _specialty = specs.first;
      if (yrs.isNotEmpty) _year = yrs.first;
    });
  }

  Future<void> _addCourse() async {
    if (_nameCtrl.text.trim().isEmpty || _specialty == null || _year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المادة واختيار التخصص والسنة')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('courses').add({
      'name': _nameCtrl.text.trim(),
      'imageUrl': _imageCtrl.text.trim(),
      'specialty': _specialty,
      'year': _year,
      'meetLink': '',
    });
    _nameCtrl.clear();
    _imageCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المادة')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم المادة')),
                  const SizedBox(height: 8),
                  TextField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة (اختياري)')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _specialty,
                    decoration: const InputDecoration(labelText: 'التخصص', hintText: 'اختر التخصص'),
                    items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _specialty = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _year,
                    decoration: const InputDecoration(labelText: 'السنة', hintText: 'اختر السنة'),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (v) => setState(() => _year = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة المادة'),
                    onPressed: _addCourse,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final courses = snapshot.data!.docs;
              if (courses.isEmpty) return const Center(child: Text('لا توجد مواد بعد'));
              return ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final data = courses[index].data() as Map<String, dynamic>;
                  final id = courses[index].id;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text('${data['specialty']} - ${data['year']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCourseDialog(context, id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteCourse(id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المادة')));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _editCourseDialog(BuildContext context, String id, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name']);
    final imageCtrl = TextEditingController(text: data['imageUrl']);
    String specialty = data['specialty'] ?? (_specialties.isNotEmpty ? _specialties.first : '');
    String year = data['year'] ?? (_years.isNotEmpty ? _years.first : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل المادة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة')),
              DropdownButtonFormField<String>(
                value: _specialties.contains(specialty) ? specialty : null,
                decoration: const InputDecoration(labelText: 'التخصص'),
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => specialty = v!),
              ),
              DropdownButtonFormField<String>(
                value: _years.contains(year) ? year : null,
                decoration: const InputDecoration(labelText: 'السنة'),
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setDialogState(() => year = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('courses').doc(id).update({
                  'name': nameCtrl.text,
                  'imageUrl': imageCtrl.text,
                  'specialty': specialty,
                  'year': year,
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCourse(String id) async {
    final lectures = await FirebaseFirestore.instance.collection('courses').doc(id).collection('lectures').get();
    for (var doc in lectures.docs) {
      final quizzes = await doc.reference.collection('quizzes').get();
      for (var q in quizzes.docs) {
        await q.reference.delete();
      }
      await doc.reference.delete();
    }
    final messages = await FirebaseFirestore.instance.collection('courses').doc(id).collection('messages').get();
    for (var msg in messages.docs) {
      await msg.reference.delete();
    }
    await FirebaseFirestore.instance.collection('courses').doc(id).delete();
  }
}

// ==================== إدارة التخصصات والسنوات ====================
class _SpecialtiesAndYearsManagement extends StatefulWidget {
  const _SpecialtiesAndYearsManagement();

  @override
  State<_SpecialtiesAndYearsManagement> createState() => _SpecialtiesAndYearsManagementState();
}

class _SpecialtiesAndYearsManagementState extends State<_SpecialtiesAndYearsManagement> {
  final _specialtyCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  List<String> _specialties = [];
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final specs = await SpecialtiesService.getSpecialties();
    final yrs = await SpecialtiesService.getYears();
    setState(() {
      _specialties = specs;
      _years = yrs;
    });
  }

  Future<void> _addSpecialty() async {
    if (_specialtyCtrl.text.trim().isEmpty) return;
    setState(() => _specialties.add(_specialtyCtrl.text.trim()));
    await SpecialtiesService.saveSpecialties(_specialties);
    _specialtyCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة التخصص')));
  }

  Future<void> _editSpecialty(int index) async {
    final ctrl = TextEditingController(text: _specialties[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل التخصص'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'اسم التخصص')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _specialties[index] = result);
      await SpecialtiesService.saveSpecialties(_specialties);
    }
  }

  Future<void> _deleteSpecialty(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التخصص'),
        content: Text('هل أنت متأكد من حذف "${_specialties[index]}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _specialties.removeAt(index));
      await SpecialtiesService.saveSpecialties(_specialties);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف التخصص')));
    }
  }

  Future<void> _addYear() async {
    if (_yearCtrl.text.trim().isEmpty) return;
    setState(() => _years.add(_yearCtrl.text.trim()));
    await SpecialtiesService.saveYears(_years);
    _yearCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة السنة')));
  }

  Future<void> _editYear(int index) async {
    final ctrl = TextEditingController(text: _years[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل السنة'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'اسم السنة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _years[index] = result);
      await SpecialtiesService.saveYears(_years);
    }
  }

  Future<void> _deleteYear(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السنة'),
        content: Text('هل أنت متأكد من حذف "${_years[index]}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _years.removeAt(index));
      await SpecialtiesService.saveYears(_years);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف السنة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التخصصات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF3131))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _specialtyCtrl,
                        decoration: const InputDecoration(labelText: 'اسم التخصص الجديد'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      onPressed: _addSpecialty,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_specialties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('لا توجد تخصصات بعد. أضف أول تخصص.', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...List.generate(_specialties.length, (index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_specialties[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editSpecialty(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSpecialty(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('السنوات الدراسية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(labelText: 'اسم السنة الجديدة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                      onPressed: _addYear,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_years.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('لا توجد سنوات بعد. أضف أول سنة.', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...List.generate(_years.length, (index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(_years[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editYear(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteYear(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== إدارة الحسابات ====================
class _AccountsManagement extends StatelessWidget {
  const _AccountsManagement();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        if (users.isEmpty) return const Center(child: Text('لا توجد حسابات'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            final uid = users[index].id;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: data['disabled'] == true ? Colors.red : Colors.green,
                  child: Icon(data['disabled'] == true ? Icons.block : Icons.check, color: Colors.white),
                ),
                title: Text(data['username'] ?? 'بدون اسم'),
                subtitle: Text('${data['role']} - ${data['email']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    switch (action) {
                      case 'toggle':
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'disabled': !(data['disabled'] ?? false),
                        });
                        break;
                      case 'changeRole':
                        final roles = ['student', 'teacher', 'admin'];
                        final currentIndex = roles.indexOf(data['role'] ?? 'student');
                        final newRole = roles[(currentIndex + 1) % roles.length];
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
                        break;
                      case 'delete':
                        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                        break;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التنفيذ')));
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(data['disabled'] == true ? 'تفعيل الحساب' : 'تعطيل الحساب'),
                    ),
                    PopupMenuItem(
                      value: 'changeRole',
                      child: Text('تغيير الدور (حالي: ${data['role']})'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('حذف الحساب', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== نتائج الكويزات ====================
class _QuizResultsManagement extends StatelessWidget {
  const _QuizResultsManagement();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizResults').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!.docs;
        if (results.isEmpty) return const Center(child: Text('لا توجد نتائج بعد'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index].data() as Map<String, dynamic>;
            return FutureBuilder(
              future: _getStudentName(data['studentId'] ?? ''),
              builder: (context, nameSnapshot) {
                final studentName = nameSnapshot.data ?? 'طالب غير معروف';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(studentName),
                    subtitle: Text('النتيجة: ${data['score']} / ${data['totalQuestions']}'),
                    trailing: Text(_formatTimestamp(data['timestamp'])),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _getStudentName(String uid) async {
    if (uid.isEmpty) return 'غير معروف';
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.get('username') ?? doc.get('email') ?? 'طالب';
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    final date = (ts as Timestamp).toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ==================== إدارة روابط التواصل الاجتماعي ====================
class _SocialLinksManagement extends StatefulWidget {
  const _SocialLinksManagement();

  @override
  State<_SocialLinksManagement> createState() => _SocialLinksManagementState();
}

class _SocialLinksManagementState extends State<_SocialLinksManagement> {
  final _urlCtrl = TextEditingController();
  String _selectedPlatform = 'Instagram';
  final List<String> _platforms = [
    'Instagram', 'Facebook', 'Twitter/X', 'YouTube', 'TikTok', 'Telegram', 'WhatsApp', 'LinkedIn', 'Website'
  ];

  final Map<String, IconData> _icons = {
    'Instagram': Icons.camera_alt,
    'Facebook': Icons.facebook,
    'Twitter/X': Icons.alternate_email,
    'YouTube': Icons.play_circle,
    'TikTok': Icons.music_note,
    'Telegram': Icons.send,
    'WhatsApp': Icons.call,
    'LinkedIn': Icons.business,
    'Website': Icons.language,
  };

  Future<void> _addLink() async {
    if (_urlCtrl.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('socialLinks').add({
      'platform': _selectedPlatform,
      'url': _urlCtrl.text.trim(),
      'order': DateTime.now().millisecondsSinceEpoch,
    });
    _urlCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الرابط')));
  }

  Future<void> _editLink(String docId, String currentUrl, String currentPlatform) async {
    _urlCtrl.text = currentUrl;
    _selectedPlatform = currentPlatform;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الرابط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              decoration: const InputDecoration(labelText: 'المنصة'),
              items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => _selectedPlatform = v!,
            ),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'الرابط')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {'platform': _selectedPlatform, 'url': _urlCtrl.text}),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != null) {
      await FirebaseFirestore.instance.collection('socialLinks').doc(docId).update({
        'platform': result['platform'],
        'url': result['url'],
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل')));
    }
  }

  Future<void> _deleteLink(String docId) async {
    await FirebaseFirestore.instance.collection('socialLinks').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPlatform,
                      decoration: const InputDecoration(labelText: 'المنصة'),
                      items: _platforms.map((p) => DropdownMenuItem(value: p, child: Row(
                        children: [
                          Icon(_icons[p], size: 18),
                          const SizedBox(width: 8),
                          Text(p),
                        ],
                      ))).toList(),
                      onChanged: (v) => setState(() => _selectedPlatform = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'الرابط')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                    onPressed: _addLink,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('socialLinks').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final links = snapshot.data!.docs;
              if (links.isEmpty) return const Center(child: Text('لا توجد روابط'));
              return ListView.builder(
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final data = links[index].data() as Map<String, dynamic>;
                  final platform = data['platform'] ?? '';
                  final icon = _icons[platform] ?? Icons.link;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(icon, color: const Color(0xFFFF8C00)),
                      title: Text(platform),
                      subtitle: Text(data['url'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editLink(links[index].id, data['url'] ?? '', platform),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLink(links[index].id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}