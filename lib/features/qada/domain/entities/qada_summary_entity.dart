library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import 'qada_record_entity.dart';

/// Summary of all Qada records grouped by prayer type.
final class QadaSummaryEntity extends Equatable {
  const QadaSummaryEntity({
    required this.pendingRecords,
    required this.completedRecords,
  });

  const QadaSummaryEntity.empty()
      : pendingRecords   = const [],
        completedRecords = const [];

  final List<QadaRecordEntity> pendingRecords;
  final List<QadaRecordEntity> completedRecords;

  int get totalPending   => pendingRecords.length;
  int get totalCompleted => completedRecords.length;
  int get total          => totalPending + totalCompleted;

  /// Pending count for a specific prayer type.
  int pendingFor(PrayerType type) =>
      pendingRecords.where((r) => r.prayerType == type).length;

  /// Completed count for a specific prayer type.
  int completedFor(PrayerType type) =>
      completedRecords.where((r) => r.prayerType == type).length;

  /// All pending records for a specific prayer type, sorted oldest first.
  List<QadaRecordEntity> pendingRecordsFor(PrayerType type) =>
      pendingRecords
          .where((r) => r.prayerType == type)
          .toList()
        ..sort((a, b) => a.missedDate.compareTo(b.missedDate));

  /// Returns pending records sorted oldest first (to complete in order).
  List<QadaRecordEntity> get pendingSortedOldestFirst =>
      List<QadaRecordEntity>.from(pendingRecords)
        ..sort((a, b) => a.missedDate.compareTo(b.missedDate));

  @override
  List<Object> get props => [pendingRecords, completedRecords];
}
