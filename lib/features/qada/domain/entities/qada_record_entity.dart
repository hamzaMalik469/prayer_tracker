library;

import 'package:equatable/equatable.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

enum QadaStatus {
  pending,    // Not yet made up
  completed,  // Made up — original prayer record updated to qadaCompleted
}

extension QadaStatusExtension on QadaStatus {
  String get displayName => switch (this) {
        QadaStatus.pending   => 'Pending',
        QadaStatus.completed => 'Completed',
      };

  bool get isPending   => this == QadaStatus.pending;
  bool get isCompleted => this == QadaStatus.completed;
}

/// A Qada record tied to a specific missed prayer on a specific date.
///
/// When created: status = pending
/// When completed: status = completed AND the original PrayerRecord
///                for (userId, missedDate, prayerType) is updated to
///                PrayerStatus.qadaCompleted
final class QadaRecordEntity extends Equatable {
  const QadaRecordEntity({
    required this.id,
    required this.userId,
    required this.missedDate,
    required this.prayerType,
    required this.qadaStatus,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.notes,
  });

  /// Deterministic ID: userId_YYYY-MM-DD_prayerType_qada
  static String buildId({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) =>
      '${userId}_${missedDate.toLocalDateString()}_${prayerType.identifier}_qada';

  final String id;
  final String userId;

  /// The original date when this prayer was missed.
  final DateTime missedDate;

  final PrayerType prayerType;
  final QadaStatus qadaStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the Qada was completed.
  final DateTime? completedAt;
  final String? notes;

  bool get isPending   => qadaStatus.isPending;
  bool get isCompleted => qadaStatus.isCompleted;

  QadaRecordEntity copyWith({
    QadaStatus? qadaStatus,
    DateTime?   updatedAt,
    DateTime?   completedAt,
    String?     notes,
  }) {
    return QadaRecordEntity(
      id:          id,
      userId:      userId,
      missedDate:  missedDate,
      prayerType:  prayerType,
      qadaStatus:  qadaStatus  ?? this.qadaStatus,
      createdAt:   createdAt,
      updatedAt:   updatedAt   ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      notes:       notes       ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, missedDate, prayerType, qadaStatus,
        createdAt, updatedAt, completedAt, notes,
      ];
}
