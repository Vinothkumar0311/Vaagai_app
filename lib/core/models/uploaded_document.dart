import 'package:cloud_firestore/cloud_firestore.dart';

class UploadedDocument {
  final String id;
  final String title;
  final String objective;
  final String trainers;
  final String? imageUrl;
  final String? pdfUrl;
  final String? imageName;
  final String? pdfName;

  UploadedDocument({
    required this.id,
    required this.title,
    required this.objective,
    required this.trainers,
    this.imageUrl,
    this.pdfUrl,
    this.imageName,
    this.pdfName,
  });

  factory UploadedDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UploadedDocument(
      id: doc.id,
      title: data['title'] ?? '',
      objective: data['objective'] ?? '',
      trainers: data['trainers'] ?? '',
      imageUrl: data['imageUrl'],
      pdfUrl: data['pdfUrl'],
      imageName: data['imageName'],
      pdfName: data['pdfName'],
    );
  }
}
