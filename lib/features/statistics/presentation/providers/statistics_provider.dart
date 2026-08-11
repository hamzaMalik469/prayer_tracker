library;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/prayer_statistics_entity.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/usecases/get_statistics.dart';
import '../../domain/usecases/get_streak.dart';

enum StatsPeriod { weekly, monthly, yearly }

final class StatisticsProvider extends ChangeNotifier {
  StatisticsProvider({
    required GetStatistics getStatistics,
    required GetStreak getStreak,
  })  : _getStatistics = getStatistics,
        _getStreak = getStreak;

  final GetStatistics _getStatistics;
  final GetStreak _getStreak;

  PrayerStatisticsEntity? _statistics;
  StreakEntity _streak = const StreakEntity.zero();
  StatsPeriod _selectedPeriod = StatsPeriod.weekly;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  PrayerStatisticsEntity? get statistics => _statistics;
  StreakEntity get streak => _streak;
  StatsPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialise({required String userId}) async {
    _userId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([
      _loadStreak(),
      _loadStatistics(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> changePeriod({required StatsPeriod period}) async {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();

    if (_userId == null) return;
    await _loadStatistics();
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    await Future.wait([
      _loadStreak(),
      _loadStatistics(),
    ]);
  }

  Future<void> _loadStreak() async {
    if (_userId == null) return;
    try {
      _streak = await _getStreak(GetStreakParams(userId: _userId!));
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Failed to load streak',
        error: e,
        tag: 'StatisticsProvider',
      );
    }
  }

  Future<void> _loadStatistics() async {
    if (_userId == null) return;
    try {
      final range = _dateRangeForPeriod(_selectedPeriod);
      _statistics = await _getStatistics(
        GetStatisticsParams(
          userId: _userId!,
          startDate: range.$1,
          endDate: range.$2,
        ),
      );
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Failed to load statistics',
        error: e,
        tag: 'StatisticsProvider',
      );
      _errorMessage = 'Could not load statistics.';
      notifyListeners();
    }
  }

  (DateTime, DateTime) _dateRangeForPeriod(StatsPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (period) {
      StatsPeriod.weekly => (
          today.subtract(const Duration(days: 6)),
          today,
        ),
      StatsPeriod.monthly => (
          DateTime(now.year, now.month, 1),
          today,
        ),
      StatsPeriod.yearly => (
          DateTime(now.year, 1, 1),
          today,
        ),
    };
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
