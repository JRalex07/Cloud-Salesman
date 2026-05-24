import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/salesman.dart';
import '../providers/global_providers.dart';
import 'recaptcha_helper.dart';

/// Robust phone number normalization to the standard E.164 format.
/// Keeps '+' followed by digits, removes other characters, and ensures
/// proper region codes (defaults to India +91 if length is 10 digits).
String normalizePhoneToE164(String phone) {
  var clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (clean.startsWith('+')) {
    return clean;
  }
  // Remove leading single zero if present (common prefix in some countries)
  if (clean.startsWith('0')) {
    clean = clean.substring(1);
  }
  if (clean.length == 10) {
    return '+91$clean';
  } else if (clean.length == 12 && clean.startsWith('91')) {
    return '+$clean';
  } else {
    return '+$clean';
  }
}

/// Checks if the codebase is running in a sandbox/development environment
/// where the Firebase API configuration uses a dummy/progressive-offline key,
/// or general kDebugMode is enabled.
bool isBypassEnabled() {
  if (kDebugMode) return true;
  try {
    final key = Firebase.app().options.apiKey;
    if (key == 'dummy-api-key-for-progressive-offline' ||
        key.contains('dummy')) {
      return true;
    }
  } catch (_) {}
  return false;
}

abstract class AuthRepository {
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<Salesman?> getCurrentSalesman();
  Future<void> updateFcmToken(String uid);
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onFailed,
  });
  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  });
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm;
  final Ref _ref;

  // Cache confirmation results on web to match verificationId
  static final Map<String, ConfirmationResult> _webConfirmationResults = {};

  FirebaseAuthRepository(this._auth, this._firestore, this._fcm, this._ref);

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

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onFailed,
  }) async {
    try {
      final normalizedPhone = normalizePhoneToE164(phoneNumber);

      if (isBypassEnabled()) {
        final bypassId = 'mock-verification-id-bypass:$normalizedPhone';
        onCodeSent(bypassId, null);
        return;
      }

      if (kIsWeb) {
        // Build & inject reCAPTCHA div if it doesn't already exist on web
        setupRecaptchaContainer();

        // Create the official web-specific RecaptchaVerifier
        final recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.compact,
        );

        // Initiate phone verification on Web via signInWithPhoneNumber
        final ConfirmationResult confirmationResult =
            await _auth.signInWithPhoneNumber(
          normalizedPhone,
          recaptchaVerifier,
        );

        // Map and store the ConfirmationResult object so it can be verified in signInWithPhoneCredential
        final verificationId = confirmationResult.verificationId;
        _webConfirmationResults[verificationId] = confirmationResult;

        // Callback with verification ID so the UI can proceed and prompt for SMS Code
        onCodeSent(verificationId, null);
      } else {
        // Native platform phone number verification
        await _auth.verifyPhoneNumber(
          phoneNumber: normalizedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // On some Android devices, auto-retrieval may complete instantly
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            onFailed(e.message ?? 'Phone verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            onCodeSent(verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      onFailed(e.toString());
    }
  }

  // Helper function to process the user record after a successful phone sign-in
  Future<void> _postPhoneSignInSetup(UserCredential credentials) async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? existingDoc;

      // Prioritize checking for existing records based on a standardized phone number format (E.164)
      if (credentials.user!.phoneNumber != null &&
          credentials.user!.phoneNumber!.isNotEmpty) {
        final rawPhone = credentials.user!.phoneNumber!;

        // E.164 normalization keeps '+' followed by digits (e.g., +919876543210)
        var normalizedPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
        if (!normalizedPhone.startsWith('+')) {
          normalizedPhone = '+$normalizedPhone';
        }

        final phoneVariants = <String>[normalizedPhone];
        final cleanDigits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
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
          existingDoc = query.docs.first;
        }

        // Fallback robust matching based on stripping all non-digits and checking the last 10 digits
        if (existingDoc == null && cleanDigits.length >= 10) {
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
                  existingDoc = doc;
                  break;
                }
              }
            }
          }
        }
      }

      // Try searching by email if phone didn't find any match
      if (existingDoc == null &&
          credentials.user!.email != null &&
          credentials.user!.email!.isNotEmpty) {
        final query = await _firestore
            .collection('salesmen')
            .where('email', isEqualTo: credentials.user!.email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          existingDoc = query.docs.first;
        }
      }

      if (existingDoc != null) {
        // Link the authenticated user's uid to the existing document, without copying or creating any new document!
        // This ensures existing accounts retain their original IDs.
        await existingDoc.reference.update({
          'uid': credentials.user!.uid,
          'lastLogin': FieldValue.serverTimestamp(),
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
        // Fallback to checking by auth UID directly, only if no existing record matched
        final docRef =
            _firestore.collection('salesmen').doc(credentials.user!.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          // Create a brand new salesman profile
          await docRef.set({
            'uid': credentials.user!.uid,
            'name': 'Sales Executive (Phone)',
            'phone': credentials.user!.phoneNumber ?? '',
            'email': credentials.user!.email ?? '',
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

  @override
  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    // 1. Validation step to confirm the verificationId is valid before proceeding
    if (verificationId.isEmpty || verificationId.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-verification-id',
        message:
            'The verification ID is invalid or empty. Please authenticate again.',
      );
    }

    // 2. Production Security Guard:
    // When running in production / non-debug mode (!kDebugMode), we completely ban mock-verification bypasses.
    // This strictly ensures that all OTP processes interface directly with the official Firebase PhoneAuthProvider,
    // protecting live databases and user accounts from illegitimate local spoofing.
    if (!isBypassEnabled() &&
        verificationId.startsWith('mock-verification-id-bypass:')) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message:
            'Dynamic testing bypass authentication is strictly disabled in production environments.',
      );
    }

    if (verificationId.startsWith('mock-verification-id-bypass:')) {
      if (smsCode != '123456') {
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'The verification code is invalid. Please enter 123456.',
        );
      }

      final rawPhone =
          verificationId.substring('mock-verification-id-bypass:'.length);

      // Perform genuine Firebase anonymous login instead of mock UID generation
      UserCredential? credentials;
      try {
        credentials = await _auth.signInAnonymously();
      } catch (e) {
        if (kDebugMode) {
          print('Sign anonymously failed: $e');
        }
      }

      final targetUid = credentials?.user?.uid ??
          'salesman_${rawPhone.replaceAll(RegExp(r'\D'), '')}';

      // Update our bypassSession state directly!
      _ref.read(bypassSessionProvider.notifier).setSession(
            uid: targetUid,
            phone: rawPhone,
          );

      try {
        DocumentSnapshot<Map<String, dynamic>>? existingDoc;

        final normalizedPhone = normalizePhoneToE164(rawPhone);
        final phoneVariants = <String>[normalizedPhone];
        final cleanDigits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
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
          existingDoc = query.docs.first;
        }

        if (existingDoc == null && cleanDigits.length >= 10) {
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
                  existingDoc = doc;
                  break;
                }
              }
            }
          }
        }

        if (existingDoc != null) {
          await existingDoc.reference.update({
            'uid': targetUid,
            'lastLogin': FieldValue.serverTimestamp(),
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
          final docRef = _firestore.collection('salesmen').doc(targetUid);
          await docRef.set({
            'uid': targetUid,
            'name': 'Sales Executive (Demo Bypass)',
            'phone': rawPhone,
            'email': 'salesman@cloudpower.com',
            'photoUrl': '',
            'role': 'salesman',
            'assignedRouteId': 'demo-route-id',
            'assignedArea': 'Assigned Route Area',
            'isActive': true,
            'fcmToken': '',
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
        }
      } catch (_) {}

      return credentials ?? MockUserCredential(MockUser(targetUid, rawPhone));
    }

    if (kIsWeb) {
      final confirmationResult = _webConfirmationResults[verificationId];
      if (confirmationResult == null) {
        throw FirebaseAuthException(
          code: 'missing-confirmation-result',
          message:
              'The confirmation helper for Web registration is unavailable. Please request a new OTP.',
        );
      }
      final credentials = await confirmationResult.confirm(smsCode);
      if (credentials.user != null) {
        await _postPhoneSignInSetup(credentials);
      }
      return credentials;
    } else {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final credentials = await _auth.signInWithCredential(credential);
      if (credentials.user != null) {
        await _postPhoneSignInSetup(credentials);
      }
      return credentials;
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
