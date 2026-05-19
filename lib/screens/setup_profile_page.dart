import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:himmah_app/services/specialties_service.dart';
import 'package:himmah_app/screens/student_home_page.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  String? _selectedSpecialty;
  String? _selectedYear;
  List<String> _specialties = [];
  List<String> _years = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final specs = await SpecialtiesService.getSpecialties();
    final yrs = await SpecialtiesService.getYears();
    setState(() {
      _specialties = specs;
      _years = yrs;
      if (specs.isNotEmpty) _selectedSpecialty = specs.first;
      if (yrs.isNotEmpty) _selectedYear = yrs.first;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_selectedSpecialty == null || _selectedYear == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'specialty': _selectedSpecialty,
        'year': _selectedYear,
      });
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => StudentHomePage(specialty: _selectedSpecialty!, year: _selectedYear!)),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('اختر تخصصك وسنتك الدراسية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              decoration: const InputDecoration(labelText: 'التخصص'),
              items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSpecialty = v),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'السنة الدراسية'),
              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _save,
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );
  }
}
