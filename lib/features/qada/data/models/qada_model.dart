library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_record_entity.dart';

final class QadaRecordModel {
  const QadaRecordModel._();

  static Map<String, dynamic> toFirestore(QadaRecordEntity entity) => {
        'userId':      entity.userId,
        'missedDate':  entity.missedDate.toLocalDateString(),
        'prayerType':  entity.prayerType.identifier,
        'qadaStatus':  entity.qadaStatus.name,
        'createdAt':   Timestamp.fromDate(entity.createdAt),
        'updatedAt':   Timestamp.fromDate(entity.updatedAt),
        if (entity.completedAt != null)
          'completedAt': Timestamp.fromDate(entity.completedAt!),
        if (entity.notes != null) 'notes': entity.notes,
      };

  static QadaRecordEntity fromFirestore(String id, Map<String, dynamic> data) {
    final dateStr = data['missedDate'] as String;
    final parts   = dateStr.split('-');
    final missedDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    PrayerType prayerType;
    try {
      prayerType = _parsePrayerType(data['prayerType'] as String);
    } catch (_) {
      prayerType = PrayerType.fajr;
    }

    QadaStatus qadaStatus;
    try {
      qadaStatus = QadaStatus.values.byName(data['qadaStatus'] as String);
    } catch (_) {
      qadaStatus = QadaStatus.pending;
    }

    return QadaRecordEntity(
      id:          id,
      userId:      data['userId'] as String,
      missedDate:  missedDate,
      prayerType:  prayerType,
      qadaStatus:  qadaStatus,
      createdAt:   (data['createdAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:   (data['updatedAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      notes:       data['notes'] as String?,
    );
  }

  static PrayerType _parsePrayerType(String value) => switch (value) {
        'fajr'    => PrayerType.fajr,
        'dhuhr'   => PrayerType.dhuhr,
        'asr'     => PrayerType.asr,
        'maghrib' => PrayerType.maghrib,
        'isha'    => PrayerType.isha,
        _         => throw ArgumentError('Unknown prayer type: $value'),
      };
}
