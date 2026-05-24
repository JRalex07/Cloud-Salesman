import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salesman.dart';

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

// Bypass Session state class
class BypassSession {
  final bool isAuthenticated;
  final String? uid;
  final String? phone;

  BypassSession({
    this.isAuthenticated = false,
    this.uid,
    this.phone,
  });
}

class BypassSessionNotifier extends StateNotifier<BypassSession> {
  BypassSessionNotifier() : super(BypassSession());

  void setSession({required String uid, required String phone}) {
    state = BypassSession(isAuthenticated: true, uid: uid, phone: phone);
  }

  void clearSession() {
    state = BypassSession();
  }
}

final bypassSessionProvider =
    StateNotifierProvider<BypassSessionNotifier, BypassSession>((ref) {
  return BypassSessionNotifier();
});

// Reactive active UID provider
final activeUidProvider = Provider<String?>((ref) {
  final bypass = ref.watch(bypassSessionProvider);
  if (bypass.isAuthenticated) {
    return bypass.uid;
  }
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
      // Return a simulated local salesman profile if from bypass session
      final bypass = _ref.read(bypassSessionProvider);
      if (bypass.isAuthenticated && bypass.uid == uid) {
        state = AsyncValue.data(Salesman(
          uid: uid,
          name: 'Sales Executive (Demo Bypass)',
          phone: bypass.phone ?? '1234567890',
          email: 'salesman@cloudpower.com',
          photoUrl: '',
          role: 'salesman',
          assignedRouteId: 'demo-route-id',
          assignedArea: 'Assigned Route Area',
          isActive: true,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          fcmToken: '',
        ));
        return;
      }

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

      // 2. Try searching by email or phone of current authenticated user
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

        if (foundDoc == null &&
            user.phoneNumber != null &&
            user.phoneNumber!.isNotEmpty) {
          final phoneVariants = [user.phoneNumber!];
          final cleanDigits = user.phoneNumber!.replaceAll(RegExp(r'\D'), '');
          if (cleanDigits.length >= 10) {
            final last10 = cleanDigits.substring(cleanDigits.length - 10);
            if (!phoneVariants.contains(last10)) {
              phoneVariants.add(last10);
            }
            final d0 = '0$last10';
            if (!phoneVariants.contains(d0)) {
              phoneVariants.add(d0);
            }
            final dp91 = '+91$last10';
            if (!phoneVariants.contains(dp91)) {
              phoneVariants.add(dp91);
            }
            final dp91s = '+91 $last10';
            if (!phoneVariants.contains(dp91s)) {
              phoneVariants.add(dp91s);
            }
            final d91 = '91$last10';
            if (!phoneVariants.contains(d91)) {
              phoneVariants.add(d91);
            }
          }
          final query = await _firestore
              .collection('salesmen')
              .where('phone', whereIn: phoneVariants)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            foundDoc = query.docs.first;
          }

          // Fallback robust matching based on stripping all non-digits and checking the last 10 digits
          if (foundDoc == null && cleanDigits.length >= 10) {
            final loginLast10 = cleanDigits.substring(cleanDigits.length - 10);
            final allDocsQuery = await _firestore.collection('salesmen').get();
            for (final doc in allDocsQuery.docs) {
              final storedPhone = doc.data()['phone']?.toString();
              if (storedPhone != null && storedPhone.isNotEmpty) {
                final storedClean = storedPhone.replaceAll(RegExp(r'\D'), '');
                if (storedClean.length >= 10) {
                  final storedLast10 =
                      storedClean.substring(storedClean.length - 10);
                  if (storedLast10 == loginLast10) {
                    foundDoc = doc;
                    break;
                  }
                }
              }
            }
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
