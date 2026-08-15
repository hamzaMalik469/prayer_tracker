library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/data/models/prayer_record_model.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';
import '../models/qada_model.dart';

abstract interface class QadaRemoteDataSource {
  Future<QadaSummaryEntity> getSummary({required String userId});
  Stream<QadaSummaryEntity> watchSummary({required String userId});

  Future<QadaRecordEntity> addRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  });

  Future<QadaRecordEntity> completeRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  });

  Future<List<QadaRecordEntity>> getRecordsForDate({
    required String userId,
    required DateTime date,
  });

  Future<void> deleteRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  });
}

final class QadaRemoteDataSourceImpl implements QadaRemoteDataSource {
  const QadaRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _qadaRef(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.qadaRecords);

  CollectionReference<Map<String, dynamic>> _prayerRef(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.prayerRecords);

  @override
  Future<QadaSummaryEntity> getSummary({required String userId}) async {
    try {
      final snap = await _qadaRef(userId).get();
      return _buildSummary(snap.docs);
    } catch (e) {
      AppLogger.error('getQadaSummary failed', error: e, tag: 'QadaDS');
      throw const DatabaseFailure(message: 'Failed to load Qada records.');
    }
  }

  @override
  Stream<QadaSummaryEntity> watchSummary({required String userId}) {
    return _qadaRef(userId).snapshots().map(
          (snap) => _buildSummary(snap.docs),
        ).handleError((Object e) {
      AppLogger.error('watchQadaSummary error', error: e, tag: 'QadaDS');
    });
  }

  @override
  Future<QadaRecordEntity> addRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  }) async {
    try {
      final now        = DateTime.now();
      final qadaId     = QadaRecordEntity.buildId(
        userId:     userId,
        missedDate: missedDate,
        prayerType: prayerType,
      );

      final qadaRecord = QadaRecordEntity(
        id:         qadaId,
        userId:     userId,
        missedDate: missedDate,
        prayerType: prayerType,
        qadaStatus: QadaStatus.pending,
        createdAt:  now,
        updatedAt:  now,
        notes:      notes,
      );

      // Also ensure the prayer record for that date is marked as missed.
      final prayerRecordId = PrayerRecordEntity.buildId(
        userId:     userId,
        date:       missedDate,
        prayerType: prayerType,
      );

      final prayerRecord = PrayerRecordEntity(
        id:         prayerRecordId,
        userId:     userId,
        date:       missedDate,
        prayerType: prayerType,
        status:     PrayerStatus.missed,
        createdAt:  now,
        updatedAt:  now,
      );

      final batch = _firestore.batch();

      // Write Qada record.
      batch.set(
        _qadaRef(userId).doc(qadaId),
        QadaRecordModel.toFirestore(qadaRecord),
      );

      // Write/update prayer record as missed (only if not already prayed).
      final existingPrayer = await _prayerRef(userId).doc(prayerRecordId).get();
      final existingStatus = existingPrayer.exists
          ? PrayerStatus.values.byName(
              existingPrayer.data()?['status'] as String? ?? 'notRecorded',
            )
          : PrayerStatus.notRecorded;

      // Only mark as missed if not already prayed/qadaCompleted.
      if (!existingStatus.isCompleted) {
        batch.set(
          _prayerRef(userId).doc(prayerRecordId),
          PrayerRecordModel.toFirestore(prayerRecord),
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      AppLogger.info(
        'Qada record added: ${prayerType.identifier} on ${missedDate.toLocalDateString()}',
        tag: 'QadaDS',
      );

      return qadaRecord;
    } catch (e) {
      AppLogger.error('addQadaRecord failed', error: e, tag: 'QadaDS');
      throw const DatabaseFailure(message: 'Failed to add Qada record.');
    }
  }

  @override
  Future<QadaRecordEntity> completeRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) async {
    try {
      final now = DateTime.now();

      // Build updated Qada record.
      final qadaDocRef  = _qadaRef(userId).doc(qadaRecordId);
      final existingDoc = await qadaDocRef.get();

      if (!existingDoc.exists) {
        throw const DatabaseFailure(message: 'Qada record not found.');
      }

      final existing = QadaRecordModel.fromFirestore(
        existingDoc.id,
        existingDoc.data()!,
      );

      final updated = existing.copyWith(
        qadaStatus:  QadaStatus.completed,
        updatedAt:   now,
        completedAt: now,
      );

      // Also update the original prayer record to qadaCompleted.
      final prayerRecordId = PrayerRecordEntity.buildId(
        userId:     userId,
        date:       missedDate,
        prayerType: prayerType,
      );

      final prayerRecord = PrayerRecordEntity(
        id:         prayerRecordId,
        userId:     userId,
        date:       missedDate,
        prayerType: prayerType,
        status:     PrayerStatus.qadaCompleted,
        createdAt:  now,
        updatedAt:  now,
      );

      final batch = _firestore.batch();

      batch.set(
        qadaDocRef,
        QadaRecordModel.toFirestore(updated),
      );

      batch.set(
        _prayerRef(userId).doc(prayerRecordId),
        PrayerRecordModel.toFirestore(prayerRecord),
        SetOptions(merge: true),
      );

      await batch.commit();

      AppLogger.info(
        'Qada completed: ${prayerType.identifier} on ${missedDate.toLocalDateString()}',
        tag: 'QadaDS',
      );

      return updated;
    } catch (e) {
      AppLogger.error('completeQadaRecord failed', error: e, tag: 'QadaDS');
      throw const DatabaseFailure(message: 'Failed to complete Qada record.');
    }
  }

  @override
  Future<List<QadaRecordEntity>> getRecordsForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toLocalDateString();
      final snap    = await _qadaRef(userId)
          .where('missedDate', isEqualTo: dateStr)
          .get();
      return snap.docs
          .map((d) => QadaRecordModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      AppLogger.error('getQadaRecordsForDate failed', error: e, tag: 'QadaDS');
      return [];
    }
  }

  @override
  Future<void> deleteRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) async {
    try {
      final batch = _firestore.batch();

      // Delete Qada record.
      batch.delete(_qadaRef(userId).doc(qadaRecordId));

      // Revert prayer record to missed (if it was qadaCompleted).
      final prayerRecordId = PrayerRecordEntity.buildId(
        userId:     userId,
        date:       missedDate,
        prayerType: prayerType,
      );

      batch.update(
        _prayerRef(userId).doc(prayerRecordId),
        {
          'status':    PrayerStatus.missed.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      await batch.commit();
    } catch (e) {
      AppLogger.error('deleteQadaRecord failed', error: e, tag: 'QadaDS');
      throw const DatabaseFailure(message: 'Failed to delete Qada record.');
    }
  }

  QadaSummaryEntity _buildSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final pending   = <QadaRecordEntity>[];
    final completed = <QadaRecordEntity>[];

    for (final doc in docs) {
      final record = QadaRecordModel.fromFirestore(doc.id, doc.data());
      if (record.isPending) {
        pending.add(record);
      } else {
        completed.add(record);
      }
    }

    return QadaSummaryEntity(
      pendingRecords:   pending,
      completedRecords: completed,
    );
  }
}
