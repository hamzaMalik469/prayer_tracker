/// Firestore Qada data source.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_balance_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../models/qada_model.dart';

abstract interface class QadaRemoteDataSource {
  Future<QadaBalanceEntity> getBalance({required String userId});
  Stream<QadaBalanceEntity> watchBalance({required String userId});

  Future<QadaBalanceEntity> addMissed({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  });

  Future<QadaBalanceEntity> completeQada({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  });

  Future<List<QadaRecordEntity>> getHistory({
    required String userId,
    int? limit,
  });

  Future<int> getDailyTarget({required String userId});
  Future<void> saveDailyTarget({required String userId, required int target});
}

final class QadaRemoteDataSourceImpl implements QadaRemoteDataSource {
  QadaRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    Uuid? uuid,
  })  : _firestore = firestore,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  DocumentReference<Map<String, dynamic>> _balanceDoc(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.settings)
          .doc(FirestoreDocuments.qadaBalance);

  CollectionReference<Map<String, dynamic>> _historyRef(String userId) =>
      _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.qadaRecords);

  @override
  Future<QadaBalanceEntity> getBalance({required String userId}) async {
    try {
      final snap = await _balanceDoc(userId).get();
      if (!snap.exists || snap.data() == null) {
        return const QadaBalanceEntity.zero();
      }
      return QadaBalanceModel.fromFirestore(snap.data()!);
    } catch (e) {
      AppLogger.error('getQadaBalance failed', error: e, tag: 'QadaDS');
      throw DatabaseFailure(message: 'Failed to load Qada balance.');
    }
  }

  @override
  Stream<QadaBalanceEntity> watchBalance({required String userId}) {
    return _balanceDoc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const QadaBalanceEntity.zero();
      }
      return QadaBalanceModel.fromFirestore(snap.data()!);
    }).handleError((Object e) {
      AppLogger.error('watchQadaBalance error', error: e, tag: 'QadaDS');
    });
  }

  @override
  Future<QadaBalanceEntity> addMissed({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final balanceSnap = await tx.get(_balanceDoc(userId));
        final currentBalance = balanceSnap.exists && balanceSnap.data() != null
            ? QadaBalanceModel.fromFirestore(balanceSnap.data()!)
            : const QadaBalanceEntity.zero();

        final updated = currentBalance.addMissed(prayerType, quantity);

        tx.set(_balanceDoc(userId), QadaBalanceModel.toFirestore(updated));

        // Write transaction record.
        final record = QadaRecordEntity(
          id: _uuid.v4(),
          userId: userId,
          prayerType: prayerType,
          transactionType: QadaTransactionType.added,
          quantity: quantity,
          createdAt: DateTime.now(),
          notes: notes,
        );
        tx.set(
          _historyRef(userId).doc(record.id),
          QadaRecordModel.toFirestore(record),
        );

        return updated;
      });
    } catch (e) {
      AppLogger.error('addMissedQada failed', error: e, tag: 'QadaDS');
      throw DatabaseFailure(message: 'Failed to add missed prayers.');
    }
  }

  @override
  Future<QadaBalanceEntity> completeQada({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final balanceSnap = await tx.get(_balanceDoc(userId));
        final currentBalance = balanceSnap.exists && balanceSnap.data() != null
            ? QadaBalanceModel.fromFirestore(balanceSnap.data()!)
            : const QadaBalanceEntity.zero();

        final updated = currentBalance.completeQada(prayerType, quantity);

        tx.set(_balanceDoc(userId), QadaBalanceModel.toFirestore(updated));

        // Write transaction record.
        final record = QadaRecordEntity(
          id: _uuid.v4(),
          userId: userId,
          prayerType: prayerType,
          transactionType: QadaTransactionType.completed,
          quantity: quantity,
          createdAt: DateTime.now(),
          notes: notes,
        );
        tx.set(
          _historyRef(userId).doc(record.id),
          QadaRecordModel.toFirestore(record),
        );

        return updated;
      });
    } catch (e) {
      AppLogger.error('completeQada failed', error: e, tag: 'QadaDS');
      throw DatabaseFailure(message: 'Failed to complete Qada prayers.');
    }
  }

  @override
  Future<List<QadaRecordEntity>> getHistory({
    required String userId,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _historyRef(userId)
          .orderBy(FirestoreFields.createdAt, descending: true);

      if (limit != null) query = query.limit(limit);

      final snap = await query.get();
      return snap.docs
          .map((d) => QadaRecordModel.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      AppLogger.error('getQadaHistory failed', error: e, tag: 'QadaDS');
      throw DatabaseFailure(message: 'Failed to load Qada history.');
    }
  }

  @override
  Future<int> getDailyTarget({required String userId}) async {
    try {
      final snap = await _balanceDoc(userId).get();
      return (snap.data()?['dailyTarget'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveDailyTarget({
    required String userId,
    required int target,
  }) async {
    try {
      await _balanceDoc(userId).set(
        {'dailyTarget': target},
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.error('saveDailyTarget failed', error: e, tag: 'QadaDS');
      throw DatabaseFailure(message: 'Failed to save daily target.');
    }
  }
}
