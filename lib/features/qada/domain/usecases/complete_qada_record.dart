library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/qada_record_entity.dart';
import '../repositories/qada_repository.dart';

final class CompleteQadaRecord
    implements UseCase<QadaRecordEntity, CompleteQadaRecordParams> {
  const CompleteQadaRecord(this._repository);
  final QadaRepository _repository;

  @override
  Future<QadaRecordEntity> call(CompleteQadaRecordParams params) =>
      _repository.completeQadaRecord(
        userId:        params.userId,
        qadaRecordId:  params.qadaRecordId,
        missedDate:    params.missedDate,
        prayerType:    params.prayerType,
      );
}

final class CompleteQadaRecordParams extends Equatable {
  const CompleteQadaRecordParams({
    required this.userId,
    required this.qadaRecordId,
    required this.missedDate,
    required this.prayerType,
  });

  final String userId;
  final String qadaRecordId;
  final DateTime missedDate;
  final PrayerType prayerType;

  @override
  List<Object> get props => [userId, qadaRecordId, missedDate, prayerType];
}
