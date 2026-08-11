/// Notification settings UI.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
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
      appBar: AppBar(title: const Text('Notifications')),
      body: const _NotificationSettingsContent(),
    );
  }
}

class _NotificationSettingsContent extends StatelessWidget {
  const _NotificationSettingsContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // Permission status
        if (!provider.hasPermission) _PermissionBanner(provider: provider),

        // Master switch
        SwitchListTile(
          title: const Text('Prayer Notifications'),
          subtitle: const Text(
            'Receive reminders for the five daily prayers',
          ),
          value: provider.masterEnabled,
          onChanged: (value) async {
            await provider.setMasterEnabled(enabled: value);
            if (!context.mounted) return;
            AppSnackbar.showSuccess(
              context,
              value ? 'Notifications enabled' : 'Notifications disabled',
            );
          },
        ),

        const Divider(height: 1),

        if (provider.masterEnabled) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'PER PRAYER',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
          ),

          // Per-prayer configuration
          ...PrayerTypeExtension.obligatory.map((type) {
            final config = provider.settings.configFor(type);
            return _PrayerNotificationTile(
              config: config,
              onChanged: (updated) async {
                final times = context.read<PrayerTimesProvider>();
                await provider.updatePrayerConfig(
                  config: updated,
                  todayTimes: times.todayTimes,
                  tomorrowTimes: times.tomorrowTimes,
                );
              },
            );
          }),
        ],
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.provider});

  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are disabled',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable notifications to receive prayer reminders.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.requestPermission(),
            child: Text(
              'Enable',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerNotificationTile extends StatelessWidget {
  const _PrayerNotificationTile({
    required this.config,
    required this.onChanged,
  });

  final PrayerNotificationConfig config;
  final void Function(PrayerNotificationConfig) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(config.prayerType.displayName),
          subtitle: Text(
            config.minutesBefore == 0
                ? 'At prayer time'
                : '${config.minutesBefore} min before',
          ),
          value: config.enabled,
          onChanged: (value) => onChanged(config.copyWith(enabled: value)),
        ),
        if (config.enabled)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16),
                const SizedBox(width: AppSpacing.sm),
                const Text('Remind me'),
                const SizedBox(width: AppSpacing.sm),
                _MinutesSelector(
                  value: config.minutesBefore,
                  onChanged: (minutes) =>
                      onChanged(config.copyWith(minutesBefore: minutes)),
                ),
                const Text(' min before'),
              ],
            ),
          ),
        const Divider(height: 1, indent: AppSpacing.md),
      ],
    );
  }
}

class _MinutesSelector extends StatelessWidget {
  const _MinutesSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  static const _options = [0, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButton<int>(
      value: _options.contains(value) ? value : 0,
      underline: const SizedBox.shrink(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
      items: _options
          .map(
            (m) => DropdownMenuItem(
              value: m,
              child: Text(m.toString()),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
