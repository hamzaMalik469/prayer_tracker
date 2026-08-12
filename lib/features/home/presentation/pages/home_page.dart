library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_tracking/presentation/providers/prayer_tracking_provider.dart';
import '../../../qada/presentation/providers/qada_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_card_list.dart';
import '../widgets/streak_card.dart';
import '../widgets/today_progress_card.dart';
import '../../presentation/pages/calendar_page.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiseProviders();
  }

  Future<void> _initialiseProviders() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final location = settings.locationSettings;
    final prayerSettings = settings.prayerSettings;
    final notifications = context.read<NotificationProvider>();

    // Calculate prayer times for today and tomorrow.
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: location,
          settings: prayerSettings,
        );

    if (!mounted) return;

    // Start countdown.
    await context.read<NextPrayerProvider>().start(
          location: location,
          settings: prayerSettings,
        );

    if (!mounted) return;

    // Schedule notifications using the calculated times.
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.scheduleForDays(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    if (!mounted) return;

    // Load prayer tracking, statistics, and Qada if authenticated.
    if (auth.userId != null) {
      await Future.wait([
        context.read<PrayerTrackingProvider>().initialise(userId: auth.userId!),
        context.read<StatisticsProvider>().initialise(userId: auth.userId!),
        context.read<QadaProvider>().initialise(userId: auth.userId!),
      ]);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final settings = context.read<SettingsProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed(settings);
      case AppLifecycleState.paused:
        context.read<NextPrayerProvider>().pause();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onResumed(SettingsProvider settings) async {
    final auth = context.read<AuthProvider>();
    final notifications = context.read<NotificationProvider>();

    // Refresh prayer times (handles date change and timezone changes).
    await context.read<PrayerTimesProvider>().refresh(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;

    // Resume countdown.
    await context.read<NextPrayerProvider>().resume(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    if (!mounted) return;

    // Reschedule notifications with fresh times.
    final timesProvider = context.read<PrayerTimesProvider>();
    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.rescheduleAfterSettingsChange(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
      );
    }

    if (!mounted) return;

    if (auth.userId != null) {
      await context
          .read<PrayerTrackingProvider>()
          .onDateChanged(userId: auth.userId!);
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
