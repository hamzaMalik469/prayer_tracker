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
        // ── Permission Warning ──────────────────────────────────────────
        if (!provider.hasPermission)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: _PermissionCard(provider: provider),
          ),

        // ── Master Status Card ──────────────────────────────────────────
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
          _SectionTitle(title: 'Per Prayer Reminders'),

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
                      final tp = context.read<PrayerTimesProvider>();
                      await provider.updatePrayerConfig(
                        config: updated,
                        todayTimes: tp.todayTimes,
                        tomorrowTimes: tp.tomorrowTimes,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Info Card ─────────────────────────────────────────────────
          _SectionTitle(title: 'How it Works'),

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
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: colorScheme.primary),
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
                    _InfoRow(
                      icon: Icons.alarm_rounded,
                      title: 'Adhan Reminder',
                      description:
                          'Alerts you at the astronomical prayer start time.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoRow(
                      icon: Icons.people_alt_rounded,
                      title: 'Jama\'ah Reminder',
                      description: 'Reminds you before mosque congregation. '
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.onErrorContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.notifications_off_rounded,
                  color: cs.onErrorContainer, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Permission Required',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w700)),
                  Text('Enable in device settings to get prayer alerts.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onErrorContainer)),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => provider.requestPermission(),
              style: FilledButton.styleFrom(
                backgroundColor: cs.onErrorContainer,
                foregroundColor: cs.errorContainer,
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
// PRAYER CARD — Per-prayer config with Adhan + Jama'ah switches
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
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          // ── Header + Master Toggle ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                AppSpacing.md, config.enabled ? AppSpacing.sm : AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: config.enabled
                        ? cs.primary.withOpacity(0.1)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_iconFor(config.prayerType),
                      size: 22,
                      color: config.enabled ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.prayerType.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(config.prayerType.arabicName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: (v) => onChanged(config.copyWith(enabled: v)),
                ),
              ],
            ),
          ),

          if (config.enabled) ...[
            const Divider(
                height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),

            // ── ADHAN REMINDER SECTION (with switch) ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: config.adhanEnabled
                              ? cs.primary.withOpacity(0.1)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(Icons.alarm_rounded,
                            size: 16,
                            color: config.adhanEnabled
                                ? cs.primary
                                : cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Adhan Reminder',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              config.adhanEnabled
                                  ? (config.minutesBefore == 0
                                      ? 'At prayer start time'
                                      : '${config.minutesBefore} min before')
                                  : 'Disabled',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: config.adhanEnabled,
                        onChanged: (v) =>
                            onChanged(config.copyWith(adhanEnabled: v)),
                      ),
                    ],
                  ),
                  if (config.adhanEnabled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Row(
                        children: [
                          Text('Remind me',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          const SizedBox(width: AppSpacing.sm),
                          _TimeChip(
                            value: config.minutesBefore,
                            onChanged: (m) =>
                                onChanged(config.copyWith(minutesBefore: m)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('before Adhan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── JAMA'AH REMINDER SECTION (with switch) ───────────────────
            if (hasJamaah) ...[
              const Divider(
                  height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(Icons.people_alt_rounded,
                              size: 16,
                              color: config.jamaahEnabled
                                  ? AppColors.qadaCompletedColor
                                  : cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jama\'ah Reminder',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                config.jamaahEnabled
                                    ? '${config.minutesBeforeJamaah} min before congregation'
                                    : 'Disabled',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: config.jamaahEnabled,
                          onChanged: (v) =>
                              onChanged(config.copyWith(jamaahEnabled: v)),
                        ),
                      ],
                    ),
                    if (config.jamaahEnabled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Row(
                          children: [
                            Text('Remind me',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(width: AppSpacing.sm),
                            _TimeChip(
                              value: config.minutesBeforeJamaah,
                              onChanged: (m) => onChanged(
                                  config.copyWith(minutesBeforeJamaah: m)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('before Jama\'ah',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Set Jama\'ah times in Settings to enable mosque reminders.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
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
// TIME CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.value, required this.onChanged});

  final int value;
  final void Function(int) onChanged;

  static const _options = [0, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: DropdownButton<int>(
        value: _options.contains(value) ? value : 5,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: Icon(Icons.arrow_drop_down_rounded,
            size: 18, color: cs.onPrimaryContainer),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
        items: _options
            .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m == 0 ? 'At time' : '$m min'),
                ))
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
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INFO ROW
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(description,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
