import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared/models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // CURRENT USER
  // =========================

  User? get currentUser => _auth.currentUser;

  // =========================
  // LOGIN
  // =========================

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user!.uid;

    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw Exception("User data not found");
    }

    final user = UserModel.fromMap(doc.data()!);

    // =========================
    // SALESMAN CHECK
    // =========================

    if (user.role != "salesman") {
      await logout();

      throw Exception("Access denied");
    }

    // =========================
    // ACTIVE CHECK
    // =========================

    if (!user.isActive) {
      await logout();

      throw Exception("Account disabled");
    }

    return user;
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========================
  // AUTH STATE
  // =========================

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
