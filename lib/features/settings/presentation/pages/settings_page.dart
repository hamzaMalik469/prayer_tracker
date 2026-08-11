library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/domain/entities/prayer_settings_entity.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        // ── Prayer Settings ─────────────────────────────────────────────
        _SectionHeader(title: 'Prayer Calculation'),
        ListTile(
          title: const Text('Calculation Method'),
          subtitle: Text(settings.prayerSettings.calculationMethod.displayName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showCalculationMethodSheet(context, settings),
        ),
        ListTile(
          title: const Text('Madhab'),
          subtitle: Text(settings.prayerSettings.madhab.displayName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showMadhabSheet(context, settings),
        ),
        ListTile(
          title: const Text('High Latitude Rule'),
          subtitle: Text(settings.prayerSettings.highLatitudeRule.displayName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showHighLatitudeSheet(context, settings),
        ),

        // ── Appearance ──────────────────────────────────────────────────
        _SectionHeader(title: 'Appearance'),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(_themeName(settings.themeMode)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showThemeSheet(context, settings),
        ),

        // ── Account ─────────────────────────────────────────────────────
        _SectionHeader(title: 'Account'),
        if (auth.isAuthenticated) ...[
          ListTile(
            leading:
                Icon(Icons.person_outline_rounded, color: colorScheme.primary),
            title: Text(
              auth.user?.displayName ?? auth.user?.email ?? 'User',
            ),
            subtitle: auth.user?.email != null ? Text(auth.user!.email) : null,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign Out'),
            onTap: () => _confirmSignOut(context),
          ),
          ListTile(
            leading:
                Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ] else ...[
          ListTile(
            leading: Icon(Icons.login_rounded, color: colorScheme.primary),
            title: const Text('Sign In'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };

  void _showCalculationMethodSheet(
    BuildContext context,
    SettingsProvider settings,
  ) {
    _showSelectionSheet<CalculationMethodEntity>(
      context: context,
      title: 'Calculation Method',
      values: CalculationMethodEntity.values,
      selected: settings.prayerSettings.calculationMethod,
      labelOf: (m) => m.displayName,
      onSelected: (method) {
        settings.updatePrayerSettings(
          settings.prayerSettings.copyWith(calculationMethod: method),
        );
      },
    );
  }

  void _showMadhabSheet(BuildContext context, SettingsProvider settings) {
    _showSelectionSheet<MadhabEntity>(
      context: context,
      title: 'Madhab',
      values: MadhabEntity.values,
      selected: settings.prayerSettings.madhab,
      labelOf: (m) => m.displayName,
      onSelected: (madhab) {
        settings.updatePrayerSettings(
          settings.prayerSettings.copyWith(madhab: madhab),
        );
      },
    );
  }

  void _showHighLatitudeSheet(
    BuildContext context,
    SettingsProvider settings,
  ) {
    _showSelectionSheet<HighLatitudeRuleEntity>(
      context: context,
      title: 'High Latitude Rule',
      values: HighLatitudeRuleEntity.values,
      selected: settings.prayerSettings.highLatitudeRule,
      labelOf: (r) => r.displayName,
      onSelected: (rule) {
        settings.updatePrayerSettings(
          settings.prayerSettings.copyWith(highLatitudeRule: rule),
        );
      },
    );
  }

  void _showThemeSheet(BuildContext context, SettingsProvider settings) {
    _showSelectionSheet<ThemeMode>(
      context: context,
      title: 'Theme',
      values: ThemeMode.values,
      selected: settings.themeMode,
      labelOf: (m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      },
      onSelected: settings.updateThemeMode,
    );
  }

  void _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
  }) {
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
              child: Text(
                title,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: values.map((value) {
                  final isSelected = value == selected;
                  return Semantics(
                    selected: isSelected,
                    child: ListTile(
                      title: Text(labelOf(value)),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded,
                              color: colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(value);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: colorScheme.error),
        ),
        content: const Text(
          'This will permanently delete your account and all prayer data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await context.read<AuthProvider>().deleteAccount();
    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else {
      AppSnackbar.showError(
        context,
        'Could not delete account. Please sign in again and try.',
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
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
