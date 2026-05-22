import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return firestore.doc(path);
  }
}
