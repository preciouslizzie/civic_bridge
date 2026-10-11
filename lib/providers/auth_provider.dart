import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  firebase_auth.User? _firebaseUser;
  User? _userProfile;
  bool _isLoading = false;
  String? _error;
  String? _profileLoadError;
  Future<bool>? _profileLoadFuture;
  int _authStateVersion = 0;
  bool _disposed = false;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get profileLoadError => _profileLoadError;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null &&
        _firebaseUser?.uid == firebaseUser.uid &&
        _profileLoadFuture != null) {
      return;
    }

    _firebaseUser = firebaseUser;
    _error = null;
    _profileLoadError = null;
    final version = ++_authStateVersion;

    if (firebaseUser == null) {
      _userProfile = null;
      _isLoading = false;
      _notifyListeners();
      return;
    }

    _userProfile = null;
    _isLoading = true;
    _notifyListeners();
    _profileLoadFuture = _loadUserData(firebaseUser, version);
    await _profileLoadFuture;
  }

  Future<bool> _loadUserData(
    firebase_auth.User firebaseUser,
    int version,
  ) async {
    try {
      final profile = await _authService.getUserProfile(firebaseUser.uid);
      if (version != _authStateVersion) return false;

      _userProfile = profile;
      _profileLoadError = null;

      if (profile != null) {
        try {
          await _authService.saveFCMToken(firebaseUser.uid);
        } catch (e) {
          _error = 'Unable to save notification token: $e';
        }
      }
      return true;
    } catch (e) {
      if (version == _authStateVersion) {
        _profileLoadError = e.toString();
        _error = e.toString();
      }
      return false;
    } finally {
      if (version == _authStateVersion) {
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<bool> refreshUserProfile() async {
    final firebaseUser = _firebaseUser ?? _authService.currentUser;
    if (firebaseUser == null) return false;

    _firebaseUser = firebaseUser;
    _userProfile = null;
    _error = null;
    _profileLoadError = null;
    _isLoading = true;
    final version = ++_authStateVersion;
    _notifyListeners();

    _profileLoadFuture = _loadUserData(firebaseUser, version);
    return _profileLoadFuture!;
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(firebase_auth.FirebaseAuthException) onVerificationFailed,
    required Function(firebase_auth.PhoneAuthCredential)
    onVerificationCompleted,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _isLoading = false;
          _notifyListeners();
          onCodeSent(verificationId);
        },
        onVerificationFailed: (e) {
          _error = e.message ?? 'Verification failed';
          _isLoading = false;
          _notifyListeners();
          onVerificationFailed(e);
        },
        onVerificationCompleted: onVerificationCompleted,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _notifyListeners();
      if (e is firebase_auth.FirebaseAuthException) {
        onVerificationFailed(e);
      } else {
        onVerificationFailed(
          firebase_auth.FirebaseAuthException(
            code: 'unknown',
            message: e.toString(),
          ),
        );
      }
    }
  }

  Future<bool> signInWithCredential(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    _isLoading = true;
    _error = null;
    _profileLoadError = null;
    _notifyListeners();

    try {
      final result = await _authService.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw StateError('Sign-in completed without a Firebase user.');
      }

      _firebaseUser = user;
      _userProfile = null;
      final version = ++_authStateVersion;
      _isLoading = true;
      _notifyListeners();
      _profileLoadFuture = _loadUserData(user, version);
      return await _profileLoadFuture!;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _notifyListeners();
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
    _notifyListeners();

    try {
      _userProfile = await _authService.createUserProfile(
        uid: _firebaseUser!.uid,
        name: name,
        phoneNumber: _firebaseUser!.phoneNumber ?? '',
        state: state,
        lga: lga,
      );
      _isLoading = false;
      _notifyListeners();
      try {
        await _authService.saveFCMToken(_firebaseUser!.uid);
      } catch (e) {
        _error =
            'Profile created, but notification token could not be saved: $e';
        _notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _notifyListeners();
      return false;
    }
  }

  Future<void> updateUserProfile(User updatedUser) async {
    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      await _authService.updateUserProfile(updatedUser);
      _userProfile = updatedUser;
      _isLoading = false;
      _notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    _notifyListeners();
  }
}
