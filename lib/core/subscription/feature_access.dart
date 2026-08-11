library;

enum PremiumFeature {
  advancedStatistics,
  yearlyStatistics,
  prayerConsistencyCharts,
  historicalTrends,
  advancedStreakInsights,
  streakTimeline,
  yearlyStreakHistory,
  advancedQadaPlanning,
  qadaDailyTargets,
  qadaProgressCharts,
  qadaEstimatedCompletion,
  fullHistoricalCalendar,
  yearlyCalendar,
  calendarAdvancedFiltering,
  advancedNotificationSchedules,
  perPrayerReminderOffsets,
  postPrayerReminders,
  multipleSavedLocations,
  travelMode,
  dashboardCustomisation,
  premiumThemes,
  customAccentColors,
  dataExport,
  advancedBackupControls,
  adFreeExperience,
  advancedQuranTracker,
  ramadanMode,
  advancedDhikr,
}

abstract class FeatureAccessService {
  bool canAccess(PremiumFeature feature);
  bool get isPremium;
}

final class FreeFeatureAccessService implements FeatureAccessService {
  const FreeFeatureAccessService();

  @override
  bool canAccess(PremiumFeature feature) => false;

  @override
  bool get isPremium => false;
}
