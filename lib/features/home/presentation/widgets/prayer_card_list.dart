library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../../prayer_times/presentation/providers/prayer_times_provider.dart';
import '../../../prayer_tracking/domain/entities/prayer_record_entity.dart';
import '../../../prayer_tracking/presentation/providers/prayer_tracking_provider.dart';
import '../../../qada/presentation/providers/qada_provider.dart';

class PrayerCardList extends StatelessWidget {
  const PrayerCardList({super.key});

  @override
  Widget build(BuildContext context) {
    final times = context.watch<PrayerTimesProvider>().todayTimes;
    if (times == null) return const SizedBox.shrink();

    return Column(
      children: times.obligatory.map((prayerTime) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: PrayerCard(prayerTime: prayerTime),
        );
      }).toList(),
    );
  }
}

class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key, required this.prayerTime});

  final PrayerTimeEntity prayerTime;

  String _formatTime(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Color _statusColor(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => AppColors.prayedColor,
        PrayerStatus.prayedLate => AppColors.prayedLateColor,
        PrayerStatus.missed => AppColors.missedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor,
      };

  IconData _statusIcon(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => Icons.check_circle_rounded,
        PrayerStatus.prayedLate => Icons.check_circle_outline_rounded,
        PrayerStatus.missed => Icons.cancel_rounded,
        PrayerStatus.notRecorded => Icons.radio_button_unchecked_rounded,
      };

  String _statusLabel(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => 'Prayed',
        PrayerStatus.prayedLate => 'Prayed Late',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.notRecorded => 'Not recorded',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final tracking = context.watch<PrayerTrackingProvider>();

    final status = tracking.statusFor(prayerTime.prayerType);
    final isRecording = tracking.isRecordingPrayer(prayerTime.prayerType);
    final statusColor = _statusColor(status);

    return Semantics(
      label: '${prayerTime.prayerType.displayName} prayer. '
          '${_statusLabel(status)}. '
          'Prayer time: ${_formatTime(prayerTime.time)}.',
      button: true,
      child: Card(
        child: InkWell(
          onTap: isRecording || auth.userId == null
              ? null
              : () async {
                  HapticFeedback.lightImpact();
                  await tracking.togglePrayer(
                    userId: auth.userId!,
                    prayerType: prayerTime.prayerType,
                  );
                },
          onLongPress: isRecording || auth.userId == null
              ? null
              : () => _showStatusSheet(context, auth.userId!, tracking),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Status icon
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: isRecording
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.primary,
                          ),
                        )
                      : Icon(
                          _statusIcon(status),
                          key: ValueKey(status),
                          color: statusColor,
                          size: 28,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Prayer name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayerTime.prayerType.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        prayerTime.prayerType.arabicName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                // Time + status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(prayerTime.time),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusSheet(
    BuildContext context,
    String userId,
    PrayerTrackingProvider tracking,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    prayerTime.prayerType.displayName,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    prayerTime.prayerType.arabicName,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Prayed
            _StatusOption(
              icon: Icons.check_circle_rounded,
              label: 'Prayed',
              subtitle: 'Marked as completed on time',
              color: AppColors.prayedColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                  userId: userId,
                  prayerType: prayerTime.prayerType,
                  status: PrayerStatus.prayed,
                );
              },
            ),

            // Prayed Late
            _StatusOption(
              icon: Icons.check_circle_outline_rounded,
              label: 'Prayed Late',
              subtitle: 'Completed after the prayer window',
              color: AppColors.prayedLateColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                  userId: userId,
                  prayerType: prayerTime.prayerType,
                  status: PrayerStatus.prayedLate,
                );
              },
            ),

            // Missed — shows Qada dialog
            _StatusOption(
              icon: Icons.cancel_rounded,
              label: 'Missed',
              subtitle: 'Mark as missed — optionally add to Qada',
              color: AppColors.missedColor,
              onTap: () {
                Navigator.pop(ctx);
                _handleMissed(context, userId, tracking);
              },
            ),

            // Clear
            _StatusOption(
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Clear Record',
              subtitle: 'Remove the record for this prayer',
              color: AppColors.notRecordedColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                  userId: userId,
                  prayerType: prayerTime.prayerType,
                  status: PrayerStatus.notRecorded,
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Marks as missed then asks if user wants to add to Qada.
  Future<void> _handleMissed(
    BuildContext context,
    String userId,
    PrayerTrackingProvider tracking,
  ) async {
    // First record as missed.
    await tracking.recordPrayer(
      userId: userId,
      prayerType: prayerTime.prayerType,
      status: PrayerStatus.missed,
    );

    if (!context.mounted) return;

    // Then ask about Qada.
    final addToQada = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.replay_rounded,
          color: Theme.of(ctx).colorScheme.primary,
          size: 32,
        ),
        title: Text(
          '${prayerTime.prayerType.displayName} Missed',
        ),
        content: Text(
          'Would you like to add this missed '
          '${prayerTime.prayerType.displayName} prayer to your '
          'Qada balance so you can make it up later?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No thanks'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add to Qada'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (addToQada != true) return;

    // Add 1 to Qada balance.
    final qada = context.read<QadaProvider>();
    final success = await qada.addMissed(
      userId: userId,
      prayerType: prayerTime.prayerType,
      quantity: 1,
    );

    if (!context.mounted) return;

    if (success) {
      AppSnackbar.showSuccess(
        context,
        '${prayerTime.prayerType.displayName} added to Qada balance.',
      );
    } else {
      AppSnackbar.showError(
        context,
        'Could not add to Qada. Please add manually in the Qada tab.',
      );
    }
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: onTap,
      minVerticalPadding: AppSpacing.sm,
    );
  }
}
