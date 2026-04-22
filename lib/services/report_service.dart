import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static Future<List<ReportModel>> getSavedReports() async {
    final String? userId = _userId;
    if (userId == null) return <ReportModel>[];

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reports')
        .orderBy('fecha', descending: true)
        .get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => ReportModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<void> saveReport(String nombre, String contenido) async {
    final String? userId = _userId;
    if (userId == null) return;

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    await docRef.set(<String, dynamic>{
      'nombre': nombre,
      'contenido': contenido,
      'fecha': Timestamp.fromDate(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteReport(String id) async {
    final String? userId = _userId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reports')
        .doc(id)
        .delete();
  }
}