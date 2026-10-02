import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import '../../../core/services/notification_service.dart';

final authStateChangesProvider = StreamProvider<fb.User?>((ref) {
  return fb.FirebaseAuth.instance.authStateChanges();
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value ?? fb.FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // Ensure push token is saved for active user session
  NotificationService.savePushToken(user.uid);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
});

final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncValue.data(null));

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _cleanDigits(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> signInWithPhoneAndPassword({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final digits = _cleanDigits(phoneNumber);
    if (digits.isEmpty) {
      state = AsyncValue.error('Please enter a valid phone number', StackTrace.current);
      throw 'Please enter a valid phone number';
    }

    final candidateEmails = <String>{};
    candidateEmails.add('$digits@messagingapp.com');

    if (digits.startsWith('880')) {
      candidateEmails.add('${digits.substring(2)}@messagingapp.com'); // e.g. 01838865701
    } else if (digits.startsWith('0')) {
      candidateEmails.add('88$digits@messagingapp.com'); // e.g. 8801838865701
      candidateEmails.add('${digits.substring(1)}@messagingapp.com'); // e.g. 1838865701
    } else {
      candidateEmails.add('0$digits@messagingapp.com');
      candidateEmails.add('880$digits@messagingapp.com');
    }

    fb.UserCredential? credential;
    Object? lastError;

    for (final email in candidateEmails) {
      try {
        credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
        if (credential.user != null) break;
      } catch (e) {
        lastError = e;
      }
    }

    if (credential?.user != null) {
      final uid = credential!.user!.uid;
      
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      try {
        await _firestore.collection('users').doc(uid).update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          if (token != null) 'pushToken': token,
        });
      } catch (_) {}

      state = const AsyncValue.data(null);
    } else {
      final err = lastError ?? 'Incorrect phone number or password.';
      state = AsyncValue.error(err, StackTrace.current);
      throw err;
    }
  }

  Future<void> registerWithPhoneAndPassword({
    required String phoneNumber,
    required String password,
    required String displayName,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    try {
      final digits = _cleanDigits(phoneNumber);
      final email = '$digits@messagingapp.com';
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        String? token;
        try {
          token = await FirebaseMessaging.instance.getToken();
        } catch (_) {}

        final userModel = UserModel(
          uid: user.uid,
          phoneNumber: phoneNumber.trim(),
          displayName: displayName,
          username: username.toLowerCase(),
          about: 'Hey there! I am using Hel Lo.',
          status: 'Available',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: true,
          isVerified: false,
          pushToken: token,
          privacySettings: {
            'profilePhoto': 'everyone',
            'lastSeen': 'everyone',
            'about': 'everyone',
            'readReceipts': true,
          },
          notificationSettings: {
            'sound': true,
            'vibrate': true,
            'preview': true,
          },
          blockedUserIds: [],
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? about}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null && displayName.isNotEmpty) updates['displayName'] = displayName;
    if (about != null) updates['about'] = about;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> privacySettings) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'privacySettings': privacySettings,
    });
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> notificationSettings) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'notificationSettings': notificationSettings,
    });
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> resetPassword({required String phoneNumber}) async {
    try {
      final digits = _cleanDigits(phoneNumber);
      final email = '$digits@messagingapp.com';
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> blockUser(String targetUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> unblockUser(String targetUserId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
    });
  }
}

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = fb.FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!doc.exists) return null;

  return UserModel.fromMap(doc.data()!);
});
