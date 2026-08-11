library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = context.watch<StatisticsProvider>();
    final streak = stats.streak;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Current Streak',
                  value: streak.currentStreak,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: streak.currentStreak > 0
                      ? Colors.orange
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: colorScheme.outlineVariant,
              ),
              Expanded(
                child: _StreakStat(
                  label: 'Best Streak',
                  value: streak.longestStreak,
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.premiumGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
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
      label: '$label: $value days',
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.toString(),
            style: AppTextStyles.streakDisplay.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
            ),
          ),
          Text(
            value == 1 ? '1 day' : '$value days',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
