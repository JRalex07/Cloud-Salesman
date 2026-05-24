import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tracking.dart';
import '../providers/global_providers.dart';

abstract class TrackingRepository {
  Future<void> updateLiveLocation(String salesmanId, double lat, double lng, double accuracy, double speed, double battery);
  Future<void> logHistoricalPathPoint(String salesmanId, TrackingPoints point);
  Stream<List<TrackingPoints>> getHistoricalPathStream(String salesmanId);
}

class FirebaseTrackingRepository implements TrackingRepository {
  final FirebaseFirestore _firestore;

  FirebaseTrackingRepository(this._firestore);

  @override
  Future<void> updateLiveLocation(
    String salesmanId,
    double lat,
    double lng,
    double accuracy,
    double speed,
    double battery,
  ) async {
    await _firestore.collection('tracking_live').doc(salesmanId).set({
      'salesmanId': salesmanId,
      'latitude': lat,
      'longitude': lng,
      'accuracy': accuracy,
      'speed': speed,
      'battery': battery,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> logHistoricalPathPoint(String salesmanId, TrackingPoints point) async {
    await _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('tracking')
        .add(point.toJson());
  }

  @override
  Stream<List<TrackingPoints>> getHistoricalPathStream(String salesmanId) {
    return _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('tracking')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TrackingPoints.fromJson(doc.data()))
            .toList());
  }
}

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return FirebaseTrackingRepository(ref.watch(firestoreProvider));
});

