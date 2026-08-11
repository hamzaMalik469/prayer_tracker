library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../providers/statistics_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => stats.refresh(),
          ),
        ],
      ),
      body: stats.isLoading
          ? const Center(child: AppLoadingIndicator(size: 48))
          : stats.errorMessage != null
              ? _ErrorContent(
                  message: stats.errorMessage!,
                  onRetry: () => stats.refresh(),
                )
              : _StatisticsContent(provider: stats),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.provider});

  final StatisticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final streak = provider.streak;
    final stats = provider.statistics;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Period selector ──────────────────────────────────────────────
        _PeriodSelector(provider: provider),
        const SizedBox(height: AppSpacing.lg),

        // ── Streak ───────────────────────────────────────────────────────
        _SectionCard(
          title: 'Streaks',
          child: Row(
            children: [
              Expanded(
                child: _StreakStatItem(
                  label: 'Current',
                  value: streak.currentStreak,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: streak.currentStreak > 0
                      ? Colors.orange
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                  width: 1, height: 56, color: colorScheme.outlineVariant),
              Expanded(
                child: _StreakStatItem(
                  label: 'Best',
                  value: streak.longestStreak,
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.premiumGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Overview ─────────────────────────────────────────────────────
        if (stats != null) ...[
          _SectionCard(
            title: 'Overview',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Prayed',
                        value: stats.totalPrayed.toString(),
                        icon: Icons.check_circle_rounded,
                        iconColor: AppColors.prayedColor,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Missed',
                        value: stats.totalMissed.toString(),
                        icon: Icons.cancel_rounded,
                        iconColor: AppColors.missedColor,
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        label: 'Rate',
                        value:
                            '${(stats.overallCompletionPercentage * 100).toStringAsFixed(0)}%',
                        icon: Icons.bar_chart_rounded,
                        iconColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  label:
                      'Overall completion ${(stats.overallCompletionPercentage * 100).toStringAsFixed(0)} percent',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: stats.overallCompletionPercentage.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stats.totalDays} days tracked',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '${stats.totalPossible} possible prayers',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Per-prayer consistency ─────────────────────────────────────
          _SectionCard(
            title: 'Prayer Consistency',
            child: Column(
              children: PrayerTypeExtension.obligatory.map((type) {
                final consistency = stats.perPrayerConsistency[type];
                if (consistency == null) return const SizedBox.shrink();

                final pct = (consistency.consistencyPercentage * 100)
                    .toStringAsFixed(0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              type.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Semantics(
                              label: '${type.displayName} $pct percent',
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                                child: LinearProgressIndicator(
                                  value: consistency.consistencyPercentage
                                      .clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _consistencyColor(
                                      consistency.consistencyPercentage,
                                      colorScheme,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '$pct%',
                              textAlign: TextAlign.end,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _consistencyColor(
                                      consistency.consistencyPercentage,
                                      colorScheme,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const SizedBox(width: 72),
                          Expanded(
                            child: Text(
                              '${consistency.prayedCount} prayed · ${consistency.missedCount} missed',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Most missed insight ────────────────────────────────────────
          if (stats.mostMissedPrayer != null)
            _SectionCard(
              title: 'Insight',
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: stats.mostMissedPrayer!.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' is your most missed prayer this period.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Streak details ─────────────────────────────────────────────
          if (streak.streakStartDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: 'Streak Details',
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Current streak started',
                    value: _formatDate(streak.streakStartDate!),
                  ),
                  if (streak.lastFullyCompletedDate != null)
                    _DetailRow(
                      label: 'Last fully completed day',
                      value: _formatDate(streak.lastFullyCompletedDate!),
                    ),
                  _DetailRow(
                    label: 'All-time best streak',
                    value:
                        '${streak.longestStreak} ${streak.longestStreak == 1 ? "day" : "days"}',
                  ),
                ],
              ),
            ),
          ],
        ],

        // ── Empty state ──────────────────────────────────────────────────
        if (stats == null &&
            !provider.isLoading &&
            provider.errorMessage == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No statistics yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start tracking your prayers to see statistics here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Color _consistencyColor(double percentage, ColorScheme colorScheme) {
    if (percentage >= 0.9) return AppColors.prayedColor;
    if (percentage >= 0.7) return colorScheme.primary;
    if (percentage >= 0.5) return AppColors.warning;
    return AppColors.missedColor;
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

// ── Period Selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.provider});

  final StatisticsProvider provider;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatsPeriod>(
      segments: const [
        ButtonSegment(
          value: StatsPeriod.weekly,
          label: Text('Week'),
          icon: Icon(Icons.calendar_view_week_rounded, size: 16),
        ),
        ButtonSegment(
          value: StatsPeriod.monthly,
          label: Text('Month'),
          icon: Icon(Icons.calendar_view_month_rounded, size: 16),
        ),
        ButtonSegment(
          value: StatsPeriod.yearly,
          label: Text('Year'),
          icon: Icon(Icons.calendar_today_rounded, size: 16),
        ),
      ],
      selected: {provider.selectedPeriod},
      onSelectionChanged: (selected) {
        provider.changePeriod(period: selected.first);
      },
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Streak Stat Item ──────────────────────────────────────────────────────────

class _StreakStatItem extends StatelessWidget {
  const _StreakStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label streak: $value days',
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            value == 1 ? '1 day' : '$value days',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
