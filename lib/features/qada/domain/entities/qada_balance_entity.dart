/// Represents the user's outstanding Qada prayer debt.
///
/// IMPORTANT: Qada is entirely separate from daily prayer tracking.
/// Completing a Qada Fajr does NOT affect today's Fajr status.
/// These are distinct domain concepts.
library;

import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entity.dart';

/// The outstanding Qada balance per prayer type.
final class QadaBalanceEntity extends Equatable {
  const QadaBalanceEntity({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  const QadaBalanceEntity.zero()
      : fajr = 0,
        dhuhr = 0,
        asr = 0,
        maghrib = 0,
        isha = 0;

  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  int get total => fajr + dhuhr + asr + maghrib + isha;

  int balanceFor(PrayerType type) => switch (type) {
        PrayerType.fajr => fajr,
        PrayerType.dhuhr => dhuhr,
        PrayerType.asr => asr,
        PrayerType.maghrib => maghrib,
        PrayerType.isha => isha,
        PrayerType.sunrise => 0,
      };

  QadaBalanceEntity copyWith({
    int? fajr,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return QadaBalanceEntity(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  /// Returns a new balance after adding [quantity] missed prayers of [type].
  QadaBalanceEntity addMissed(PrayerType type, int quantity) {
    assert(quantity > 0, 'Quantity must be positive');
    return switch (type) {
      PrayerType.fajr => copyWith(fajr: fajr + quantity),
      PrayerType.dhuhr => copyWith(dhuhr: dhuhr + quantity),
      PrayerType.asr => copyWith(asr: asr + quantity),
      PrayerType.maghrib => copyWith(maghrib: maghrib + quantity),
      PrayerType.isha => copyWith(isha: isha + quantity),
      PrayerType.sunrise => this,
    };
  }

  /// Returns a new balance after completing [quantity] Qada of [type].
  /// Balance cannot go below zero.
  QadaBalanceEntity completeQada(PrayerType type, int quantity) {
    assert(quantity > 0, 'Quantity must be positive');
    return switch (type) {
      PrayerType.fajr => copyWith(fajr: (fajr - quantity).clamp(0, fajr)),
      PrayerType.dhuhr => copyWith(dhuhr: (dhuhr - quantity).clamp(0, dhuhr)),
      PrayerType.asr => copyWith(asr: (asr - quantity).clamp(0, asr)),
      PrayerType.maghrib =>
        copyWith(maghrib: (maghrib - quantity).clamp(0, maghrib)),
      PrayerType.isha => copyWith(isha: (isha - quantity).clamp(0, isha)),
      PrayerType.sunrise => this,
    };
  }

  @override
  List<Object> get props => [fajr, dhuhr, asr, maghrib, isha];
}
