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
        PrayerStatus.qadaCompleted => AppColors.qadaCompletedColor,
        PrayerStatus.notRecorded => AppColors.notRecordedColor,
      };

  IconData _statusIcon(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => Icons.check_circle_rounded,
        PrayerStatus.prayedLate => Icons.check_circle_outline_rounded,
        PrayerStatus.missed => Icons.cancel_rounded,
        PrayerStatus.qadaCompleted => Icons.replay_circle_filled_rounded,
        PrayerStatus.notRecorded => Icons.radio_button_unchecked_rounded,
      };

  String _statusLabel(PrayerStatus status) => switch (status) {
        PrayerStatus.prayed => 'Prayed',
        PrayerStatus.prayedLate => 'Prayed Late',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.qadaCompleted => 'Qada Completed',
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

    final now = DateTime.now();
    final isUpcoming = prayerTime.isUpcoming(now);
    final isActive = prayerTime.isActive(now);
    final hasPassed = prayerTime.hasPassed(now);

    // Disable tracking for prayers that have not arrived yet.
    // Allow tracking for active and passed prayers.
    final canTrack = !isUpcoming && auth.hasUserId && !isRecording;

    // Visual emphasis for the currently active prayer.
    final cardColor =
        isActive ? colorScheme.primaryContainer.withOpacity(0.3) : null;

    return Semantics(
      label: '${prayerTime.prayerType.displayName} prayer. '
          '${_statusLabel(status)}. '
          'Time: ${_formatTime(prayerTime.time)}.'
          '${isUpcoming ? ' Not yet arrived.' : ''}',
      button: canTrack,
      child: Opacity(
        opacity: isUpcoming ? 0.5 : 1.0,
        child: Card(
          color: cardColor,
          child: InkWell(
            onTap: canTrack
                ? () async {
                    HapticFeedback.lightImpact();
                    await tracking.togglePrayer(
                      userId: auth.userId!,
                      prayerType: prayerTime.prayerType,
                    );
                  }
                : null,
            onLongPress: canTrack
                ? () => _showStatusSheet(context, auth.userId!, tracking)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // ── Status icon / active indicator ─────────────────────
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
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _statusIcon(status),
                                key: ValueKey(status),
                                color: isUpcoming
                                    ? colorScheme.onSurfaceVariant
                                    : statusColor,
                                size: 28,
                              ),
                              // Active prayer pulse ring
                              if (isActive &&
                                  status == PrayerStatus.notRecorded)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          colorScheme.primary.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // ── Prayer name + Arabic + time window ────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              prayerTime.prayerType.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  'NOW',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9,
                                      ),
                                ),
                              ),
                            ],
                            if (isUpcoming) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                            if (prayerTime.isCustom) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: colorScheme.primary.withOpacity(0.6),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          prayerTime.prayerType.arabicName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // ── Time + end time + status ──────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Start time
                      Row(
                        children: [
                          Text(
                            _formatTime(prayerTime.time),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),

                          // End time
                          if (prayerTime.endTime != null)
                            Text(
                              '  ---> ${_formatTime(prayerTime.endTime!)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                        ],
                      ),

                      // Status label
                      if (!isUpcoming)
                        Text(
                          _statusLabel(status),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      if (isUpcoming)
                        Text(
                          'Upcoming',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Status bottom sheet ───────────────────────────────────────────────────

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
              child: Row(children: [
                Text(prayerTime.prayerType.displayName,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: AppSpacing.sm),
                Text(prayerTime.prayerType.arabicName,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ]),
            ),
            const Divider(height: 1),
            _StatusOption(
              icon: Icons.check_circle_rounded,
              label: 'Prayed',
              subtitle: 'Completed on time',
              color: AppColors.prayedColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                    userId: userId,
                    prayerType: prayerTime.prayerType,
                    status: PrayerStatus.prayed);
              },
            ),
            _StatusOption(
              icon: Icons.check_circle_outline_rounded,
              label: 'Prayed Late',
              subtitle: 'Completed after the window',
              color: AppColors.prayedLateColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                    userId: userId,
                    prayerType: prayerTime.prayerType,
                    status: PrayerStatus.prayedLate);
              },
            ),
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
            _StatusOption(
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Clear Record',
              subtitle: 'Remove the record',
              color: AppColors.notRecordedColor,
              onTap: () {
                Navigator.pop(ctx);
                tracking.recordPrayer(
                    userId: userId,
                    prayerType: prayerTime.prayerType,
                    status: PrayerStatus.notRecorded);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMissed(
    BuildContext context,
    String userId,
    PrayerTrackingProvider tracking,
  ) async {
    await tracking.recordPrayer(
      userId: userId,
      prayerType: prayerTime.prayerType,
      status: PrayerStatus.missed,
    );
    if (!context.mounted) return;

    final addToQada = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.replay_rounded,
            color: Theme.of(ctx).colorScheme.primary, size: 36),
        title: Text('${prayerTime.prayerType.displayName} Missed'),
        content: Text(
          'Add this missed ${prayerTime.prayerType.displayName} '
          'to your Qada list?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No thanks')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add to Qada')),
        ],
      ),
    );
    if (!context.mounted || addToQada != true) return;

    final qada = context.read<QadaProvider>();
    final today = DateTime.now();
    final success = await qada.addQadaRecord(
      userId: userId,
      missedDate: DateTime(today.year, today.month, today.day),
      prayerType: prayerTime.prayerType,
    );
    if (!context.mounted) return;
    if (success) {
      AppSnackbar.showSuccess(
          context, '${prayerTime.prayerType.displayName} added to Qada.');
    } else {
      AppSnackbar.showError(
          context, qada.errorMessage ?? 'Could not add to Qada.');
      qada.clearError();
    }
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      onTap: onTap,
      minVerticalPadding: AppSpacing.sm,
    );
  }
}
