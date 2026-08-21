library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../../prayer_tracking/domain/usecases/get_summaries_for_range.dart';
import '../../../../core/di/injection_container.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MAIN CALENDAR PAGE — Tabs: Monthly + Yearly
// ═══════════════════════════════════════════════════════════════════════════

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // optional
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Monthly',
              icon: Icon(Icons.calendar_view_month_rounded, size: 18),
            ),
            Tab(
              text: 'Yearly',
              icon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
          ],
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MonthlyCalendarTab(),
          _YearlyCalendarTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MONTHLY CALENDAR TAB — scrollable with detail below
// ═══════════════════════════════════════════════════════════════════════════

class _MonthlyCalendarTab extends StatefulWidget {
  const _MonthlyCalendarTab();

  @override
  State<_MonthlyCalendarTab> createState() => _MonthlyCalendarTabState();
}

class _MonthlyCalendarTabState extends State<_MonthlyCalendarTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, DailyPrayerSummaryEntity> _summaries = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  Future<void> _loadMonth() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() => _isLoading = true);

    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      final useCase = sl<GetSummariesForRange>();

      final summaries = await useCase(
        GetSummariesForRangeParams(
          userId: auth.userId!,
          startDate: startDate,
          endDate: endDate,
        ),
      );

      if (!mounted) return;

      setState(() {
        for (final s in summaries) {
          _summaries[DateTime(s.date.year, s.date.month, s.date.day)] = s;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSummary = _summaries[DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    )];

    // Everything in a single scrollable view.
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.sm),

        // ── Calendar ────────────────────────────────────────────────────
        TableCalendar<DailyPrayerSummaryEntity>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) => setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          }),
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            _loadMonth();
          },
          calendarStyle: CalendarStyle(
            todayDecoration: const BoxDecoration(),
            selectedDecoration: const BoxDecoration(),
            todayTextStyle: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
            selectedTextStyle: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            cellMargin: const EdgeInsets.all(2),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          rowHeight: 56,
          calendarBuilders: CalendarBuilders(
            // Small TODAY circle
            todayBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },

            // Small SELECTED circle
            selectedBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },

            // Your existing prayer markers
            markerBuilder: (context, day, events) {
              final summary =
                  _summaries[DateTime(day.year, day.month, day.day)];

              if (summary == null) return null;

              return Positioned(
                bottom: 2,
                child: _FivePrayerDots(
                  summary: summary,
                ),
              );
            },
          ),
        ),
        // ── Legend ──────────────────────────────────────────────────────
        const _Legend(),
        const Divider(height: 1),

        // ── Selected day detail (always visible, scrollable) ────────────
        _SelectedDayDetail(
          day: _selectedDay,
          summary: selectedSummary,
        ),

        // Extra padding at bottom for comfortable scrolling.
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════════
// FIVE PRAYER DOTS — shows Fajr, Dhuhr, Asr, Maghrib, Isha as colored dots
// ═══════════════════════════════════════════════════════════════════════════

class _FivePrayerDots extends StatelessWidget {
  const _FivePrayerDots({required this.summary});

  final DailyPrayerSummaryEntity summary;

