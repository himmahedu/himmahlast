import 'package:cloud_firestore/cloud_firestore.dart';

class Lecture {
  final String id;
  final String title;
  final String videoUrl;
  final String pdfUrl;

  Lecture({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.pdfUrl,
  });

  factory Lecture.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lecture(
      id: doc.id,
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
    );
  }
}