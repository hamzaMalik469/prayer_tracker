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
  })  : _getQadaSummary = getQadaSummary,
        _watchQadaSummary = watchQadaSummary,
        _addQadaRecord = addQadaRecord,
        _completeQadaRecord = completeQadaRecord;

  final GetQadaSummary _getQadaSummary;
  final WatchQadaSummary _watchQadaSummary;
  final AddQadaRecord _addQadaRecord;
  final CompleteQadaRecord _completeQadaRecord;

  StreamSubscription<QadaSummaryEntity>? _subscription;

  QadaSummaryEntity _summary = const QadaSummaryEntity.empty();
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _userId;

  QadaSummaryEntity get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  bool get hasPending => _summary.totalPending > 0;
  int get totalPending => _summary.totalPending;

  Future<void> initialise({required String userId}) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _summary = await _getQadaSummary(GetQadaSummaryParams(userId: userId));
      _isLoading = false;
      notifyListeners();

      AppLogger.info(
        'Qada loaded: ${_summary.totalPending} pending, '
        '${_summary.totalCompleted} completed.',
        tag: 'QadaProvider',
      );

      // Watch for real-time changes.
      _subscription?.cancel();
      _subscription = _watchQadaSummary(
        WatchQadaSummaryParams(userId: userId),
      ).listen(
        (summary) {
          _summary = summary;
          notifyListeners();
        },
        onError: (Object e) {
          AppLogger.warning(
            'Qada stream error',
            error: e,
            tag: 'QadaProvider',
          );
        },
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load Qada',
        error: e,
        tag: 'QadaProvider',
      );
      _isLoading = false;
      _errorMessage = 'Could not load Qada records.';
      notifyListeners();
    }
  }

  /// Refreshes Qada data from repository.
  Future<void> _refresh() async {
    if (_userId == null) return;
    try {
      _summary = await _getQadaSummary(
        GetQadaSummaryParams(userId: _userId!),
      );
      notifyListeners();
    } catch (e) {
      AppLogger.warning('Qada refresh failed', error: e, tag: 'QadaProvider');
    }
  }

  Future<bool> addQadaRecord({
    required String userId,
    required DateTime missedDate,
    required PrayerType prayerType,
    String? notes,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _addQadaRecord(
        AddQadaRecordParams(
          userId: userId,
          missedDate: missedDate,
          prayerType: prayerType,
          notes: notes,
        ),
      );
      _isUpdating = false;

      // Force immediate refresh to update UI.
      await _refresh();

      AppLogger.info(
        'Qada record added: ${prayerType.identifier}',
        tag: 'QadaProvider',
      );

      return true;
    } catch (e) {
      AppLogger.error(
        'addQadaRecord failed',
        error: e,
        tag: 'QadaProvider',
      );
      _isUpdating = false;
      _errorMessage = 'Could not add Qada record.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeQadaRecord({
    required String userId,
    required QadaRecordEntity record,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _completeQadaRecord(
        CompleteQadaRecordParams(
          userId: userId,
          qadaRecordId: record.id,
          missedDate: record.missedDate,
          prayerType: record.prayerType,
        ),
      );
      _isUpdating = false;

      // Force immediate refresh to update UI.
      await _refresh();

      AppLogger.info(
        'Qada completed: ${record.prayerType.identifier}',
        tag: 'QadaProvider',
      );

      return true;
    } catch (e) {
      AppLogger.error(
        'completeQadaRecord failed',
        error: e,
        tag: 'QadaProvider',
      );
      _isUpdating = false;
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
