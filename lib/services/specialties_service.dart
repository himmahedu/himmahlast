import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialtiesService {
  // لا توجد قوائم افتراضية - المدير ينشئ كل شيء

  static Future<List<String>> getSpecialties() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('specialties')
        .get();
    if (doc.exists && doc.get('list') != null) {
      final list = List<String>.from(doc.get('list'));
      return list;
    }
    // إرجاع قائمة فارغة إذا لم يضف المدير شيئاً بعد
    return [];
  }

  static Future<void> saveSpecialties(List<String> specialties) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('specialties')
        .set({'list': specialties});
  }

  static Future<List<String>> getYears() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('years')
        .get();
    if (doc.exists && doc.get('list') != null) {
      final list = List<String>.from(doc.get('list'));
      return list;
    }
    // إرجاع قائمة فارغة إذا لم يضف المدير شيئاً بعد
    return [];
  }

  static Future<void> saveYears(List<String> years) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('years')
        .set({'list': years});
  }
}