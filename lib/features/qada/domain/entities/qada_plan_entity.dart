/// Qada planning entity — Premium feature.
///
/// Provides a mathematical estimate for Qada completion.
/// IMPORTANT: This is a planning tool only. The app must
/// never present completion estimates as religious rulings.
library;

import 'package:equatable/equatable.dart';

import 'qada_balance_entity.dart';

final class QadaPlanEntity extends Equatable {
  const QadaPlanEntity({
    required this.balance,
    required this.dailyTarget,
    required this.estimatedCompletionDate,
    required this.daysRemaining,
  });

  factory QadaPlanEntity.calculate({
    required QadaBalanceEntity balance,
    required int dailyTarget,
    required DateTime fromDate,
  }) {
    if (dailyTarget <= 0 || balance.total == 0) {
      return QadaPlanEntity(
        balance: balance,
        dailyTarget: dailyTarget,
        estimatedCompletionDate: null,
        daysRemaining: null,
      );
    }

    final daysNeeded = (balance.total / dailyTarget).ceil();
    final completionDate = fromDate.add(Duration(days: daysNeeded));

    return QadaPlanEntity(
      balance: balance,
      dailyTarget: dailyTarget,
      estimatedCompletionDate: completionDate,
      daysRemaining: daysNeeded,
    );
  }

  final QadaBalanceEntity balance;
  final int dailyTarget;

  /// Mathematical estimate only — not a religious ruling.
  final DateTime? estimatedCompletionDate;
  final int? daysRemaining;

  bool get hasEstimate => estimatedCompletionDate != null;

  @override
  List<Object?> get props => [
        balance,
        dailyTarget,
        estimatedCompletionDate,
        daysRemaining,
      ];
}