  Color _dotColor(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.qadaCompleted => AppColors.qadaCompletedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor.withOpacity(0.3),
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: PrayerTypeExtension.obligatory.map((type) {
        final status = summary.statusFor(type);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _dotColor(status),
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// YEARLY CALENDAR TAB — 12 months grid overview
// ═══════════════════════════════════════════════════════════════════════════

class _YearlyCalendarTab extends StatefulWidget {
  const _YearlyCalendarTab();

  @override
  State<_YearlyCalendarTab> createState() => _YearlyCalendarTabState();
}

class _YearlyCalendarTabState extends State<_YearlyCalendarTab>
    with AutomaticKeepAliveClientMixin {
  int _selectedYear = DateTime.now().year;
  Map<DateTime, DailyPrayerSummaryEntity> _yearlySummaries = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadYear());
  }

  Future<void> _loadYear() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() => _isLoading = true);

    try {
      final startDate = DateTime(_selectedYear, 1, 1);
      final endDate = DateTime(_selectedYear, 12, 31);
      final useCase = sl<GetSummariesForRange>();

      final summaries = await useCase(
        GetSummariesForRangeParams(
          userId: auth.userId!,
          startDate: startDate,
          endDate: endDate,
        ),
      );

      if (!mounted) return;

      setState(() {
        _yearlySummaries = {};
        for (final s in summaries) {
          _yearlySummaries[DateTime(s.date.year, s.date.month, s.date.day)] = s;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Year selector
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _selectedYear--);
                  _loadYear();
                },
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous year',
              ),
              Text(
                '$_selectedYear',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              IconButton(
                onPressed: _selectedYear < DateTime.now().year
                    ? () {
                        setState(() => _selectedYear++);
                        _loadYear();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next year',
              ),
            ],
          ),
        ),

        // Legend
        // const _Legend(),
        // const Divider(height: 1),

        // Yearly grid
        Expanded(
          child: _isLoading
              ? const Center(child: AppLoadingIndicator(size: 48))
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    return _YearlyMonthCard(
                      year: _selectedYear,
                      month: month,
                      summaries: _yearlySummaries,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// YEARLY MONTH CARD — Mini calendar for a single month
// ═══════════════════════════════════════════════════════════════════════════

class _YearlyMonthCard extends StatelessWidget {
  const _YearlyMonthCard({
    required this.year,
    required this.month,
    required this.summaries,
  });

  final int year;
  final int month;
  final Map<DateTime, DailyPrayerSummaryEntity> summaries;

  static const _monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;

    // Calculate stats for this month.
    int prayedDays = 0;
    int missedDays = 0;
    int partialDays = 0;
    int totalDays = 0;

    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(year, month, d);
      final summary = summaries[day];
      if (summary == null) continue;

      totalDays++;
      if (summary.isFullyCompleted) {
        prayedDays++;
      } else if (summary.hasExplicitMiss) {
        missedDays++;
      } else if (summary.prayedCount > 0) {
        partialDays++;
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Month header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            color: isCurrentMonth
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthNames[month],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCurrentMonth
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                ),
                if (totalDays > 0)
                  Text(
                    '${(prayedDays / math.max(totalDays, 1) * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _percentColor(
                            prayedDays / math.max(totalDays, 1),
                            colorScheme,
                          ),
                        ),
                  ),
              ],
            ),
          ),

          // Day dots grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = DateTime(year, month, index + 1);
                  final summary = summaries[day];

                  if (summary == null) {
                    return const _DayDot(color: Colors.transparent);
                  }

                  return _DayDotWithPrayers(summary: summary);
                },
              ),
            ),
          ),

          // Month summary bar
          if (totalDays > 0)
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Row(
                  children: [
                    if (prayedDays > 0)
                      Flexible(
                        flex: prayedDays,
                        child: Container(color: AppColors.prayedColor),
                      ),
                    if (partialDays > 0)
                      Flexible(
                        flex: partialDays,
                        child: Container(color: AppColors.prayedLateColor),
                      ),
                    if (missedDays > 0)
                      Flexible(
                        flex: missedDays,
                        child: Container(color: AppColors.missedColor),
                      ),
                    if (totalDays - prayedDays - partialDays - missedDays > 0)
                      Flexible(
                        flex: totalDays - prayedDays - partialDays - missedDays,
                        child: Container(
                          color: AppColors.notRecordedColor.withOpacity(0.2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Color _percentColor(double pct, ColorScheme cs) {
    if (pct >= 0.9) return AppColors.prayedColor;
    if (pct >= 0.7) return cs.primary;
    if (pct >= 0.5) return AppColors.prayedLateColor;
    return AppColors.missedColor;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DAY DOT (yearly view) — single colored dot for a day
// ═══════════════════════════════════════════════════════════════════════════

class _DayDot extends StatelessWidget {
  const _DayDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Day dot with 5 tiny prayer indicators (yearly view)
class _DayDotWithPrayers extends StatelessWidget {
  const _DayDotWithPrayers({required this.summary});

  final DailyPrayerSummaryEntity summary;

  Color _statusColor(PrayerStatus s) => switch (s) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.qadaCompleted => AppColors.qadaCompletedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor.withOpacity(0.3),
      };

  @override
  Widget build(BuildContext context) {
    // Get overall color for the day circle background.
    final bgColor = summary.isFullyCompleted
        ? AppColors.prayedColor.withOpacity(0.2)
        : summary.hasExplicitMiss
            ? AppColors.missedColor.withOpacity(0.15)
            : summary.prayedCount > 0
                ? AppColors.prayedLateColor.withOpacity(0.15)
                : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 10,
          height: 3,
          child: Row(
            children: PrayerTypeExtension.obligatory.map((type) {
              final status = summary.statusFor(type);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.2),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(0.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEGEND — shared between monthly and yearly
// ═══════════════════════════════════════════════════════════════════════════

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          _LegendDot(color: AppColors.prayedColor, label: 'With Jammah'),
          _LegendDot(color: AppColors.prayedLateColor, label: 'On Time'),
          _LegendDot(color: AppColors.qadaCompletedColor, label: 'Qada'),
          _LegendDot(color: AppColors.missedColor, label: 'Missed'),
          _LegendDot(color: AppColors.notRecordedColor, label: 'No Record'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SELECTED DAY DETAIL — shows 5 prayers with status (monthly tab)
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// SELECTED DAY DETAIL — no longer needs Expanded, has its own size
// ═══════════════════════════════════════════════════════════════════════════

class _SelectedDayDetail extends StatelessWidget {
  const _SelectedDayDetail({required this.day, required this.summary});

  final DateTime day;
  final DailyPrayerSummaryEntity? summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // Minimum height so it is always visible even with no data.
      constraints: const BoxConstraints(minHeight: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Date header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(day),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        DateFormat('d MMMM yyyy').format(day),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Completion badge
                if (summary != null && summary!.records.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: summary!.isFullyCompleted
                          ? AppColors.prayedColor.withOpacity(0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (summary!.isFullyCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.prayedColor,
                          ),
                        if (summary!.isFullyCompleted) const SizedBox(width: 3),
                        Text(
                          '${summary!.prayedCount}/5',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: summary!.isFullyCompleted
                                        ? AppColors.prayedColor
                                        : colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Mini progress bar for the day ──────────────────────────────
          if (summary != null && summary!.records.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: PrayerTypeExtension.obligatory.map((type) {
                      final status = summary!.statusFor(type);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          color: _colorFor(status),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Prayer labels for the bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: PrayerTypeExtension.obligatory.map((type) {
                  return Expanded(
                    child: Text(
                      type.displayName[0], // F D A M I
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // ── No records state ───────────────────────────────────────────
          if (summary == null || summary!.records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No records for this day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Prayer records will appear here once tracked.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Prayer detail cards ────────────────────────────────────────
          if (summary != null && summary!.records.isNotEmpty)
            ...PrayerTypeExtension.obligatory.map((type) {
              final status = summary!.statusFor(type);
              return _PrayerDetailCard(type: type, status: status);
            }),
        ],
      ),
    );
  }

  Color _colorFor(PrayerStatus s) => switch (s) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.qadaCompleted => AppColors.qadaCompletedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor.withOpacity(0.3),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER DETAIL CARD — replaces the old cramped ListTile
// ═══════════════════════════════════════════════════════════════════════════

class _PrayerDetailCard extends StatelessWidget {
  const _PrayerDetailCard({
    required this.type,
    required this.status,
  });

  final PrayerType type;
  final PrayerStatus status;

  IconData _iconFor(PrayerStatus s) => switch (s) {
        PrayerStatus.prayed => Icons.people_alt_rounded,
        PrayerStatus.prayedLate => Icons.person,
        PrayerStatus.missed => Icons.cancel_rounded,
        PrayerStatus.qadaCompleted => Icons.replay_circle_filled_rounded,
        PrayerStatus.notRecorded => Icons.radio_button_unchecked_rounded,
      };

  Color _colorFor(PrayerStatus s) => switch (s) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.qadaCompleted => AppColors.qadaCompletedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor,
      };

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Semantics(
        label: '${type.displayName}: ${status.displayName}',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Status icon with background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_iconFor(status), color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),

              // Prayer name + Arabic
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      type.arabicName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  status.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
