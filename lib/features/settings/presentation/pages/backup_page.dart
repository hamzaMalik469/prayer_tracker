library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/helpers/guest_user_helper.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isSyncing = false;
  SyncResult? _lastResult;
  DateTime? _lastSyncTime;

  Future<void> _syncNow() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    if (GuestUserHelper.isGuestId(auth.userId!)) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        'Sign in to back up your data to the cloud.',
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final result = await sl<SyncService>().syncAll(userId: auth.userId!);

      if (!mounted) return;

      setState(() {
        _isSyncing = false;
        _lastResult = result;
        _lastSyncTime = DateTime.now();
      });

      if (result.hasErrors) {
        AppSnackbar.showError(
          context,
          'Sync completed with ${result.errors} errors. '
          '${result.totalSynced} records synced.',
        );
      } else if (result.totalSynced > 0) {
        AppSnackbar.showSuccess(
          context,
          '${result.totalSynced} records synced successfully.',
        );
      } else {
        AppSnackbar.showSuccess(
          context,
          'Everything is up to date.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      AppSnackbar.showError(
        context,
        'Sync failed. Please check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Sync')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Sync status card ────────────────────────────────────────────
          _StatusCard(
            isGuest: isGuest,
            isAuthenticated: auth.isAuthenticated,
            lastSyncTime: _lastSyncTime,
            lastResult: _lastResult,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── How it works ────────────────────────────────────────────────
          _InfoCard(),
          const SizedBox(height: AppSpacing.md),

          // ── Sync button ─────────────────────────────────────────────────
          if (!isGuest) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_sync_rounded),
                label: Text(_isSyncing ? 'Syncing…' : 'Sync Now'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Guest sign-in prompt ────────────────────────────────────────
          if (isGuest) _GuestPrompt(),

          // ── Data info ───────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.md),
          _DataInfoCard(),
        ],
      ),
    );
  }
}

// ── Status Card ─────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isGuest,
    required this.isAuthenticated,
    required this.lastSyncTime,
    required this.lastResult,
  });

  final bool isGuest;
  final bool isAuthenticated;
  final DateTime? lastSyncTime;
  final SyncResult? lastResult;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusSubtitle;

    if (isGuest) {
      statusColor = AppColors.warning;
      statusIcon = Icons.cloud_off_rounded;
      statusTitle = 'Local Only';
      statusSubtitle = 'Your data is stored on this device only. '
          'Sign in to enable cloud backup.';
    } else if (lastResult != null && !lastResult!.hasErrors) {
      statusColor = AppColors.prayedColor;
      statusIcon = Icons.cloud_done_rounded;
      statusTitle = 'Synced';
      statusSubtitle = lastSyncTime != null
          ? 'Last synced: ${_formatTime(lastSyncTime!)}'
          : 'Your data is backed up to the cloud.';
    } else if (lastResult != null && lastResult!.hasErrors) {
      statusColor = AppColors.missedColor;
      statusIcon = Icons.cloud_off_rounded;
      statusTitle = 'Sync Issues';
      statusSubtitle =
          '${lastResult!.errors} records failed to sync. Try again.';
    } else {
      statusColor = colorScheme.primary;
      statusIcon = Icons.cloud_outlined;
      statusTitle = isAuthenticated ? 'Cloud Backup Active' : 'Not Connected';
      statusSubtitle = isAuthenticated
          ? 'Tap Sync Now to force a sync.'
          : 'Sign in to enable backup.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ── Info Card ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('How Backup Works',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '• All prayer records are saved locally first\n'
              '• Data syncs automatically when you are signed in and online\n'
              '• Offline changes sync when you reconnect\n'
              '• Guest users keep data on device only\n'
              '• Sign in to sync across multiple devices\n'
              '• Tap "Sync Now" to force an immediate backup',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest Sign-In Prompt ────────────────────────────────────────────────────

class _GuestPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: colorScheme.onErrorContainer, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your data is not backed up',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'If you uninstall the app or switch devices, '
              'all your prayer history will be lost. '
              'Create an account to keep your data safe.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onErrorContainer,
                foregroundColor: colorScheme.errorContainer,
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Info Card ──────────────────────────────────────────────────────────

class _DataInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: AppSpacing.md),
            _DataRow(
              icon: Icons.mosque_outlined,
              label: 'Prayer Records',
              description: 'Stored locally + cloud (if signed in)',
            ),
            _DataRow(
              icon: Icons.replay_rounded,
              label: 'Qada Records',
              description: 'Stored locally + cloud (if signed in)',
            ),
            _DataRow(
              icon: Icons.settings_outlined,
              label: 'Settings',
              description: 'Stored locally + cloud (if signed in)',
            ),
            _DataRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              description: 'Stored locally only — never uploaded',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your precise location is never shared or uploaded. '
              'It is used only to calculate prayer times on your device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                Text(description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
