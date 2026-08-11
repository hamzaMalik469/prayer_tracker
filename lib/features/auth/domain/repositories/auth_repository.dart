/// Authentication repository interface.
///
/// The Data layer provides the concrete implementation.
/// The Domain layer depends only on this abstraction.
library;

import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Returns the currently signed-in user, or null if unauthenticated.
  Future<UserEntity?> getCurrentUser();

  /// Emits the current user whenever auth state changes.
  Stream<UserEntity?> watchAuthState();

  /// Signs in with email and password.
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  Future<UserEntity> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with Google.
  Future<UserEntity> signInWithGoogle();

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail({required String email});

  /// Signs out the current user.
  Future<void> signOut();

  /// Permanently deletes the current user's account and all associated data.
  Future<void> deleteAccount();

  /// Updates the display name of the current user.
  Future<void> updateDisplayName({required String displayName});
}
