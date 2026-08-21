library;

import 'package:equatable/equatable.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

enum PrayerStatus {
  notRecorded,
  prayed,
  missed,
  prayedLate,
  qadaCompleted, // NEW: was missed, now completed as Qada
}

extension PrayerStatusExtension on PrayerStatus {
  String get displayName => switch (this) {
        PrayerStatus.notRecorded => 'Not Recorded',
        PrayerStatus.prayed => 'With Jammah',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.prayedLate => 'On Time',
        PrayerStatus.qadaCompleted => 'Qada Prayed',
      };

  bool get isCompleted =>
      this == PrayerStatus.prayed ||
      this == PrayerStatus.prayedLate ||
      this == PrayerStatus.qadaCompleted;

  bool get isMissed => this == PrayerStatus.missed;

  bool get isQadaCompleted => this == PrayerStatus.qadaCompleted;

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

  static String buildId({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
  }) =>
      '${userId}_${date.toLocalDateString()}_${prayerType.identifier}';

  final String id;
  final String userId;
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
