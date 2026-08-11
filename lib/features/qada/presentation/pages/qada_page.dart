library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../prayer_times/domain/entities/prayer_time_entity.dart';
import '../providers/qada_provider.dart';

class QadaPage extends StatelessWidget {
  const QadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final qada = context.watch<QadaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qada Prayers'),
        actions: [
          IconButton(
            onPressed: () => _showAddMissedSheet(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add missed prayers',
          ),
        ],
      ),
      body: qada.isLoading
          ? const Center(child: AppLoadingIndicator(size: 48))
          : _QadaContent(provider: qada),
    );
  }

  void _showAddMissedSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddQadaSheet(),
    );
  }
}

class _QadaContent extends StatelessWidget {
  const _QadaContent({required this.provider});

  final QadaProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final balance = provider.balance;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Balance summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qada Balance',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  label: 'Total Qada remaining: ${balance.total}',
                  child: Row(
                    children: [
                      Text(
                        '${balance.total}',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'prayers remaining',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppSpacing.xl),
                ...PrayerTypeExtension.obligatory.map((type) {
                  final count = balance.balanceFor(type);
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(type.displayName),
                        ),
                        Expanded(
                          child: Text(
                            count.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: count > 0
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (count > 0)
                          FilledButton.tonal(
                            onPressed: provider.isUpdating
                                ? null
                                : () => _completeOne(context, type),
                            style: FilledButton.styleFrom(
                              minimumSize:
                                  const Size(80, AppTouchTargets.minimum),
                            ),
                            child: const Text('Complete 1'),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Disclaimer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Note: Qada completion here records your makeup prayers '
            'as a personal tracker. This does not affect today\'s prayer records.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeOne(
    BuildContext context,
    PrayerType type,
  ) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    final qada = context.read<QadaProvider>();
    final success = await qada.completeQada(
      userId: auth.userId!,
      prayerType: type,
      quantity: 1,
    );

    if (!context.mounted) return;

    if (success) {
      AppSnackbar.showSuccess(
        context,
        '${type.displayName} Qada recorded.',
      );
    } else if (qada.errorMessage != null) {
      AppSnackbar.showError(context, qada.errorMessage!);
      qada.clearError();
    }
  }
}

class _AddQadaSheet extends StatefulWidget {
  const _AddQadaSheet();

  @override
  State<_AddQadaSheet> createState() => _AddQadaSheetState();
}

class _AddQadaSheetState extends State<_AddQadaSheet> {
  PrayerType _selectedType = PrayerType.fajr;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      AppSnackbar.showError(context, 'Please enter a valid quantity.');
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    final qada = context.read<QadaProvider>();
    final success = await qada.addMissed(
      userId: auth.userId!,
      prayerType: _selectedType,
      quantity: quantity,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      AppSnackbar.showSuccess(
        context,
        'Added $quantity ${_selectedType.displayName} to Qada balance.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Missed Prayers',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<PrayerType>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Prayer'),
            items: PrayerTypeExtension.obligatory.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: 'Number of missed prayers',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add to Qada Balance'),
            ),
          ),
        ],
      ),
    );
  }
}
