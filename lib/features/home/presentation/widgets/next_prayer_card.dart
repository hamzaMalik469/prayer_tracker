library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_times/presentation/providers/next_prayer_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({super.key});

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return '00:00';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nextPrayerProvider = context.watch<NextPrayerProvider>();
    final timesProvider = context.watch<PrayerTimesProvider>();

    final nextPrayer = nextPrayerProvider.nextPrayer;
    final timeRemaining = nextPrayerProvider.timeRemaining;
    final todayTimes = timesProvider.todayTimes;

    if (nextPrayerProvider.isLoading || timesProvider.isLoading) {
      return const _CardShell(
        child: _LoadingContent(),
      );
    }

    if (nextPrayer == null || todayTimes == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final currentPrayer = todayTimes.currentPrayer(now);

    final progress = _calculateProgress(
      now: now,
      currentPrayer: currentPrayer,
      nextPrayer: nextPrayer,
      todayTimes: todayTimes,
    );

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LEFT COLUMN: CURRENT ACTIVE PRAYER ───────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CURRENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: currentPrayer != null
                            ? AppColors.prayedColor
                            : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPrayer != null
                          ? currentPrayer.prayerType.displayName
                          : 'Interval',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: currentPrayer != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (currentPrayer != null) ...[
                      Text(
                        _formatTime(currentPrayer.time),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (currentPrayer.endTime != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Ends ${_formatTime(currentPrayer.endTime!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.coffee_outlined,
                            size: 14,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'No active\nṣalāh',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── CENTER COLUMN: COUNTDOWN CONTAINER ──────────────────────
              _CountdownCircle(
                duration: timeRemaining,
                progress: progress,
                formattedDuration: _formatDuration(timeRemaining),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── RIGHT COLUMN: NEXT PRAYER ────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'UPCOMING',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextPrayer.prayerType.displayName,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatTime(nextPrayer.time),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (nextPrayer.hasJamaah) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'J: ${_formatTime(nextPrayer.jamaahTime!)}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateProgress({
    required DateTime now,
    required dynamic currentPrayer,
    required dynamic nextPrayer,
    required dynamic todayTimes,
  }) {
    if (currentPrayer == null) {
      return 0;
    }

    final start = currentPrayer.time as DateTime;
    final end = nextPrayer.time as DateTime;

    final total = end.difference(start).inSeconds;
    var elapsed = now.difference(start).inSeconds;

    if (total <= 0) {
      return 0;
    }

    elapsed = elapsed.clamp(0, total);

    return elapsed / total;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTDOWN CIRCLE — No changes
// ═══════════════════════════════════════════════════════════════════════════

class _CountdownCircle extends StatelessWidget {
  const _CountdownCircle({
    required this.duration,
    required this.progress,
    required this.formattedDuration,
  });

  final Duration duration;
  final double progress;
  final String formattedDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(96, 96),
            painter: _CountdownPainter(
              progress: progress,
              trackColor: colorScheme.surfaceContainerHighest,
              progressColor: colorScheme.primary,
            ),
          ),
          Container(
            width: 78,
            height: 88,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NEXT IN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      formattedDuration,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  const _CountdownPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.35),
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Calculating prayer times...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
