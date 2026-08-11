/// Firestore ↔ Domain prayer record mapper.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/extensions/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/prayer_record_entity.dart';

final class PrayerRecordModel {
  const PrayerRecordModel._();

  static Map<String, dynamic> toFirestore(PrayerRecordEntity entity) => {
        'userId': entity.userId,
        'date': entity.date.toLocalDateString(),
        'prayerType': entity.prayerType.identifier,
        'status': entity.status.name,
        'timezone': DateTime.now().timeZoneName,
        'createdAt': Timestamp.fromDate(entity.createdAt),
        'updatedAt': Timestamp.fromDate(entity.updatedAt),
        if (entity.notes != null) 'notes': entity.notes,
      };

  static PrayerRecordEntity fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final dateStr = data['date'] as String;
    final parts = dateStr.split('-');
    final date = DateTime(
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

    PrayerStatus status;
    try {
      status = PrayerStatus.values.byName(data['status'] as String);
    } catch (_) {
      status = PrayerStatus.notRecorded;
    }

    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt =
        (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return PrayerRecordEntity(
      id: id,
      userId: data['userId'] as String,
      date: date,
      prayerType: prayerType,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
