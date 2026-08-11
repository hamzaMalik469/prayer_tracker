library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_balance_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/repositories/qada_repository.dart';
import '../datasources/qada_remote_datasource.dart';

final class QadaRepositoryImpl implements QadaRepository {
  const QadaRepositoryImpl({required QadaRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final QadaRemoteDataSource _dataSource;

  @override
  Future<QadaBalanceEntity> getQadaBalance({required String userId}) =>
      _dataSource.getBalance(userId: userId);

  @override
  Stream<QadaBalanceEntity> watchQadaBalance({required String userId}) =>
      _dataSource.watchBalance(userId: userId);

  @override
  Future<QadaBalanceEntity> addMissedPrayers({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) =>
      _dataSource.addMissed(
        userId: userId,
        prayerType: prayerType,
        quantity: quantity,
        notes: notes,
      );

  @override
  Future<QadaBalanceEntity> completeQadaPrayers({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) =>
      _dataSource.completeQada(
        userId: userId,
        prayerType: prayerType,
        quantity: quantity,
        notes: notes,
      );

  @override
  Future<List<QadaRecordEntity>> getQadaHistory({
    required String userId,
    int? limit,
  }) =>
      _dataSource.getHistory(userId: userId, limit: limit);

  @override
  Future<int> getDailyQadaTarget({required String userId}) =>
      _dataSource.getDailyTarget(userId: userId);

  @override
  Future<void> saveDailyQadaTarget({
    required String userId,
    required int target,
  }) =>
      _dataSource.saveDailyTarget(userId: userId, target: target);
}
