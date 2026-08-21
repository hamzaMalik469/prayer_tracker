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
  // Key incremented to force calendar rebuild when switching to it.
  int _calendarVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    // Step 1 — Prayer times.
    if (!mounted) return;
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: location,
          settings: prayerSettings,
        );

    // Step 2 — Countdown.
    if (!mounted) return;
    await context.read<NextPrayerProvider>().start(
          location: location,
          settings: prayerSettings,
        );

    // Step 3 — Notifications.
    if (!mounted) return;
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.scheduleForDays(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    // Step 4 — All tracking providers.
    if (!mounted) return;
    await Future.wait([
      context
          .read<PrayerTrackingProvider>()
          .initialise(userId: effectiveUserId),
      context.read<StatisticsProvider>().initialise(userId: effectiveUserId),
      context.read<QadaProvider>().initialise(userId: effectiveUserId),
    ]);

    // Step 5 — Background sync.
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
        if (mounted) context.read<NextPrayerProvider>().pause();
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

    if (!mounted) return;
    await context.read<PrayerTimesProvider>().refresh(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;
    await context.read<NextPrayerProvider>().resume(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.rescheduleAfterSettingsChange(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    if (!mounted) return;
    if (effectiveUserId != null) {
      await context
          .read<PrayerTrackingProvider>()
          .onDateChanged(userId: effectiveUserId);

      context.read<StatisticsProvider>().refresh();

      if (auth.isAuthenticated) {
        sl<SyncService>().syncAll(userId: effectiveUserId).ignore();
      }
    }
  }

  /// Called every time a tab is tapped.
  /// Refreshes the target tab's data from local SQLite.
  void _onTabChanged(int index) {
    final previousIndex = _currentIndex;
    final auth = context.read<AuthProvider>();
    final effectiveUserId = auth.userId;

    setState(() => _currentIndex = index);

    // Coming FROM Home tab → something might have changed.
    // Refresh whichever tab we are going TO.
    if (effectiveUserId == null) return;

    switch (index) {
      case 0:
        // Home — refresh tracking summary.
        context
            .read<PrayerTrackingProvider>()
            .onDateChanged(userId: effectiveUserId);

      case 1:
        // Calendar — force rebuild to pick up new prayer records.
        setState(() => _calendarVersion++);

      case 2:
        // Statistics — refresh streak + stats.
        context.read<StatisticsProvider>().refresh();

      case 3:
        // Qada — refresh balance.
        context.read<QadaProvider>().initialise(userId: effectiveUserId);

      case 4:
        // Settings — nothing to refresh.
        break;
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
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const _DashboardTab(),
                // Key changes force CalendarPage to rebuild with fresh data.
                CalendarPage(key: ValueKey('calendar_$_calendarVersion')),
                const StatisticsPage(),
                const QadaPage(),
                const SettingsPage(),
              ],
            ),
          ),
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
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
        // SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        // SliverToBoxAdapter(child: StreakCard()),
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
