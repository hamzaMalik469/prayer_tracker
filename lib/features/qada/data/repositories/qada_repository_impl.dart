library;

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';
import '../../domain/repositories/qada_repository.dart';
import '../datasources/qada_remote_datasource.dart';

final class QadaRepositoryImpl implements QadaRepository {
  const QadaRepositoryImpl({required QadaRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final QadaRemoteDataSource _dataSource;

  @override
  Future<QadaSummaryEntity> getQadaSummary({required String userId}) =>
      _dataSource.getSummary(userId: userId);

  @override
  Stream<QadaSummaryEntity> watchQadaSummary({required String userId}) =>
      _dataSource.watchSummary(userId: userId);

  @override
  Future<QadaRecordEntity> addQadaRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  }) =>
      _dataSource.addRecord(
        userId:     userId,
        missedDate: missedDate,
        prayerType: prayerType,
        notes:      notes,
      );

  @override
  Future<QadaRecordEntity> completeQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) =>
      _dataSource.completeRecord(
        userId:       userId,
        qadaRecordId: qadaRecordId,
        missedDate:   missedDate,
        prayerType:   prayerType,
      );

  @override
  Future<List<QadaRecordEntity>> getQadaRecordsForDate({
    required String userId,
    required DateTime date,
  }) =>
      _dataSource.getRecordsForDate(userId: userId, date: date);

  @override
  Future<void> deleteQadaRecord({
    required String userId,
    required String qadaRecordId,
    required DateTime missedDate,
    required PrayerType prayerType,
  }) =>
      _dataSource.deleteRecord(
        userId:       userId,
        qadaRecordId: qadaRecordId,
        missedDate:   missedDate,
        prayerType:   prayerType,
      );
}
