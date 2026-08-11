library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../settings/domain/entities/location_settings_entity.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../../domain/entities/prayer_time_entity.dart';
import '../../domain/usecases/get_next_prayer.dart';

final class NextPrayerProvider extends ChangeNotifier {
  NextPrayerProvider({required GetNextPrayer getNextPrayer})
      : _getNextPrayer = getNextPrayer;

  final GetNextPrayer _getNextPrayer;

  Timer? _countdownTimer;
  NextPrayerResult? _nextPrayerResult;
  Duration _timeRemaining = Duration.zero;
  bool _isLoading = false;
  String? _errorMessage;

  NextPrayerResult? get nextPrayerResult => _nextPrayerResult;
  Duration get timeRemaining => _timeRemaining;
  PrayerTimeEntity? get nextPrayer => _nextPrayerResult?.prayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> start({
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) async {
    _stopTimer();
    _isLoading = true;
    notifyListeners();

    try {
      _nextPrayerResult = await _getNextPrayer(
        GetNextPrayerParams(
          now: DateTime.now(),
          location: location,
          settings: settings,
        ),
      );
      _isLoading = false;
      _updateTimeRemaining();
      _startTimer(location: location, settings: settings);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to get next prayer', error: e, tag: 'NextPrayerProvider');
      _isLoading = false;
      _errorMessage = 'Could not determine next prayer time.';
      notifyListeners();
    }
  }

  void pause() => _stopTimer();

  Future<void> resume({
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) =>
      start(location: location, settings: settings);

  void _startTimer({
    required LocationSettingsEntity location,
    required PrayerSettingsEntity settings,
  }) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();

      if (_timeRemaining == Duration.zero) {
        _stopTimer();
        start(location: location, settings: settings);
        return;
      }

      notifyListeners();
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _updateTimeRemaining() {
    if (_nextPrayerResult == null) {
      _timeRemaining = Duration.zero;
      return;
    }
    _timeRemaining = _nextPrayerResult!.timeRemaining(DateTime.now());
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
