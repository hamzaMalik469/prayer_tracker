library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/qada_record_entity.dart';
import '../repositories/qada_repository.dart';

final class AddQadaRecord
    implements UseCase<QadaRecordEntity, AddQadaRecordParams> {
  const AddQadaRecord(this._repository);
  final QadaRepository _repository;

  @override
  Future<QadaRecordEntity> call(AddQadaRecordParams params) =>
      _repository.addQadaRecord(
        userId:      params.userId,
        missedDate:  params.missedDate,
        prayerType:  params.prayerType,
        notes:       params.notes,
      );
}

final class AddQadaRecordParams extends Equatable {
  const AddQadaRecordParams({
    required this.userId,
    required this.missedDate,
    required this.prayerType,
    this.notes,
  });

  final String userId;
  final DateTime missedDate;
  final PrayerType prayerType;
  final String? notes;

  @override
  List<Object?> get props => [userId, missedDate, prayerType, notes];
}
