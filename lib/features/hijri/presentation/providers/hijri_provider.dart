library;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/hijri_date_entity.dart';
import '../../domain/usecases/get_hijri_date.dart';

final class HijriProvider extends ChangeNotifier {
  HijriProvider({required GetHijriDate getHijriDate})
      : _getHijriDate = getHijriDate;

  final GetHijriDate _getHijriDate;

  HijriDateEntity? _todayHijri;
  bool _isLoading = false;

  HijriDateEntity? get todayHijri => _todayHijri;
  bool get isLoading => _isLoading;

  String get todayHijriFormatted => _todayHijri?.formatted ?? '';

  Future<void> loadTodayHijri() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayHijri = await _getHijriDate(
        GetHijriDateParams(date: DateTime.now()),
      );
    } catch (e) {
      AppLogger.error('Failed to load Hijri date', error: e, tag: 'HijriProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshForDate(DateTime date) async {
    try {
      _todayHijri = await _getHijriDate(GetHijriDateParams(date: date));
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to refresh Hijri date', error: e, tag: 'HijriProvider');
    }
  }
}
