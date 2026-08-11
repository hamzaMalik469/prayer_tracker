/// Firestore prayer tracking data source.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/prayer_record_entity.dart';
import '../models/prayer_record_model.dart';

abstract interface class PrayerTrackingRemoteDataSource {
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required String recordId,
  });

  Future<List<PrayerRecordEntity>> getPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  });

  Future<List<PrayerRecordEntity>> getPrayerRecordsForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<PrayerRecordEntity> upsertPrayerRecord({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
    required PrayerStatus status,
  });

  Stream<List<PrayerRecordEntity>> watchPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  });
}

final class PrayerTrackingRemoteDataSourceImpl
    implements PrayerTrackingRemoteDataSource {
  const PrayerTrackingRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _recordsRef(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.prayerRecords);

  @override
  Future<PrayerRecordEntity?> getPrayerRecord({
    required String userId,
    required String recordId,
  }) async {
    try {
      final snap = await _recordsRef(userId).doc(recordId).get();
      if (!snap.exists || snap.data() == null) return null;
      return PrayerRecordModel.fromFirestore(snap.id, snap.data()!);
    } catch (e) {
      AppLogger.error('getPrayerRecord failed',
          error: e, tag: 'PrayerTrackingDS');
      throw DatabaseFailure(message: 'Failed to load prayer record.');
    }
  }

  @override
  Future<List<PrayerRecordEntity>> getPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toLocalDateString();
      final snap = await _recordsRef(userId)
          .where(FirestoreFields.date, isEqualTo: dateStr)
          .get();

      return snap.docs
          .map((d) => PrayerRecordModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      AppLogger.error('getPrayerRecordsForDate failed',
          error: e, tag: 'PrayerTrackingDS');
      throw DatabaseFailure(message: 'Failed to load prayer records.');
    }
  }

  @override
  Future<List<PrayerRecordEntity>> getPrayerRecordsForRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = startDate.toLocalDateString();
      final endStr = endDate.toLocalDateString();

      final snap = await _recordsRef(userId)
          .where(FirestoreFields.date, isGreaterThanOrEqualTo: startStr)
          .where(FirestoreFields.date, isLessThanOrEqualTo: endStr)
          .orderBy(FirestoreFields.date, descending: false)
          .get();

      return snap.docs
          .map((d) => PrayerRecordModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      AppLogger.error('getPrayerRecordsForRange failed',
          error: e, tag: 'PrayerTrackingDS');
      throw DatabaseFailure(message: 'Failed to load prayer records.');
    }
  }

  @override
  Future<PrayerRecordEntity> upsertPrayerRecord({
    required String userId,
    required DateTime date,
    required PrayerType prayerType,
    required PrayerStatus status,
  }) async {
    try {
      final recordId = PrayerRecordEntity.buildId(
        userId: userId,
        date: date,
        prayerType: prayerType,
      );

      final now = DateTime.now();
      final docRef = _recordsRef(userId).doc(recordId);
      final existing = await docRef.get();

      final PrayerRecordEntity record;

      if (existing.exists && existing.data() != null) {
        // Update existing record — preserve createdAt.
        record = PrayerRecordModel.fromFirestore(
          existing.id,
          existing.data()!,
        ).copyWith(status: status, updatedAt: now);
      } else {
        // Create new record.
        record = PrayerRecordEntity(
          id: recordId,
          userId: userId,
          date: date,
          prayerType: prayerType,
          status: status,
          createdAt: now,
          updatedAt: now,
        );
      }

      await docRef.set(
        PrayerRecordModel.toFirestore(record),
        SetOptions(merge: true),
      );

      return record;
    } catch (e) {
      AppLogger.error('upsertPrayerRecord failed',
          error: e, tag: 'PrayerTrackingDS');
      throw DatabaseFailure(message: 'Failed to save prayer record.');
    }
  }

  @override
  Stream<List<PrayerRecordEntity>> watchPrayerRecordsForDate({
    required String userId,
    required DateTime date,
  }) {
    final dateStr = date.toLocalDateString();

    return _recordsRef(userId)
        .where(FirestoreFields.date, isEqualTo: dateStr)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PrayerRecordModel.fromFirestore(d.id, d.data()))
              .toList(),
        )
        .handleError((Object e) {
      AppLogger.error('watchPrayerRecordsForDate error',
          error: e, tag: 'PrayerTrackingDS');
    });
  }
}
