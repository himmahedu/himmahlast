import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String name;
  final String imageUrl;
  final String meetLink;
  final String specialty;
  final String year;

  Course({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.meetLink = '',
    required this.specialty,
    required this.year,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      meetLink: data['meetLink'] ?? '',
      specialty: data['specialty'] ?? '',
      year: data['year'] ?? '',
    );
  }
}