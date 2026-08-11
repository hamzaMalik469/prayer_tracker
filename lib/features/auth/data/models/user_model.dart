/// Firebase User → Domain UserEntity mapper.
library;

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

final class UserModel {
  const UserModel._();

  static UserEntity fromFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isAnonymous: user.isAnonymous,
    );
  }
}
