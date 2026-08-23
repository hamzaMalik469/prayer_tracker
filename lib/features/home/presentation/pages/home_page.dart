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
import '../../../qada/presentation/pages/qada_page.dart';
import '../../../qada/presentation/providers/qada_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../presentation/pages/calendar_page.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_card_list.dart';
import '../widgets/today_progress_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _initialised = false;
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

    // Calculate prayer times
    if (!mounted) return;
    await context.read<PrayerTimesProvider>().calculatePrayerTimes(
          location: location,
          settings: prayerSettings,
        );

    // Start countdown
    if (!mounted) return;
    await context.read<NextPrayerProvider>().start(
          location: location,
          settings: prayerSettings,
        );

    // Initialise tracking providers
    if (!mounted) return;
    await Future.wait([
      context
          .read<PrayerTrackingProvider>()
          .initialise(userId: effectiveUserId),
      context.read<StatisticsProvider>().initialise(userId: effectiveUserId),
      context.read<QadaProvider>().initialise(userId: effectiveUserId),
    ]);

    // Schedule notifications with full dynamic context
    if (!mounted) return;
    _rescheduleNotifications();

    // Listen for prayer changes to auto-cancel and update streak alerts
    if (!mounted) return;
    context
        .read<PrayerTrackingProvider>()
        .addChangeListener(_onPrayerRecordChanged);

    // Background sync
    if (auth.isAuthenticated && mounted) {
      sl<SyncService>().syncAll(userId: effectiveUserId).ignore();
    }

    if (mounted) setState(() => _initialised = true);
  }

  /// Calculates current unrecorded list and streak value, then schedules.
  Future<void> _rescheduleNotifications() async {
    if (!mounted) return;

    final timesProvider = context.read<PrayerTimesProvider>();
    final notifications = context.read<NotificationProvider>();
    final tracking = context.read<PrayerTrackingProvider>();
    final stats = context.read<StatisticsProvider>();

    if (timesProvider.todayTimes != null &&
        timesProvider.tomorrowTimes != null) {
      await notifications.scheduleForDays(
        today: timesProvider.todayTimes!,
        tomorrow: timesProvider.tomorrowTimes!,
        todaySummary: tracking.todaySummary,
        currentStreak: stats.streak.currentStreak,
      );
    }
  }

  void _onPrayerRecordChanged() {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    // Refresh statistics & Qada state
    context.read<StatisticsProvider>().refresh();
    context.read<QadaProvider>().initialise(userId: auth.userId!);

    // Re-evaluate notification alarms (e.g. cancel streak saver if completed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rescheduleNotifications();
    });
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
    final effectiveUserId = auth.userId;

    // Refresh calculation times
    if (!mounted) return;
    await context.read<PrayerTimesProvider>().refresh(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    // Resume countdown
    if (!mounted) return;
    await context.read<NextPrayerProvider>().resume(
          location: settings.locationSettings,
          settings: settings.prayerSettings,
        );

    // Refresh tracking on date rollover
    if (!mounted) return;
    if (effectiveUserId != null) {
      await context
          .read<PrayerTrackingProvider>()
          .onDateChanged(userId: effectiveUserId);

      await context.read<StatisticsProvider>().refresh();

      // Reschedule alarms
      await _rescheduleNotifications();

      if (auth.isAuthenticated) {
        sl<SyncService>().syncAll(userId: effectiveUserId).ignore();
      }
    }
  }

  void _onTabChanged(int index) {
    final previousIndex = _currentIndex;
    final auth = context.read<AuthProvider>();
    final effectiveUserId = auth.userId;

    setState(() => _currentIndex = index);

    if (effectiveUserId == null) return;

    switch (index) {
      case 0:
        context
            .read<PrayerTrackingProvider>()
            .onDateChanged(userId: effectiveUserId);
      case 1:
        setState(() => _calendarVersion++);
      case 2:
        context.read<StatisticsProvider>().refresh();
      case 3:
        context.read<QadaProvider>().initialise(userId: effectiveUserId);
      case 4:
        break;
    }

    // Keep notifications updated with active state on tab shifts
    _rescheduleNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      context
          .read<PrayerTrackingProvider>()
          .removeChangeListener(_onPrayerRecordChanged);
    } catch (_) {}
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
            icon: QadaTabIcon(),
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
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: PrayerCardList()),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class QadaTabIcon extends StatelessWidget {
  const QadaTabIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final qada = context.watch<QadaProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final pendingQada = qada.summary.totalPending;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Icon(Icons.replay_outlined),
        if (pendingQada > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  pendingQada > 99 ? '99+' : pendingQada.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
