library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../../domain/entities/qada_record_entity.dart';
import '../providers/qada_provider.dart';

class QadaPage extends StatelessWidget {
  const QadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final qada = context.watch<QadaProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qada Prayers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add missed prayer to Qada',
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: !auth.isAuthenticated
          ? _buildNotSignedIn(context)
          : qada.isLoading
              ? const Center(child: AppLoadingIndicator(size: 48))
              : _buildBody(context, qada, auth),
    );
  }

  Widget _buildNotSignedIn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('Sign in to track Qada',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, QadaProvider qada, AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // How it works
        _HowItWorksCard(),
        const SizedBox(height: AppSpacing.md),

        // Summary header
        _SummaryCard(qada: qada),
        const SizedBox(height: AppSpacing.md),

        // Pending Qada list
        if (qada.summary.totalPending > 0) ...[
          Text('Pending Qada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: AppSpacing.sm),
          ...qada.summary.pendingSortedOldestFirst.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _QadaRecordCard(
                record: record,
                userId: auth.userId!,
                pending: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // // Completed Qada list
        // if (qada.summary.totalCompleted > 0) ...[
        //   Text('Completed Qada',
        //       style: Theme.of(context).textTheme.titleSmall?.copyWith(
        //             fontWeight: FontWeight.w700,
        //             color: AppColors.prayedColor,
        //           )),
        //   const SizedBox(height: AppSpacing.sm),
        //   ...qada.summary.completedRecords
        //       .take(20) // show last 20 completed
        //       .map(
        //         (record) => Padding(
        //           padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        //           child: _QadaRecordCard(
        //             record: record,
        //             userId: auth.userId!,
        //             pending: false,
        //           ),
        //         ),
        //       ),
        //   const SizedBox(height: AppSpacing.md),
        // ],

        // // Empty state
        // if (qada.summary.total == 0)
        //   _EmptyCard(onAdd: () => _showAddSheet(context)),

        // Disclaimer
        _Disclaimer(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddQadaSheet(),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: colorScheme.onPrimaryContainer, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('How Qada Works',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        )),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '1. Mark a prayer as Missed on the home screen\n'
              '2. Choose "Add to Qada" when prompted\n'
              '3. The missed prayer is saved with its original date\n'
              '4. When you make it up, tap "Complete" here\n'
              '5. The original prayer date shows as Qada Completed in the calendar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.qada});
  final QadaProvider qada;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  Text(
                    '${qada.summary.totalPending}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: qada.summary.totalPending > 0
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 48, color: colorScheme.outlineVariant),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Completed',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  Text(
                    '${qada.summary.totalCompleted}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.prayedColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 48, color: colorScheme.outlineVariant),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                  Text(
                    '${qada.summary.total}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
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
}

// ── Qada Record Card ──────────────────────────────────────────────────────────

class _QadaRecordCard extends StatelessWidget {
  const _QadaRecordCard({
    required this.record,
    required this.userId,
    required this.pending,
  });

  final QadaRecordEntity record;
  final String userId;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final qada = context.read<QadaProvider>();
    final dateStr = DateFormat('EEE, d MMM yyyy').format(record.missedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pending
                    ? colorScheme.errorContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                pending
                    ? Icons.hourglass_empty_rounded
                    : Icons.check_circle_rounded,
                color: pending
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.prayerType.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        record.prayerType.arabicName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    'Missed on $dateStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (record.completedAt != null)
                    Text(
                      'Completed ${DateFormat('d MMM yyyy').format(record.completedAt!)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.prayedColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    Text(
                      record.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),

            // Complete button
            if (pending)
              FilledButton(
                onPressed: qada.isUpdating
                    ? null
                    : () async {
                        final success = await qada.completeQadaRecord(
                          userId: userId,
                          record: record,
                        );
                        if (!context.mounted) return;
                        if (success) {
                          AppSnackbar.showSuccess(
                            context,
                            '${record.prayerType.displayName} Qada completed. '
                            'Calendar updated.',
                          );
                        } else {
                          AppSnackbar.showError(
                            context,
                            qada.errorMessage ?? 'Could not complete.',
                          );
                          qada.clearError();
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                child: const Text('Complete'),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 64, color: AppColors.prayedColor.withOpacity(0.8)),
            const SizedBox(height: AppSpacing.md),
            Text('No Qada Prayers',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your Qada balance is clear.\n'
              'Mark prayers as Missed on the home screen and add them here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Historical Missed Prayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'Note: Completing a Qada prayer updates the original missed date '
        'in the calendar to show "Qada Completed". This is a personal '
        'tracking tool only.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
      ),
    );
  }
}

// ── Add Qada Sheet ────────────────────────────────────────────────────────────

class _AddQadaSheet extends StatefulWidget {
  const _AddQadaSheet();

  @override
  State<_AddQadaSheet> createState() => _AddQadaSheetState();
}

class _AddQadaSheetState extends State<_AddQadaSheet> {
  PrayerType _selectedType = PrayerType.fajr;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select the date when this prayer was missed',
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) {
      AppSnackbar.showError(context, 'Please sign in to track Qada prayers.');
      return;
    }

    final qada = context.read<QadaProvider>();
    final success = await qada.addQadaRecord(
      userId: auth.userId!,
      missedDate: _selectedDate,
      prayerType: _selectedType,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      AppSnackbar.showSuccess(
        context,
        '${_selectedType.displayName} on '
        '${DateFormat('d MMM yyyy').format(_selectedDate)} '
        'added to Qada.',
      );
    } else {
      AppSnackbar.showError(
        context,
        qada.errorMessage ?? 'Could not add Qada record.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Add Missed Prayer to Qada',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select the prayer and the date it was missed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Prayer type chips
            Text('Prayer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: PrayerTypeExtension.obligatory.map((type) {
                final isSelected = type == _selectedType;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date picker
            Text('Date Missed',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          'Tap to change date',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.edit_rounded,
                        size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Was travelling, ill, etc.',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add ${_selectedType.displayName} '
                  '(${DateFormat('d MMM').format(_selectedDate)}) to Qada',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
