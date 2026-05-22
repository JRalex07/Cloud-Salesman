import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:uuid/uuid.dart';

import '../../../core/services/location_service.dart';

import '../../shops/models/shop_visit_model.dart';

class VisitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final locationService = LocationService();

  // =========================
  // CHECK IN
  // =========================

  Future<void> checkIn({
    required String shopId,
    required String shopName,
  }) async {
    final uid = _auth.currentUser!.uid;

    // =========================
    // PREVENT MULTIPLE ACTIVE VISITS
    // =========================

    final active = await _firestore
        .collection("shop_visits")
        .where("salesmanId", isEqualTo: uid)
        .where("active", isEqualTo: true)
        .limit(1)
        .get();

    if (active.docs.isNotEmpty) {
      throw Exception("Complete active visit first");
    }

    // =========================
    // GET LOCATION
    // =========================

    final location = await locationService.getCurrentLocation();

    // =========================
    // CREATE VISIT
    // =========================

    final visit = ShopVisitModel(
      id: const Uuid().v4(),

      salesmanId: uid,

      shopId: shopId,

      shopName: shopName,

      checkInTime: DateTime.now(),

      checkOutTime: null,

      checkInLatitude: location.latitude,

      checkInLongitude: location.longitude,

      checkOutLatitude: null,

      checkOutLongitude: null,

      active: true,
    );

    // =========================
    // SAVE
    // =========================

    await _firestore.collection("shop_visits").doc(visit.id).set(visit.toMap());
  }

  // =========================
  // CHECK OUT
  // =========================

  Future<void> checkOut(String visitId) async {
    final location = await locationService.getCurrentLocation();

    await _firestore.collection("shop_visits").doc(visitId).update({
      "checkOutTime": DateTime.now().toIso8601String(),

      "checkOutLatitude": location.latitude,

      "checkOutLongitude": location.longitude,

      "active": false,
    });
  }

  // =========================
  // ACTIVE VISIT
  // =========================

  Stream<ShopVisitModel?> activeVisit() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection("shop_visits")
        .where("salesmanId", isEqualTo: uid)
        .where("active", isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;

          return ShopVisitModel.fromMap(doc.data(), doc.id);
        });
  }

  // =========================
  // VISIT HISTORY
  // =========================

  Stream<List<ShopVisitModel>> getVisits() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection("shop_visits")
        .where("salesmanId", isEqualTo: uid)
        .orderBy("checkInTime", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((e) {
            return ShopVisitModel.fromMap(e.data(), e.id);
          }).toList();
        });
  }
}
