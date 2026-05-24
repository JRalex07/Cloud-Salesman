import 'dart:math' show cos, sqrt, asin, pi;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visit.dart';
import '../providers/global_providers.dart';

abstract class VisitRepository {
  Future<void> checkIn(String salesmanId, Visit visit);
  Future<void> checkOut(String salesmanId, String visitId, double lat, double lng, String notes);
  Stream<List<Visit>> getVisitsHistoryStream(String salesmanId);
  Future<Visit?> getActiveVisit(String salesmanId);
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);
}

class FirebaseVisitRepository implements VisitRepository {
  final FirebaseFirestore _firestore;

  FirebaseVisitRepository(this._firestore);

  @override
  Future<void> checkIn(String salesmanId, Visit visit) async {
    await _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('visits')
        .doc(visit.visitId)
        .set(visit.toJson());
  }

  @override
  Future<void> checkOut(
    String salesmanId,
    String visitId,
    double lat,
    double lng,
    String notes,
  ) async {
    final docRef = _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('visits')
        .doc(visitId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) return;

    final data = docSnap.data()!;
    final double inLat = (data['checkInLatitude'] as num?)?.toDouble() ?? 0.0;
    final double inLng = (data['checkInLongitude'] as num?)?.toDouble() ?? 0.0;

    // Calculate dynamic distance walked or distance from original checkout log
    final double distanceVal = calculateDistance(inLat, inLng, lat, lng);

    await docRef.update({
      'checkOutTime': Timestamp.fromDate(DateTime.now()),
      'checkOutLatitude': lat,
      'checkOutLongitude': lng,
      'distanceFromShop': distanceVal,
      'notes': notes,
      'status': 'Completed',
    });
  }

  @override
  Stream<List<Visit>> getVisitsHistoryStream(String salesmanId) {
    return _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('visits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Visit.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<Visit?> getActiveVisit(String salesmanId) async {
    final snap = await _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('visits')
        .where('status', isEqualTo: 'CheckedIn')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return Visit.fromJson(snap.docs.first.data());
  }

  @override
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const p = pi / 180;
    final c = cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Returns distance in meters
  }
}

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return FirebaseVisitRepository(ref.watch(firestoreProvider));
});

