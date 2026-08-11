/// Represents the user's onboarding progress.
library;

import 'package:equatable/equatable.dart';

final class OnboardingStateEntity extends Equatable {
  const OnboardingStateEntity({
    required this.isCompleted,
    required this.hasSelectedCalculationMethod,
    required this.hasSelectedMadhab,
    required this.hasConfiguredLocation,
    required this.hasGrantedNotificationPermission,
  });

  const OnboardingStateEntity.initial()
      : isCompleted = false,
        hasSelectedCalculationMethod = false,
        hasSelectedMadhab = false,
        hasConfiguredLocation = false,
        hasGrantedNotificationPermission = false;

  final bool isCompleted;
  final bool hasSelectedCalculationMethod;
  final bool hasSelectedMadhab;
  final bool hasConfiguredLocation;
  final bool hasGrantedNotificationPermission;

  OnboardingStateEntity copyWith({
    bool? isCompleted,
    bool? hasSelectedCalculationMethod,
    bool? hasSelectedMadhab,
    bool? hasConfiguredLocation,
    bool? hasGrantedNotificationPermission,
  }) {
    return OnboardingStateEntity(
      isCompleted: isCompleted ?? this.isCompleted,
      hasSelectedCalculationMethod:
          hasSelectedCalculationMethod ?? this.hasSelectedCalculationMethod,
      hasSelectedMadhab: hasSelectedMadhab ?? this.hasSelectedMadhab,
      hasConfiguredLocation:
          hasConfiguredLocation ?? this.hasConfiguredLocation,
      hasGrantedNotificationPermission: hasGrantedNotificationPermission ??
          this.hasGrantedNotificationPermission,
    );
  }

  @override
  List<Object> get props => [
        isCompleted,
        hasSelectedCalculationMethod,
        hasSelectedMadhab,
        hasConfiguredLocation,
        hasGrantedNotificationPermission,
      ];
}
