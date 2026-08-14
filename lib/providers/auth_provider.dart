import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  firebase_auth.User? _firebaseUser;
  User? _userProfile;
  bool _isLoading = false;
  String? _error;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    _error = null;

    if (firebaseUser != null) {
      // Load user profile
      _userProfile = await _authService.getUserProfile(firebaseUser.uid);

      // Save FCM token for push notifications
      await _authService.saveFCMToken(firebaseUser.uid);
    } else {
      _userProfile = null;
    }

    notifyListeners();
  }

  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(firebase_auth.FirebaseAuthException) onVerificationFailed,
    required Function(firebase_auth.PhoneAuthCredential) onVerificationCompleted,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationFailed: (e) {
          _error = e.message ?? 'Verification failed';
          _isLoading = false;
          notifyListeners();
          if (e is firebase_auth.FirebaseAuthException) {
            onVerificationFailed(e);
          } else {
            onVerificationFailed(firebase_auth.FirebaseAuthException(
              code: 'unknown',
              message: e.message ?? 'Verification failed',
            ));
          }
        },
        onVerificationCompleted: onVerificationCompleted,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (e is firebase_auth.FirebaseAuthException) {
        onVerificationFailed(e);
      } else {
        onVerificationFailed(firebase_auth.FirebaseAuthException(
          code: 'unknown',
          message: e.toString(),
        ));
      }
    }
  }

  Future<bool> signInWithCredential(firebase_auth.PhoneAuthCredential credential) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithCredential(credential);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createUserProfile({
    required String name,
    required String state,
    required String lga,
  }) async {
    if (_firebaseUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProfile = await _authService.createUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        phoneNumber: _firebaseUser!.phoneNumber ?? '',
        state: state,
        lga: lga,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUserProfile(User updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(updatedUser);
      _userProfile = updatedUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}