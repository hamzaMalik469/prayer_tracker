library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_balance_entity.dart';
import '../../domain/entities/qada_plan_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../../domain/usecases/add_missed_prayers.dart';
import '../../domain/usecases/complete_qada_prayers.dart';
import '../../domain/usecases/get_qada_balance.dart';
import '../../domain/usecases/watch_qada_balance.dart';

final class QadaProvider extends ChangeNotifier {
  QadaProvider({
    required GetQadaBalance getQadaBalance,
    required WatchQadaBalance watchQadaBalance,
    required AddMissedPrayers addMissedPrayers,
    required CompleteQadaPrayers completeQadaPrayers,
  })  : _getQadaBalance = getQadaBalance,
        _watchQadaBalance = watchQadaBalance,
        _addMissedPrayers = addMissedPrayers,
        _completeQadaPrayers = completeQadaPrayers;

  final GetQadaBalance _getQadaBalance;
  final WatchQadaBalance _watchQadaBalance;
  final AddMissedPrayers _addMissedPrayers;
  final CompleteQadaPrayers _completeQadaPrayers;

  StreamSubscription<QadaBalanceEntity>? _balanceSubscription;

  QadaBalanceEntity _balance = const QadaBalanceEntity.zero();
  QadaPlanEntity? _plan;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  int _dailyTarget = 0;

  QadaBalanceEntity get balance => _balance;
  QadaPlanEntity? get plan => _plan;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  int get dailyTarget => _dailyTarget;
  bool get hasQada => _balance.total > 0;

  Future<void> initialise({required String userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _balance = await _getQadaBalance(GetQadaBalanceParams(userId: userId));
      _isLoading = false;
      _recomputePlan();
      notifyListeners();

      _balanceSubscription = _watchQadaBalance(
        WatchQadaBalanceParams(userId: userId),
      ).listen(
        (balance) {
          _balance = balance;
          _recomputePlan();
          notifyListeners();
        },
        onError: (Object e) {
          AppLogger.warning('Qada balance stream error', error: e, tag: 'QadaProvider');
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load Qada balance', error: e, tag: 'QadaProvider');
      _isLoading = false;
      _errorMessage = 'Could not load Qada balance.';
      notifyListeners();
    }
  }

  Future<bool> addMissed({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _balance = await _addMissedPrayers(
        AddMissedPrayersParams(
          userId: userId,
          prayerType: prayerType,
          quantity: quantity,
          notes: notes,
        ),
      );
      _isUpdating = false;
      _recomputePlan();
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Failed to add missed prayers', error: e, tag: 'QadaProvider');
      _isUpdating = false;
      _errorMessage = 'Could not add missed prayers.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeQada({
    required String userId,
    required PrayerType prayerType,
    required int quantity,
    String? notes,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _balance = await _completeQadaPrayers(
        CompleteQadaPrayersParams(
          userId: userId,
          prayerType: prayerType,
          quantity: quantity,
          notes: notes,
        ),
      );
      _isUpdating = false;
      _recomputePlan();
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Failed to complete Qada', error: e, tag: 'QadaProvider');
      _isUpdating = false;
      _errorMessage = 'Could not record Qada completion.';
      notifyListeners();
      return false;
    }
  }

  void updateDailyTarget(int target) {
    _dailyTarget = target;
    _recomputePlan();
    notifyListeners();
  }

  void _recomputePlan() {
    _plan = QadaPlanEntity.calculate(
      balance: _balance,
      dailyTarget: _dailyTarget,
      fromDate: DateTime.now(),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel();
    super.dispose();
  }
}
