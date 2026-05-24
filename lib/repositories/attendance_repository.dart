import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import '../providers/global_providers.dart';

abstract class AttendanceRepository {
  Future<void> startDuty(String salesmanId, Attendance attendance);
  Future<void> endDuty(String salesmanId, String attendanceId,
      DateTime endDutyTime, double endLat, double endLng);
  Stream<List<Attendance>> getAttendanceHistoryStream(String salesmanId);
  Future<Attendance?> getTodayAttendance(String salesmanId, String date);
}

class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  FirebaseAttendanceRepository(this._firestore);

  @override
  Future<void> startDuty(String salesmanId, Attendance attendance) async {
    final batch = _firestore.batch();

    // Set in subcollection
    final attendanceRef = _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('attendance')
        .doc(attendance.attendanceId);
    batch.set(attendanceRef, attendance.toJson());

    // Also set in global root collection 'attendance', under date and salesman subcollection
    final rootAttendanceRef = _firestore
        .collection('attendance')
        .doc(attendance.date)
        .collection(salesmanId)
        .doc(attendance.attendanceId);
    final rootAttendanceData = attendance.toJson();
    rootAttendanceData['salesmanId'] = salesmanId;
    batch.set(rootAttendanceRef, rootAttendanceData);

    // Update real-time status in tracking_live
    final liveTrackingRef =
        _firestore.collection('tracking_live').doc(salesmanId);
    batch.set(
        liveTrackingRef,
        {
          'salesmanId': salesmanId,
          'isOnDuty': true,
          'isOnline': true,
          'latitude': attendance.startLatitude,
          'longitude': attendance.startLongitude,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<void> endDuty(
    String salesmanId,
    String attendanceId,
    DateTime endDutyTime,
    double endLat,
    double endLng,
  ) async {
    final docRef = _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('attendance')
        .doc(attendanceId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final startField = doc.data()?['startDutyTime'] as Timestamp?;
      final date = doc.data()?['date'] as String? ?? '';
      int calcMinutes = 0;
      if (startField != null) {
        final start = startField.toDate();
        calcMinutes = endDutyTime.difference(start).inMinutes;
      }

      final updateData = {
        'endDutyTime': Timestamp.fromDate(endDutyTime),
        'duration': calcMinutes,
        'endLatitude': endLat,
        'endLongitude': endLng,
        'status': 'Present',
      };

      transaction.update(docRef, updateData);

      // Also update in global 'attendance' collection, under date and salesman subcollection
      if (date.isNotEmpty) {
        final rootAttendanceRef = _firestore
            .collection('attendance')
            .doc(date)
            .collection(salesmanId)
            .doc(attendanceId);
        final rootUpdateData = {
          ...updateData,
          'salesmanId': salesmanId,
        };
        transaction.set(
            rootAttendanceRef, rootUpdateData, SetOptions(merge: true));
      }

      // Update live status to offline/off-duty
      transaction.set(
          _firestore.collection('tracking_live').doc(salesmanId),
          {
            'isOnDuty': false,
            'isOnline': false,
            'latitude': endLat,
            'longitude': endLng,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }

  @override
  Stream<List<Attendance>> getAttendanceHistoryStream(String salesmanId) {
    return _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Attendance.fromJson(doc.data())).toList());
  }

  @override
  Future<Attendance?> getTodayAttendance(String salesmanId, String date) async {
    final snap = await _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('attendance')
        .where('date', isEqualTo: date)
        .get();

    if (snap.docs.isEmpty) return null;

    final list =
        snap.docs.map((doc) => Attendance.fromJson(doc.data())).toList();

    // Prioritize an active session (where endDutyTime is null)
    final active = list.where((a) => a.endDutyTime == null).toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => (b.startDutyTime ?? DateTime(0))
          .compareTo(a.startDutyTime ?? DateTime(0)));
      return active.first;
    }

    // Otherwise, return the most recently completed session
    list.sort((a, b) => (b.startDutyTime ?? DateTime(0))
        .compareTo(a.startDutyTime ?? DateTime(0)));
    return list.first;
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return FirebaseAttendanceRepository(ref.watch(firestoreProvider));
});
