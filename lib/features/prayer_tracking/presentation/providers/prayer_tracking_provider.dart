library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/daily_prayer_summary_entity.dart';
import '../../domain/entities/prayer_record_entity.dart';
import '../../domain/usecases/get_daily_summary.dart';
import '../../domain/usecases/record_prayer.dart';
import '../../domain/usecases/watch_daily_summary.dart';

final class PrayerTrackingProvider extends ChangeNotifier {
  PrayerTrackingProvider({
    required GetDailySummary getDailySummary,
    required WatchDailySummary watchDailySummary,
    required RecordPrayer recordPrayer,
  })  : _getDailySummary = getDailySummary,
        _watchDailySummary = watchDailySummary,
        _recordPrayer = recordPrayer;

  final GetDailySummary _getDailySummary;
  final WatchDailySummary _watchDailySummary;
  final RecordPrayer _recordPrayer;

  StreamSubscription<DailyPrayerSummaryEntity>? _summarySubscription;

  DailyPrayerSummaryEntity? _todaySummary;
  DateTime _currentDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecording = false;
  String? _errorMessage;

  final Set<PrayerType> _recordingPrayers = {};

  DailyPrayerSummaryEntity? get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  String? get errorMessage => _errorMessage;

  bool isRecordingPrayer(PrayerType type) => _recordingPrayers.contains(type);

  PrayerStatus statusFor(PrayerType type) =>
      _todaySummary?.statusFor(type) ?? PrayerStatus.notRecorded;

  int get prayedCount => _todaySummary?.prayedCount ?? 0;
  int get missedCount => _todaySummary?.missedCount ?? 0;
  bool get isFullyCompleted => _todaySummary?.isFullyCompleted ?? false;
  double get completionPercentage => _todaySummary?.completionPercentage ?? 0;

  Future<void> initialise({required String userId}) async {
    _currentDate = DateTime.now();
    _isLoading = true;
    notifyListeners();

    try {
      _todaySummary = await _getDailySummary(
        GetDailySummaryParams(userId: userId, date: _currentDate),
      );
      _isLoading = false;
      notifyListeners();

      _subscribeToSummary(userId: userId);
    } catch (e) {
      AppLogger.error('Failed to load today summary', error: e, tag: 'PrayerTrackingProvider');
      _isLoading = false;
      _errorMessage = "Could not load today's prayers.";
      notifyListeners();
    }
  }

  Future<bool> recordPrayer({
    required String userId,
    required PrayerType prayerType,
    required PrayerStatus status,
  }) async {
    _recordingPrayers.add(prayerType);
    _errorMessage = null;
    notifyListeners();

    try {
      await _recordPrayer(
        RecordPrayerParams(
          userId: userId,
          date: _currentDate,
          prayerType: prayerType,
          status: status,
        ),
      );
      _recordingPrayers.remove(prayerType);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Failed to record prayer', error: e, tag: 'PrayerTrackingProvider');
      _recordingPrayers.remove(prayerType);
      _errorMessage = 'Could not save prayer. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePrayer({
    required String userId,
    required PrayerType prayerType,
  }) async {
    final current = statusFor(prayerType);
    final newStatus = current.isCompleted
        ? PrayerStatus.notRecorded
        : PrayerStatus.prayed;

    return recordPrayer(
      userId: userId,
      prayerType: prayerType,
      status: newStatus,
    );
  }

  Future<bool> markMissed({
    required String userId,
    required PrayerType prayerType,
  }) =>
      recordPrayer(
        userId: userId,
        prayerType: prayerType,
        status: PrayerStatus.missed,
      );

  Future<void> onDateChanged({required String userId}) async {
    _summarySubscription?.cancel();
    _todaySummary = null;
    _recordingPrayers.clear();
    await initialise(userId: userId);
  }

  void _subscribeToSummary({required String userId}) {
    _summarySubscription?.cancel();
    _summarySubscription = _watchDailySummary(
      WatchDailySummaryParams(userId: userId, date: _currentDate),
    ).listen(
      (summary) {
        _todaySummary = summary;
        notifyListeners();
      },
      onError: (Object e) {
        AppLogger.warning('Daily summary stream error', error: e, tag: 'PrayerTrackingProvider');
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _summarySubscription?.cancel();
    super.dispose();
  }
}
