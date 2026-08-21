library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: const _NotificationContent(),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final times = context.watch<PrayerTimesProvider>().todayTimes;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        // ── Permission Warning Card ─────────────────────────────────────
        if (!provider.hasPermission)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: _PermissionCard(provider: provider),
          ),

        // ── Status Overview Card ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: provider.masterEnabled
                          ? AppColors.prayedColor.withOpacity(0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      provider.masterEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: provider.masterEnabled
                          ? AppColors.prayedColor
                          : colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.masterEnabled
                              ? 'Notifications Active'
                              : 'Notifications Off',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: provider.masterEnabled
                                        ? AppColors.prayedColor
                                        : colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.masterEnabled
                              ? 'Reminders enabled for prayers'
                              : 'Tap the switch to enable',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: provider.masterEnabled,
                    onChanged: (value) async {
                      await provider.setMasterEnabled(enabled: value);
                      if (!context.mounted) return;
                      AppSnackbar.showSuccess(
                        context,
                        value
                            ? 'Notifications enabled'
                            : 'Notifications disabled',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        if (provider.masterEnabled) ...[
          // ── Per Prayer Configuration Section ──────────────────────────
          const _SectionTitle(title: 'Per Prayer Reminders'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: PrayerTypeExtension.obligatory.map((type) {
                final config = provider.settings.configFor(type);
                final hasJamaah = times?.forType(type).hasJamaah ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PrayerCard(
                    config: config,
                    hasJamaah: hasJamaah,
                    onChanged: (updated) async {
                      final timesProv = context.read<PrayerTimesProvider>();
                      await provider.updatePrayerConfig(
                        config: updated,
                        todayTimes: timesProv.todayTimes,
                        tomorrowTimes: timesProv.tomorrowTimes,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Info Card ─────────────────────────────────────────────────
          const _SectionTitle(title: 'How it Works'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Card(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Notification Types',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InfoRow(
                      icon: Icons.alarm_rounded,
                      title: 'Adhan Reminder',
                      description: 'Alerts you at the prayer start time.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _InfoRow(
                      icon: Icons.people_alt_rounded,
                      title: 'Jama\'ah Reminder',
                      description: 'Reminds you before mosque Jama\'ah. '
                          'Only available when Jama\'ah times are set.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERMISSION CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.provider});

  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.onErrorContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                color: colorScheme.onErrorContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Required',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Enable in device settings to get prayer alerts.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => provider.requestPermission(),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onErrorContainer,
                foregroundColor: colorScheme.errorContainer,
                minimumSize: const Size(72, 36),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRAYER CARD — Per prayer notification configuration
// ═══════════════════════════════════════════════════════════════════════════

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.config,
    required this.hasJamaah,
    required this.onChanged,
  });

  final PrayerNotificationConfig config;
  final bool hasJamaah;
  final void Function(PrayerNotificationConfig) onChanged;

  IconData _iconFor(PrayerType type) => switch (type) {
        PrayerType.fajr => Icons.dark_mode_outlined,
        PrayerType.dhuhr => Icons.light_mode_outlined,
        PrayerType.asr => Icons.wb_cloudy_outlined,
        PrayerType.maghrib => Icons.nights_stay_outlined,
        PrayerType.isha => Icons.bedtime_outlined,
        _ => Icons.access_time_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          // ── Prayer Header + Master Toggle ──────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              config.enabled ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.enabled
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconFor(config.prayerType),
                    size: 22,
                    color: config.enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.prayerType.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        config.prayerType.arabicName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: (value) =>
                      onChanged(config.copyWith(enabled: value)),
                ),
              ],
            ),
          ),

          if (config.enabled) ...[
            const Divider(
                height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),

            // ── Adhan Reminder Section ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adhan Reminder',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              config.minutesBefore == 0
                                  ? 'At prayer start time'
                                  : '${config.minutesBefore} min before',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _TimeChip(
                        value: config.minutesBefore,
                        onChanged: (m) =>
                            onChanged(config.copyWith(minutesBefore: m)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Jama'ah Reminder Section ─────────────────────────────────
            if (hasJamaah) ...[
              const Divider(
                  height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: config.jamaahEnabled
                                ? AppColors.qadaCompletedColor.withOpacity(0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: config.jamaahEnabled
                                ? AppColors.qadaCompletedColor
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jama\'ah Reminder',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                config.jamaahEnabled
                                    ? '${config.minutesBeforeJamaah} min before Jama\'ah'
                                    : 'Disabled',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: config.jamaahEnabled,
                          onChanged: (value) =>
                              onChanged(config.copyWith(jamaahEnabled: value)),
                        ),
                      ],
                    ),
                    if (config.jamaahEnabled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Row(
                          children: [
                            Text(
                              'Remind me',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _TimeChip(
                              value: config.minutesBeforeJamaah,
                              onChanged: (m) => onChanged(
                                  config.copyWith(minutesBeforeJamaah: m)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'before',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Tip when no Jama'ah is configured
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Set Jama\'ah times in Settings to enable mosque reminders.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIME CHIP — Dropdown-style time picker
// ═══════════════════════════════════════════════════════════════════════════

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  static const _options = [0, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: DropdownButton<int>(
        value: _options.contains(value) ? value : 5,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          size: 18,
          color: colorScheme.onPrimaryContainer,
        ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
        items: _options
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(m == 0 ? 'At time' : '$m min'),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INFO ROW — used in info card
// ═══════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
