library;

import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../entities/qada_balance_entity.dart';
import '../repositories/qada_repository.dart';

final class AddMissedPrayers
    implements UseCase<QadaBalanceEntity, AddMissedPrayersParams> {
  const AddMissedPrayers(this._repository);

  final QadaRepository _repository;

  @override
  Future<QadaBalanceEntity> call(AddMissedPrayersParams params) =>
      _repository.addMissedPrayers(
        userId: params.userId,
        prayerType: params.prayerType,
        quantity: params.quantity,
        notes: params.notes,
      );
}

final class AddMissedPrayersParams extends Equatable {
  const AddMissedPrayersParams({
    required this.userId,
    required this.prayerType,
    required this.quantity,
    this.notes,
  });

  final String userId;
  final PrayerType prayerType;
  final int quantity;
  final String? notes;

  @override
  List<Object?> get props => [userId, prayerType, quantity, notes];
}
