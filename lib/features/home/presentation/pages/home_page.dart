library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_tracking/presentation/providers/prayer_tracking_provider.dart';
import '../../../qada/presentation/providers/qada_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../presentation/pages/calendar_page.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_card_list.dart';
import '../widgets/streak_card.dart';
import '../widgets/today_progress_card.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../qada/presentation/pages/qada_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer initialisation until AFTER the first frame is built.
    // This prevents setState() called during build errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialiseProviders();
    });
  }

  Future<void> _initialiseProviders() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final effectiveUserId = auth.userId;

    if (effectiveUserId == null) return;

    final location = settings.locationSettings;
    final prayerSettings = settings.prayerSettings;
    final notifications = context.read<NotificationProvider>();

    // Step 1 — Calculate prayer times.
    if (!mounted) return;
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: location,
          settings: prayerSettings,
        );

    // Step 2 — Start next prayer countdown.
    if (!mounted) return;
    await context.read<NextPrayerProvider>().start(
          location: location,
          settings: prayerSettings,
        );

    // Step 3 — Schedule notifications.
    if (!mounted) return;
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.scheduleForDays(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    // Step 4 — Initialise tracking providers.
    if (!mounted) return;
    await Future.wait([
      context
          .read<PrayerTrackingProvider>()
          .initialise(userId: effectiveUserId),
      context.read<StatisticsProvider>().initialise(userId: effectiveUserId),
      context.read<QadaProvider>().initialise(userId: effectiveUserId),
    ]);

    // Step 5 — Trigger background sync for authenticated users.
    if (auth.isAuthenticated && mounted) {
      sl<SyncService>().syncAll(userId: effectiveUserId).ignore();
    }

    if (mounted) setState(() => _initialised = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onResumed();
        });
      case AppLifecycleState.paused:
        if (mounted) {
          context.read<NextPrayerProvider>().pause();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onResumed() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final notifications = context.read<NotificationProvider>();
    final effectiveUserId = auth.userId;

    // Refresh prayer times (handles date change + timezone change).
    if (!mounted) return;
    await context.read<PrayerTimesProvider>().refresh(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    // Resume countdown.
    if (!mounted) return;
    await context.read<NextPrayerProvider>().resume(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    // Reschedule notifications with fresh times.
    if (!mounted) return;
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.rescheduleAfterSettingsChange(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    // Refresh tracking on date change.
    if (!mounted) return;
    if (effectiveUserId != null) {
      await context
          .read<PrayerTrackingProvider>()
          .onDateChanged(userId: effectiveUserId);

      // Background sync on resume.
      if (auth.isAuthenticated) {
        sl<SyncService>().syncAll(userId: effectiveUserId).ignore();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                _DashboardTab(),
                CalendarPage(),
                StatisticsPage(),
                QadaPage(),
                SettingsPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.replay_outlined),
            selectedIcon: Icon(Icons.replay_rounded),
            label: 'Qada',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: DashboardHeader()),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(child: NextPrayerCard()),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(child: TodayProgressCard()),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(child: StreakCard()),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: PrayerCardList()),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}
