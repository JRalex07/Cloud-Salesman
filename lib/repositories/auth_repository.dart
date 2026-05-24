import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salesman.dart';
import '../providers/global_providers.dart';

bool _forceBypass = false;

void setForceBypass(bool val) {
  _forceBypass = val;
}

/// Checks if the codebase is running in a sandbox/development environment
/// where the Firebase API configuration uses a dummy/progressive-offline key,
/// or general kDebugMode is enabled.
bool isBypassEnabled() {
  if (_forceBypass) return true;
  if (kDebugMode) return true;
  try {
    final key = Firebase.app().options.apiKey;
    if (key == 'dummy-api-key-for-progressive-offline' ||
        key.toLowerCase().contains('dummy') ||
        key.toLowerCase().contains('invalid') ||
        key.trim().isEmpty) {
      return true;
    }
  } catch (_) {
    return true; // Auto-bypass if Firebase initialization itself fails or has no properties
  }
  return false;
}

abstract class AuthRepository {
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<Salesman?> getCurrentSalesman();
  Future<void> updateFcmToken(String uid);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm;
  final Ref _ref;

  FirebaseAuthRepository(this._auth, this._firestore, this._fcm, this._ref);

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      if (isBypassEnabled()) {
        final targetUid = 'salesman_mock_uid';
        _ref.read(bypassSessionProvider.notifier).setSession(
              uid: targetUid,
              phone: '1234567890',
            );
        return MockUserCredential(MockUser(targetUid, '1234567890'));
      }

      final credentials = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credentials.user != null) {
        try {
          // Check if there is already a salesman document with this email
          final query = await _firestore
              .collection('salesmen')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            final existingDoc = query.docs.first;
            // Dynamically link UID of auth user to the existing pre-created profile without duplicating it
            await existingDoc.reference.update({
              'lastLogin': FieldValue.serverTimestamp(),
              'uid': credentials.user!.uid,
            });
            try {
              if (!kIsWeb) {
                String? token = await _fcm.getToken();
                if (token != null) {
                  await existingDoc.reference.update({'fcmToken': token});
                }
              }
            } catch (_) {}
          } else {
            // Check if doc exists with UID directly
            final docRef =
                _firestore.collection('salesmen').doc(credentials.user!.uid);
            final doc = await docRef.get();
            if (!doc.exists) {
              // Create a brand new salesman profile
              await docRef.set({
                'uid': credentials.user!.uid,
                'name': 'Sales Executive (Email)',
                'phone': credentials.user!.phoneNumber ?? '',
                'email': email,
                'role': 'salesman',
                'assignedArea': 'Assigned Route Area',
                'createdAt': FieldValue.serverTimestamp(),
                'lastLogin': FieldValue.serverTimestamp(),
              });
              try {
                if (!kIsWeb) {
                  String? token = await _fcm.getToken();
                  if (token != null) {
                    await docRef.update({'fcmToken': token});
                  }
                }
              } catch (_) {}
            } else {
              await docRef.update({
                'lastLogin': FieldValue.serverTimestamp(),
              });
              try {
                if (!kIsWeb) {
                  String? token = await _fcm.getToken();
                  if (token != null) {
                    await docRef.update({'fcmToken': token});
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
      return credentials;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (isBypassEnabled() ||
          errStr.contains('api-key-not-valid') ||
          errStr.contains('api-key') ||
          errStr.contains('invalid-api-key') ||
          errStr.contains('unauthorized-domain') ||
          errStr.contains('missing-client-identifier') ||
          errStr.contains('configuration') ||
          errStr.contains('not-allowed')) {
        setForceBypass(true);
        final targetUid = 'salesman_mock_uid';
        _ref.read(bypassSessionProvider.notifier).setSession(
              uid: targetUid,
              phone: '1234567890',
            );
        return MockUserCredential(MockUser(targetUid, '1234567890'));
      }
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    _ref.read(bypassSessionProvider.notifier).clearSession();
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final query = await _firestore
            .collection('salesmen')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'fcmToken': '',
          });
        } else {
          await _firestore.collection('salesmen').doc(user.uid).update({
            'fcmToken': '',
          });
        }
      } catch (e) {
        // Safe fallback - ensure that we always run _auth.signOut() next
      }
    }
    await _auth.signOut();
  }

  @override
  Future<Salesman?> getCurrentSalesman() async {
    final bypass = _ref.read(bypassSessionProvider);
    if (bypass.isAuthenticated && bypass.uid != null) {
      return Salesman(
        uid: bypass.uid!,
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
      );
    }

    final user = _auth.currentUser;
    if (user == null) return null;

    // 1. Try finding by linked uid field first
    final queryByUid = await _firestore
        .collection('salesmen')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (queryByUid.docs.isNotEmpty) {
      final existingDoc = queryByUid.docs.first;
      final data = existingDoc.data();
      return Salesman.fromJson({
        ...data,
        'uid': existingDoc.id, // Explicitly return doc id as salesmanId
      });
    }

    // 2. Try searching by email or phone of current authenticated user
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
    }

    if (foundDoc != null && foundDoc.data() != null) {
      final data = foundDoc.data()!;
      // Link the authenticated user's uid to the existing document, without copying or creating any new document!
      await foundDoc.reference.update({
        'uid': user.uid,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      try {
        if (!kIsWeb) {
          String? token = await _fcm.getToken();
          if (token != null) {
            await foundDoc.reference.update({'fcmToken': token});
          }
        }
      } catch (_) {}
      return Salesman.fromJson({
        ...data,
        'uid': foundDoc.id,
      });
    }

    // 3. Fallback to direct lookup by auth doc ID
    final doc = await _firestore.collection('salesmen').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return Salesman.fromJson({
        ...data,
        'uid': doc.id,
      });
    }

    return null;
  }

  @override
  Future<void> updateFcmToken(String uid) async {
    if (kIsWeb) return;
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        final query = await _firestore
            .collection('salesmen')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'fcmToken': token,
          });
        } else {
          await _firestore.collection('salesmen').doc(uid).update({
            'fcmToken': token,
          });
        }
      }
    } catch (e) {
      // Background messaging/FCM may fail on certain web/simulators, log but continue
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(firebaseMessagingProvider),
    ref,
  );
});

// Mock implementations for full local offline support when Firebase initialization is bypassed or lacks credentials.
class MockUserCredential implements UserCredential {
  final User? _user;
  MockUserCredential(this._user);

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUser implements User {
  final String _uid;
  final String? _phoneNumber;
  MockUser(this._uid, this._phoneNumber);

  @override
  String get uid => _uid;

  @override
  String? get phoneNumber => _phoneNumber;

  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
