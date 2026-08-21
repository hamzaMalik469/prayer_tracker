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
        PrayerStatus.prayed => Icons.people_alt_rounded,
        PrayerStatus.prayedLate => Icons.person,
        PrayerStatus.missed => Icons.cancel_rounded,
        PrayerStatus.qadaCompleted => Icons.replay_circle_filled_rounded,
        PrayerStatus.notRecorded => Icons.radio_button_unchecked_rounded,
      };

  String _statusLabel(PrayerStatus status) => switch (status) {
        PrayerStatus.notRecorded => 'Not Recorded',
        PrayerStatus.prayed => 'With Jammah',
        PrayerStatus.missed => 'Missed',
        PrayerStatus.prayedLate => 'On Time',
        PrayerStatus.qadaCompleted => 'Qada Prayed'
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

    final canTrack = !isUpcoming && auth.hasUserId && !isRecording;

    final cardColor =
        isActive ? colorScheme.primaryContainer.withOpacity(0.2) : null;

    return Semantics(
      label: '${prayerTime.prayerType.displayName} prayer. '
          '${_statusLabel(status)}. '
          'Adhan start: ${_formatTime(prayerTime.time)}.'
          '${prayerTime.hasJamaah ? " Jamaah Jama\'ah time: ${_formatTime(prayerTime.jamaahTime!)}" : ""}',
      button: canTrack,
      child: Opacity(
        opacity: isUpcoming ? 0.55 : 1.0,
        child: Card(
          color: cardColor,
          elevation: isActive ? AppElevation.medium : AppElevation.low,
          child: InkWell(
            // onTap: canTrack
            //     ? () async {
            //         HapticFeedback.lightImpact();
            //         await tracking.togglePrayer(
            //           userId: auth.userId!,
            //           prayerType: prayerTime.prayerType,
            //         );
            //       }
            //     : null,
            onTap: canTrack
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
                  // ── Tracker status indicator icon ─────────────────────
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
                                        .withOpacity(0.5)
                                    : statusColor,
                                size: 28,
                              ),
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

                  // ── Prayer Identifier Details ─────────────────────────
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
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                ),
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
                        const SizedBox(height: AppSpacing.xs),

                        // 👥 JAMA'AH PILL INDICATOR
                        if (prayerTime.hasJamaah)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary.withOpacity(0.15)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 11,
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Jama\'ah: ${_formatTime(prayerTime.jamaahTime!)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: isActive
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Astronomical Timings and Closing Boundary ─────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(prayerTime.time),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (prayerTime.endTime != null)
                        Text(
                          'ends ${_formatTime(prayerTime.endTime!)}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                      const SizedBox(height: 2),
                      if (!isUpcoming)
                        Text(
                          _statusLabel(status),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      if (isUpcoming)
                        Text(
                          'Upcoming',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.6),
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
              label: 'With Jammah',
              subtitle: 'Completed on time with Jammah in Masjid',
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
              label: 'On time',
              subtitle: 'Completed in allowed time of the prayer',
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
              label: 'Missed/Qada',
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
          SizedBox(
            height: 10,
          ),
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
