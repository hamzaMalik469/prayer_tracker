library;

import '../../../../core/helpers/hijri_calculator.dart';
import '../../domain/entities/hijri_date_entity.dart';
import '../../domain/repositories/hijri_repository.dart';

final class HijriRepositoryImpl implements HijriRepository {
  const HijriRepositoryImpl();

  @override
  HijriDateEntity toHijri(DateTime date) => HijriCalculator.toHijri(date);

  @override
  HijriDateEntity todayHijri() => HijriCalculator.toHijri(DateTime.now());
}
