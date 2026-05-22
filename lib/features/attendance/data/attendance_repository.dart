import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:uuid/uuid.dart';

import '../../../shared/models/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // START DUTY
  // =========================

  Future<void> startDuty() async {
    final uid = _auth.currentUser!.uid;

    // prevent multiple duty sessions

    final active = await _firestore
        .collection("attendance")
        .where("salesmanId", isEqualTo: uid)
        .where("active", isEqualTo: true)
        .limit(1)
        .get();

    if (active.docs.isNotEmpty) {
      throw Exception("Duty already active");
    }

    final attendance = AttendanceModel(
      id: const Uuid().v4(),

      salesmanId: uid,

      startDuty: DateTime.now(),

      endDuty: null,

      active: true,
    );

    await _firestore
        .collection("attendance")
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  // =========================
  // END DUTY
  // =========================

  Future<void> endDuty(String attendanceId) async {
    await _firestore.collection("attendance").doc(attendanceId).update({
      "endDuty": DateTime.now().toIso8601String(),

      "active": false,
    });
  }

  // =========================
  // ACTIVE DUTY
  // =========================

  Stream<AttendanceModel?> activeDuty() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection("attendance")
        .where("salesmanId", isEqualTo: uid)
        .where("active", isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;

          return AttendanceModel.fromMap(doc.data(), doc.id);
        });
  }

  // =========================
  // DUTY HISTORY
  // =========================

  Stream<List<AttendanceModel>> history() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection("attendance")
        .where("salesmanId", isEqualTo: uid)
        .orderBy("startDuty", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AttendanceModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
