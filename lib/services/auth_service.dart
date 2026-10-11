import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = FirebaseService().auth;
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(firebase_auth.FirebaseAuthException) onVerificationFailed,
    required Function(firebase_auth.PhoneAuthCredential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<firebase_auth.UserCredential> signInWithCredential(firebase_auth.PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> createUserProfile({
    required String uid,
    required String name,
    required String phoneNumber,
    required String state,
    required String lga,
  }) async {
    final user = User(
      id: uid,
      name: name,
      phoneNumber: phoneNumber,
      state: state,
      lga: lga,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
    return user;
  }

  Future<User?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> updateUserProfile(User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    final query = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .get();

    return query.docs.isNotEmpty;
  }

  // FCM Token management
  Future<void> saveFCMToken(String userId) async {
    final token = await FirebaseService().messaging.getToken();
    if (token != null) {
      final userDocument = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDocument.get();
      if (!userSnapshot.exists) return;

      await userDocument.update({
        'fcmToken': token,
        'tokenUpdatedAt': Timestamp.now(),
      });
    }
  }

  Future<void> removeFCMToken(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': FieldValue.delete(),
      'tokenUpdatedAt': FieldValue.delete(),
    });
  }
}