library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_model.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required FirebaseFirestore firestore,
  })  : _authDataSource = authDataSource,
        _firestore = firestore;

  final FirebaseAuthDataSource _authDataSource;
  final FirebaseFirestore _firestore;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _authDataSource.currentUser;
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    } catch (e) {
      AppLogger.error('getCurrentUser failed', error: e, tag: 'AuthRepo');
      throw const UnknownFailure();
    }
  }

  @override
  Stream<UserEntity?> watchAuthState() {
    return _authDataSource.authStateChanges.map(
      (user) => user != null ? UserModel.fromFirebaseUser(user) : null,
    );
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _authDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserEntity> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _authDataSource.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    if (displayName != null && displayName.isNotEmpty) {
      await _authDataSource.updateDisplayName(displayName: displayName);
    }

    // Create the user document in Firestore.
    await _createUserDocument(user.uid, email: email, displayName: displayName);

    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final credential = await _authDataSource.signInWithGoogle();
    final user = credential.user!;

    // Ensure user document exists for new Google sign-ins.
    await _createUserDocumentIfAbsent(
      user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );

    return UserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _authDataSource.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _authDataSource.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _authDataSource.currentUser;
    if (user == null) throw const UnauthenticatedFailure();

    // Delete all user data from Firestore before deleting the auth account.
    await _deleteUserData(user.uid);
    await _authDataSource.deleteAccount();
  }

  @override
  Future<void> updateDisplayName({required String displayName}) =>
      _authDataSource.updateDisplayName(displayName: displayName);

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _createUserDocument(
    String userId, {
    required String email,
    String? displayName,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.users).doc(userId).set({
        FirestoreFields.userId: userId,
        'email': email,
        'displayName': displayName,
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.warning('Failed to create user document',
          error: e, tag: 'AuthRepo');
      // Non-fatal — the auth account still exists.
    }
  }

  Future<void> _createUserDocumentIfAbsent(
    String userId, {
    required String email,
    String? displayName,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        await _createUserDocument(userId,
            email: email, displayName: displayName);
      }
    } catch (e) {
      AppLogger.warning('_createUserDocumentIfAbsent failed',
          error: e, tag: 'AuthRepo');
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      // Firestore does not automatically delete sub-collections.
      // We delete each sub-collection's documents individually.
      await _deleteCollection(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userId)
            .collection(FirestoreCollections.prayerRecords),
      );

      await _deleteCollection(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userId)
            .collection(FirestoreCollections.qadaRecords),
      );

      await _deleteCollection(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userId)
            .collection(FirestoreCollections.settings),
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .delete();
    } catch (e) {
      AppLogger.error('_deleteUserData failed', error: e, tag: 'AuthRepo');
      throw DatabaseFailure(
        message: 'Failed to delete account data. Please try again.',
      );
    }
  }

  Future<void> _deleteCollection(CollectionReference ref) async {
    const batchSize = 100;
    QuerySnapshot snapshot;

    do {
      snapshot = await ref.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchSize);
  }
}
