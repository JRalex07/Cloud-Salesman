import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/models/salesman.dart';

// Firebase core object providers
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider =
    Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final firebaseMessagingProvider =
    Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

// Authenticated user stream
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Reactive active UID provider
final activeUidProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(authStateChangesProvider);
  return userAsync.valueOrNull?.uid;
});

// Salesman profile state provider
class SalesmanProfileNotifier extends StateNotifier<AsyncValue<Salesman?>> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref;

  SalesmanProfileNotifier(this._firestore, this._auth, this._ref)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _ref.listen<String?>(activeUidProvider, (previous, nextUid) {
      if (nextUid != null) {
        _fetchSalesmanProfile(nextUid);
      } else {
        state = const AsyncValue.data(null);
      }
    }, fireImmediately: true);
  }

  Future<void> _fetchSalesmanProfile(String uid) async {
    try {
      // 1. Try finding by linked uid field first
      final queryByUid = await _firestore
          .collection('salesmen')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (queryByUid.docs.isNotEmpty) {
        final existingDoc = queryByUid.docs.first;
        final data = existingDoc.data();
        state = AsyncValue.data(Salesman.fromJson({
          ...data,
          'uid': existingDoc.id, // Explicitly return doc id as salesmanId
        }));
        return;
      }

      // 2. Try searching by email of current authenticated user to find matching salesman record
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>>? foundDoc;
        if (user.email != null && user.email!.isNotEmpty) {
          final query = await _firestore
              .collection('salesmen')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            foundDoc = query.docs.first;
          }
        }

        if (foundDoc != null && foundDoc.data() != null) {
          final data = foundDoc.data()!;
          // Link uid to the existing document, do NOT copy or write to salesmen/{uid}!
          await foundDoc.reference.update({
            'uid': uid,
            'lastLogin': FieldValue.serverTimestamp(),
          });
          state = AsyncValue.data(Salesman.fromJson({
            ...data,
            'uid': foundDoc.id,
          }));
          return;
        }
      }

      // 3. Fallback to direct lookup by auth doc ID
      final doc = await _firestore.collection('salesmen').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        state = AsyncValue.data(Salesman.fromJson({
          ...data,
          'uid': doc.id,
        }));
        return;
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    final activeUid = _ref.read(activeUidProvider);
    if (activeUid != null) {
      state = const AsyncValue.loading();
      await _fetchSalesmanProfile(activeUid);
    }
  }

  void setProfile(Salesman? salesman) {
    state = AsyncValue.data(salesman);
  }
}

final salesmanProfileProvider =
    StateNotifierProvider<SalesmanProfileNotifier, AsyncValue<Salesman?>>(
        (ref) {
  return SalesmanProfileNotifier(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref,
  );
});

// Stream of live salesman status in tracking_live
final trackingLiveStreamProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, salesmanId) {
  return ref
      .watch(firestoreProvider)
      .collection('tracking_live')
      .doc(salesmanId)
      .snapshots()
      .map((doc) => doc.data());
});
