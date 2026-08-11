library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_tracking/domain/entities/daily_prayer_summary_entity.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../../prayer_tracking/domain/usecases/get_summaries_for_range.dart';
import '../../../../core/di/injection_container.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, DailyPrayerSummaryEntity> _summaries = {};
  bool _isLoading = false;

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

  Color? _dayColor(DateTime day) {
    final summary = _summaries[DateTime(day.year, day.month, day.day)];
    if (summary == null) return null;
    if (summary.isFullyCompleted) return AppColors.prayedColor;
    if (summary.hasExplicitMiss) return AppColors.missedColor;
    if (summary.prayedCount > 0) return AppColors.prayedLateColor;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<DailyPrayerSummaryEntity>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadMonth();
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final color = _dayColor(day);
                if (color == null) return null;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _SelectedDayDetail(
              day: _selectedDay,
              summary: _summaries[DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
              )],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayDetail extends StatelessWidget {
  const _SelectedDayDetail({required this.day, required this.summary});

  final DateTime day;
  final DailyPrayerSummaryEntity? summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (summary == null) {
      return Center(
        child: Text(
          'No records for this day',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: PrayerTypeExtension.obligatory.map((type) {
        final status = summary!.statusFor(type);
        return ListTile(
          leading: Icon(
            _iconFor(status),
            color: _colorFor(status),
            semanticLabel: status.displayName,
          ),
          title: Text(type.displayName),
          trailing: Text(
            status.displayName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _colorFor(status),
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => Icons.check_circle_rounded,
        PrayerStatus.prayedLate => Icons.check_circle_outline_rounded,
        PrayerStatus.missed => Icons.cancel_rounded,
        PrayerStatus.notRecorded => Icons.radio_button_unchecked_rounded,
      };

  Color _colorFor(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor,
      };
}
