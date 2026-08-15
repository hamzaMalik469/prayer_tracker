library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:prayers_tracker_plus/features/prayer_times/data/datasources/prayer_times_custom_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../logging/app_logger.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';
import '../subscription/feature_access.dart';
import '../subscription/subscription_domain.dart';
import '../subscription/subscription_repository_impl.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/create_account.dart';
import '../../features/auth/domain/usecases/delete_account.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/send_password_reset.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/watch_auth_state.dart';
import '../../features/hijri/data/repositories/hijri_repository_impl.dart';
import '../../features/hijri/domain/repositories/hijri_repository.dart';
import '../../features/hijri/domain/usecases/get_hijri_date.dart';
import '../../features/notifications/data/datasources/notification_local_datasource.dart';
import '../../features/notifications/data/datasources/notification_settings_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/cancel_all_notifications.dart';
import '../../features/notifications/domain/usecases/get_notification_settings.dart';
import '../../features/notifications/domain/usecases/request_notification_permission.dart';
import '../../features/notifications/domain/usecases/save_notification_settings.dart';
import '../../features/notifications/domain/usecases/schedule_prayer_notifications.dart';
import '../../features/onboarding/data/datasources/onboarding_local_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_status.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/prayer_times/data/datasources/prayer_times_local_datasource.dart';
import '../../features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../features/prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../features/prayer_times/domain/usecases/get_next_prayer.dart';
import '../../features/prayer_times/domain/usecases/get_prayer_times.dart';
import '../../features/prayer_tracking/data/datasources/prayer_tracking_local_datasource.dart';
import '../../features/prayer_tracking/data/datasources/prayer_tracking_remote_datasource.dart';
import '../../features/prayer_tracking/data/repositories/prayer_tracking_repository_impl.dart';
import '../../features/prayer_tracking/domain/repositories/prayer_tracking_repository.dart';
import '../../features/prayer_tracking/domain/usecases/get_daily_summary.dart';
import '../../features/prayer_tracking/domain/usecases/get_summaries_for_range.dart';
import '../../features/prayer_tracking/domain/usecases/record_prayer.dart';
import '../../features/prayer_tracking/domain/usecases/watch_daily_summary.dart';
import '../../features/qada/data/datasources/qada_local_datasource.dart';
import '../../features/qada/data/datasources/qada_remote_datasource.dart';
import '../../features/qada/data/repositories/qada_repository_impl.dart';
import '../../features/qada/domain/repositories/qada_repository.dart';
import '../../features/qada/domain/usecases/add_qada_record.dart';
import '../../features/qada/domain/usecases/complete_qada_record.dart';
import '../../features/qada/domain/usecases/get_qada_summary.dart';
import '../../features/qada/domain/usecases/watch_qada_summary.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/save_location_settings.dart';
import '../../features/settings/domain/usecases/save_prayer_settings.dart';
import '../../features/settings/domain/usecases/save_theme_mode.dart';
import '../../features/settings/domain/usecases/watch_settings.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/calculate_streak.dart';
import '../../features/statistics/domain/usecases/get_statistics.dart';
import '../../features/statistics/domain/usecases/get_streak.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  AppLogger.info('Initialising DI container…', tag: 'DI');

  // ════════════════════════════════════════════════════════════════════════
  // EXTERNAL SERVICES
  // ════════════════════════════════════════════════════════════════════════
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(_configureFirestore());
  sl.registerSingleton<Uuid>(const Uuid());

  // Initialise local SQLite database.
  await LocalDatabaseService.database;

  // ════════════════════════════════════════════════════════════════════════
  // CORE / SUBSCRIPTION
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<FeatureAccessService>(
    const FreeFeatureAccessService(),
  );
  sl.registerSingleton<SubscriptionRepository>(
    const StubSubscriptionRepository(),
  );

  // ════════════════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<FirebaseAuthDataSource>(
    FirebaseAuthDataSourceImpl(firebaseAuth: sl<FirebaseAuth>()),
  );
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      authDataSource: sl<FirebaseAuthDataSource>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerFactory(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerFactory(() => WatchAuthState(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithEmail(sl<AuthRepository>()));
  sl.registerFactory(() => CreateAccount(sl<AuthRepository>()));
  sl.registerFactory(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerFactory(() => SignOut(sl<AuthRepository>()));
  sl.registerFactory(() => SendPasswordReset(sl<AuthRepository>()));
  sl.registerFactory(() => DeleteAccount(sl<AuthRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // ONBOARDING
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<OnboardingLocalDataSource>(
    OnboardingLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
  sl.registerSingleton<OnboardingRepository>(
    OnboardingRepositoryImpl(dataSource: sl<OnboardingLocalDataSource>()),
  );
  sl.registerFactory(() => CheckOnboardingStatus(sl<OnboardingRepository>()));
  sl.registerFactory(() => CompleteOnboarding(sl<OnboardingRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<SettingsLocalDataSource>(
    SettingsLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
  sl.registerSingleton<SettingsRemoteDataSource>(
    SettingsRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerSingleton<SettingsRepositoryImpl>(
    SettingsRepositoryImpl(
      localDataSource: sl<SettingsLocalDataSource>(),
      remoteDataSource: sl<SettingsRemoteDataSource>(),
    ),
  );
  sl.registerSingleton<SettingsRepository>(sl<SettingsRepositoryImpl>());
  sl.registerFactory(() => GetSettings(sl<SettingsRepository>()));
  sl.registerFactory(() => WatchSettings(sl<SettingsRepository>()));
  sl.registerFactory(() => SavePrayerSettings(sl<SettingsRepository>()));
  sl.registerFactory(() => SaveLocationSettings(sl<SettingsRepository>()));
  sl.registerFactory(() => SaveThemeMode(sl<SettingsRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // PRAYER TIMES
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<PrayerTimesLocalDataSource>(
    const PrayerTimesLocalDataSourceImpl(),
  );
  sl.registerSingleton<PrayerTimesRepository>(
    PrayerTimesRepositoryImpl(dataSource: sl<PrayerTimesLocalDataSource>()),
  );
  sl.registerFactory(() => GetPrayerTimes(sl<PrayerTimesRepository>()));
  sl.registerFactory(() => GetNextPrayer(sl<PrayerTimesRepository>()));

  // ── Custom Prayer Times ──────────────────────────────────────────────────
  sl.registerSingleton<PrayerTimesCustomDataSource>(
    PrayerTimesCustomDataSourceImpl(prefs: sl<SharedPreferences>()),
  );

  // ════════════════════════════════════════════════════════════════════════
  // PRAYER TRACKING — local + remote
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<PrayerTrackingLocalDataSource>(
    const PrayerTrackingLocalDataSourceImpl(),
  );
  sl.registerSingleton<PrayerTrackingRemoteDataSource>(
    PrayerTrackingRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerSingleton<PrayerTrackingRepository>(
    PrayerTrackingRepositoryImpl(
      localDataSource: sl<PrayerTrackingLocalDataSource>(),
      remoteDataSource: sl<PrayerTrackingRemoteDataSource>(),
    ),
  );
  sl.registerFactory(() => GetDailySummary(sl<PrayerTrackingRepository>()));
  sl.registerFactory(() => WatchDailySummary(sl<PrayerTrackingRepository>()));
  sl.registerFactory(() => RecordPrayer(sl<PrayerTrackingRepository>()));
  sl.registerFactory(
      () => GetSummariesForRange(sl<PrayerTrackingRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // QADA — local + remote
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<QadaLocalDataSource>(
    const QadaLocalDataSourceImpl(),
  );
  sl.registerSingleton<QadaRemoteDataSource>(
    QadaRemoteDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );
  sl.registerSingleton<QadaRepository>(
    QadaRepositoryImpl(
      localDataSource: sl<QadaLocalDataSource>(),
      remoteDataSource: sl<QadaRemoteDataSource>(),
    ),
  );
  sl.registerFactory(() => GetQadaSummary(sl<QadaRepository>()));
  sl.registerFactory(() => WatchQadaSummary(sl<QadaRepository>()));
  sl.registerFactory(() => AddQadaRecord(sl<QadaRepository>()));
  sl.registerFactory(() => CompleteQadaRecord(sl<QadaRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // STATISTICS — reads from PrayerTrackingRepository (local-first)
  // ════════════════════════════════════════════════════════════════════════
  sl.registerFactory(() => const CalculateStreak());
  sl.registerSingleton<StatisticsRepository>(
    StatisticsRepositoryImpl(
      localDataSource: sl<PrayerTrackingLocalDataSource>(),
      remoteDataSource: sl<PrayerTrackingRemoteDataSource>(),
      calculateStreak: sl<CalculateStreak>(),
    ),
  );
  sl.registerFactory(() => GetStreak(sl<StatisticsRepository>()));
  sl.registerFactory(() => GetStatistics(sl<StatisticsRepository>()));
  // ════════════════════════════════════════════════════════════════════════
  // HIJRI
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<HijriRepository>(const HijriRepositoryImpl());
  sl.registerFactory(() => GetHijriDate(sl<HijriRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<NotificationLocalDataSource>(
    NotificationLocalDataSourceImpl(),
  );
  sl.registerSingleton<NotificationSettingsDataSource>(
    NotificationSettingsDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
  sl.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(
      notificationDataSource: sl<NotificationLocalDataSource>(),
      settingsDataSource: sl<NotificationSettingsDataSource>(),
    ),
  );
  sl.registerFactory(
      () => GetNotificationSettings(sl<NotificationRepository>()));
  sl.registerFactory(
      () => SaveNotificationSettings(sl<NotificationRepository>()));
  sl.registerFactory(
      () => SchedulePrayerNotifications(sl<NotificationRepository>()));
  sl.registerFactory(
      () => CancelAllNotifications(sl<NotificationRepository>()));
  sl.registerFactory(
      () => RequestNotificationPermission(sl<NotificationRepository>()));

  // ════════════════════════════════════════════════════════════════════════
  // SYNC SERVICE
  // ════════════════════════════════════════════════════════════════════════
  sl.registerSingleton<SyncService>(
    SyncService(
      localPrayer: sl<PrayerTrackingLocalDataSource>(),
      remotePrayer: sl<PrayerTrackingRemoteDataSource>(),
      localQada: sl<QadaLocalDataSource>(),
      remoteQada: sl<QadaRemoteDataSource>(),
    ),
  );

  AppLogger.info('DI container initialised.', tag: 'DI');
}

FirebaseFirestore _configureFirestore() {
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  return firestore;
}
