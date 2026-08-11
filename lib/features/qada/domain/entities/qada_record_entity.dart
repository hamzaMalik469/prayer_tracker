/// A single Qada transaction record.
library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

enum QadaTransactionType {
  /// User added missed prayers to their balance.
  added,

  /// User recorded completion of Qada prayers.
  completed,
}

final class QadaRecordEntity extends Equatable {
  const QadaRecordEntity({
    required this.id,
    required this.userId,
    required this.prayerType,
    required this.transactionType,
    required this.quantity,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String userId;
  final PrayerType prayerType;
  final QadaTransactionType transactionType;
  final int quantity;
  final DateTime createdAt;
  final String? notes;

  @override
  List<Object?> get props => [
        id,
        userId,
        prayerType,
        transactionType,
        quantity,
        createdAt,
        notes,
      ];
}
