library;

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

abstract final class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

abstract final class AppElevation {
  static const double none = 0.0;
  static const double low = 1.0;
  static const double medium = 3.0;
  static const double high = 6.0;
}

abstract final class AppTouchTargets {
  static const double minimum = 44.0;
}

abstract final class PrayerIdentifiers {
  static const String fajr = 'fajr';
  static const String dhuhr = 'dhuhr';
  static const String asr = 'asr';
  static const String maghrib = 'maghrib';
  static const String isha = 'isha';

  static const List<String> ordered = [fajr, dhuhr, asr, maghrib, isha];
}

abstract final class PreferenceKeys {
  // Onboarding
  static const String onboardingCompleted = 'onboarding_completed';

  // Location
  static const String locationMode = 'location_mode';
  static const String lastLatitude = 'last_latitude';
  static const String lastLongitude = 'last_longitude';
  static const String manualCityName = 'manual_city_name';

  // Prayer settings
  static const String calculationMethod = 'calculation_method';
  static const String madhab = 'madhab';
  static const String highLatitudeRule = 'high_latitude_rule';

  // Appearance
  static const String themeMode = 'theme_mode';

  // Subscription cache
  static const String subscriptionStatusCache = 'subscription_status_cache';

  // Notifications
  static const String notificationsEnabled = 'notifications_master_enabled';

  // Guest user — NEW
  static const String guestUserId = 'guest_user_id';
}

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgetPassword = '/forgot-password';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String statistics = '/statistics';
  static const String qada = '/qada';
  static const String calendar = '/calendar';
  static const String premium = '/premium';
  static const String prayerDetail = '/prayer-detail';
}
