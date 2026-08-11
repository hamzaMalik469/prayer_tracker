library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/subscription/feature_access.dart';
import 'core/subscription/subscription_domain.dart';
import 'core/subscription/subscription_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/usecases/create_account.dart';
import 'features/auth/domain/usecases/delete_account.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/send_password_reset.dart';
import 'features/auth/domain/usecases/sign_in_with_email.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/watch_auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/hijri/domain/usecases/get_hijri_date.dart';
import 'features/hijri/presentation/providers/hijri_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/cancel_all_notifications.dart';
import 'features/notifications/domain/usecases/get_notification_settings.dart';
import 'features/notifications/domain/usecases/request_notification_permission.dart';
import 'features/notifications/domain/usecases/save_notification_settings.dart';
import 'features/notifications/domain/usecases/schedule_prayer_notifications.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'features/onboarding/domain/usecases/complete_onboarding.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';
import 'features/prayer_times/domain/usecases/get_next_prayer.dart';
import 'features/prayer_times/domain/usecases/get_prayer_times.dart';
import 'features/prayer_times/presentation/providers/next_prayer_provider.dart';
import 'features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'features/prayer_tracking/domain/usecases/get_daily_summary.dart';
import 'features/prayer_tracking/domain/usecases/record_prayer.dart';
import 'features/prayer_tracking/domain/usecases/watch_daily_summary.dart';
import 'features/prayer_tracking/presentation/providers/prayer_tracking_provider.dart';
import 'features/qada/domain/usecases/add_missed_prayers.dart';
import 'features/qada/domain/usecases/complete_qada_prayers.dart';
import 'features/qada/domain/usecases/get_qada_balance.dart';
import 'features/qada/domain/usecases/watch_qada_balance.dart';
import 'features/qada/presentation/providers/qada_provider.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/save_location_settings.dart';
import 'features/settings/domain/usecases/save_prayer_settings.dart';
import 'features/settings/domain/usecases/save_theme_mode.dart';
import 'features/settings/domain/usecases/watch_settings.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/statistics/domain/usecases/get_statistics.dart';
import 'features/statistics/domain/usecases/get_streak.dart';
import 'features/statistics/presentation/providers/statistics_provider.dart';

class DailyDeenApp extends StatelessWidget {
  const DailyDeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FeatureAccessService>(
          create: (_) => sl<FeatureAccessService>(),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(
            repository: sl<SubscriptionRepository>(),
            featureAccessService: sl<FeatureAccessService>(),
          )..initialise(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            getCurrentUser: sl<GetCurrentUser>(),
            watchAuthState: sl<WatchAuthState>(),
            signInWithEmail: sl<SignInWithEmail>(),
            createAccount: sl<CreateAccount>(),
            signInWithGoogle: sl<SignInWithGoogle>(),
            signOut: sl<SignOut>(),
            sendPasswordReset: sl<SendPasswordReset>(),
            deleteAccount: sl<DeleteAccount>(),
          )..initialise(),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(
            checkOnboardingStatus: sl<CheckOnboardingStatus>(),
            completeOnboarding: sl<CompleteOnboarding>(),
          )..checkStatus(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            getSettings: sl<GetSettings>(),
            watchSettings: sl<WatchSettings>(),
            savePrayerSettings: sl<SavePrayerSettings>(),
            saveLocationSettings: sl<SaveLocationSettings>(),
            saveThemeMode: sl<SaveThemeMode>(),
          )..initialise(),
        ),
        ChangeNotifierProvider<PrayerTimesProvider>(
          create: (_) => PrayerTimesProvider(
            getPrayerTimes: sl<GetPrayerTimes>(),
          ),
        ),
        ChangeNotifierProvider<NextPrayerProvider>(
          create: (_) => NextPrayerProvider(
            getNextPrayer: sl<GetNextPrayer>(),
          ),
        ),
        ChangeNotifierProvider<PrayerTrackingProvider>(
          create: (_) => PrayerTrackingProvider(
            getDailySummary: sl<GetDailySummary>(),
            watchDailySummary: sl<WatchDailySummary>(),
            recordPrayer: sl<RecordPrayer>(),
          ),
        ),
        ChangeNotifierProvider<QadaProvider>(
          create: (_) => QadaProvider(
            getQadaBalance: sl<GetQadaBalance>(),
            watchQadaBalance: sl<WatchQadaBalance>(),
            addMissedPrayers: sl<AddMissedPrayers>(),
            completeQadaPrayers: sl<CompleteQadaPrayers>(),
          ),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(
            getStatistics: sl<GetStatistics>(),
            getStreak: sl<GetStreak>(),
          ),
        ),
        ChangeNotifierProvider<HijriProvider>(
          create: (_) => HijriProvider(
            getHijriDate: sl<GetHijriDate>(),
          )..loadTodayHijri(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            repository: sl<NotificationRepository>(),
            getNotificationSettings: sl<GetNotificationSettings>(),
            saveNotificationSettings: sl<SaveNotificationSettings>(),
            schedulePrayerNotifications:
                sl<SchedulePrayerNotifications>(),
            cancelAllNotifications: sl<CancelAllNotifications>(),
            requestNotificationPermission:
                sl<RequestNotificationPermission>(),
          )..initialise(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (s) => s.themeMode,
    );

    return MaterialApp(
      title: 'Daily Deen',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.onboarding: (_) => const OnboardingPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.home: (_) => const HomePage(),
      },
    );
  }
}