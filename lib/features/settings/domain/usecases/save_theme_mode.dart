library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

final class SaveThemeMode implements UseCase<void, SaveThemeModeParams> {
  const SaveThemeMode(this._repository);

  final SettingsRepository _repository;

  @override
  Future<void> call(SaveThemeModeParams params) =>
      _repository.saveThemeMode(params.themeMode);
}

final class SaveThemeModeParams extends Equatable {
  const SaveThemeModeParams({required this.themeMode});

  final ThemeMode themeMode;

  @override
  List<Object> get props => [themeMode];
}
