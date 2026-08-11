library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/hijri_date_entity.dart';
import '../repositories/hijri_repository.dart';

final class GetHijriDate
    implements UseCase<HijriDateEntity, GetHijriDateParams> {
  const GetHijriDate(this._repository);

  final HijriRepository _repository;

  @override
  Future<HijriDateEntity> call(GetHijriDateParams params) async =>
      _repository.toHijri(params.date);
}

final class GetHijriDateParams extends Equatable {
  const GetHijriDateParams({required this.date});

  final DateTime date;

  @override
  List<Object> get props => [date];
}
