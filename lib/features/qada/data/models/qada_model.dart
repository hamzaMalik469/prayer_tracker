/// Firestore ↔ Domain Qada mappers.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_balance_entity.dart';
import '../../domain/entities/qada_record_entity.dart';

final class QadaRecordModel {
  const QadaRecordModel._();

  static Map<String, dynamic> toFirestore(QadaRecordEntity entity) => {
        'userId': entity.userId,
        'prayerType': entity.prayerType.identifier,
        'transactionType': entity.transactionType.name,
        'quantity': entity.quantity,
        'createdAt': Timestamp.fromDate(entity.createdAt),
        if (entity.notes != null) 'notes': entity.notes,
      };

  static QadaRecordEntity fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    PrayerType prayerType;
    try {
      prayerType = _parsePrayerType(data['prayerType'] as String);
    } catch (_) {
      prayerType = PrayerType.fajr;
    }

    QadaTransactionType transactionType;
    try {
      transactionType = QadaTransactionType.values.byName(
        data['transactionType'] as String,
      );
    } catch (_) {
      transactionType = QadaTransactionType.added;
    }

    return QadaRecordEntity(
      id: id,
      userId: data['userId'] as String,
      prayerType: prayerType,
      transactionType: transactionType,
      quantity: data['quantity'] as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] as String?,
    );
  }

  static PrayerType _parsePrayerType(String value) => switch (value) {
        'fajr' => PrayerType.fajr,
        'dhuhr' => PrayerType.dhuhr,
        'asr' => PrayerType.asr,
        'maghrib' => PrayerType.maghrib,
        'isha' => PrayerType.isha,
        _ => throw ArgumentError('Unknown prayer type: $value'),
      };
}

final class QadaBalanceModel {
  const QadaBalanceModel._();

  static Map<String, dynamic> toFirestore(QadaBalanceEntity entity) => {
        'fajr': entity.fajr,
        'dhuhr': entity.dhuhr,
        'asr': entity.asr,
        'maghrib': entity.maghrib,
        'isha': entity.isha,
      };

  static QadaBalanceEntity fromFirestore(Map<String, dynamic> data) =>
      QadaBalanceEntity(
        fajr: (data['fajr'] as int?) ?? 0,
        dhuhr: (data['dhuhr'] as int?) ?? 0,
        asr: (data['asr'] as int?) ?? 0,
        maghrib: (data['maghrib'] as int?) ?? 0,
        isha: (data['isha'] as int?) ?? 0,
      );
}
