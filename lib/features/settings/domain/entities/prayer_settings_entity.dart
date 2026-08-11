/// User's prayer calculation preferences.
library;

import 'package:equatable/equatable.dart';

enum CalculationMethodEntity {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  moonsightingCommittee,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  morocco,
  other,
}

extension CalculationMethodEntityExtension on CalculationMethodEntity {
  String get displayName => switch (this) {
        CalculationMethodEntity.muslimWorldLeague => 'Muslim World League',
        CalculationMethodEntity.egyptian => 'Egyptian General Authority',
        CalculationMethodEntity.karachi =>
          'University of Islamic Sciences, Karachi',
        CalculationMethodEntity.ummAlQura => 'Umm Al-Qura, Makkah',
        CalculationMethodEntity.dubai => 'Dubai',
        CalculationMethodEntity.moonsightingCommittee =>
          'Moonsighting Committee',
        CalculationMethodEntity.northAmerica => 'ISNA (North America)',
        CalculationMethodEntity.kuwait => 'Kuwait',
        CalculationMethodEntity.qatar => 'Qatar',
        CalculationMethodEntity.singapore => 'Singapore',
        CalculationMethodEntity.tehran => 'Tehran',
        CalculationMethodEntity.turkey => 'Turkey (Diyanet)',
        CalculationMethodEntity.morocco => 'Morocco',
        CalculationMethodEntity.other => 'Other / Custom',
      };
}

enum MadhabEntity {
  shafi,
  hanafi,
}

extension MadhabEntityExtension on MadhabEntity {
  String get displayName => switch (this) {
        MadhabEntity.shafi => "Shafi'i, Maliki, Hanbali",
        MadhabEntity.hanafi => 'Hanafi',
      };
}

enum HighLatitudeRuleEntity {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
  none,
}

extension HighLatitudeRuleEntityExtension on HighLatitudeRuleEntity {
  String get displayName => switch (this) {
        HighLatitudeRuleEntity.middleOfTheNight => 'Middle of the Night',
        HighLatitudeRuleEntity.seventhOfTheNight => 'Seventh of the Night',
        HighLatitudeRuleEntity.twilightAngle => 'Twilight Angle',
        HighLatitudeRuleEntity.none => 'None',
      };
}

final class PrayerSettingsEntity extends Equatable {
  const PrayerSettingsEntity({
    required this.calculationMethod,
    required this.madhab,
    required this.highLatitudeRule,
  });

  const PrayerSettingsEntity.defaults()
      : calculationMethod = CalculationMethodEntity.muslimWorldLeague,
        madhab = MadhabEntity.shafi,
        highLatitudeRule = HighLatitudeRuleEntity.none;

  final CalculationMethodEntity calculationMethod;
  final MadhabEntity madhab;
  final HighLatitudeRuleEntity highLatitudeRule;

  PrayerSettingsEntity copyWith({
    CalculationMethodEntity? calculationMethod,
    MadhabEntity? madhab,
    HighLatitudeRuleEntity? highLatitudeRule,
  }) {
    return PrayerSettingsEntity(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    );
  }

  @override
  List<Object> get props => [calculationMethod, madhab, highLatitudeRule];
}
