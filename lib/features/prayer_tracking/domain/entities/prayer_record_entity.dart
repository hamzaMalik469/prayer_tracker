/// A prayer tracking record for a single obligatory prayer on a given day.
///
/// Semantic rules (enforced in domain, not just UI):
///
///   [PrayerStatus.notRecorded] — The app has NO information.
///                                This is NOT the same as missed.
///
///   [PrayerStatus.prayed]      — The user explicitly recorded completion.
///
///   [PrayerStatus.missed]      — The user explicitly recorded a miss.
///
///   [PrayerStatus.prayedLate]  — The user recorded completion after the
///                                prayer window closed (optional tracking).
///
/// IMPORTANT: notRecorded ≠ missed. Never treat them the same.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

enum PrayerStatus {
  notRecorded,
  prayed,
  missed,
  prayedLate,
}

extension PrayerStatusExtension on PrayerStatus {
  String get displayName => switch (this) {
        PrayerStatus.notRecorded => 'Not Recorded',
        PrayerStatus.prayed => 'Prayed',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.prayedLate => 'Prayed Late',
      };

  bool get isCompleted =>
      this == PrayerStatus.prayed || this == PrayerStatus.prayedLate;

  bool get isMissed => this == PrayerStatus.missed;
  bool get isRecorded => this != PrayerStatus.notRecorded;
}

final class PrayerRecordEntity extends Equatable {
  const PrayerRecordEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.prayerType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Deterministic ID: userId_YYYY-MM-DD_prayerType
  /// Prevents duplicate records across devices.
  static String buildId({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
  }) =>
      '${userId}_${date.toLocalDateString()}_${prayerType.identifier}';

  final String id;
  final String userId;

  /// The local calendar date — NOT a UTC timestamp.
  /// Date handling is intentionally local to prevent midnight boundary bugs.
  final DateTime date;

  final PrayerType prayerType;
  final PrayerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  PrayerRecordEntity copyWith({
    PrayerStatus? status,
    DateTime? updatedAt,
    String? notes,
  }) {
    return PrayerRecordEntity(
      id: id,
      userId: userId,
      date: date,
      prayerType: prayerType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        prayerType,
        status,
        createdAt,
        updatedAt,
        notes,
      ];
}
