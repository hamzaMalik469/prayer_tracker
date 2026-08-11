/// Firebase Authentication data source.
///
/// All Firebase-specific code is isolated here.
/// The rest of the application must not import firebase_auth directly.
library;

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';

/// Raw data source — returns Firebase types.
/// The repository implementation maps these to domain entities.
abstract interface class FirebaseAuthDataSource {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<void> updateDisplayName({required String displayName});
}

final class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('signInWithEmailAndPassword failed',
          error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('createUserWithEmailAndPassword failed',
          error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    // Google Sign-In requires the google_sign_in package wired in Phase 7.
    // For now, throw a clear UnsupportedError so the repository can handle it.
    throw UnimplementedError(
      'Google Sign-In will be implemented in Phase 7 '
      'when google_sign_in is added to pubspec.yaml.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('sendPasswordResetEmail failed', error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      AppLogger.error('signOut failed', error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const UnauthenticatedFailure();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      AppLogger.error('deleteAccount failed', error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> updateDisplayName({required String displayName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const UnauthenticatedFailure();
      await user.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('updateDisplayName failed', error: e, tag: 'AuthDS');
      throw _mapFirebaseAuthException(e);
    }
  }

  AuthFailure _mapFirebaseAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'email-already-in-use' => 'An account already exists with this email.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' => 'Password must be at least 6 characters.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      'requires-recent-login' =>
        'Please sign in again to complete this action.',
      'invalid-credential' => 'Invalid credentials. Please try again.',
      _ => 'Authentication failed. Please try again.',
    };
    return AuthFailure(message: message, code: e.code);
  }
}
