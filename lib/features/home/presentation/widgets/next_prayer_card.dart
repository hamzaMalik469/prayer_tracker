library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prayers_tracker_plus/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
          // // ─────────────────────────────────────────────────────────────
          // // HEADER
          // // ─────────────────────────────────────────────────────────────
          // Row(
          //   children: [
          //     Container(
          //       width: 34,
          //       height: 34,
          //       decoration: BoxDecoration(
          //         color: colorScheme.primary.withOpacity(0.10),
          //         borderRadius: BorderRadius.circular(AppRadius.sm),
          //       ),
          //       child: Icon(
          //         Icons.access_time_rounded,
          //         size: 18,
          //         color: colorScheme.primary,
          //       ),
          //     ),
          //     const SizedBox(width: AppSpacing.sm),
          //     Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(
          //           'NEXT PRAYER',
          //           style: theme.textTheme.labelSmall?.copyWith(
          //             fontWeight: FontWeight.w700,
          //             letterSpacing: 1.1,
          //             color: colorScheme.primary,
          //           ),
          //         ),
          //         const SizedBox(height: 2),
          //         Text(
          //           'Stay mindful of your salah',
          //           style: theme.textTheme.bodySmall?.copyWith(
          //             color: colorScheme.onSurfaceVariant,
          //           ),
          //         ),
          //       ],
          //     ),
          //     const Spacer(),

          //     // Tomorrow badge
          //     if (nextPrayerProvider.nextPrayerResult?.isNextDay == true)
          //       Container(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: AppSpacing.sm,
          //           vertical: 5,
          //         ),
          //         decoration: BoxDecoration(
          //           color: colorScheme.surfaceContainerHighest,
          //           borderRadius: BorderRadius.circular(AppRadius.full),
          //         ),
          //         child: Row(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Icon(
          //               Icons.nightlight_round,
          //               size: 13,
          //               color: colorScheme.onSurfaceVariant,
          //             ),
          //             const SizedBox(width: 4),
          //             Text(
          //               'Tomorrow',
          //               style: theme.textTheme.labelSmall?.copyWith(
          //                 fontWeight: FontWeight.w600,
          //                 color: colorScheme.onSurfaceVariant,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //   ],
          // ),

          // const SizedBox(height: AppSpacing.lg),

          // ─────────────────────────────────────────────────────────────
          // CURRENT PRAYER STATUS
          // ─────────────────────────────────────────────────────────────
          if (currentPrayer != null) ...[
            _CurrentPrayerBanner(
              prayerName: currentPrayer.prayerType.displayName,
              endTime: currentPrayer.endTime,
              formatTime: _formatTime,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─────────────────────────────────────────────────────────────
          // MAIN PRAYER AREA
          // ─────────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prayer information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextPrayer.prayerType.displayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(nextPrayer.time),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // 👥 JAMA'AH PILL INDICATOR
                    if (nextPrayer.hasJamaah)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded,
                              size: 15, color: colorScheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Jama\'ah: ${_formatTime(nextPrayer.jamaahTime!)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                          ),
                        ],
                      ),

                    if (nextPrayer.endTime != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Ends ${_formatTime(nextPrayer.endTime!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Countdown circle
              _CountdownCircle(
                duration: timeRemaining,
                progress: progress,
                formattedDuration: _formatDuration(timeRemaining),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // // ─────────────────────────────────────────────────────────────
          // // PROGRESS SECTION
          // // ─────────────────────────────────────────────────────────────
          // Row(
          //   children: [
          //     Text(
          //       'Prayer time progress',
          //       style: theme.textTheme.labelSmall?.copyWith(
          //         color: colorScheme.onSurfaceVariant,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),
          //     const Spacer(),
          //     Text(
          //       '${(progress * 100).round()}%',
          //       style: theme.textTheme.labelSmall?.copyWith(
          //         color: colorScheme.primary,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: AppSpacing.xs),

          // ClipRRect(
          //   borderRadius: BorderRadius.circular(AppRadius.full),
          //   child: LinearProgressIndicator(
          //     value: progress.clamp(0.0, 1.0),
          //     minHeight: 5,
          //     backgroundColor: colorScheme.surfaceContainerHighest,
          //     valueColor: AlwaysStoppedAnimation<Color>(
          //       colorScheme.primary,
          //     ),
          //   ),
          // ),
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

    var total = end.difference(start).inSeconds;
    var elapsed = now.difference(start).inSeconds;

    if (total <= 0) {
      return 0;
    }

    elapsed = elapsed.clamp(0, total);

    return elapsed / total;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CURRENT PRAYER BANNER
// ═══════════════════════════════════════════════════════════════════════════

class _CurrentPrayerBanner extends StatelessWidget {
  const _CurrentPrayerBanner({
    required this.prayerName,
    required this.endTime,
    required this.formatTime,
  });

  final String prayerName;
  final DateTime? endTime;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.prayedColor.withOpacity(0.13),
            AppColors.prayedColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.prayedColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.prayedColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 17,
              color: AppColors.prayedColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  prayerName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.prayedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (endTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ends at',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatTime(endTime!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.prayedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COUNTDOWN CIRCLE
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
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(108, 108),
            painter: _CountdownPainter(
              progress: progress,
              trackColor: colorScheme.surfaceContainerHighest,
              progressColor: colorScheme.primary,
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'IN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedDuration,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: colorScheme.primary,
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

// ═══════════════════════════════════════════════════════════════════════════
// COUNTDOWN PAINTER
// ═══════════════════════════════════════════════════════════════════════════

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
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
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

// ═══════════════════════════════════════════════════════════════════════════
// CARD SHELL
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// LOADING
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
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
