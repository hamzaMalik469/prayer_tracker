library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/qada_balance_entity.dart';
import '../entities/qada_record_entity.dart';

abstract interface class QadaRepository {
  /// Returns the current Qada balance for [userId].
  Future<QadaBalanceEntity> getQadaBalance({required String userId});

  /// Watches the Qada balance in real time.
  Stream<QadaBalanceEntity> watchQadaBalance({required String userId});

  /// Adds [quantity] missed prayers of [prayerType] to the balance.
  Future<QadaBalanceEntity> addMissedPrayers({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  });

  /// Records [quantity] completed Qada prayers of [prayerType].
  Future<QadaBalanceEntity> completeQadaPrayers({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  });

  /// Returns the full transaction history for [userId].
  Future<List<QadaRecordEntity>> getQadaHistory({
    required String userId,
    int? limit,
  });

  /// Returns the daily Qada target (stored in settings).
  Future<int> getDailyQadaTarget({required String userId});

  /// Saves the daily Qada target.
  Future<void> saveDailyQadaTarget({
    required String userId,
    required int target,
  });
}
