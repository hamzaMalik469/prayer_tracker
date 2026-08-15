library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _formatTime(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextPrayerProvider = context.watch<NextPrayerProvider>();
    final timesProvider = context.watch<PrayerTimesProvider>();

    final nextPrayer = nextPrayerProvider.nextPrayer;
    final timeRemaining = nextPrayerProvider.timeRemaining;
    final todayTimes = timesProvider.todayTimes;

    if (nextPrayerProvider.isLoading || timesProvider.isLoading) {
      return const _CardShell(child: _LoadingContent());
    }

    if (nextPrayer == null || todayTimes == null) {
      return const SizedBox.shrink();
    }

    // Current active prayer
    final now = DateTime.now();
    final currentPrayer = todayTimes.currentPrayer(now);

    // Day progress
    double progress = 0;
    final totalDaySeconds =
        todayTimes.isha.time.difference(todayTimes.fajr.time).inSeconds;
    final elapsedSeconds = now
        .difference(todayTimes.fajr.time)
        .inSeconds
        .clamp(0, totalDaySeconds);
    progress = totalDaySeconds > 0 ? elapsedSeconds / totalDaySeconds : 0;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current prayer banner ──────────────────────────────────────
          if (currentPrayer != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.prayedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_alarm_rounded,
                    size: 16,
                    color: AppColors.prayedColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Current: ${currentPrayer.prayerType.displayName}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.prayedColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (currentPrayer.endTime != null)
                    Text(
                      'Ends ${_formatTime(currentPrayer.endTime!)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.prayedColor,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Next prayer ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Next Prayer',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (nextPrayerProvider.nextPrayerResult?.isNextDay == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Tomorrow',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Prayer name + start time + end time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextPrayer.prayerType.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTime(nextPrayer.time),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (nextPrayer.endTime != null) ...[
                        Text(
                          ' — ${_formatTime(nextPrayer.endTime!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Countdown
              Semantics(
                label: 'Time remaining: ${_formatDuration(timeRemaining)}',
                child: Text(
                  _formatDuration(timeRemaining),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: colorScheme.primary,
                        letterSpacing: -1,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
