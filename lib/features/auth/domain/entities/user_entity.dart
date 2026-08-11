/// The authenticated user entity.
///
/// Domain-layer representation of a signed-in user.
/// Must not contain Firebase-specific types.
library;

import 'package:equatable/equatable.dart';

final class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
    required this.isAnonymous,
  });

  /// The unique user identifier — stable across sessions.
  final String id;

  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;

  /// True when the user is signed in anonymously (guest mode).
  final bool isAnonymous;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        isEmailVerified,
        createdAt,
        isAnonymous,
      ];
}