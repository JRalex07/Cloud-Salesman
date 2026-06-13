import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/models/salesman.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

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

  FirebaseAuthRepository(this._auth, this._firestore, this._fcm);

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
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
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
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

    // 2. Try searching by email of current authenticated user to locate pre-created records
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
  );
});
