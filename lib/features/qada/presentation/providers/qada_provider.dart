library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/entities/qada_summary_entity.dart';
import '../../domain/usecases/add_qada_record.dart';
import '../../domain/usecases/complete_qada_record.dart';
import '../../domain/usecases/get_qada_summary.dart';
import '../../domain/usecases/watch_qada_summary.dart';

final class QadaProvider extends ChangeNotifier {
  QadaProvider({
    required GetQadaSummary getQadaSummary,
    required WatchQadaSummary watchQadaSummary,
    required AddQadaRecord addQadaRecord,
    required CompleteQadaRecord completeQadaRecord,
  })  : _getQadaSummary     = getQadaSummary,
        _watchQadaSummary   = watchQadaSummary,
        _addQadaRecord      = addQadaRecord,
        _completeQadaRecord = completeQadaRecord;

  final GetQadaSummary     _getQadaSummary;
  final WatchQadaSummary   _watchQadaSummary;
  final AddQadaRecord      _addQadaRecord;
  final CompleteQadaRecord _completeQadaRecord;

  StreamSubscription<QadaSummaryEntity>? _subscription;

  QadaSummaryEntity _summary   = const QadaSummaryEntity.empty();
  bool              _isLoading = false;
  bool              _isUpdating = false;
  String?           _errorMessage;

  QadaSummaryEntity get summary      => _summary;
  bool              get isLoading    => _isLoading;
  bool              get isUpdating   => _isUpdating;
  String?           get errorMessage => _errorMessage;
  bool              get hasPending   => _summary.totalPending > 0;
  int               get totalPending => _summary.totalPending;

  Future<void> initialise({required String userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _summary   = await _getQadaSummary(GetQadaSummaryParams(userId: userId));
      _isLoading = false;
      notifyListeners();

      _subscription = _watchQadaSummary(
        WatchQadaSummaryParams(userId: userId),
      ).listen(
        (summary) {
          _summary = summary;
          notifyListeners();
        },
        onError: (Object e) {
          AppLogger.warning('Qada stream error', error: e, tag: 'QadaProvider');
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load Qada', error: e, tag: 'QadaProvider');
      _isLoading    = false;
      _errorMessage = 'Could not load Qada records.';
      notifyListeners();
    }
  }

  /// Add a missed prayer to Qada for a specific date.
  Future<bool> addQadaRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  }) async {
    _isUpdating   = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _addQadaRecord(
        AddQadaRecordParams(
          userId:     userId,
          missedDate: missedDate,
          prayerType: prayerType,
          notes:      notes,
        ),
      );
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('addQadaRecord failed', error: e, tag: 'QadaProvider');
      _isUpdating   = false;
      _errorMessage = 'Could not add Qada record.';
      notifyListeners();
      return false;
    }
  }

  /// Complete a specific Qada record — updates original prayer to qadaCompleted.
  Future<bool> completeQadaRecord({
    required String userId,
    required QadaRecordEntity record,
  }) async {
    _isUpdating   = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _completeQadaRecord(
        CompleteQadaRecordParams(
          userId:       userId,
          qadaRecordId: record.id,
          missedDate:   record.missedDate,
          prayerType:   record.prayerType,
        ),
      );
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('completeQadaRecord failed', error: e, tag: 'QadaProvider');
      _isUpdating   = false;
      _errorMessage = 'Could not complete Qada record.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
